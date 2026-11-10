import 'package:flutter/material.dart';
import '../../../core/network/signalr_service.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/theme.dart';
import '../controllers/steam_link_controller.dart';
import '../models/login_response.dart';
import 'widgets/steam_input_search_bar.dart';
import 'widgets/steam_linked_card.dart';

/// Modal oficial do Ciclo Completo de Vinculação da Steam.
/// Clean, direto ao ponto e rigorosamente alinhado ao Design System do projeto:
/// - Cores de Destaque: Vermelho Arena (AppColors.primary) e Ouro Aegis (AppColors.dotaGold).
/// - Modularizado por SRP com reutilização obrigatória do SteamPreviewCard e sub-widgets dedicados.
class SteamConfigDialog extends StatefulWidget {
  final bool isMandatory;
  final LoginResponse? currentProfile;

  const SteamConfigDialog({
    super.key,
    this.isMandatory = false,
    this.currentProfile,
  });

  static Future<bool?> show(
    BuildContext context, {
    bool isMandatory = false,
    LoginResponse? currentProfile,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !isMandatory,
      barrierColor: Colors.black.withValues(alpha: 0.80),
      builder: (context) => SteamConfigDialog(
        isMandatory: isMandatory,
        currentProfile: currentProfile,
      ),
    );
  }

  @override
  State<SteamConfigDialog> createState() => _SteamConfigDialogState();
}

class _SteamConfigDialogState extends State<SteamConfigDialog> {
  late final SteamLinkController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SteamLinkController();
    _controller.identifierFocus.addListener(_onFocusChange);

    // Registra ouvinte em tempo real do evento ReceiveSteamUnlocked via SignalR
    SignalRService.instance.addSteamUnlockedListener(_onSteamUnlockedReceived);

    final isLinked = widget.currentProfile?.isSteamLinked == true;
    final isLocked = isLinked && (widget.currentProfile?.isSteamLocked ?? true);

    // Se estiver vinculado e BLOQUEADO, preenche em modo consulta
    if (isLinked && isLocked) {
      final steamId = widget.currentProfile?.steamId ?? '';
      _controller.identifierController.text = steamId.isNotEmpty
          ? steamId
          : (widget.currentProfile?.dotaPersonaName ?? 'Steam Vinculada');
    }
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _onSteamUnlockedReceived(dynamic data) {
    if (!mounted) return;
    _controller.handleSteamUnlocked(data);
    AppFeedback.showSuccess(
      context,
      message:
          'Solicitação Aprovada! O Administrador autorizou a troca. Você já pode vincular sua nova Steam.',
    );
  }

  @override
  void dispose() {
    SignalRService.instance
        .removeSteamUnlockedListener(_onSteamUnlockedReceived);
    _controller.identifierFocus.removeListener(_onFocusChange);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    FocusScope.of(context).unfocus();
    final text = _controller.identifierController.text.trim();
    if (text.isEmpty) {
      AppFeedback.showWarning(
        context,
        message: 'Informe o SteamID64 ou o link do perfil Steam.',
      );
      return;
    }

    final ok = await _controller.verifySteam();
    if (!ok && _controller.errorMessage != null && mounted) {
      if (_controller.preview?.isAlreadyInUse != true) {
        AppFeedback.showError(context, message: _controller.errorMessage!);
      }
    }
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final success = await _controller.linkSteam();
    if (success && mounted) {
      AppFeedback.showSuccess(
        context,
        message: 'Conta Steam vinculada com sucesso!',
      );
      if (widget.isMandatory) {
        Navigator.of(context).pop(true);
      }
    } else if (_controller.errorMessage != null && mounted) {
      AppFeedback.showError(context, message: _controller.errorMessage!);
    }
  }

  Future<void> _handleRequestUnlock() async {
    FocusScope.of(context).unfocus();
    final success = await _controller.requestSteamUnlock();
    if (success && mounted) {
      AppFeedback.showSuccess(
        context,
        message: 'Solicitação enviada ao administrador! Aguarde a liberação.',
      );
    } else if (_controller.errorMessage != null && mounted) {
      AppFeedback.showError(context, message: _controller.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LoginResponse?>(
      valueListenable: TokenStorage.profileNotifier,
      builder: (context, activeProfile, _) {
        final profile = activeProfile ?? widget.currentProfile;
        final isLinked = profile?.isSteamLinked == true;
        final isLocked = profile?.isSteamLocked == true;

        final String subtitleText;
        if (!isLinked) {
          subtitleText =
              'Vincule sua Steam para participar de torneios e sincronizar seus dados.';
        } else if (isLocked) {
          subtitleText =
              'Sua conta Steam já está vinculada e bloqueada. Solicite a um administrador para alterá-la.';
        } else {
          subtitleText =
              'Desbloqueio autorizado! Digite o novo link ou SteamID64 para atualizar sua conta.';
        }

        final String titleText;
        if (isLocked) {
          titleText = 'CONTA STEAM VINCULADA';
        } else if (isLinked) {
          titleText = 'TROCAR CONTA STEAM';
        } else {
          titleText = 'VINCULAR STEAM';
        }

        return PopScope(
          canPop: true,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final isReadyToSave = _controller.preview != null &&
                  !_controller.preview!.isAlreadyInUse &&
                  !_controller.isSaving;

              return AppDialog(
                title: titleText,
                icon: Icons.sports_esports_rounded,
                iconColor: AppColors.primaryNeon,
                maxWidth: 440,
                contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                trailingHeader: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isLocked && isLinked) ...[
                      const AppBadge(
                        label: 'DESBLOQUEADA',
                        variant: AppBadgeVariant.success,
                      ),
                      const SizedBox(width: 8),
                    ] else if (!isLocked && widget.isMandatory) ...[
                      const AppBadge(
                        label: 'OBRIGATÓRIO',
                        variant: AppBadgeVariant.warning,
                      ),
                      const SizedBox(width: 8),
                    ],
                    AppIconButton(
                      icon: Icons.close_rounded,
                      size: AppIconButtonSize.compact,
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                                  // Caixa de Informação Estruturada (Callout)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceHighlight
                                          .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.border
                                            .withValues(alpha: 0.6),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isLocked
                                              ? Icons.lock_outline_rounded
                                              : (isLinked
                                                  ? Icons.sync_rounded
                                                  : Icons.info_outline_rounded),
                                          size: 16,
                                          color: AppColors.primaryNeon,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            subtitleText,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12.5,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Barra de Busca de Steam / Campo Bloqueado
                                  SteamInputSearchBar(
                                    controller: _controller,
                                    isLocked: isLocked,
                                    linkedSteamId: profile?.steamId,
                                    onVerify: _handleVerify,
                                    onRequestUnlock: _handleRequestUnlock,
                                  ),
                                  const SizedBox(height: 16),

                                  // Card de Pré-Visualização / Card de Conta Bloqueada
                                  if (isLocked &&
                                      profile != null &&
                                      _controller.preview == null)
                                    SteamLinkedCard(
                                      profile: profile,
                                      previewRankTier: _controller
                                          .preview?.rankTier
                                          .toString(),
                                      previewLeaderboardRank:
                                          _controller.preview?.leaderboardRank,
                                    )
                                  else
                                    SteamPreviewCard(
                                      preview: _controller.preview,
                                      isVerifying: _controller.isVerifying,
                                      errorText: _controller.errorMessage,
                                      onClear: _controller.resetPreview,
                                      currentIdentifier:
                                          _controller.identifierController.text,
                                    ),

                  ],
                ),
                actions: isLocked
                    ? null
                    : [
                        if (!widget.isMandatory)
                          AppCancelButton(
                            height: 46,
                            label: 'CANCELAR',
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                        AppButton.primary(
                          text: isLinked ? 'SALVAR ALTERAÇÕES' : 'VINCULAR CONTA',
                          size: AppButtonSize.medium,
                          isFullWidth: true,
                          reserveLeadingSlot: false,
                          customColor: AppColors.primaryNeon,
                          isLoading: _controller.isSaving,
                          onPressed: isReadyToSave ? _handleSave : null,
                        ),
                      ],
              );
            },
          ),
        );
      },
    );
  }
}
