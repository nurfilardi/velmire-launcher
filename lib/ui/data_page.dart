import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../platform/native_bridge.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final _bridge = NativeBridge();
  final _lite = TextEditingController();
  final _full = TextEditingController();
  bool _initialized = false;
  bool _storage = false;
  DataStatus? _status;
  bool _busy = false;
  String? _active;
  double _progress = 0;
  String _progressLabel = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final config = AppScope.of(context).config;
      _lite.text = config.liteUrl;
      _full.text = config.fullUrl;
      _refresh();
    }
  }

  @override
  void dispose() {
    _lite.dispose();
    _full.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final state = AppScope.of(context);
    final storage = await _bridge.hasStorageAccess();
    final status = await state.gameData.status();
    if (!mounted) return;
    setState(() {
      _storage = storage;
      _status = status;
    });
  }

  Future<void> _request() async {
    await _bridge.requestStorageAccess();
    await _refresh();
  }

  Future<void> _saveUrls() async {
    final state = AppScope.of(context);
    await state.updateConfig(
      state.config.copyWith(liteUrl: _lite.text.trim(), fullUrl: _full.text.trim()),
    );
  }

  Future<void> _download(bool lite) async {
    final state = AppScope.of(context);
    final url = (lite ? _lite.text : _full.text).trim();
    if (url.isEmpty) {
      _toast('Isi URL file .zip dulu.');
      return;
    }
    if (!_storage) {
      _toast('Izin folder belum diberikan.');
      return;
    }
    await _saveUrls();
    setState(() {
      _busy = true;
      _active = lite ? 'LITE' : 'ORIGINAL';
      _progress = 0;
      _progressLabel = 'Menyambung...';
    });
    String? zipPath;
    try {
      await for (final p in state.gameData.download(url, lite: lite)) {
        if (!mounted) return;
        setState(() {
          _progress = p.ratio;
          _progressLabel =
              '${formatBytes(p.received)}${p.total > 0 ? ' / ${formatBytes(p.total)}' : ''}';
          if (p.done) zipPath = p.path;
        });
      }
      if (zipPath == null) throw StateError('unduhan tidak selesai');
      if (mounted) setState(() => _progressLabel = 'Ekstrak...');
      await state.gameData.extract(zipPath!);
      await _refresh();
      _toast('Data ${lite ? 'Lite' : 'Original'} siap.');
    } catch (e) {
      _toast('Gagal: $e');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _active = null;
          _progress = 0;
        });
      }
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
      _active = 'IMPORT';
      _progressLabel = 'Ekstrak...';
    });
    try {
      await data.importArchive(path);
      await _refresh();
      _toast('Import selesai.');
    } catch (e) {
      _toast('Gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final state = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.surface,
        title: const Text('Hapus data game?'),
        content: Text('Semua isi ${state.config.cachePath} akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('HAPUS')),
        ],
      ),
    );
    if (ok != true) return;
    await state.gameData.deleteData();
    await _refresh();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final status = _status;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const Text(
              'DATA GAME',
              style: TextStyle(
                fontFamily: AppTheme.display,
                fontSize: 38,
                fontWeight: FontWeight.w700,
                height: 1,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'App tidak membawa aset GTA. Isi URL zip milik lu sendiri.',
              style: TextStyle(fontFamily: AppTheme.body, fontSize: 12.5, color: Palette.muted),
            ),
            const SizedBox(height: 18),
            Panel(
              child: Column(
                children: [
                  Row(
                    children: [
                      StatusDot(ok: _storage, label: _storage ? 'Akses folder aktif' : 'Akses folder belum'),
                      const Spacer(),
                      TextButton(
                        onPressed: _request,
                        child: Text(_storage ? 'CEK ULANG' : 'IZINKAN'),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: StatusDot(
                          ok: status?.ready ?? false,
                          label: status == null
                              ? 'Memeriksa...'
                              : '${formatBytes(status.bytes)} · ${status.files} file',
                        ),
                      ),
                      if (status != null && status.folderExists)
                        TextButton(
                          onPressed: _busy ? null : _delete,
                          child: const Text('HAPUS'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      state.config.cachePath,
                      style: const TextStyle(
                        fontFamily: AppTheme.body,
                        fontSize: 11,
                        color: Palette.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _ProfileCard(
              title: 'LITE',
              subtitle: 'Paket ringkas untuk HP RAM kecil.',
              controller: _lite,
              busy: _busy,
              active: _active == 'LITE',
              progress: _progress,
              progressLabel: _progressLabel,
              onDownload: () => _download(true),
            ),
            const SizedBox(height: 12),
            _ProfileCard(
              title: 'ORIGINAL',
              subtitle: 'Data penuh, kualitas asli.',
              controller: _full,
              busy: _busy,
              active: _active == 'ORIGINAL',
              progress: _progress,
              progressLabel: _progressLabel,
              onDownload: () => _download(false),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _importZip,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: Palette.ink,
                side: const BorderSide(color: Palette.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: const Icon(Icons.folder_open, size: 20),
              label: const Text('IMPORT ZIP DARI HP'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Format: .zip. Folder top-level GTA/ otomatis di-strip. .7z/.rar belum didukung. '
              'Download mendukung resume kalau server mendukung Range.',
              style: TextStyle(fontFamily: AppTheme.body, fontSize: 11.5, color: Palette.muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final bool busy;
  final bool active;
  final double progress;
  final String progressLabel;
  final VoidCallback onDownload;

  const _ProfileCard({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.busy,
    required this.active,
    required this.progress,
    required this.progressLabel,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTheme.display,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(fontFamily: AppTheme.body, fontSize: 11.5, color: Palette.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            enabled: !busy,
            decoration: const InputDecoration(
              hintText: 'https://hosting-lu/data.zip',
              isDense: true,
            ),
          ),
          if (active) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress == 0 ? null : progress),
            const SizedBox(height: 6),
            Text(
              progressLabel,
              style: const TextStyle(fontFamily: AppTheme.body, fontSize: 11, color: Palette.muted),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : onDownload,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: Text(active ? 'MENGUNDUH...' : 'UNDUH & EKSTRAK'),
            ),
          ),
        ],
      ),
    );
  }
}
