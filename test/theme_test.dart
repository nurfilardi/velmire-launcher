import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samp_launcher/theme/app_theme.dart';

void main() {
  testWidgets('theme uses asphalt background and amber accent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.scaffoldBackgroundColor, Palette.bg);
    expect(theme.colorScheme.primary, Palette.accent);
    expect(theme.textTheme.displayLarge?.fontFamily, AppTheme.display);
  });
}
