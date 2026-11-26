class Server {
  final String host;
  final int port;
  final String name;
  final String gamemode;
  final String language;
  final String version;
  final int players;
  final int maxPlayers;
  final bool passworded;
  final bool manual;

  const Server({
    required this.host,
    required this.port,
    required this.name,
    this.gamemode = '',
    this.language = '',
    this.version = '',
    this.players = 0,
    this.maxPlayers = 0,
    this.passworded = false,
    this.manual = false,
  });

  String get address => '$host:$port';

  factory Server.fromApi(Map<String, dynamic> json) => Server(
        host: (json['ipAddress'] ?? '').toString(),
        port: _int(json['port'], 7777),
        name: (json['hostname'] ?? '').toString().trim(),
        gamemode: (json['gamemode'] ?? '').toString().trim(),
        language: (json['language'] ?? '').toString().trim(),
        version: (json['version'] ?? '').toString().trim(),
        players: _int(json['onlinePlayers'], 0),
        maxPlayers: _int(json['maxplayers'], 0),
        passworded: _int(json['passworded'], 0) != 0,
      );

  factory Server.fromJson(Map<String, dynamic> json) => Server(
        host: (json['host'] ?? '').toString(),
        port: _int(json['port'], 7777),
        name: (json['name'] ?? '').toString(),
        gamemode: (json['gamemode'] ?? '').toString(),
        language: (json['language'] ?? '').toString(),
        version: (json['version'] ?? '').toString(),
        players: _int(json['players'], 0),
        maxPlayers: _int(json['maxPlayers'], 0),
        passworded: json['passworded'] == true,
        manual: true,
      );

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'name': name,
        'gamemode': gamemode,
        'language': language,
        'version': version,
        'players': players,
        'maxPlayers': maxPlayers,
        'passworded': passworded,
      };

  Server copyWith({
    String? name,
    String? gamemode,
    String? language,
    String? version,
    int? players,
    int? maxPlayers,
    bool? passworded,
  }) =>
      Server(
        host: host,
        port: port,
        name: name ?? this.name,
        gamemode: gamemode ?? this.gamemode,
        language: language ?? this.language,
        version: version ?? this.version,
        players: players ?? this.players,
        maxPlayers: maxPlayers ?? this.maxPlayers,
        passworded: passworded ?? this.passworded,
        manual: manual,
      );

  static int _int(Object? v, int fallback) {
    if (v is int) return v;
    return int.tryParse('$v') ?? fallback;
  }
}

String versionFamily(String version) {
  final v = version.toLowerCase().trim();
  if (v.isEmpty) return 'LAIN';
  if (v.contains('omp') || v.contains('open.mp') || v.contains('openmp')) {
    return 'OPENMP';
  }
  if (v.contains('0.3.dl') || v.contains('03dl') || v.contains('dl r')) {
    return '0.3.DL';
  }
  if (v.contains('0.3.7') || v.contains('037')) return '0.3.7';
  return 'LAIN';
}
