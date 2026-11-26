import 'package:flutter/material.dart';

import '../models/server.dart';
import '../theme/app_theme.dart';
import 'widgets/common.dart';

class ServerCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final family = versionFamily(server.version);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Palette.line),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontFamily: AppTheme.display,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Palette.muted,
                    ),
                  ),
                ),
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: Palette.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (server.passworded)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.lock_outline, size: 12, color: Palette.muted),
                            ),
                          if (family != 'LAIN')
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Tag(family, color: Palette.accent),
                            ),
                          if (server.manual)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Tag('MANUAL', color: Palette.online),
                            ),
                          Flexible(
                            child: Text(
                              server.gamemode.isEmpty ? server.address : server.gamemode,
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
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${server.players}',
                      style: const TextStyle(
                        fontFamily: AppTheme.display,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 0.9,
                        color: Palette.accent,
                      ),
                    ),
                    Text(
                      '/${server.maxPlayers}',
                      style: const TextStyle(
                        fontFamily: AppTheme.body,
                        fontSize: 10,
                        letterSpacing: 0.6,
                        color: Palette.muted,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: onToggleFavorite,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    favorite ? Icons.star : Icons.star_border,
                    size: 20,
                    color: favorite ? Palette.accent : Palette.muted,
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
