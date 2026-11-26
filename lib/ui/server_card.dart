import 'package:flutter/material.dart';

import '../data/samp_query.dart';
import '../models/server.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';

class ServerCard extends StatefulWidget {
  final Server server;
  final int index;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onLongPress;

  const ServerCard({
    super.key,
    required this.server,
    required this.index,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Palette.surface,
        child: InkWell(
          onTap: () => setState(() => _open = !_open),
          onLongPress: widget.onLongPress,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _open ? Palette.signal : Palette.line),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                  child: Row(
                    children: [
                      RouteShield(
                        value: widget.index.toString().padLeft(2, '0'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              server.name.isEmpty
                                  ? server.address
                                  : server.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppTheme.body,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: Palette.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (server.passworded)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(
                                      Icons.lock_outline,
                                      size: 12,
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
                                    child: Tag('MANUAL', color: Palette.accent),
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
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${server.players}',
                            style: const TextStyle(
                              fontFamily: AppTheme.display,
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                              height: 0.9,
                              color: Palette.ink,
                            ),
                          ),
                          Text(
                            '/${server.maxPlayers}',
                            style: const TextStyle(
                              fontFamily: AppTheme.body,
                              fontSize: 10,
                              color: Palette.muted,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: widget.onToggleFavorite,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          widget.favorite ? Icons.star : Icons.star_border,
                          size: 19,
                          color: widget.favorite
                              ? Palette.signal
                              : Palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: _open
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Palette.line),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      server.address,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.body,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
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
                              ClipRect(
                                child: LinearProgressIndicator(
                                  value: ratio.clamp(0, 1),
                                  minHeight: 4,
                                  color: Palette.signal,
                                  backgroundColor: Palette.line,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  OutlinedButton(
                                    onPressed: _pinging ? null : _checkPing,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 36),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                    child: Text(
                                      _pinging
                                          ? 'CEK...'
                                          : _ping == null
                                          ? 'CEK PING'
                                          : '$_ping ms',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: widget.onTap,
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size.fromHeight(36),
                                      ),
                                      child: const Text('MASUK'),
                                    ),
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
      ),
    );
  }
}
