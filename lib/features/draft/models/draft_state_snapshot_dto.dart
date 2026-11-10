import 'draft_player_dto.dart';
import 'draft_team_dto.dart';

/// DTO com o snapshot em tempo real do estado do Draft (Tournaments.Contracts/Draft/DraftStateSnapshotDto).
class DraftStateSnapshotDto {
  final String draftSessionId;
  final String tournamentId;
  final String state;
  final int targetTeamCount;
  final int currentPickIndex;
  final String? currentTurnTeamId;
  final int? currentTurnPickOrder;
  final int draftVersion;
  final String? substitutingPlayerId;
  final String? substitutingTeamId;
  final List<DraftPlayerDto> playerPool;
  final List<DraftTeamDto> teams;
  final int minRequiredPlayers;
  final bool canStartDraft;
  final bool allCaptainsAssigned;
  final bool allStartersPicked;
  final int totalStarterPicks;

  const DraftStateSnapshotDto({
    required this.draftSessionId,
    required this.tournamentId,
    required this.state,
    required this.targetTeamCount,
    this.currentPickIndex = 0,
    this.currentTurnTeamId,
    this.currentTurnPickOrder,
    this.draftVersion = 0,
    this.substitutingPlayerId,
    this.substitutingTeamId,
    this.playerPool = const [],
    this.teams = const [],
    this.minRequiredPlayers = 0,
    this.canStartDraft = false,
    this.allCaptainsAssigned = false,
    this.allStartersPicked = false,
    this.totalStarterPicks = 0,
  });

  factory DraftStateSnapshotDto.fromJson(Map<String, dynamic> json) {
    return DraftStateSnapshotDto(
      draftSessionId: json['draftSessionId']?.toString() ?? '',
      tournamentId: json['tournamentId']?.toString() ?? '',
      state: json['state']?.toString() ?? 'Pending',
      targetTeamCount: (json['targetTeamCount'] as num?)?.toInt() ?? 0,
      currentPickIndex: (json['currentPickIndex'] as num?)?.toInt() ?? 0,
      currentTurnTeamId: json['currentTurnTeamId']?.toString(),
      currentTurnPickOrder: (json['currentTurnPickOrder'] as num?)?.toInt(),
      draftVersion: (json['draftVersion'] as num?)?.toInt() ?? 0,
      substitutingPlayerId: json['substitutingPlayerId']?.toString(),
      substitutingTeamId: json['substitutingTeamId']?.toString(),
      playerPool: (json['playerPool'] as List<dynamic>?)
              ?.map((e) => DraftPlayerDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      teams: (json['teams'] as List<dynamic>?)
              ?.map((e) => DraftTeamDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      minRequiredPlayers: (json['minRequiredPlayers'] as num?)?.toInt() ?? 0,
      canStartDraft: json['canStartDraft'] as bool? ?? false,
      allCaptainsAssigned: json['allCaptainsAssigned'] as bool? ?? false,
      allStartersPicked: json['allStartersPicked'] as bool? ?? false,
      totalStarterPicks: (json['totalStarterPicks'] as num?)?.toInt() ?? 0,
    );
  }

  /// Verifica se está na fase de escolha/atribuição de capitães (Fase 1)
  bool get isSelectingCaptains => state == 'SelectingCaptains';

  /// Verifica se está na fase de definição da ordem do Snake Draft (Fase 2)
  bool get isCaptainOrderSelection => state == 'CaptainOrderSelection';

  /// Verifica se está na fase de escolha de titulares (Fase 3)
  bool get isDraftingStarters => state == 'DraftingStarters';

  /// Verifica se está na fase de escolha de reservas (Fase 4)
  bool get isDraftingSubstitutes => state == 'DraftingSubstitutes';

  /// Se o draft já foi completamente consolidado
  bool get isCompleted => state == 'Completed';

  /// Número do pick global atual para exibição humana (1-indexed: Pick #1, Pick #2...)
  int get displayCurrentPick => currentPickIndex + 1;

  /// Quantidade atual de capitães já definidos
  int get assignedCaptainsCount => teams.where((t) => t.captainId != null).length;

  /// Total de capitães necessários (dinâmico para 4, 5, 6, 7, 8 equipes)
  int get totalCaptainsRequired => targetTeamCount > 0 ? targetTeamCount : teams.length;

  /// Determina se a sessão está no momento de decisão entre reservas ou finalizar
  bool get canDecidePostStarters => allStartersPicked && isDraftingStarters;

  /// Retorna o número da etapa ativa (1 a 4)
  int get currentStepNumber {
    switch (state) {
      case 'SelectingCaptains':
        return 1;
      case 'CaptainOrderSelection':
        return 2;
      case 'DraftingStarters':
      case 'Substituting':
        return 3;
      case 'DraftingSubstitutes':
        return 4;
      case 'Completed':
        return 4;
      default:
        return 1;
    }
  }
}

