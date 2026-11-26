import 'package:flutter/material.dart';

import '../core/format.dart';
import '../data/game_data.dart';
import '../platform/native_bridge.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'nickname_sheet.dart';
import 'server_card.dart';
import 'widgets/common.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onOpenServers;

  const HomePage({super.key, required this.onOpenServers});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _bridge = NativeBridge();
  bool _loaded = false;
  bool _storage = false;
  DataStatus? _status;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _refresh();
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

  Future<void> _reloadAll() async {
    final state = AppScope.of(context);
    await Future.wait([state.refreshServers(force: true), _refresh()]);
  }

  Future<void> _play() async {
    final state = AppScope.of(context);
    if (!(_status?.ready ?? false)) {
      await state.updateConfig(state.config.copyWith(onboardingDone: false));
      return;
    }
    final server = state.quickServer;
    if (server == null) {
      widget.onOpenServers();
      return;
    }
    if (mounted) await NicknameSheet.show(context, server);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final quick = state.quickServer;
    final top = state.topServers.take(3).toList();
    final ready = _status?.ready ?? false;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: Palette.signal,
          backgroundColor: Palette.surface,
          onRefresh: _reloadAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            children: [
              Row(
                children: [
                  const SampMark(size: 30, caption: 'SA-MP'),
                  const Spacer(),
                  IconButton(
                    onPressed: _reloadAll,
                    icon: const Icon(Icons.refresh, color: Palette.muted),
                    tooltip: 'Muat ulang',
                  ),
                ],
              ),
              const SizedBox(height: 38),
              if (!ready) ...[
                const Text(
                  'Data game belum siap.',
                  style: TextStyle(
                    fontFamily: AppTheme.display,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    height: 0.98,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _storage
                      ? 'Pilih Lite atau Original untuk mulai.'
                      : 'Beri akses folder GTA untuk mulai.',
                  style: const TextStyle(
                    fontFamily: AppTheme.body,
                    fontSize: 14,
                    color: Palette.muted,
                  ),
                ),
              ] else ...[
                Text(
                  quick?.name.isNotEmpty == true ? quick!.name : 'Siap main.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.display,
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    height: 0.96,
                    letterSpacing: -0.4,
                    color: Palette.ink,
                  ),
                ),
                if (quick != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${quick.address} · ${quick.players}/${quick.maxPlayers}'
                    '${quick.gamemode.isEmpty ? '' : ' · ${quick.gamemode}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.body,
                      fontSize: 12.5,
                      color: Palette.muted,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              if (ready)
                StatusDot(
                  ok: true,
                  label:
                      'Data siap · ${formatBytes(_status!.bytes)} · ${_status!.files} file',
                )
              else
                StatusDot(
                  ok: _storage,
                  label: _storage ? 'Akses folder aktif' : 'Akses folder belum',
                ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _play,
                icon: Icon(
                  ready ? Icons.play_arrow_rounded : Icons.download_rounded,
                  size: 22,
                ),
                label: Text(
                  ready
                      ? (quick == null ? 'Pilih server' : 'Main')
                      : 'Siapkan data',
                ),
              ),
              const SizedBox(height: 38),
              SectionLabel(
                'Server ramai',
                trailing: TextButton(
                  onPressed: widget.onOpenServers,
                  child: const Text('Semua'),
                ),
              ),
              if (top.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    state.serversLoading
                        ? 'Memuat server...'
                        : (state.serversError ??
                              'Belum ada server. Tambah manual di tab Server.'),
                    style: const TextStyle(
                      fontFamily: AppTheme.body,
                      fontSize: 13,
                      color: Palette.muted,
                    ),
                  ),
                )
              else
                ...top.map(
                  (server) => ServerCard(
                    server: server,
                    favorite: state.favorites.contains(server.address),
                    onTap: () => NicknameSheet.show(context, server),
                    onToggleFavorite: () =>
                        state.toggleFavorite(server.address),
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                'Data server: sa-mp.co.id',
                style: TextStyle(
                  fontFamily: AppTheme.body,
                  fontSize: 10.5,
                  color: Palette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
