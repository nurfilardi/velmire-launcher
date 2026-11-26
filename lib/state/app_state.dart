import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../data/config_store.dart';
import '../data/game_data.dart';
import '../data/server_repository.dart';
import '../models/server.dart';

class AppState extends ChangeNotifier {
  final ConfigStore store;
  final ServerRepository repository;

  late AppConfig config;
  late List<Server> manual;
  late Set<String> favorites;
  late Map<String, String> nicks;

  List<Server> _api = const [];
  bool serversLoading = false;
  String? serversError;
  DateTime? serversUpdatedAt;

  AppState({required this.store, ServerRepository? repository})
      : repository = repository ?? ServerRepository(http.Client());

  void bootstrap() {
    config = store.readConfig();
    manual = store.manualServers();
    favorites = store.favorites();
    nicks = store.nicks();
    unawaited(refreshServers());
  }

  List<Server> get servers => ServerRepository.mergeManual(_api, manual);

  GameData get gameData => GameData(config.cachePath);

  Future<void> refreshServers({bool force = false}) async {
    if (serversLoading) return;
    serversLoading = true;
    serversError = null;
    notifyListeners();
    try {
      _api = await repository.fetchApi(force: force);
      serversUpdatedAt = DateTime.now();
    } catch (e) {
      serversError = 'Gagal memuat data server. Cek koneksi.';
    } finally {
      serversLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateConfig(AppConfig next) async {
    config = next;
    await store.writeConfig(next);
    notifyListeners();
  }

  Future<void> addManual(Server server) async {
    manual = [
      server,
      ...manual.where((s) => s.address != server.address),
    ];
    await store.saveManualServers(manual);
    notifyListeners();
  }

  Future<void> removeManual(Server server) async {
    manual = manual.where((s) => s.address != server.address).toList();
    await store.saveManualServers(manual);
    notifyListeners();
  }

  Future<void> toggleFavorite(String address) async {
    if (!favorites.add(address)) favorites.remove(address);
    await store.saveFavorites(favorites);
    notifyListeners();
  }

  String nickFor(Server server) => nicks[server.address] ?? config.nick;

  Future<void> saveNick(String address, String nick) async {
    nicks = {...nicks, address: nick};
    await store.saveNicks(nicks);
    if (config.nick.isEmpty) {
      config = config.copyWith(nick: nick);
      await store.writeConfig(config);
    }
    notifyListeners();
  }

  Server? get quickServer {
    final all = servers;
    if (all.isEmpty) return null;
    for (final s in all) {
      if (favorites.contains(s.address)) return s;
    }
    return all.reduce((a, b) => a.players >= b.players ? a : b);
  }

  List<Server> get topServers {
    final all = [...servers]..sort((a, b) => b.players.compareTo(a.players));
    return all.take(4).toList(growable: false);
  }

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan');
    return scope!.notifier!;
  }
}
