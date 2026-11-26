import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/app_log.dart';
import '../core/format.dart';
import '../data/game_data.dart';
import '../data/resource_manifest.dart';
import '../platform/native_bridge.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';
import 'widgets/feedback.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _bridge = NativeBridge();
  bool _initialized = false;
  bool _storage = false;
  DataEdition _edition = DataEdition.lite;
  DataStatus? _status;
  bool _busy = false;
  double _progress = 0;
  String _progressLabel = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _init();
  }

  Future<void> _init() async {
    final state = AppScope.of(context);
    try {
      final storage = await _bridge.hasStorageAccess();
      final status = await state.gameData.status();
      if (state.manifest == null && state.config.manifestUrl.isNotEmpty) {
        await state.loadManifest();
      }
      if (!mounted) return;
      setState(() {
        _storage = storage;
        _status = status;
      });
      AppLog.log('setup storage=$storage ready=${status.ready}');
    } catch (e, s) {
      AppLog.exception('setup init', e, s);
    }
  }

  Future<void> _requestStorage() async {
    await _bridge.requestStorageAccess();
    await _init();
  }

  ResourceSource? _source(AppState state) =>
      state.manifest?.sourceFor(_edition);

  Future<void> _primary() async {
    if (_status?.ready ?? false) {
      await AppScope.of(context).updateConfig(
        AppScope.of(context).config.copyWith(onboardingDone: true),
      );
      return;
    }
    await _download();
  }

  Future<void> _download() async {
    final state = AppScope.of(context);
    if (!_storage) {
      await _requestStorage();
      if (!_storage) {
        if (mounted) showToast(context, 'Izinkan akses folder dulu.');
        return;
      }
    }
    if (state.manifest == null) {
      if (state.config.manifestUrl.isEmpty) {
        if (mounted) showToast(context, 'Provider data belum diatur.');
        return;
      }
      await state.loadManifest();
      if (!mounted) return;
    }
    final source = _source(state);
    if (source == null) {
      if (mounted) {
        showToast(
          context,
          'Sumber ${_edition == DataEdition.lite ? 'Lite' : 'Original'} tidak ada di manifest.',
        );
      }
      return;
    }
    setState(() {
      _busy = true;
      _progress = 0;
      _progressLabel = 'Menyambung...';
    });
    String? zipPath;
    try {
      await for (final p in state.gameData.download(
        source.url,
        lite: _edition == DataEdition.lite,
        maxBytes: source.size,
        checksum: source.checksum,
        filename: _edition == DataEdition.lite ? 'lite' : 'original',
      )) {
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
      if (mounted) setState(() => _progressLabel = 'Menyiapkan data...');
      await state.gameData.extract(
        zipPath!,
        onProgress: (done, total, _) {
          if (!mounted || total == 0) return;
          setState(() {
            _progress = done / total;
            _progressLabel = 'Menyiapkan ${done * 100 ~/ total}%';
          });
        },
      );
      await _init();
      if (mounted) showToast(context, 'Data siap.');
    } catch (e) {
      if (mounted) showToast(context, 'Gagal: $e');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = 0;
        });
      }
    }
  }

  Future<void> _skip() async {
    final state = AppScope.of(context);
    await state.updateConfig(state.config.copyWith(onboardingDone: true));
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
      _progressLabel = 'Menyiapkan data...';
    });
    try {
      await data.importArchive(path);
      await _init();
      if (mounted) showToast(context, 'Data siap.');
    } catch (e) {
      if (mounted) showToast(context, 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final status = _status;
    final ready = status?.ready ?? false;
    final source = _source(state);
    final configured = state.config.manifestUrl.trim().isNotEmpty;
    final canDownload = ready || (configured && source != null);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
          children: [
            const SampMark(size: 30, caption: 'SA-MP'),
            const SizedBox(height: 44),
            const Text(
              'Siap main?',
              style: TextStyle(
                fontFamily: AppTheme.display,
                fontSize: 50,
                fontWeight: FontWeight.w700,
                height: 0.95,
                letterSpacing: -0.8,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Pilih data, unduh sekali, lalu masuk server.',
              style: TextStyle(
                fontFamily: AppTheme.body,
                fontSize: 14,
                color: Palette.muted,
              ),
            ),
            const SizedBox(height: 36),
            _PermissionRow(
              granted: _storage,
              onTap: _busy ? null : _requestStorage,
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: _EditionTile(
                    title: 'Lite',
                    caption: sourceSize(state, DataEdition.lite) ?? 'Ringan',
                    selected: _edition == DataEdition.lite,
                    onTap: _busy
                        ? null
                        : () => setState(() => _edition = DataEdition.lite),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _EditionTile(
                    title: 'Original',
                    caption:
                        sourceSize(state, DataEdition.original) ?? 'Lengkap',
                    selected: _edition == DataEdition.original,
                    onTap: _busy
                        ? null
                        : () => setState(() => _edition = DataEdition.original),
                  ),
                ),
              ],
            ),
            if (ready) ...[
              const SizedBox(height: 16),
              StatusDot(
                ok: true,
                label:
                    'Data siap · ${formatBytes(status!.bytes)} · ${status.files} file',
              ),
            ] else if (!configured) ...[
              const SizedBox(height: 14),
              const Text(
                'Provider data belum diatur.',
                style: TextStyle(
                  fontFamily: AppTheme.body,
                  fontSize: 12.5,
                  color: Palette.muted,
                ),
              ),
            ] else if (state.manifestLoading) ...[
              const SizedBox(height: 14),
              const Text(
                'Memuat provider...',
                style: TextStyle(
                  fontFamily: AppTheme.body,
                  fontSize: 12.5,
                  color: Palette.muted,
                ),
              ),
            ] else if (source == null) ...[
              const SizedBox(height: 14),
              Text(
                state.manifestError ??
                    'Sumber ${_edition == DataEdition.lite ? 'Lite' : 'Original'} tidak tersedia.',
                style: const TextStyle(
                  fontFamily: AppTheme.body,
                  fontSize: 12.5,
                  color: Palette.muted,
                ),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 24),
              LinearProgressIndicator(value: _progress == 0 ? null : _progress),
              const SizedBox(height: 8),
              Text(
                _progressLabel,
                style: const TextStyle(
                  fontFamily: AppTheme.body,
                  fontSize: 12,
                  color: Palette.muted,
                ),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _busy || !canDownload ? null : _primary,
              icon: Icon(
                ready ? Icons.arrow_forward_rounded : Icons.download_rounded,
                size: 20,
              ),
              label: Text(ready ? 'Lanjut' : 'Unduh'),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _importZip,
                child: const Text('Impor ZIP dari HP'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _skip,
                child: const Text('Lewati'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? sourceSize(AppState state, DataEdition edition) {
    final size = state.manifest?.sourceFor(edition)?.size ?? 0;
    return size > 0 ? formatBytes(size) : null;
  }
}

class _PermissionRow extends StatelessWidget {
  final bool granted;
  final VoidCallback? onTap;

  const _PermissionRow({required this.granted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          granted ? Icons.check_circle : Icons.folder_outlined,
          size: 20,
          color: granted ? Palette.online : Palette.signal,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            granted ? 'Akses folder aktif' : 'Butuh akses folder GTA',
            style: const TextStyle(
              fontFamily: AppTheme.body,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Palette.ink,
            ),
          ),
        ),
        if (!granted)
          TextButton(onPressed: onTap, child: const Text('Izinkan')),
      ],
    );
  }
}

class _EditionTile extends StatelessWidget {
  final String title;
  final String caption;
  final bool selected;
  final VoidCallback? onTap;

  const _EditionTile({
    required this.title,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
        decoration: BoxDecoration(
          color: selected ? Palette.accent : Palette.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.display,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1,
                color: selected ? Palette.accentInk : Palette.ink,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              caption,
              style: TextStyle(
                fontFamily: AppTheme.body,
                fontSize: 11.5,
                color: selected
                    ? Palette.accentInk.withValues(alpha: 0.72)
                    : Palette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
