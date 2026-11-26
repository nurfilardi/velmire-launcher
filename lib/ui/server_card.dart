import 'package:flutter/material.dart';

import '../data/samp_query.dart';
import '../models/server.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';

class ServerCard extends StatefulWidget {
  final Server server;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onLongPress;

  const ServerCard({
    super.key,
    required this.server,
    required this.favorite,
    required this.onTap,
    required this.onToggleFavorite,
    this.onLongPress,
  });

  @override
  State<ServerCard> createState() => _ServerCardState();
}

class _ServerCardState extends State<ServerCard> {
  bool _open = false;
  bool _pinging = false;
  int? _ping;

  Future<void> _checkPing() async {
    if (_pinging) return;
    setState(() => _pinging = true);
    final watch = Stopwatch()..start();
    final info = await queryServer(widget.server.host, widget.server.port);
    watch.stop();
    if (!mounted) return;
    setState(() {
      _pinging = false;
      _ping = info == null ? null : watch.elapsedMilliseconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final server = widget.server;
    final family = versionFamily(server.version);
    final ratio = server.maxPlayers > 0
        ? server.players / server.maxPlayers
        : 0.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        onLongPress: widget.onLongPress,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Palette.line)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 0, 13),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            server.name.isEmpty ? server.address : server.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTheme.body,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              color: Palette.ink,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              if (server.passworded)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.lock_outline,
                                    size: 13,
                                    color: Palette.muted,
                                  ),
                                ),
                              if (family != 'LAIN')
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Tag(family, color: Palette.signal),
                                ),
                              if (server.manual)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Tag('Manual', color: Palette.accent),
                                ),
                              Flexible(
                                child: Text(
                                  server.gamemode.isEmpty
                                      ? server.address
                                      : server.gamemode,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.body,
                                    fontSize: 11.5,
                                    color: Palette.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${server.players}',
                      style: const TextStyle(
                        fontFamily: AppTheme.display,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        color: Palette.ink,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/${server.maxPlayers}',
                      style: const TextStyle(
                        fontFamily: AppTheme.body,
                        fontSize: 10,
                        color: Palette.muted,
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onToggleFavorite,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        widget.favorite ? Icons.star : Icons.star_border,
                        size: 20,
                        color: widget.favorite ? Palette.signal : Palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: _open
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    server.address,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.body,
                                      fontSize: 12,
                                      color: Palette.muted,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(ratio * 100).round()}% penuh',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.body,
                                    fontSize: 10.5,
                                    color: Palette.muted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: ratio.clamp(0, 1),
                                minHeight: 3,
                                color: Palette.signal,
                                backgroundColor: Palette.line,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: _pinging ? null : _checkPing,
                                  child: Text(
                                    _pinging
                                        ? 'Mengukur...'
                                        : _ping == null
                                        ? 'Cek ping'
                                        : '$_ping ms',
                                  ),
                                ),
                                const Spacer(),
                                FilledButton.icon(
                                  onPressed: widget.onTap,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Masuk'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
