import 'package:flutter/material.dart';

import '../platform/native_bridge.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _bridge = NativeBridge();
  final _package = TextEditingController();
  final _activity = TextEditingController();
  final _cache = TextEditingController();
  final _nick = TextEditingController();
  bool _initialized = false;
  bool _storage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final config = AppScope.of(context).config;
    _package.text = config.clientPackage;
    _activity.text = config.clientActivity;
    _cache.text = config.cachePath;
    _nick.text = config.nick;
    _refreshStorage();
  }

  Future<void> _refreshStorage() async {
    final storage = await _bridge.hasStorageAccess();
    if (!mounted) return;
    setState(() => _storage = storage);
  }

  @override
  void dispose() {
    _package.dispose();
    _activity.dispose();
    _cache.dispose();
    _nick.dispose();
    super.dispose();
  }

  Future<void> _requestStorage() async {
    await _bridge.requestStorageAccess();
    await _refreshStorage();
  }

  Future<void> _save() async {
    final state = AppScope.of(context);
    final package = _package.text.trim();
    final cache = _cache.text.trim();
    if (package.isEmpty || cache.isEmpty) {
      _toast('Package dan folder tidak boleh kosong.');
      return;
    }
    await state.updateConfig(
      state.config.copyWith(
        clientPackage: package,
        clientActivity: _activity.text.trim(),
        cachePath: cache.replaceAll(RegExp(r'/+$'), ''),
        nick: _nick.text.trim(),
      ),
    );
    _toast('Disimpan.');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final configured = state.config.manifestUrl.trim().isNotEmpty;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          children: [
            const Text(
              'Setelan',
              style: TextStyle(
                fontFamily: AppTheme.display,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                height: 1,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 28),
            const _Heading('Game'),
            TextField(
              controller: _package,
              decoration: const InputDecoration(
                labelText: 'Package klien',
                hintText: 'com.gta.game',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _activity,
              decoration: const InputDecoration(
                labelText: 'Activity',
                hintText: 'com.gta.game.SAMP',
              ),
            ),
            const SizedBox(height: 24),
            const _Heading('Data'),
            TextField(
              controller: _cache,
              decoration: const InputDecoration(labelText: 'Folder GTA'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nick,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: 'Nick default',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatusDot(
                    ok: _storage,
                    label: _storage
                        ? 'Akses folder aktif'
                        : 'Akses folder belum',
                  ),
                ),
                TextButton(
                  onPressed: _requestStorage,
                  child: Text(_storage ? 'Perbarui' : 'Izinkan'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            StatusDot(
              ok: configured,
              label: configured
                  ? 'Provider data siap'
                  : 'Provider data belum diatur',
            ),
            const SizedBox(height: 26),
            FilledButton(onPressed: _save, child: const Text('Simpan')),
            const SizedBox(height: 32),
            const _Heading('Lainnya'),
            _LinkRow(
              label: 'Lisensi',
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Velmire Launcher',
                applicationVersion: '0.1.0',
              ),
            ),
            _LinkRow(
              label: 'Ulangi persiapan data',
              onTap: () => state.updateConfig(
                state.config.copyWith(onboardingDone: false),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Velmire 0.1.0',
              style: TextStyle(
                fontFamily: AppTheme.body,
                fontSize: 11,
                color: Palette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppTheme.display,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Palette.ink,
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LinkRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Palette.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTheme.body,
                  fontSize: 14,
                  color: Palette.ink,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Palette.muted),
          ],
        ),
      ),
    );
  }
}
