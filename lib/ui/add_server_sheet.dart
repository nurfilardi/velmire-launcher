import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/samp_query.dart';
import '../models/server.dart';
import '../theme/app_theme.dart';

class AddServerSheet extends StatefulWidget {
  const AddServerSheet({super.key});

  static Future<Server?> show(BuildContext context) {
    return showModalBottomSheet<Server>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddServerSheet(),
    );
  }

  @override
  State<AddServerSheet> createState() => _AddServerSheetState();
}

class _AddServerSheetState extends State<AddServerSheet> {
  final _host = TextEditingController();
  final _port = TextEditingController(text: '7777');
  final _name = TextEditingController();
  String? _error;
  String? _testResult;
  bool _testing = false;

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final host = _host.text.trim();
    final port = int.tryParse(_port.text.trim());
    if (host.isEmpty || port == null || port < 1 || port > 65535) {
      setState(() => _error = 'Host dan port harus valid (1–65535).');
      return;
    }
    setState(() {
      _testing = true;
      _error = null;
      _testResult = null;
    });
    final info = await queryServer(host, port);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = info == null
          ? 'Tidak ada jawaban. Server mungkin offline atau memblokir query.'
          : '${info.hostname} — ${info.players}/${info.maxPlayers} player';
    });
  }

  void _submit() {
    final host = _host.text.trim();
    final port = int.tryParse(_port.text.trim());
    if (host.isEmpty) {
      setState(() => _error = 'Alamat IP/domain wajib diisi.');
      return;
    }
    if (port == null || port < 1 || port > 65535) {
      setState(() => _error = 'Port harus 1–65535.');
      return;
    }
    if (host.contains(' ') || host.contains('/')) {
      setState(() => _error = 'Masukkan IP atau domain tanpa spasi/skema.');
      return;
    }
    Navigator.pop(
      context,
      Server(
        host: host,
        port: port,
        name: _name.text.trim().isEmpty ? host : _name.text.trim(),
        manual: true,
      ),
    );
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
            const Text(
              'TAMBAH SERVER',
              style: TextStyle(
                fontFamily: AppTheme.display,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Masukkan IP/domain dan port. Domain di-resolve otomatis.',
              style: TextStyle(fontFamily: AppTheme.body, fontSize: 12.5, color: Palette.muted),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _host,
              keyboardType: TextInputType.url,
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              decoration: const InputDecoration(
                labelText: 'IP / domain',
                hintText: 'contoh: 31.58.143.109 atau play.server.id',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _port,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Port'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Nama (opsional)'),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Palette.danger, fontFamily: AppTheme.body, fontSize: 12.5),
              ),
            ],
            if (_testResult != null) ...[
              const SizedBox(height: 12),
              Text(
                _testResult!,
                style: const TextStyle(color: Palette.muted, fontFamily: AppTheme.body, fontSize: 12.5),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _testing ? null : _test,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: Palette.line),
                      foregroundColor: Palette.ink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: _testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('TES KONEKSI'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('SIMPAN'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
