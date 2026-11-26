import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/server.dart';
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
  bool _installed = false;
  bool _storage = false;
  DataStatus? _status;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final state = AppScope.of(context);
    final installed = await _bridge.isInstalled(state.config.clientPackage);
    final storage = await _bridge.hasStorageAccess();
    final status = await state.gameData.status();
    if (!mounted) return;
    setState(() {
      _installed = installed;
      _storage = storage;
      _status = status;
    });
  }

  Future<void> _reloadAll() async {
    final state = AppScope.of(context);
    await Future.wait([state.refreshServers(force: true), _refresh()]);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final quick = state.quickServer;
    final top = state.topServers.take(3).toList();
    return Scaffold(
      body: ContourBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            color: Palette.signal,
            backgroundColor: Palette.surface,
            onRefresh: _reloadAll,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: SampMark()),
                    IconButton(
                      onPressed: _reloadAll,
                      icon: const Icon(Icons.refresh, color: Palette.muted),
                      tooltip: 'Muat ulang',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _Hero(
                  installed: _installed,
                  storage: _storage,
                  dataReady: _status?.ready ?? false,
                  quick: quick,
                  onPlay: () {
                    if (quick == null) {
                      widget.onOpenServers();
                    } else {
                      NicknameSheet.show(context, quick);
                    }
                  },
                ),
                const SizedBox(height: 24),
                SectionLabel(
                  'Server ramai',
                  trailing: TextButton(
                    onPressed: widget.onOpenServers,
                    child: const Text('LIHAT SEMUA'),
                  ),
                ),
                if (top.isEmpty)
                  Panel(
                    child: Text(
                      state.serversLoading
                          ? 'Memuat server Indonesia...'
                          : (state.serversError ??
                                'Belum ada server. Tambah manual di tab Server.'),
                      style: const TextStyle(
                        fontFamily: AppTheme.body,
                        color: Palette.muted,
                      ),
                    ),
                  )
                else
                  ...top.asMap().entries.map(
                    (e) => ServerCard(
                      server: e.value,
                      index: e.key + 1,
                      favorite: state.favorites.contains(e.value.address),
                      onTap: () => NicknameSheet.show(context, e.value),
                      onToggleFavorite: () =>
                          state.toggleFavorite(e.value.address),
                    ),
                  ),
                const SizedBox(height: 14),
                const Text(
                  'Data server: SA:MP Indonesia · sa-mp.co.id',
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
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final bool installed;
  final bool storage;
  final bool dataReady;
  final Server? quick;
  final VoidCallback onPlay;

  const _Hero({
    required this.installed,
    required this.storage,
    required this.dataReady,
    required this.quick,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final ready = installed && storage && dataReady;
    return Container(
      decoration: BoxDecoration(
        color: Palette.surface,
        border: Border.all(color: Palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: ready ? Palette.accent : Palette.surfaceHi,
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(
              children: [
                Text(
                  ready ? 'JALUR SIAP' : 'PERSIAPAN',
                  style: TextStyle(
                    fontFamily: AppTheme.body,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: ready ? Palette.accentInk : Palette.muted,
                  ),
                ),
                const Spacer(),
                Text(
                  ready ? 'IGNITION ON' : 'CHECK ROUTE',
                  style: TextStyle(
                    fontFamily: AppTheme.body,
                    fontSize: 9.5,
                    letterSpacing: 1.2,
                    color: ready
                        ? Palette.accentInk.withValues(alpha: 0.75)
                        : Palette.muted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (quick != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          quick!.name.isEmpty ? quick!.address : quick!.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.display,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            height: 0.98,
                            color: Palette.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      RouteShield(
                        value: '${quick!.players}',
                        caption: 'ONLINE',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${quick!.address} · ${quick!.players}/${quick!.maxPlayers}'
                    '${quick!.gamemode.isEmpty ? '' : ' · ${quick!.gamemode}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.body,
                      fontSize: 11.5,
                      color: Palette.muted,
                    ),
                  ),
                ] else
                  const Text(
                    'Tentukan server tujuan',
                    style: TextStyle(
                      fontFamily: AppTheme.display,
                      fontSize: 32,
                      height: 1,
                      color: Palette.ink,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatusDot(
                        ok: installed,
                        label: installed ? 'klien siap' : 'klien belum',
                      ),
                    ),
                    Expanded(
                      child: StatusDot(
                        ok: dataReady,
                        label: dataReady ? 'data siap' : 'data belum',
                      ),
                    ),
                    StatusDot(
                      ok: storage,
                      label: storage ? 'folder' : 'izin folder',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Palette.line)),
            ),
            child: FilledButton.icon(
              onPressed: onPlay,
              icon: Icon(
                quick == null ? Icons.alt_route : Icons.play_arrow_rounded,
                size: 21,
              ),
              label: Text(quick == null ? 'PILIH SERVER' : 'MASUK SERVER'),
            ),
          ),
        ],
      ),
    );
  }
}
