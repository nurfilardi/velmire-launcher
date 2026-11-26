import 'package:file_picker/file_picker.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final c = AppScope.of(context).config;
      _package.text = c.clientPackage;
      _activity.text = c.clientActivity;
      _cache.text = c.cachePath;
      _nick.text = c.nick;
    }
  }

  @override
  void dispose() {
    _package.dispose();
    _activity.dispose();
    _cache.dispose();
    _nick.dispose();
    super.dispose();
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

  Future<void> _installApk() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
    );
    final path = picked?.files.single.path;
    if (path == null) return;
    final ok = await _bridge.installApk(path);
    if (!ok) _toast('Gagal membuka installer.');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const Text(
              'SETELAN',
              style: TextStyle(
                fontFamily: AppTheme.display,
                fontSize: 38,
                fontWeight: FontWeight.w700,
                height: 1,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 18),
            const SectionLabel('Klien game'),
            Panel(
              child: Column(
                children: [
                  TextField(
                    controller: _package,
                    decoration: const InputDecoration(labelText: 'Package klien'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _activity,
                    decoration: const InputDecoration(
                      labelText: 'Activity tujuan',
                      hintText: 'com.gta.game.SAMP',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _installApk,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Palette.ink,
                            side: const BorderSide(color: Palette.line),
                            minimumSize: const Size.fromHeight(46),
                          ),
                          icon: const Icon(Icons.android, size: 18),
                          label: const Text('INSTALL APK'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _bridge.requestStorageAccess();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Palette.ink,
                            side: const BorderSide(color: Palette.line),
                            minimumSize: const Size.fromHeight(46),
                          ),
                          icon: const Icon(Icons.folder_shared, size: 18),
                          label: const Text('AKSES FOLDER'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionLabel('Penyimpanan'),
            Panel(
              child: Column(
                children: [
                  TextField(
                    controller: _cache,
                    decoration: const InputDecoration(labelText: 'Folder data GTA'),
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
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('SIMPAN')),
            const SizedBox(height: 24),
            const SectionLabel('Tentang'),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Velmire Launcher — sideload, tanpa backend.\nData server: SA:MP Indonesia (sa-mp.co.id).',
                    style: TextStyle(fontFamily: AppTheme.body, fontSize: 12.5, color: Palette.muted, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        onPressed: () => showLicensePage(
                          context: context,
                          applicationName: 'Velmire Launcher',
                          applicationVersion: '0.1.0',
                        ),
                        child: const Text('LISENSI'),
                      ),
                      TextButton(
                        onPressed: () => state.updateConfig(
                          AppScope.of(context).config.copyWith(onboardingDone: false),
                        ),
                        child: const Text('ULANGI ONBOARDING'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
