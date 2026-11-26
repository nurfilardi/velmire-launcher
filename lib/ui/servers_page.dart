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
  String _filter = 'Semua';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Server server, String query) {
    if (_filter == 'Favorit' && !_favoriteSet.contains(server.address)) {
      return false;
    }
    if (_filter == 'Manual' && !server.manual) return false;
    if (_filter != 'Semua' &&
        _filter != 'Favorit' &&
        _filter != 'Manual' &&
        versionFamily(server.version) != _filter.toUpperCase()) {
      return false;
    }
    if (query.isEmpty) return true;
    final haystack =
        '${server.name} ${server.host} ${server.gamemode} ${server.language}'
            .toLowerCase();
    return haystack.contains(query);
  }

  Set<String> _favoriteSet = {};

  Future<void> _add() async {
    final state = AppScope.of(context);
    final server = await AddServerSheet.show(context);
    if (server == null || !mounted) return;
    await state.addManual(server);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${server.name} ditambahkan')));
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
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
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Server',
                        style: TextStyle(
                          fontFamily: AppTheme.display,
                          fontSize: 34,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh, color: Palette.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari server',
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: Palette.muted,
                      ),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _search.clear()),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final f in const [
                          'Semua',
                          'Favorit',
                          '0.3.7',
                          '0.3.DL',
                          'OpenMP',
                          'Manual',
                        ])
                          _FilterTab(
                            label: f,
                            selected: _filter == f,
                            onTap: () => setState(() => _filter = f),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (state.serversError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Gagal memuat. Menampilkan data terakhir.',
                        style: TextStyle(
                          fontFamily: AppTheme.body,
                          fontSize: 12,
                          color: Palette.muted,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => state.refreshServers(force: true),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                color: Palette.signal,
                backgroundColor: Palette.surface,
                onRefresh: () => state.refreshServers(force: true),
                child: list.isEmpty
                    ? ListView(
                        children: [
                          EmptyState(
                            title: state.serversLoading
                                ? 'Memuat server...'
                                : 'Tidak ada server',
                            message: state.serversLoading
                                ? 'Mengambil daftar server Indonesia.'
                                : 'Ubah filter atau tambah server manual.',
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(22, 4, 22, 100),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final server = list[i];
                          return ServerCard(
                            server: server,
                            favorite: state.favorites.contains(server.address),
                            onTap: () => NicknameSheet.show(context, server),
                            onToggleFavorite: () =>
                                state.toggleFavorite(server.address),
                            onLongPress: server.manual
                                ? () => _removeManual(server)
                                : null,
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
          'Tambah',
          style: TextStyle(
            fontFamily: AppTheme.body,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 18),
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? Palette.signal : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.body,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Palette.ink : Palette.muted,
          ),
        ),
      ),
    );
  }
}
