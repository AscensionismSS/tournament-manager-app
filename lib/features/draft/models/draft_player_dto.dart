import '../../../../core/utils/dota_rank_helper.dart';

/// DTO de jogador dentro de uma sessão de Draft (Tournaments.Contracts/Draft/DraftPlayerDto).
class DraftPlayerDto {
  final String id;
  final String name;
  final String? externalUserId;
  final List<String> roles;
  final String? preferredRole;
  final int? rankTier;
  final int? leaderboardRank;
  final String? avatarUrl;
  final String? dotaFriendId;
  final String? steamProfileUrl;

  const DraftPlayerDto({
    required this.id,
    required this.name,
    this.externalUserId,
    this.roles = const [],
    this.preferredRole,
    this.rankTier,
    this.leaderboardRank,
    this.avatarUrl,
    this.dotaFriendId,
    this.steamProfileUrl,
  });

  factory DraftPlayerDto.fromJson(Map<String, dynamic> json) {
    return DraftPlayerDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      externalUserId: json['externalUserId']?.toString(),
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      preferredRole: json['preferredRole']?.toString(),
      rankTier: (json['rankTier'] as num?)?.toInt(),
      leaderboardRank: (json['leaderboardRank'] as num?)?.toInt(),
      avatarUrl: json['avatarUrl']?.toString(),
      dotaFriendId: json['dotaFriendId']?.toString(),
      steamProfileUrl: json['steamProfileUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'externalUserId': externalUserId,
        'roles': roles,
        'preferredRole': preferredRole,
        'rankTier': rankTier,
        'leaderboardRank': leaderboardRank,
        'avatarUrl': avatarUrl,
        'dotaFriendId': dotaFriendId,
        'steamProfileUrl': steamProfileUrl,
      };

  /// Iniciais para avatar
  String get initials {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Tier numérico da Valve (0 a 8)
  int get tierNumber => DotaRankHelper.parseTierNumber(rankTier);

  /// Estrelas da medalha (1 a 5)
  int get rankStars => DotaRankHelper.parseRankStars(rankTier);

  /// Nome formatado da medalha
  String get rankDetail => DotaRankHelper.formatRankDetail(rankTier: rankTier);
}

