import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/format.dart';
import '../data/client_installer.dart';
import '../data/game_data.dart';
import '../data/resource_manifest.dart';
import '../platform/native_bridge.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';
import 'widgets/feedback.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final _bridge = NativeBridge();
  final _manifestUrl = TextEditingController();
  final _lite = TextEditingController();
  final _full = TextEditingController();
  final _client = ClientInstaller();
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
      final state = AppScope.of(context);
      _manifestUrl.text = state.config.manifestUrl;
      _lite.text = state.config.liteUrl;
      _full.text = state.config.fullUrl;
      _refresh();
      if (state.manifest == null && state.config.manifestUrl.isNotEmpty) {
        state.loadManifest();
      }
    }
  }

  @override
  void dispose() {
    _manifestUrl.dispose();
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

  Future<void> _loadManifest() async {
    final state = AppScope.of(context);
    final url = _manifestUrl.text.trim();
    if (url.isEmpty) {
      showToast(context, 'Isi URL sources.json dulu.');
      return;
    }
    await state.updateConfig(state.config.copyWith(manifestUrl: url));
    await state.loadManifest(force: true);
    if (!mounted || state.manifestError == null) return;
    showToast(context, state.manifestError!);
  }

  Future<void> _saveUrls() async {
    final state = AppScope.of(context);
    await state.updateConfig(
      state.config.copyWith(
        liteUrl: _lite.text.trim(),
        fullUrl: _full.text.trim(),
      ),
    );
  }

  Future<void> _downloadSource(ResourceSource source) => _startDownload(
    url: source.url,
    name: source.name,
    checksum: source.checksum,
    maxBytes: source.size,
  );

  Future<void> _downloadUrl(String url, String name) =>
      _startDownload(url: url, name: name);

  Future<void> _startDownload({
    required String url,
    required String name,
    String checksum = '',
    int maxBytes = 0,
  }) async {
    final state = AppScope.of(context);
    if (url.trim().isEmpty) {
      showToast(context, 'Isi URL file .zip dulu.');
      return;
    }
    if (!_storage) {
      showToast(context, 'Izin folder belum diberikan.');
      return;
    }
    await _saveUrls();
    setState(() {
      _busy = true;
      _active = name.toUpperCase();
      _progress = 0;
      _progressLabel = 'Menyambung...';
    });
    String? zipPath;
    try {
      await for (final p in state.gameData.download(
        url,
        lite: false,
        maxBytes: maxBytes,
        checksum: checksum,
        filename: name,
      )) {
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
      await state.gameData.extract(
        zipPath!,
        onProgress: (done, total, entry) {
          if (!mounted) return;
          setState(() {
            _progress = total > 0 ? done / total : 0;
            _progressLabel = 'Ekstrak $done/$total · $entry';
          });
        },
      );
      await _refresh();
      if (!mounted) return;
      showToast(context, 'Data $name siap.');
    } catch (e) {
      if (!mounted) return;
      showToast(context, 'Gagal: $e');
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

  Future<void> _installClient(ClientPackage package) async {
    setState(() {
      _busy = true;
      _active = 'KLIEN';
      _progress = 0;
      _progressLabel = 'Menyambung...';
    });
    try {
      final file = await _client.download(
        package,
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _progress = p.ratio;
            _progressLabel = p.total > 0
                ? '${formatBytes(p.received)} / ${formatBytes(p.total)}'
                : formatBytes(p.received);
          });
        },
      );
      final ok = await _client.install(file);
      if (!mounted) return;
      showToast(
        context,
        ok ? 'Installer klien dibuka.' : 'Gagal membuka installer.',
      );
    } catch (e) {
      if (!mounted) return;
      showToast(context, 'Gagal unduh klien: $e');
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
      await data.importArchive(
        path,
        onProgress: (done, total, entry) {
          if (!mounted) return;
          setState(() {
            _progress = total > 0 ? done / total : 0;
            _progressLabel = 'Ekstrak $done/$total · $entry';
          });
        },
      );
      await _refresh();
      if (!mounted) return;
      showToast(context, 'Import selesai.');
    } catch (e) {
      if (!mounted) return;
      showToast(context, 'Gagal: $e');
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('BATAL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await state.gameData.deleteData();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final status = _status;
    final manifest = state.manifest;
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
              'Sumber data dari manifest, seperti launcher komunitas.',
              style: TextStyle(
                fontFamily: AppTheme.body,
                fontSize: 12.5,
                color: Palette.muted,
              ),
            ),
            const SizedBox(height: 18),
            Panel(
              child: Column(
                children: [
                  Row(
                    children: [
                      StatusDot(
                        ok: _storage,
                        label: _storage
                            ? 'Akses folder aktif'
                            : 'Akses folder belum',
                      ),
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
            SectionLabel('Sumber manifest'),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _manifestUrl,
                    keyboardType: TextInputType.url,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      hintText: 'https://hosting-lu/sources.json',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Format: {"sources":[{"name","url","size","checksum"}]}',
                          style: const TextStyle(
                            fontFamily: AppTheme.body,
                            fontSize: 10.5,
                            color: Palette.muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _busy || state.manifestLoading
                            ? null
                            : _loadManifest,
                        child: Text(
                          state.manifestLoading ? 'MEMUAT...' : 'MUAT',
                        ),
                      ),
                    ],
                  ),
                  if (state.manifestError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        state.manifestError!,
                        style: const TextStyle(
                          fontFamily: AppTheme.body,
                          fontSize: 11,
                          color: Palette.danger,
                        ),
                      ),
                    ),
                  if (manifest != null && manifest.sources.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...manifest.sources.map(
                      (source) => _SourceRow(
                        source: source,
                        busy: _busy,
                        active: _active == source.name.toUpperCase(),
                        progress: _progress,
                        progressLabel: _progressLabel,
                        onDownload: () => _downloadSource(source),
                      ),
                    ),
                  ] else if (manifest != null)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'Manifest kosong.',
                        style: TextStyle(
                          fontFamily: AppTheme.body,
                          fontSize: 11.5,
                          color: Palette.muted,
                        ),
                      ),
                    ),
                  if (manifest?.client != null) ...[
                    const SizedBox(height: 10),
                    _ClientRow(
                      package: manifest!.client!,
                      busy: _busy,
                      active: _active == 'KLIEN',
                      progress: _progress,
                      progressLabel: _progressLabel,
                      onInstall: () => _installClient(manifest.client!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionLabel('URL manual'),
            _ProfileCard(
              title: 'LITE',
              subtitle: 'URL zip langsung.',
              controller: _lite,
              busy: _busy,
              active: _active == 'LITE',
              progress: _progress,
              progressLabel: _progressLabel,
              onDownload: () => _downloadUrl(_lite.text.trim(), 'lite'),
            ),
            const SizedBox(height: 12),
            _ProfileCard(
              title: 'ORIGINAL',
              subtitle: 'URL zip langsung.',
              controller: _full,
              busy: _busy,
              active: _active == 'ORIGINAL',
              progress: _progress,
              progressLabel: _progressLabel,
              onDownload: () => _downloadUrl(_full.text.trim(), 'original'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _importZip,
              icon: const Icon(Icons.folder_open, size: 20),
              label: const Text('IMPORT ZIP DARI HP'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Format: .zip. Folder top-level GTA/ otomatis di-strip. .7z/.rar belum didukung. '
              'Unduhan memakai resume, batas ukuran, dan verifikasi SHA-256 dari manifest.',
              style: TextStyle(
                fontFamily: AppTheme.body,
                fontSize: 11.5,
                color: Palette.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final ResourceSource source;
  final bool busy;
  final bool active;
  final double progress;
  final String progressLabel;
  final VoidCallback onDownload;

  const _SourceRow({
    required this.source,
    required this.busy,
    required this.active,
    required this.progress,
    required this.progressLabel,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Palette.surfaceHi,
        border: Border.all(color: active ? Palette.signal : Palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  source.name,
                  style: const TextStyle(
                    fontFamily: AppTheme.body,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                  ),
                ),
              ),
              Text(
                source.size > 0 ? formatBytes(source.size) : 'ukuran ?',
                style: const TextStyle(
                  fontFamily: AppTheme.body,
                  fontSize: 11,
                  color: Palette.muted,
                ),
              ),
            ],
          ),
          if (source.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                source.description,
                style: const TextStyle(
                  fontFamily: AppTheme.body,
                  fontSize: 11,
                  color: Palette.muted,
                ),
              ),
            ),
          if (active) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress == 0 ? null : progress),
            const SizedBox(height: 4),
            Text(
              progressLabel,
              style: const TextStyle(
                fontFamily: AppTheme.body,
                fontSize: 10.5,
                color: Palette.muted,
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy ? null : onDownload,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(38),
              ),
              child: Text(active ? 'MENGUNDUH...' : 'UNDUH & EKSTRAK'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  final ClientPackage package;
  final bool busy;
  final bool active;
  final double progress;
  final String progressLabel;
  final VoidCallback onInstall;

  const _ClientRow({
    required this.package,
    required this.busy,
    required this.active,
    required this.progress,
    required this.progressLabel,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Palette.surfaceHi,
        border: Border.all(color: Palette.signal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.android, size: 16, color: Palette.signal),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Klien: ${package.name}',
                  style: const TextStyle(
                    fontFamily: AppTheme.body,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                  ),
                ),
              ),
              Text(
                package.size > 0 ? formatBytes(package.size) : 'APK',
                style: const TextStyle(
                  fontFamily: AppTheme.body,
                  fontSize: 10.5,
                  color: Palette.muted,
                ),
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress == 0 ? null : progress),
            const SizedBox(height: 4),
            Text(
              progressLabel,
              style: const TextStyle(
                fontFamily: AppTheme.body,
                fontSize: 10.5,
                color: Palette.muted,
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : onInstall,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(38),
              ),
              child: Text(active ? 'MENYIAPKAN...' : 'UNDUH & PASANG KLIEN'),
            ),
          ),
        ],
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
                  style: const TextStyle(
                    fontFamily: AppTheme.body,
                    fontSize: 11.5,
                    color: Palette.muted,
                  ),
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
              style: const TextStyle(
                fontFamily: AppTheme.body,
                fontSize: 11,
                color: Palette.muted,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : onDownload,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(active ? 'MENGUNDUH...' : 'UNDUH & EKSTRAK'),
            ),
          ),
        ],
      ),
    );
  }
}
