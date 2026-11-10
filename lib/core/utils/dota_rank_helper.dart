/// Utilitário centralizado para conversão e formatação de patentes (Ranks) do Dota 2.
/// Segue os padrões oficiais da Valve (tiers 1 a 8 e estrelas 1 a 5).
abstract final class DotaRankHelper {
  /// Mapeia o rankTier bruto (int ou String, ex: 11-85, 1-8 ou 'archon') para o tier numérico da Valve (0 a 8)
  static int parseTierNumber(dynamic rankTier) {
    if (rankTier == null) return 0;

    if (rankTier is num) {
      final int val = rankTier.toInt();
      if (val >= 10 && val <= 89) return val ~/ 10;
      if (val >= 1 && val <= 8) return val;
      return 0;
    }

    final cleaned = rankTier.toString().trim().toLowerCase();
    final parsedInt = int.tryParse(cleaned);
    if (parsedInt != null) {
      if (parsedInt >= 10 && parsedInt <= 89) return parsedInt ~/ 10;
      if (parsedInt >= 1 && parsedInt <= 8) return parsedInt;
      return 0;
    }

    if (cleaned.contains('heraldo') || cleaned.contains('herald')) return 1;
    if (cleaned.contains('guardi') || cleaned.contains('guardian')) return 2;
    if (cleaned.contains('cruzado') || cleaned.contains('crusader')) return 3;
    if (cleaned.contains('arconte') || cleaned.contains('archon')) return 4;
    if (cleaned.contains('lenda') || cleaned.contains('legend')) return 5;
    if (cleaned.contains('ancestral') || cleaned.contains('ancient')) return 6;
    if (cleaned.contains('divino') || cleaned.contains('divine')) return 7;
    if (cleaned.contains('imortal') || cleaned.contains('immortal')) return 8;

    return 0;
  }

  /// Retorna as estrelas da medalha (1 a 5) a partir do rankTier numérico ou de estrelas explícitas
  static int parseRankStars(dynamic rankTier, [int explicitStars = 0]) {
    if (explicitStars > 0 && explicitStars <= 5) return explicitStars;

    if (rankTier is num) {
      final int val = rankTier.toInt();
      if (val >= 10 && val <= 89) return val % 10;
      return 0;
    }

    final parsedInt = int.tryParse(rankTier?.toString().trim() ?? '');
    if (parsedInt != null && parsedInt >= 10 && parsedInt <= 89) {
      return parsedInt % 10;
    }

    return 0;
  }

  /// Retorna o nome oficial em inglês do rank tier (1 a 8)
  static String getRankName(int tierNumber) {
    switch (tierNumber) {
      case 1:
        return 'Herald';
      case 2:
        return 'Guardian';
      case 3:
        return 'Crusader';
      case 4:
        return 'Archon';
      case 5:
        return 'Legend';
      case 6:
        return 'Ancient';
      case 7:
        return 'Divine';
      case 8:
        return 'Immortal';
      default:
        return 'Sem Rank';
    }
  }

  /// Formata a descrição completa do rank (ex: 'Ancient [★ 3]' ou 'Immortal #42')
  static String formatRankDetail({
    required dynamic rankTier,
    int? leaderboardRank,
    int explicitStars = 0,
  }) {
    final tier = parseTierNumber(rankTier);
    if (tier == 0) return 'Sem Rank';

    if (tier == 8) {
      if (leaderboardRank != null && leaderboardRank > 0) {
        return 'Immortal #$leaderboardRank';
      }
      return 'Immortal';
    }

    final name = getRankName(tier);
    final stars = parseRankStars(rankTier, explicitStars);
    if (stars > 0) {
      return '$name $stars';
    }
    return name;
  }
}
