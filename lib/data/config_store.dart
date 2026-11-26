import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/server.dart';

const builtInManifestUrl = String.fromEnvironment('PROVIDER_MANIFEST');

String _manifestUrl(Object? raw) {
  final value = raw?.toString().trim() ?? '';
  return value.isEmpty ? builtInManifestUrl : value;
}

class AppConfig {
  final String clientPackage;
  final String clientActivity;
  final String cachePath;
  final String liteUrl;
  final String fullUrl;
  final String nick;
  final String manifestUrl;
  final bool onboardingDone;

  const AppConfig({
    this.clientPackage = 'com.gta.game',
    this.clientActivity = 'com.gta.game.SAMP',
    this.cachePath = '/storage/emulated/0/GTA',
    this.liteUrl = '',
    this.fullUrl = '',
    this.nick = '',
    this.manifestUrl = builtInManifestUrl,
    this.onboardingDone = false,
  });

  AppConfig copyWith({
    String? clientPackage,
    String? clientActivity,
    String? cachePath,
    String? liteUrl,
    String? fullUrl,
    String? nick,
    String? manifestUrl,
    bool? onboardingDone,
  }) => AppConfig(
    clientPackage: clientPackage ?? this.clientPackage,
    clientActivity: clientActivity ?? this.clientActivity,
    cachePath: cachePath ?? this.cachePath,
    liteUrl: liteUrl ?? this.liteUrl,
    fullUrl: fullUrl ?? this.fullUrl,
    nick: nick ?? this.nick,
    manifestUrl: manifestUrl ?? this.manifestUrl,
    onboardingDone: onboardingDone ?? this.onboardingDone,
  );

  Map<String, dynamic> toJson() => {
    'clientPackage': clientPackage,
    'clientActivity': clientActivity,
    'cachePath': cachePath,
    'liteUrl': liteUrl,
    'fullUrl': fullUrl,
    'nick': nick,
    'manifestUrl': manifestUrl,
    'onboardingDone': onboardingDone,
  };

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
    clientPackage: j['clientPackage'] ?? 'com.gta.game',
    clientActivity: j['clientActivity'] ?? 'com.gta.game.SAMP',
    cachePath: j['cachePath'] ?? '/storage/emulated/0/GTA',
    liteUrl: j['liteUrl'] ?? '',
    fullUrl: j['fullUrl'] ?? '',
    nick: j['nick'] ?? '',
    manifestUrl: _manifestUrl(j['manifestUrl']),
    onboardingDone: j['onboardingDone'] == true,
  );
}

class ConfigStore {
  static const _configKey = 'config.v1';
  static const _manualKey = 'servers.manual.v1';
  static const _favoritesKey = 'favorites.v1';
  static const _nicksKey = 'nicks.v1';
  static const _manifestKey = 'manifest.v1';

  final SharedPreferences _prefs;

  ConfigStore(this._prefs);

  AppConfig readConfig() {
    final raw = _prefs.getString(_configKey);
    if (raw == null) return const AppConfig();
    try {
      return AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppConfig();
    }
  }

  Future<void> writeConfig(AppConfig config) =>
      _prefs.setString(_configKey, jsonEncode(config.toJson()));

  List<Server> manualServers() {
    final raw = _prefs.getString(_manualKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(Server.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveManualServers(List<Server> servers) => _prefs.setString(
    _manualKey,
    jsonEncode(servers.map((s) => s.toJson()).toList()),
  );

  Set<String> favorites() =>
      (_prefs.getStringList(_favoritesKey) ?? const []).toSet();

  Future<void> saveFavorites(Set<String> favorites) =>
      _prefs.setStringList(_favoritesKey, favorites.toList()..sort());

  Map<String, String> nicks() {
    final raw = _prefs.getString(_nicksKey);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, '$v'));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveNicks(Map<String, String> nicks) =>
      _prefs.setString(_nicksKey, jsonEncode(nicks));

  String? cachedManifest() => _prefs.getString(_manifestKey);

  Future<void> saveManifestCache(String json) =>
      _prefs.setString(_manifestKey, json);
}
