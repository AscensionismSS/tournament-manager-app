import '../../../../core/utils/dota_rank_helper.dart';

/// DTO oficial de Membro/Jogador mapeado rigorosamente pelo contrato por contexto (/api/v1/users).
class MemberDto {
  final String userId;
  final String displayName;
  final String? personaName;
  final String? avatarUrl;
  final String? steamId;
  final String? dotaFriendId;
  final int? rankTier;
  final int? leaderboardRank;
  final List<String> roles;
  final String? preferredRole;
  final String role;
  final bool isSteamLocked;
  final bool isActive;
  final bool isTournamentEligible;
  final String? statusReason;
  final String? email;

  const MemberDto({
    required this.userId,
    required this.displayName,
    this.personaName,
    this.avatarUrl,
    this.steamId,
    this.dotaFriendId,
    this.rankTier,
    this.leaderboardRank,
    this.roles = const [],
    this.preferredRole,
    required this.role,
    this.isSteamLocked = false,
    this.isActive = true,
    this.isTournamentEligible = true,
    this.statusReason,
    this.email,
  });

  /// Nome exibido: Nome no jogo (Steam Persona) primeiro; se não tiver, DisplayName
  String get effectiveNickname {
    final persona = personaName?.trim();
    if (persona != null && persona.isNotEmpty) return persona;
    return displayName.trim().isNotEmpty ? displayName.trim() : 'Jogador';
  }

  /// E-mail para exibição limpa na tabela
  String get displayEmail {
    if (email != null && email!.trim().isNotEmpty) return email!.trim();
    if (displayName.contains('@')) return displayName.trim();
    return 'Sem e-mail';
  }

  /// Iniciais para fallback de avatar
  String get initials {
    final clean = effectiveNickname.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Verifica se possui Steam vinculada
  bool get isSteamLinked => steamId != null && steamId!.trim().isNotEmpty;

  /// Tier numérico da Valve (0 a 8)
  int get tierNumber => DotaRankHelper.parseTierNumber(rankTier);

  /// Estrelas da medalha (1 a 5)
  int get rankStars => DotaRankHelper.parseRankStars(rankTier);

  /// Nome formatado da medalha
  String get rankDetail => DotaRankHelper.formatRankDetail(
        rankTier: rankTier,
        leaderboardRank: leaderboardRank,
      );

  /// URL direta do perfil no OpenDota
  String? get openDotaUrl {
    final fid = dotaFriendId ?? steamId;
    if (fid != null && fid.isNotEmpty) {
      return 'https://www.opendota.com/players/$fid';
    }
    return null;
  }

  /// URL direta da comunidade Steam
  String? get computedSteamProfileUrl {
    if (steamId != null && steamId!.trim().isNotEmpty) {
      return 'https://steamcommunity.com/profiles/${steamId!.trim()}';
    }
    return null;
  }

  /// Cargo formatado para apresentação na UI (Dumb UI)
  String get roleDisplayName {
    final clean = role.toLowerCase();
    if (clean == 'superadmin') return 'SUPERADMIN';
    if (clean == 'admin') return 'ADMIN';
    return 'JOGADOR';
  }

  /// Verifica se o membro é SuperAdmin
  bool get isSuperAdmin => role.toLowerCase() == 'superadmin';

  /// Verifica se o membro é Administrador de Torneios
  bool get isAdmin => role.toLowerCase() == 'admin';

  factory MemberDto.fromJson(Map<String, dynamic> json) {
    final target = json['data'] is Map<String, dynamic>
        ? (json['data'] as Map<String, dynamic>)
        : json;

    final rawRoles = target['roles'];
    List<String> parsedRoles = [];
    if (rawRoles is List) {
      parsedRoles = rawRoles.map((e) => e.toString()).toList();
    }

    final rawRankTier = target['rankTier'];
    final parsedRankTier = rawRankTier is int
        ? rawRankTier
        : int.tryParse(rawRankTier?.toString() ?? '');

    final rawLeaderboard = target['leaderboardRank'];
    final parsedLeaderboard = rawLeaderboard is int
        ? rawLeaderboard
        : int.tryParse(rawLeaderboard?.toString() ?? '');

    final bool isLocked = target['isSteamLocked'] == true ||
        target['isSteamLocked']?.toString().toLowerCase() == 'true';

    final bool isActive = target['isActive'] == null ||
        target['isActive'] == true ||
        target['isActive']?.toString().toLowerCase() == 'true';

    final bool isEligible = target['isTournamentEligible'] == null ||
        target['isTournamentEligible'] == true ||
        target['isTournamentEligible']?.toString().toLowerCase() == 'true';

    final statusReason = target['statusReason']?.toString();
    final email = target['email']?.toString();

    return MemberDto(
      userId: target['userId']?.toString() ?? '',
      displayName: target['displayName']?.toString() ?? 'Jogador',
      personaName: target['personaName']?.toString(),
      avatarUrl: target['avatarUrl']?.toString(),
      steamId: target['steamId']?.toString(),
      dotaFriendId: target['dotaFriendId']?.toString(),
      rankTier: parsedRankTier,
      leaderboardRank: parsedLeaderboard,
      roles: parsedRoles,
      preferredRole: target['preferredRole']?.toString(),
      role: target['role']?.toString() ?? 'User',
      isSteamLocked: isLocked,
      isActive: isActive,
      isTournamentEligible: isEligible,
      statusReason: statusReason,
      email: email,
    );
  }
}
