import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samp_launcher/data/config_store.dart';
import 'package:samp_launcher/state/app_state.dart';
import 'package:samp_launcher/theme/app_theme.dart';
import 'package:samp_launcher/ui/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('id.samp.launcher/native'),
          (call) async => false,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('id.samp.launcher/native'),
          null,
        );
  });

  testWidgets('skip finishes setup without downloading', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final state = AppState(store: ConfigStore(prefs));
    state.config = const AppConfig();
    state.manual = const [];
    state.favorites = {};
    state.nicks = {};

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(theme: AppTheme.dark, home: const OnboardingPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lewati'), findsOneWidget);
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    expect(state.config.onboardingDone, isTrue);
  });
}
