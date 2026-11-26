import 'package:flutter/material.dart';

import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'ui/app_shell.dart';
import 'ui/onboarding_page.dart';

class SampApp extends StatelessWidget {
  final AppState state;

  const SampApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Velmire Launcher',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _Gate(),
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return state.config.onboardingDone ? const AppShell() : const OnboardingPage();
  }
}
