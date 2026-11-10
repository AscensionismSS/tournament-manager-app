import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../controllers/admin_tournaments_controller.dart';
import '../../models/tournament_options_dto.dart';
import '../../models/tournament_wizard_state.dart';
import 'wizard_banner_frame.dart';
import 'wizard_format_support_panel.dart';
import 'wizard_team_count_selector.dart';

/// Passo 1 do Wizard: Nome da Competição, Banner & Quantidade de Equipes (Dumb UI).
/// Composto pelos sub-blocos modulares [WizardBannerFrame], [WizardTeamCountSelector]
/// e [WizardFormatSupportPanel].
class WizardStepTeams extends StatefulWidget {
  final AdminTournamentsController controller;
  final TextEditingController nameController;
  final TournamentWizardState state;
  final TournamentConfigurationOptionsDto? options;
  final ValueChanged<int> onTeamCountChanged;
  final VoidCallback onBannerChanged;

  const WizardStepTeams({
    super.key,
    required this.controller,
    required this.nameController,
    required this.state,
    required this.options,
    required this.onTeamCountChanged,
    required this.onBannerChanged,
  });

  static const List<int> defaultCounts = [4, 5, 6, 7, 8];

  @override
  State<WizardStepTeams> createState() => _WizardStepTeamsState();
}

class _WizardStepTeamsState extends State<WizardStepTeams> {
  bool _isUploadingBanner = false;

  Future<void> _pickBanner(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        if (file.bytes != null) {
          if (file.bytes!.lengthInBytes > 5 * 1024 * 1024) {
            if (context.mounted) {
              AppFeedback.showWarning(context, message: 'A imagem deve ter no máximo 5MB.');
            }
            return;
          }

          setState(() => _isUploadingBanner = true);

          try {
            // Upload delegado ao AdminTournamentsController, garantindo Dumb UI e separação de camadas
            final url = await widget.controller.uploadTournamentBanner(
              file.bytes!,
              file.name,
            );

            widget.state.bannerUrl = url;
            widget.state.bannerBytes = file.bytes;
            widget.state.bannerFileName = file.name;
            widget.onBannerChanged();

            if (context.mounted) {
              AppFeedback.showSuccess(
                context,
                title: 'BANNER APROVADO',
                message: 'Imagem validada e anexada com sucesso!',
              );
            }
          } on ApiException catch (e) {
            if (context.mounted) {
              AppFeedback.showError(
                context,
                title: 'BANNER INVÁLIDO',
                message: e.message,
              );
            }
          } catch (e) {
            if (context.mounted) {
              AppFeedback.showError(
                context,
                title: 'ERRO NO UPLOAD',
                message: 'Não foi possível enviar o banner: $e',
              );
            }
          } finally {
            if (mounted) {
              setState(() => _isUploadingBanner = false);
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        final errorStr = e.toString();
        if (errorStr.contains('MissingPluginException')) {
          AppFeedback.showWarning(
            context,
            message: 'Reinicie o terminal do Flutter para ativar o novo plugin de upload.',
          );
        } else {
          AppFeedback.showError(context, message: 'Não foi possível selecionar o arquivo: $e');
        }
      }
    }
  }

  void _restoreDefaultBanner() {
    widget.state.bannerBytes = null;
    widget.state.bannerFileName = null;
    widget.state.bannerUrl = null;
    widget.onBannerChanged();
  }

  @override
  Widget build(BuildContext context) {
    final supportedCounts = widget.options?.supportedTeamCounts ?? WizardStepTeams.defaultCounts;

    // UI Passiva: Compatibilidade informada estritamente pelo backend
    final isDirectPlayoffsAllowed = widget.options != null
        ? widget.options!.availableFormats.any((f) => f.type == 'DirectPlayoffs')
        : (widget.state.teamCount == 4 || widget.state.teamCount == 8);

    final groupFormat = widget.options?.availableFormats
        .where((f) => f.type == 'GroupStageAndPlayoffs')
        .firstOrNull;
    final isTwoGroupsAllowed = widget.options != null
        ? (groupFormat?.allowedGroupCounts.contains(2) ?? false)
        : (widget.state.teamCount == 8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),

        // 1. Campo Nome do Torneio
        AppInput(
          controller: widget.nameController,
          labelText: 'Nome do Campeonato *',
          hintText: 'Digite aqui o título oficial (Ex: Tsurus Cup Season 1)',
          prefixIcon: Icons.emoji_events_rounded,
          prefixIconColor: AppColors.dotaGold,
        ),
        const SizedBox(height: 14),

        // 2. Moldura do Banner da Competição (Subwidget SRP)
        WizardBannerFrame(
          state: widget.state,
          nameController: widget.nameController,
          isUploadingBanner: _isUploadingBanner,
          onPickBanner: () => _pickBanner(context),
          onRestoreDefault: _restoreDefaultBanner,
        ),
        const SizedBox(height: 14),

        // 3. Seletor de Equipes (Subwidget SRP)
        WizardTeamCountSelector(
          supportedCounts: supportedCounts,
          selectedCount: widget.state.teamCount,
          onTeamCountChanged: widget.onTeamCountChanged,
        ),
        const SizedBox(height: 14),

        // 4. Painel Informativo de Formatos Suportados (Subwidget SRP)
        WizardFormatSupportPanel(
          teamCount: widget.state.teamCount,
          isDirectPlayoffsAllowed: isDirectPlayoffsAllowed,
          isTwoGroupsAllowed: isTwoGroupsAllowed,
        ),
      ],
    );
  }
}
