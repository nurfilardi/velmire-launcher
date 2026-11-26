import 'package:flutter_test/flutter_test.dart';
import 'package:samp_launcher/data/config_store.dart';
import 'package:samp_launcher/models/server.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults, manual servers, favorites', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = ConfigStore(prefs);

    final config = store.readConfig();
    expect(config.clientPackage, 'com.gta.game');
    expect(config.cachePath, '/storage/emulated/0/GTA');
    expect(config.onboardingDone, isFalse);

    await store.writeConfig(config.copyWith(onboardingDone: true, nick: 'Reyzo'));
    expect(store.readConfig().onboardingDone, isTrue);
    expect(store.readConfig().nick, 'Reyzo');

    await store.saveManualServers([
      const Server(host: '1.2.3.4', port: 7777, name: 'A', manual: true),
    ]);
    expect(store.manualServers().single.name, 'A');

    await store.saveFavorites({'1.2.3.4:7777'});
    expect(store.favorites(), contains('1.2.3.4:7777'));

    await store.saveNicks({'1.2.3.4:7777': 'Budi'});
    expect(store.nicks()['1.2.3.4:7777'], 'Budi');
  });
}
