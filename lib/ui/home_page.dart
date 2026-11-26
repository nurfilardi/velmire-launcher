import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/server.dart';
import '../platform/native_bridge.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'nickname_sheet.dart';
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
    await Future.wait([
      state.refreshServers(force: true),
      _refresh(),
    ]);
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
            color: Palette.accent,
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
                const SizedBox(height: 24),
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
                          : (state.serversError ?? 'Belum ada server. Tambah manual di tab Server.'),
                      style: const TextStyle(fontFamily: AppTheme.body, color: Palette.muted),
                    ),
                  )
                else
                  ...top.asMap().entries.map(
                        (e) => _TopServerRow(
                          rank: e.key + 1,
                          server: e.value,
                          onTap: () => NicknameSheet.show(context, e.value),
                        ),
                      ),
                const SizedBox(height: 18),
                const Text(
                  'Data server: SA:MP Indonesia · sa-mp.co.id',
                  style: TextStyle(fontFamily: AppTheme.body, fontSize: 10.5, color: Palette.muted),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.line),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1D21), Color(0xFF101215)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ready ? 'SIAP MAIN' : 'PERSIAPAN',
                      style: const TextStyle(
                        fontFamily: AppTheme.display,
                        fontSize: 13,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w600,
                        color: Palette.accent,
                      ),
                    ),
                    const Spacer(),
                    StatusDot(ok: storage, label: storage ? 'folder ok' : 'folder belum'),
                  ],
                ),
                const SizedBox(height: 16),
                if (quick != null) ...[
                  Text(
                    quick!.name.isEmpty ? quick!.address : quick!.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.display,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      height: 1.02,
                      color: Palette.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${quick!.address} · ${quick!.players}/${quick!.maxPlayers} player'
                    '${quick!.gamemode.isEmpty ? '' : ' · ${quick!.gamemode}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: AppTheme.body, fontSize: 12, color: Palette.muted),
                  ),
                ] else
                  const Text(
                    'Pilih server untuk mulai',
                    style: TextStyle(fontFamily: AppTheme.display, fontSize: 30, color: Palette.ink),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusDot(ok: installed, label: installed ? 'klien terpasang' : 'klien belum ada'),
                    StatusDot(ok: dataReady, label: dataReady ? 'data siap' : 'data belum'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Palette.line)),
            ),
            child: FilledButton.icon(
              onPressed: onPlay,
              icon: Icon(quick == null ? Icons.dns : Icons.play_arrow_rounded, size: 22),
              label: Text(quick == null ? 'PILIH SERVER' : 'MAIN SEKARANG'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopServerRow extends StatelessWidget {
  final int rank;
  final Server server;
  final VoidCallback onTap;

  const _TopServerRow({required this.rank, required this.server, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Palette.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Palette.line),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      fontFamily: AppTheme.display,
                      fontSize: 20,
                      color: Palette.muted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    server.name.isEmpty ? server.address : server.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Palette.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${server.players}',
                  style: const TextStyle(
                    fontFamily: AppTheme.display,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Palette.accent,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: Palette.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
