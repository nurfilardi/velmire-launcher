import 'package:flutter/material.dart';

import '../core/app_log.dart';
import '../theme/app_theme.dart';

class CrashView extends StatelessWidget {
  final String message;
  const CrashView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VELMIRE',
                  style: TextStyle(
                    fontFamily: AppTheme.display,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Launcher gagal dimuat.',
                  style: TextStyle(fontFamily: AppTheme.body, fontSize: 16, color: Palette.danger),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      '$message\n\nLog: ${AppLog.path}',
                      style: const TextStyle(fontFamily: AppTheme.body, fontSize: 12, color: Palette.muted),
                    ),
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
