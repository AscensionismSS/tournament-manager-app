/// Payload enviado ao backend para criar um novo campeonato (POST /api/v1/tournaments).
class CreateTournamentRequest {
  final String name;
  final int type; // 1 = DirectPlayoffs, 2 = GroupStageAndPlayoffs, 3 = GroupStageDirectFinal
  final int playoffFormat; // 1 = SingleElimination, 2 = DoubleElimination
  final int teamCount; // 4 a 8
  final int groupCount; // 1 ou 2
  final int? groupStageFormat; // 1 = Bo1, 2 = Bo2, 3 = Bo3 (null se DirectPlayoffs)
  final int playoffSeriesFormat; // 1 = Bo1, 3 = Bo3, 5 = Bo5
  final int grandFinalSeriesFormat; // 1 = Bo1, 3 = Bo3, 5 = Bo5
  final bool enableDraftMode;
  final String? bannerUrl;

  const CreateTournamentRequest({
    required this.name,
    required this.type,
    required this.playoffFormat,
    required this.teamCount,
    required this.groupCount,
    this.groupStageFormat,
    required this.playoffSeriesFormat,
    required this.grandFinalSeriesFormat,
    required this.enableDraftMode,
    this.bannerUrl,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name.trim(),
      'type': type,
      'playoffFormat': playoffFormat,
      'teamCount': teamCount,
      'groupCount': groupCount,
      'playoffSeriesFormat': playoffSeriesFormat,
      'grandFinalSeriesFormat': grandFinalSeriesFormat,
      'enableDraftMode': enableDraftMode,
    };

    if (groupStageFormat != null) {
      map['groupStageFormat'] = groupStageFormat;
    }

    if (bannerUrl != null && bannerUrl!.trim().isNotEmpty) {
      map['bannerUrl'] = bannerUrl!.trim();
    }

    return map;
  }
}
