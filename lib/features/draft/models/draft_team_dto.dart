import 'draft_player_dto.dart';

/// DTO de equipe montada durante a sessão de Draft (Tournaments.Contracts/Draft/DraftTeamDto).
class DraftTeamDto {
  final String id;
  final String name;
  final String? captainId;
  final int pickOrder;
  final List<DraftPlayerDto> starters;
  final List<DraftPlayerDto> reserves;

  const DraftTeamDto({
    required this.id,
    required this.name,
    this.captainId,
    required this.pickOrder,
    this.starters = const [],
    this.reserves = const [],
  });

  factory DraftTeamDto.fromJson(Map<String, dynamic> json) {
    return DraftTeamDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      captainId: json['captainId']?.toString(),
      pickOrder: (json['pickOrder'] as num?)?.toInt() ?? 0,
      starters: (json['starters'] as List<dynamic>?)
              ?.map((e) => DraftPlayerDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      reserves: (json['reserves'] as List<dynamic>?)
              ?.map((e) => DraftPlayerDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Ordem de escolha para exibição humana (1-indexed: 1º, 2º, 3º...)
  int get displayPickOrder => pickOrder + 1;

  /// Jogador capitão da equipe (se atribuído)
  DraftPlayerDto? get captainPlayer {
    if (captainId == null) return null;
    for (final p in starters) {
      if (p.id == captainId) return p;
    }
    return null;
  }

  /// Total de jogadores titulares incluindo o capitão
  int get totalStartersCount => starters.length;

  /// Se a equipe já completou seus 5 titulares (1 capitão + 4 titulares)
  bool get hasFullStarters => starters.length >= 5 && captainId != null;
}

