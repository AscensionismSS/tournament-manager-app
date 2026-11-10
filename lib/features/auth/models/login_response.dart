import '../../../core/utils/app_date_formatter.dart';

/// DTO oficial de resposta de autenticação (AuthResponseDto) retornado pelo backend.
class LoginResponse {
  final String userId;
  final String email;
  final String displayName;
  final String role; // "Player", "TournamentAdmin", "SuperAdmin"
  final String token;
  final String? refreshToken;
  final DateTime? expiresAtUtc;
  final bool isSteamLinked;
  final bool isSteamLocked;
  final String? steamId;
  final String? dotaRankTier;
  final int? dotaLeaderboardRank;
  final String? dotaPersonaName;
  final String? dotaAvatarUrl;
  final List<String> roles;
  final String? preferredRole;
  final String? preferredLandingPage; // "Player" | "Admin"

  const LoginResponse({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.token,
    this.refreshToken,
    this.expiresAtUtc,
    this.isSteamLinked = false,
    this.isSteamLocked = false,
    this.steamId,
    this.dotaRankTier,
    this.dotaLeaderboardRank,
    this.dotaPersonaName,
    this.dotaAvatarUrl,
    this.roles = const [],
    this.preferredRole,
    this.preferredLandingPage = 'Player',
  });

  /// Permissão de Gestão: SuperAdmin ou TournamentAdmin
  bool get canManageTournaments =>
      role == 'SuperAdmin' || role == 'TournamentAdmin';

  bool get isSuperAdmin => role == 'SuperAdmin';
  bool get isPlayer => role == 'Player';
  bool get isAdminRole => role == 'SuperAdmin' || role == 'TournamentAdmin';

  /// Preferência de Abertura Inicial (Player ou Admin)
  bool get prefersAdminLanding =>
      (preferredLandingPage ?? '').toLowerCase() == 'admin';

  LoginResponse copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? role,
    String? token,
    String? refreshToken,
    DateTime? expiresAtUtc,
    bool? isSteamLinked,
    bool? isSteamLocked,
    String? steamId,
    String? dotaRankTier,
    int? dotaLeaderboardRank,
    String? dotaPersonaName,
    String? dotaAvatarUrl,
    List<String>? roles,
    String? preferredRole,
    String? preferredLandingPage,
  }) {
    return LoginResponse(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAtUtc: expiresAtUtc ?? this.expiresAtUtc,
      isSteamLinked: isSteamLinked ?? this.isSteamLinked,
      isSteamLocked: isSteamLocked ?? this.isSteamLocked,
      steamId: steamId ?? this.steamId,
      dotaRankTier: dotaRankTier ?? this.dotaRankTier,
      dotaLeaderboardRank: dotaLeaderboardRank ?? this.dotaLeaderboardRank,
      dotaPersonaName: dotaPersonaName ?? this.dotaPersonaName,
      dotaAvatarUrl: dotaAvatarUrl ?? this.dotaAvatarUrl,
      roles: roles ?? this.roles,
      preferredRole: preferredRole ?? this.preferredRole,
      preferredLandingPage: preferredLandingPage ?? this.preferredLandingPage,
    );
  }

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Suporte caso venha envelopado em 'data'
    final target = json['data'] is Map<String, dynamic>
        ? (json['data'] as Map<String, dynamic>)
        : json;

    final token = (target['token'] ??
            target['accessToken'] ??
            target['jwt'] ??
            target['bearerToken'] ??
            '')
        .toString();

    final refreshToken = target['refreshToken']?.toString();

    final expires = AppDateFormatter.tryParse(target['expiresAtUtc']);

    final rawRoles = target['roles'];
    List<String> parsedRoles = [];
    if (rawRoles is List) {
      parsedRoles = rawRoles.map((e) => e.toString()).toList();
    }

    final steamId = target['steamId']?.toString() ?? target['SteamId']?.toString();
    final rawSteamLinked = target['isSteamLinked'] ?? target['IsSteamLinked'];
    final rawSteamLocked = target['isSteamLocked'] ?? target['IsSteamLocked'];

    final bool isLinked = rawSteamLinked == true ||
        rawSteamLinked?.toString().toLowerCase() == 'true' ||
        (steamId != null && steamId.isNotEmpty);

    final bool isLocked = rawSteamLocked == true ||
        rawSteamLocked?.toString().toLowerCase() == 'true' ||
        target['isLocked'] == true;

    final preferredLandingPage = target['preferredLandingPage']?.toString() ??
        target['PreferredLandingPage']?.toString() ??
        'Player';

    return LoginResponse(
      userId: target['userId']?.toString() ?? target['id']?.toString() ?? '',
      email: target['email']?.toString() ?? '',
      displayName: target['displayName']?.toString() ??
          target['userName']?.toString() ??
          target['email']?.toString() ??
          'Usuário',
      role: target['role']?.toString() ?? 'Player',
      token: token,
      refreshToken: refreshToken,
      expiresAtUtc: expires,
      isSteamLinked: isLinked,
      isSteamLocked: isLocked,
      steamId: steamId,
      dotaRankTier: target['dotaRankTier']?.toString() ??
          target['rankTier']?.toString() ??
          target['RankTier']?.toString() ??
          target['DotaRankTier']?.toString(),
      dotaLeaderboardRank: target['dotaLeaderboardRank'] is int
          ? target['dotaLeaderboardRank'] as int
          : (target['leaderboardRank'] is int
              ? target['leaderboardRank'] as int
              : int.tryParse(target['dotaLeaderboardRank']?.toString() ??
                  target['leaderboardRank']?.toString() ??
                  target['LeaderboardRank']?.toString() ??
                  '')),
      dotaPersonaName: target['dotaPersonaName']?.toString() ??
          target['personaName']?.toString() ??
          target['PersonaName']?.toString() ??
          target['DotaPersonaName']?.toString(),
      dotaAvatarUrl: target['dotaAvatarUrl']?.toString() ??
          target['avatarUrl']?.toString() ??
          target['AvatarUrl']?.toString() ??
          target['DotaAvatarUrl']?.toString(),
      roles: parsedRoles,
      preferredRole: target['preferredRole']?.toString(),
      preferredLandingPage: preferredLandingPage,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'displayName': displayName,
        'role': role,
        'token': token,
        'refreshToken': refreshToken,
        'expiresAtUtc': expiresAtUtc?.toIso8601String(),
        'isSteamLinked': isSteamLinked,
        'isSteamLocked': isSteamLocked,
        'steamId': steamId,
        'dotaRankTier': dotaRankTier,
        'dotaLeaderboardRank': dotaLeaderboardRank,
        'dotaPersonaName': dotaPersonaName,
        'dotaAvatarUrl': dotaAvatarUrl,
        'roles': roles,
        'preferredRole': preferredRole,
        'preferredLandingPage': preferredLandingPage,
      };
}
