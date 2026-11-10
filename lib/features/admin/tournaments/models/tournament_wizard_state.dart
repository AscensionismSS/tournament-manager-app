import 'dart:typed_data';
import 'tournament_options_dto.dart';

/// Estado do formulário do assistente de criação de torneio.
class TournamentWizardState {
  String name;
  int teamCount;
  String formatType; // 'DirectPlayoffs' | 'GroupStageAndPlayoffs'
  String playoffFormat; // 'SingleElimination' | 'DoubleElimination'
  int groupCount; // 1 | 2
  String groupStageFormat; // 'Bo1' | 'Bo2' | 'Bo3'
  String playoffSeriesFormat; // 'Bo1' | 'Bo3' | 'Bo5'
  String grandFinalSeriesFormat; // 'Bo1' | 'Bo3' | 'Bo5'
  bool enableDraftMode;

  // Banner da Competição
  Uint8List? bannerBytes;
  String? bannerFileName;
  String? bannerUrl;

  TournamentWizardState({
    this.name = '',
    this.teamCount = 8,
    this.formatType = 'GroupStageAndPlayoffs',
    this.playoffFormat = 'DoubleElimination',
    this.groupCount = 2,
    this.groupStageFormat = 'Bo2',
    this.playoffSeriesFormat = 'Bo3',
    this.grandFinalSeriesFormat = 'Bo5',
    this.enableDraftMode = true,
    this.bannerBytes,
    this.bannerFileName,
    this.bannerUrl,
  });

  /// Ajusta valores automaticamente caso a nova configuração de opções torne algum dado inválido
  void reconcileWithOptions(TournamentConfigurationOptionsDto? options) {
    if (options == null) {
      playoffFormat =
          formatType == 'DirectPlayoffs' ? 'SingleElimination' : 'DoubleElimination';
      return;
    }

    // 1. Validar teamCount
    if (!options.supportedTeamCounts.contains(teamCount)) {
      teamCount = options.supportedTeamCounts.contains(8)
          ? 8
          : (options.supportedTeamCounts.isNotEmpty ? options.supportedTeamCounts.first : 8);
    }

    // 2. Validar formato
    final matchingFormat = options.availableFormats.firstWhere(
      (f) => f.type == formatType,
      orElse: () => options.availableFormats.first,
    );
    formatType = matchingFormat.type;

    // 3. Validar playoffFormat (DirectPlayoffs -> SingleElimination | GroupStageAndPlayoffs -> DoubleElimination)
    if (formatType == 'DirectPlayoffs') {
      playoffFormat = 'SingleElimination';
    } else if (formatType == 'GroupStageAndPlayoffs') {
      playoffFormat = 'DoubleElimination';
    } else if (!matchingFormat.allowedPlayoffFormats.contains(playoffFormat)) {
      playoffFormat = matchingFormat.allowedPlayoffFormats.first;
    }

    // 4. Validar groupCount e séries dependentes
    if (formatType == 'DirectPlayoffs') {
      groupCount = 1;
      if (playoffSeriesFormat == 'Bo5') {
        playoffSeriesFormat = 'Bo3';
      }
    } else {
      if (!matchingFormat.allowedGroupCounts.contains(groupCount)) {
        groupCount = matchingFormat.allowedGroupCounts.first;
      }
      if (groupCount == 2 && teamCount != 8) {
        groupCount = 1;
      }
      if ((groupStageFormat == 'Bo1' || groupStageFormat == 'Bo2') &&
          playoffSeriesFormat == 'Bo5') {
        playoffSeriesFormat = 'Bo3';
      }
    }
    if (playoffSeriesFormat == 'Bo1' && grandFinalSeriesFormat == 'Bo5') {
      grandFinalSeriesFormat = 'Bo3';
    }
  }

  // --- Mapeamentos numéricos para o backend ---

  int get numericType {
    switch (formatType) {
      case 'DirectPlayoffs':
        return 1;
      case 'GroupStageAndPlayoffs':
        return 2;
      case 'GroupStageDirectFinal':
        return 3;
      default:
        return 2;
    }
  }

  int get numericPlayoffFormat {
    switch (playoffFormat) {
      case 'SingleElimination':
        return 1;
      case 'DoubleElimination':
        return 2;
      default:
        return 1;
    }
  }

  int? get numericGroupStageFormat {
    if (formatType == 'DirectPlayoffs') return null;
    switch (groupStageFormat) {
      case 'Bo1':
        return 1;
      case 'Bo2':
        return 2;
      case 'Bo3':
        return 3;
      default:
        return 2;
    }
  }

  int get numericPlayoffSeriesFormat {
    switch (playoffSeriesFormat) {
      case 'Bo1':
        return 1;
      case 'Bo3':
        return 3;
      case 'Bo5':
        return 5;
      default:
        return 3;
    }
  }

  int get numericGrandFinalSeriesFormat {
    switch (grandFinalSeriesFormat) {
      case 'Bo1':
        return 1;
      case 'Bo3':
        return 3;
      case 'Bo5':
        return 5;
      default:
        return 5;
    }
  }
}
