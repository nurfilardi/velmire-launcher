import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/server.dart';
import '../platform/native_bridge.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class NicknameSheet extends StatefulWidget {
  final Server server;

  const NicknameSheet({super.key, required this.server});

  static Future<void> show(BuildContext context, Server server) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => NicknameSheet(server: server),
    );
  }

  @override
  State<NicknameSheet> createState() => _NicknameSheetState();
}

class _NicknameSheetState extends State<NicknameSheet> {
  late final _nick = TextEditingController();
  final _password = TextEditingController();
  final _bridge = NativeBridge();
  String? _error;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nick.text.isEmpty) {
      _nick.text = AppScope.of(context).nickFor(widget.server);
    }
  }

  @override
  void dispose() {
    _nick.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final state = AppScope.of(context);
    final nick = _nick.text.trim();
    if (nick.length < 3 || nick.length > 20 || RegExp(r'\s').hasMatch(nick)) {
      setState(() => _error = 'Nick 3–20 karakter, tanpa spasi.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      var access = await _bridge.hasStorageAccess();
      if (!access) access = await _bridge.requestStorageAccess();
      if (!access) {
        setState(() => _error = 'Akses folder GTA ditolak. Buka Pengaturan lalu izinkan.');
        return;
      }
      final installed = await _bridge.isInstalled(state.config.clientPackage);
      if (!installed) {
        setState(() => _error =
            'Klien ${state.config.clientPackage} belum terpasang. Install APK dulu di Pengaturan.');
        return;
      }
      await state.saveNick(widget.server.address, nick);
      await state.gameData.saveClient(
        name: nick,
        host: widget.server.host,
        port: widget.server.port,
        password: _password.text,
      );
      final launched = await _bridge.launchGame(
        package: state.config.clientPackage,
        activity: state.config.clientActivity,
      );
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: widget.server.address));
        if (mounted) {
          setState(() => _error = 'Gagal membuka klien. Alamat disalin ke clipboard.');
        }
        return;
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal menyiapkan game: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.server.name.isEmpty ? widget.server.address : widget.server.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.display,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.server.address} · ${widget.server.players}/${widget.server.maxPlayers} player',
              style: const TextStyle(fontFamily: AppTheme.body, fontSize: 12, color: Palette.muted),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nick,
              maxLength: 20,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              decoration: const InputDecoration(
                labelText: 'Username UCP / nick',
                hintText: 'contoh: Reyzo',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password server (opsional)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: Palette.danger,
                  fontFamily: AppTheme.body,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _busy ? null : _play,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Palette.accentInk),
                    )
                  : const Text('MASUK SERVER'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nick disimpan per server. Login UCP tetap dilakukan di dalam game.',
              style: TextStyle(fontFamily: AppTheme.body, fontSize: 11.5, color: Palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}
