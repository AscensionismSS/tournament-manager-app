/// Opções de formato disponíveis para um torneio (Domain/Contracts/TournamentFormatOptionDto).
class TournamentFormatOptionDto {
  final String type;
  final String name;
  final String description;
  final List<String> allowedPlayoffFormats;
  final List<int> allowedGroupCounts;
  final bool supportsDraftMode;

  const TournamentFormatOptionDto({
    required this.type,
    required this.name,
    required this.description,
    required this.allowedPlayoffFormats,
    required this.allowedGroupCounts,
    required this.supportsDraftMode,
  });

  factory TournamentFormatOptionDto.fromJson(Map<String, dynamic> json) {
    return TournamentFormatOptionDto(
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      allowedPlayoffFormats: (json['allowedPlayoffFormats'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      allowedGroupCounts: (json['allowedGroupCounts'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      supportsDraftMode: json['supportsDraftMode'] as bool? ?? true,
    );
  }
}

/// Formatos de séries permitidos (Bo1, Bo2, Bo3, Bo5).
class SeriesFormatOptionsDto {
  final List<String> groupStageFormats;
  final List<String> playoffFormats;
  final List<String> grandFinalFormats;

  const SeriesFormatOptionsDto({
    required this.groupStageFormats,
    required this.playoffFormats,
    required this.grandFinalFormats,
  });

  factory SeriesFormatOptionsDto.fromJson(Map<String, dynamic> json) {
    return SeriesFormatOptionsDto(
      groupStageFormats: (json['groupStageFormats'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      playoffFormats: (json['playoffFormats'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      grandFinalFormats: (json['grandFinalFormats'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// DTO completo retornado por GET /api/v1/tournaments/options
class TournamentConfigurationOptionsDto {
  final int? selectedTeamCount;
  final List<int> supportedTeamCounts;
  final List<TournamentFormatOptionDto> availableFormats;
  final SeriesFormatOptionsDto seriesFormats;

  const TournamentConfigurationOptionsDto({
    this.selectedTeamCount,
    required this.supportedTeamCounts,
    required this.availableFormats,
    required this.seriesFormats,
  });

  factory TournamentConfigurationOptionsDto.fromJson(Map<String, dynamic> json) {
    final formats = (json['availableFormats'] as List<dynamic>?)
            ?.map((f) => TournamentFormatOptionDto.fromJson(f as Map<String, dynamic>))
            .toList() ??
        [];

    final series = json['seriesFormats'] != null
        ? SeriesFormatOptionsDto.fromJson(json['seriesFormats'] as Map<String, dynamic>)
        : const SeriesFormatOptionsDto(
            groupStageFormats: ['Bo1', 'Bo2', 'Bo3'],
            playoffFormats: ['Bo1', 'Bo3', 'Bo5'],
            grandFinalFormats: ['Bo1', 'Bo3', 'Bo5'],
          );

    return TournamentConfigurationOptionsDto(
      selectedTeamCount: json['selectedTeamCount'] as int?,
      supportedTeamCounts: (json['supportedTeamCounts'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [4, 5, 6, 7, 8],
      availableFormats: formats,
      seriesFormats: series,
    );
  }
}
