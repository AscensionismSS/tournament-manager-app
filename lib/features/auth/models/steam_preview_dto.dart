/// DTO retornado pelo endpoint GET /api/v1/auth/preview-steam.
/// Utiliza estritamente String para steamId, prevenindo perda de precisão de 64 bits (IEEE-754) no Dart Web.
class SteamPreviewDto {
  final String steamId; // String no Dart para imunidade total contra arredondamento JS
  final String personaName;
  final String? avatarUrl;
  final int? rankTier;
  final int? leaderboardRank;
  final String? profileUrl;
  final String? steamIdString;
  final bool isAlreadyInUse;
  final String? alreadyInUseMessage;

  const SteamPreviewDto({
    required this.steamId,
    required this.personaName,
    this.avatarUrl,
    this.rankTier,
    this.leaderboardRank,
    this.profileUrl,
    this.steamIdString,
    this.isAlreadyInUse = false,
    this.alreadyInUseMessage,
  });

  /// URL direta do perfil na Steam Community
  String get effectiveProfileUrl {
    if (profileUrl != null && profileUrl!.trim().isNotEmpty) {
      return profileUrl!.trim();
    }
    final id = steamIdString?.trim().isNotEmpty == true ? steamIdString!.trim() : steamId.trim();
    return id.isNotEmpty ? 'https://steamcommunity.com/profiles/$id' : '';
  }

  /// Retorna o SteamID definitivo em texto
  String get effectiveSteamId =>
      (steamIdString != null && steamIdString!.trim().isNotEmpty) ? steamIdString!.trim() : steamId;

  /// Compatibilidade legada
  String get steamIdStr => effectiveSteamId;

  /// Nome amigável da medalha Dota 2 (baseado no rank_tier da Valve/OpenDota)
  String get rankName {
    final tier = rankTier ?? 0;
    if (tier <= 0) return 'Sem Rank';
    final medal = tier ~/ 10;
    final stars = tier % 10;

    String tierName;
    switch (medal) {
      case 1:
        tierName = 'Herald';
        break;
      case 2:
        tierName = 'Guardian';
        break;
      case 3:
        tierName = 'Crusader';
        break;
      case 4:
        tierName = 'Archon';
        break;
      case 5:
        tierName = 'Legend';
        break;
      case 6:
        tierName = 'Ancient';
        break;
      case 7:
        tierName = 'Divine';
        break;
      case 8:
        if (leaderboardRank != null && leaderboardRank! > 0) {
          return 'Immortal #$leaderboardRank';
        }
        return 'Immortal';
      default:
        return 'Dota 2';
    }

    return stars > 0 ? '$tierName [$stars★]' : tierName;
  }

  factory SteamPreviewDto.fromJson(Map<String, dynamic> json) {
    final target = json['data'] is Map<String, dynamic>
        ? (json['data'] as Map<String, dynamic>)
        : json;

    // Extrai o identificador diretamente como String para blindagem contra truncamento do JS
    final idStr = target['steamIdString']?.toString().trim() ??
        target['SteamIdString']?.toString().trim() ??
        target['steamId']?.toString().trim() ??
        target['SteamId']?.toString().trim() ??
        target['steamId64']?.toString().trim() ??
        target['id']?.toString().trim() ??
        '';

    final rawRankTier = target['rankTier'] ??
        target['RankTier'] ??
        target['dotaRankTier'] ??
        target['DotaRankTier'];
    final parsedRankTier = rawRankTier is int
        ? rawRankTier
        : int.tryParse(rawRankTier?.toString() ?? '');

    final rawLeaderboard = target['leaderboardRank'] ??
        target['LeaderboardRank'] ??
        target['dotaLeaderboardRank'] ??
        target['DotaLeaderboardRank'];
    final parsedLeaderboard = rawLeaderboard is int
        ? rawLeaderboard
        : int.tryParse(rawLeaderboard?.toString() ?? '');

    final rawInUse = target['isAlreadyInUse'] ??
        target['IsAlreadyInUse'] ??
        target['inUse'] ??
        target['InUse'];
    final parsedInUse = rawInUse == true || rawInUse?.toString().toLowerCase() == 'true';

    final personaName = (target['personaName'] ??
            target['PersonaName'] ??
            target['dotaPersonaName'] ??
            target['DotaPersonaName'] ??
            target['name'] ??
            target['displayName'] ??
            'Jogador Steam')
        .toString();

    final avatarUrl = target['avatarUrl']?.toString() ??
        target['AvatarUrl']?.toString() ??
        target['dotaAvatarUrl']?.toString() ??
        target['DotaAvatarUrl']?.toString() ??
        target['avatar']?.toString();

    final profileUrl = target['profileUrl']?.toString() ??
        target['ProfileUrl']?.toString() ??
        (idStr.isNotEmpty ? 'https://steamcommunity.com/profiles/$idStr' : null);

    final steamIdString = target['steamIdString']?.toString() ??
        target['SteamIdString']?.toString() ??
        (idStr.isNotEmpty ? idStr : null);

    return SteamPreviewDto(
      steamId: idStr,
      steamIdString: steamIdString,
      profileUrl: profileUrl,
      personaName: personaName,
      avatarUrl: avatarUrl,
      rankTier: parsedRankTier,
      leaderboardRank: parsedLeaderboard,
      isAlreadyInUse: parsedInUse,
      alreadyInUseMessage: target['alreadyInUseMessage']?.toString() ??
          target['AlreadyInUseMessage']?.toString() ??
          target['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'steamId': steamId,
        if (steamIdString != null) 'steamIdString': steamIdString,
        if (profileUrl != null) 'profileUrl': profileUrl,
        'personaName': personaName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (rankTier != null) 'rankTier': rankTier,
        if (leaderboardRank != null) 'leaderboardRank': leaderboardRank,
        'isAlreadyInUse': isAlreadyInUse,
        if (alreadyInUseMessage != null) 'alreadyInUseMessage': alreadyInUseMessage,
      };
}
