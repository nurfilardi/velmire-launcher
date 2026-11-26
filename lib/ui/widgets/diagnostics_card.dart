import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_log.dart';
import '../../theme/app_theme.dart';
import 'common.dart';
import 'feedback.dart';

class DiagnosticsCard extends StatelessWidget {
  const DiagnosticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tail = AppLog.lines.length > 10
        ? AppLog.lines.sublist(AppLog.lines.length - 10)
        : AppLog.lines;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Log startup tersimpan lokal. Salin kalau app bermasalah.',
            style: TextStyle(fontFamily: AppTheme.body, fontSize: 12, color: Palette.muted, height: 1.4),
          ),
          const SizedBox(height: 10),
          SelectableText(
            tail.isEmpty ? '(kosong)' : tail.join('\n'),
            style: const TextStyle(fontFamily: AppTheme.body, fontSize: 10.5, color: Palette.muted, height: 1.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLog.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: AppTheme.body, fontSize: 10, color: Palette.muted),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: AppLog.lines.join('\n')));
                  if (context.mounted) showToast(context, 'Log disalin.');
                },
                child: const Text('SALIN LOG'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
