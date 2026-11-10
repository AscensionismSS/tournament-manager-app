import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/system_security_service.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../controllers/admin_tournaments_controller.dart';
import '../models/create_tournament_request.dart';
import '../models/tournament_options_dto.dart';
import '../models/tournament_wizard_state.dart';
import 'widgets/wizard_step_format.dart';
import 'widgets/wizard_step_review.dart';
import 'widgets/wizard_step_series.dart';
import 'widgets/wizard_step_teams.dart';

/// Modal Wizard em 3 passos para criação oficial de torneios (Tsurus Plus+).
class CreateTournamentDialog extends StatefulWidget {
  final AdminTournamentsController controller;

  const CreateTournamentDialog({
    super.key,
    required this.controller,
  });

  static Future<bool?> show(
    BuildContext context, {
    required AdminTournamentsController controller,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateTournamentDialog(controller: controller),
    );
  }

  @override
  State<CreateTournamentDialog> createState() => _CreateTournamentDialogState();
}

class _CreateTournamentDialogState extends State<CreateTournamentDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TournamentWizardState _wizardState = TournamentWizardState();

  int _currentStep = 1;
  TournamentConfigurationOptionsDto? _options;
  final Map<int, TournamentConfigurationOptionsDto> _optionsCache = {};

  @override
  void initState() {
    super.initState();
    _loadOptionsForTeamCount(_wizardState.teamCount);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _hasEdits =>
      _nameController.text.trim().isNotEmpty ||
      _currentStep > 1 ||
      _wizardState.teamCount != 8;

  Future<void> _loadOptionsForTeamCount(int teamCount) async {
    if (_optionsCache.containsKey(teamCount)) {
      setState(() {
        _options = _optionsCache[teamCount];
        _wizardState.reconcileWithOptions(_options);
      });
      return;
    }

    final opts = await widget.controller.fetchFormatOptions(teamCount);
    if (mounted && opts != null) {
      _optionsCache[teamCount] = opts;
      setState(() {
        _options = opts;
        _wizardState.reconcileWithOptions(opts);
      });
    }
  }

  Future<bool> _handlePopScope() async {
    if (!_hasEdits) return true;

    final confirm = await AppConfirmDialog.show(
      context,
      title: 'CANCELAR CRIAÇÃO',
      message:
          'Existem dados não salvos no assistente. Se sair agora, todas as configurações serão descartadas. Deseja realmente sair?',
      confirmLabel: 'DESCARTAR',
      cancelLabel: 'CONTINUAR EDITANDO',
      isDestructive: true,
      icon: Icons.warning_amber_rounded,
    );

    return confirm;
  }

  void _onNextStep() {
    if (_currentStep == 1) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        AppFeedback.showWarning(context, message: 'Digite o nome do campeonato.');
        return;
      }
      if (name.length < 3) {
        AppFeedback.showWarning(
          context,
          message: 'O nome do campeonato deve ter pelo menos 3 caracteres.',
        );
        return;
      }
      _wizardState.name = name;
    }

    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _onPreviousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _onSubmit() async {
    if (SystemSecurityService.instance.isTournamentCreationLocked) {
      final msg = SystemSecurityService.instance.message;
      AppFeedback.showWarning(
        context,
        title: 'CRIAÇÃO DE TORNEIOS BLOQUEADA',
        message: (msg != null && msg.trim().isNotEmpty)
            ? msg.trim()
            : 'A criação de novos torneios está temporariamente bloqueada pela administração do sistema.',
      );
      return;
    }

    _wizardState.name = _nameController.text.trim();

    // Se houver banner selecionado localmente e ainda não enviado, faz upload
    if (_wizardState.bannerBytes != null && _wizardState.bannerUrl == null) {
      try {
        final uploadedUrl = await widget.controller.uploadTournamentBanner(
          _wizardState.bannerBytes!,
          _wizardState.bannerFileName ?? 'banner.png',
        );
        if (uploadedUrl != null) {
          _wizardState.bannerUrl = uploadedUrl;
        }
      } on ApiException catch (e) {
        if (mounted) {
          AppFeedback.showError(context, title: 'BANNER INVÁLIDO', message: e.message);
        }
        return;
      } catch (e) {
        if (mounted) {
          AppFeedback.showError(context, title: 'ERRO NO UPLOAD', message: 'Falha ao enviar banner: $e');
        }
        return;
      }
    }

    final request = CreateTournamentRequest(
      name: _wizardState.name,
      type: _wizardState.numericType,
      playoffFormat: _wizardState.numericPlayoffFormat,
      teamCount: _wizardState.teamCount,
      groupCount: _wizardState.groupCount,
      groupStageFormat: _wizardState.numericGroupStageFormat,
      playoffSeriesFormat: _wizardState.numericPlayoffSeriesFormat,
      grandFinalSeriesFormat: _wizardState.numericGrandFinalSeriesFormat,
      enableDraftMode: _wizardState.enableDraftMode,
      bannerUrl: _wizardState.bannerUrl,
    );

    final success = await widget.controller.createTournament(request);

    if (mounted) {
      if (success) {
        AppFeedback.showSuccess(
          context,
          message: 'Campeonato "${_wizardState.name}" criado com sucesso!',
        );
        Navigator.of(context).pop(true);
      } else {
        AppFeedback.showError(
          context,
          message: 'Não foi possível criar o campeonato. Verifique as regras e tente novamente.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handlePopScope();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: AppDialog(
        title: 'CRIAR NOVO CAMPEONATO',
        icon: Icons.emoji_events_rounded,
        maxWidth: 720,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Stepper Header com 4 Etapas
            _buildStepperHeader(),
            const SizedBox(height: 14),

            // 2. Conteúdo com Altura Estável e Transição Instantânea sem Reconstrução
            SizedBox(
              height: 565,
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
                child: IndexedStack(
                  index: _currentStep - 1,
                  children: [
                    WizardStepTeams(
                      controller: widget.controller,
                      nameController: _nameController,
                      state: _wizardState,
                      options: _options,
                      onTeamCountChanged: (count) {
                        setState(() => _wizardState.teamCount = count);
                        _loadOptionsForTeamCount(count);
                      },
                      onBannerChanged: () => setState(() {}),
                    ),
                    WizardStepFormat(
                      state: _wizardState,
                      options: _options,
                      onChanged: () => setState(() {}),
                    ),
                    WizardStepSeries(
                      state: _wizardState,
                      options: _options,
                      onChanged: () => setState(() {}),
                    ),
                    WizardStepReview(
                      state: _wizardState,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 3. Rodapé com Botões de Navegação
            _buildFooterActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        children: [
          _buildStepIndicator(1, 'Equipes'),
          _buildStepConnector(1),
          _buildStepIndicator(2, 'Formato'),
          _buildStepConnector(2),
          _buildStepIndicator(3, 'Séries'),
          _buildStepConnector(3),
          _buildStepIndicator(4, 'Resumo'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isDone = _currentStep > step;
    final isActive = _currentStep == step;

    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? AppColors.primaryNeon
                  : (isActive ? AppColors.primaryNeon : AppColors.surface),
              border: Border.all(
                color: (isActive || isDone)
                    ? Colors.transparent
                    : AppColors.border.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : Text(
                      '$step',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isActive ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isDone = _currentStep > step;
    return Container(
      width: 14,
      height: 1.5,
      color: isDone ? AppColors.primaryNeon : AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }

  Widget _buildFooterActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_currentStep > 1) ...[
          AppButton(
            text: 'VOLTAR',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.medium,
            onPressed: widget.controller.isCreating ? null : _onPreviousStep,
          ),
          const SizedBox(width: 10),
        ] else ...[
          AppButton(
            text: 'CANCELAR',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.medium,
            onPressed: widget.controller.isCreating
                ? null
                : () async {
                    final canPop = await _handlePopScope();
                    if (canPop && mounted) {
                      Navigator.of(context).pop(false);
                    }
                  },
          ),
          const SizedBox(width: 10),
        ],
        if (_currentStep < 4)
          AppButton(
            text: 'PRÓXIMO',
            icon: Icons.arrow_forward_rounded,
            size: AppButtonSize.medium,
            onPressed: _onNextStep,
          )
        else
          AppButton(
            text: 'CRIAR CAMPEONATO',
            icon: Icons.emoji_events_rounded,
            size: AppButtonSize.medium,
            isLoading: widget.controller.isCreating,
            onPressed: widget.controller.isCreating ? null : _onSubmit,
          ),
      ],
    );
  }
}
