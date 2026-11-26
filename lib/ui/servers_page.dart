import 'package:flutter/material.dart';

import '../models/server.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'add_server_sheet.dart';
import 'nickname_sheet.dart';
import 'server_card.dart';
import 'widgets/common.dart';

class ServersPage extends StatefulWidget {
  const ServersPage({super.key});

  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> {
  final _search = TextEditingController();
  String _filter = 'SEMUA';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Server s, String query) {
    if (_filter == 'FAVORIT' && !_favoriteSet.contains(s.address)) return false;
    if (_filter == 'MANUAL' && !s.manual) return false;
    if (_filter != 'SEMUA' && _filter != 'FAVORIT' && _filter != 'MANUAL') {
      if (versionFamily(s.version) != _filter) return false;
    }
    if (query.isEmpty) return true;
    final haystack = '${s.name} ${s.host} ${s.gamemode} ${s.language}'.toLowerCase();
    return haystack.contains(query);
  }

  Set<String> _favoriteSet = {};

  Future<void> _add() async {
    final state = AppScope.of(context);
    final server = await AddServerSheet.show(context);
    if (server == null || !mounted) return;
    await state.addManual(server);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${server.name} ditambahkan')),
    );
  }

  Future<void> _removeManual(Server server) async {
    final state = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.surface,
        title: const Text('Hapus server?'),
        content: Text('${server.name}\n${server.address}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('HAPUS')),
        ],
      ),
    );
    if (ok == true) await state.removeManual(server);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    _favoriteSet = state.favorites;
    final query = _search.text.trim().toLowerCase();
    final list = state.servers.where((s) => _matches(s, query)).toList()
      ..sort((a, b) => b.players.compareTo(a.players));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'SERVER',
                        style: TextStyle(
                          fontFamily: AppTheme.display,
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: Palette.ink,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => state.refreshServers(force: true),
                        icon: state.serversLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh, color: Palette.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, gamemode, IP...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: Palette.muted),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _search.clear()),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final f in const ['SEMUA', 'FAVORIT', '0.3.7', '0.3.DL', 'OPENMP', 'MANUAL'])
                          _FilterPill(
                            label: f,
                            selected: _filter == f,
                            onTap: () => setState(() => _filter = f),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (state.serversError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Panel(
                  color: Palette.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Gagal memuat, menampilkan cache terakhir.',
                          style: TextStyle(fontFamily: AppTheme.body, fontSize: 12, color: Palette.muted),
                        ),
                      ),
                      TextButton(
                        onPressed: () => state.refreshServers(force: true),
                        child: const Text('COBA LAGI'),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                color: Palette.accent,
                backgroundColor: Palette.surface,
                onRefresh: () => state.refreshServers(force: true),
                child: list.isEmpty
                    ? ListView(
                        children: [
                          EmptyState(
                            title: state.serversLoading ? 'MEMUAT...' : 'TIDAK ADA SERVER',
                            message: state.serversLoading
                                ? 'Mengambil daftar server Indonesia.'
                                : 'Coba ubah filter atau tambah server manual lewat tombol di bawah.',
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final server = list[i];
                          return ServerCard(
                            server: server,
                            index: i + 1,
                            favorite: state.favorites.contains(server.address),
                            onTap: () => NicknameSheet.show(context, server),
                            onToggleFavorite: () => state.toggleFavorite(server.address),
                            onLongPress: server.manual ? () => _removeManual(server) : null,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: Palette.accent,
        foregroundColor: Palette.accentInk,
        icon: const Icon(Icons.add),
        label: const Text(
          'SERVER',
          style: TextStyle(fontFamily: AppTheme.body, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? Palette.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: selected ? Palette.accent : Palette.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.body,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: selected ? Palette.accentInk : Palette.muted,
            ),
          ),
        ),
      ),
    );
  }
}
