import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../platform/native_bridge.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _bridge = NativeBridge();
  final _url = TextEditingController();
  int _step = 1;
  bool _storage = false;
  bool _lite = true;
  bool _busy = false;
  double _progress = 0;
  String _progressLabel = '';
  bool _dataReady = false;
  bool _installed = false;
  bool _checkedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checkedOnce) {
      _checkedOnce = true;
      final config = AppScope.of(context).config;
      _url.text = config.liteUrl;
      _init();
    }
  }

  Future<void> _init() async {
    final state = AppScope.of(context);
    final storage = await _bridge.hasStorageAccess();
    final installed = await _bridge.isInstalled(state.config.clientPackage);
    final status = await state.gameData.status();
    if (!mounted) return;
    setState(() {
      _storage = storage;
      _installed = installed;
      _dataReady = status.ready;
    });
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _requestStorage() async {
    await _bridge.requestStorageAccess();
    await _init();
  }

  Future<void> _download() async {
    final state = AppScope.of(context);
    final url = _url.text.trim();
    if (url.isEmpty) {
      _toast('Isi URL zip data game dulu.');
      return;
    }
    await state.updateConfig(
      state.config.copyWith(liteUrl: _lite ? url : state.config.liteUrl, fullUrl: _lite ? state.config.fullUrl : url),
    );
    setState(() {
      _busy = true;
      _progress = 0;
      _progressLabel = 'Menyambung...';
    });
    String? zipPath;
    try {
      await for (final p in state.gameData.download(url, lite: _lite)) {
        if (!mounted) return;
        setState(() {
          _progress = p.ratio;
          _progressLabel = p.total > 0
              ? '${formatBytes(p.received)} / ${formatBytes(p.total)}'
              : formatBytes(p.received);
          if (p.done) zipPath = p.path;
        });
      }
      if (zipPath == null) throw StateError('unduhan tidak selesai');
      if (mounted) setState(() => _progressLabel = 'Ekstrak...');
      await state.gameData.extract(zipPath!);
      await _init();
      _toast('Data siap.');
    } catch (e) {
      _toast('Gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importZip() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final path = picked?.files.single.path;
    if (path == null || !mounted) return;
    final data = AppScope.of(context).gameData;
    setState(() {
      _busy = true;
      _progressLabel = 'Ekstrak...';
    });
    try {
      await data.importArchive(path);
      await _init();
      _toast('Import selesai.');
    } catch (e) {
      _toast('Gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _installApk() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
    );
    final path = picked?.files.single.path;
    if (path == null) return;
    await _bridge.installApk(path);
    await Future.delayed(const Duration(seconds: 2));
    await _init();
  }

  Future<void> _finish() async {
    await AppScope.of(context).updateConfig(
      AppScope.of(context).config.copyWith(onboardingDone: true),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'SETUP ${_step.toString().padLeft(2, '0')}/03',
                    style: const TextStyle(
                      fontFamily: AppTheme.body,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: Palette.accent,
                    ),
                  ),
                  const Spacer(),
                  if (_step > 1)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _step--),
                      child: const Text('KEMBALI'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  if (_step == 1) ..._stepPermission(),
                  if (_step == 2) ..._stepData(),
                  if (_step == 3) ..._stepClient(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _stepPermission() => [
        const SampMark(size: 66),
        const SizedBox(height: 22),
        const Text(
          'AKSES FOLDER GTA',
          style: TextStyle(
            fontFamily: AppTheme.display,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Palette.ink,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Launcher menyimpan data game di folder GTA dan menulis file setting koneksi. '
          'Butuh izin akses folder supaya proses unduh, ekstrak, dan connect bisa jalan.',
          style: TextStyle(fontFamily: AppTheme.body, fontSize: 13.5, color: Palette.muted, height: 1.55),
        ),
        const SizedBox(height: 18),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusDot(ok: _storage, label: _storage ? 'Akses folder aktif' : 'Belum ada akses'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _storage ? null : _requestStorage,
                child: Text(_storage ? 'SUDAH DIIZINKAN' : 'IZINKAN AKSES FOLDER'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _step = 2),
                child: const Text('LANJUT TANPA IZIN'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Yang app ini TIDAK lakukan: membawa atau menyediakan file GTA. Data game berasal dari URL milik lu.',
          style: TextStyle(fontFamily: AppTheme.body, fontSize: 11.5, color: Palette.muted, height: 1.5),
        ),
      ];

  List<Widget> _stepData() => [
        const SampMark(size: 40, caption: 'LANGKAH 2 — DATA GAME'),
        const SizedBox(height: 22),
        const Text(
          'UNDUH DATA GAME',
          style: TextStyle(
            fontFamily: AppTheme.display,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Palette.ink,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Pilih Lite atau Original, lalu tempel URL zip langsung (bukan link halaman). '
          'Butuh .zip; .7z/.rar belum didukung.',
          style: TextStyle(fontFamily: AppTheme.body, fontSize: 13, color: Palette.muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _Choice(label: 'LITE', selected: _lite, onTap: () => setState(() => _lite = true))),
            const SizedBox(width: 10),
            Expanded(child: _Choice(label: 'ORIGINAL', selected: !_lite, onTap: () => setState(() => _lite = false))),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          enabled: !_busy,
          decoration: const InputDecoration(hintText: 'https://hosting-lu/data.zip'),
        ),
        if (_busy) ...[
          const SizedBox(height: 14),
          LinearProgressIndicator(value: _progress == 0 ? null : _progress),
          const SizedBox(height: 6),
          Text(
            _progressLabel,
            style: const TextStyle(fontFamily: AppTheme.body, fontSize: 11, color: Palette.muted),
          ),
        ],
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _busy ? null : _download,
          child: const Text('UNDUH & EKSTRAK'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _busy ? null : _importZip,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: Palette.ink,
            side: const BorderSide(color: Palette.line),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('IMPORT ZIP DARI HP'),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _busy ? null : () => setState(() => _step = 3),
                child: Text(_dataReady ? 'LANJUT' : 'LEWATI DULU'),
              ),
            ),
          ],
        ),
      ];

  List<Widget> _stepClient() => [
        const SampMark(size: 40, caption: 'LANGKAH 3 — KLIEN GAME'),
        const SizedBox(height: 22),
        const Text(
          'KLIEN SA-MP',
          style: TextStyle(
            fontFamily: AppTheme.display,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Palette.ink,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Game dijalankan oleh klien SA-MP Android yang terpasang. Install dari APK milik lu.',
          style: TextStyle(fontFamily: AppTheme.body, fontSize: 13, color: Palette.muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusDot(ok: _installed, label: _installed ? 'Klien terdeteksi' : 'Klien belum terpasang'),
              const SizedBox(height: 4),
              Text(
                AppScope.of(context).config.clientPackage,
                style: const TextStyle(fontFamily: AppTheme.body, fontSize: 11, color: Palette.muted),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _installApk,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  foregroundColor: Palette.ink,
                  side: const BorderSide(color: Palette.line),
                ),
                icon: const Icon(Icons.android, size: 18),
                label: const Text('PILIH APK UNTUK INSTALL'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(onPressed: _finish, child: const Text('SELESAI')),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => _toast('Bisa diganti nanti di Setelan.'),
            child: const Text('ATUR PACKAGE NANTI'),
          ),
        ),
      ];
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Choice({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Palette.accent : Palette.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? Palette.accent : Palette.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.display,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: selected ? Palette.accentInk : Palette.muted,
          ),
        ),
      ),
    );
  }
}
