import 'package:flutter/material.dart';
import '../../../core/models/system_security_settings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/system_security_service.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/app_date_formatter.dart';
import 'widgets/security_lock_tile.dart';

/// Diálogo administrativo exclusivo para SuperAdmin gerenciar travas globais de segurança
/// e o Modo de Manutenção da plataforma (SRP & Dumb UI).
class SystemSecurityDialog extends StatefulWidget {
  const SystemSecurityDialog({super.key});

  /// Exibe o diálogo com restrição de 480px e animação suave
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.background.withValues(alpha: 0.70),
      builder: (context) => const SystemSecurityDialog(),
    );
  }

  @override
  State<SystemSecurityDialog> createState() => _SystemSecurityDialogState();
}

class _SystemSecurityDialogState extends State<SystemSecurityDialog> {
  late bool _maintenanceMode;
  late bool _lockTournamentCreation;
  late bool _lockTournamentRegistration;
  late bool _lockResultSubmission;
  late bool _lockDraftPicks;
  late final TextEditingController _messageController;

  bool _isSaving = false;
  bool _isDirty = false;
  DateTime? _updatedAtUtc;
  String? _updatedBy;

  @override
  void initState() {
    super.initState();
    final current = SystemSecurityService.instance.current;
    _maintenanceMode = current.maintenanceMode;
    _lockTournamentCreation = current.lockTournamentCreation;
    _lockTournamentRegistration = current.lockTournamentRegistration;
    _lockResultSubmission = current.lockResultSubmission;
    _lockDraftPicks = current.lockDraftPicks;
    _updatedAtUtc = current.updatedAtUtc;
    _updatedBy = current.updatedBy;
    _messageController = TextEditingController(text: current.message ?? '');
    _messageController.addListener(_onUserEdited);

    _refreshSettings();
  }

  void _onUserEdited() {
    if (!_isDirty) {
      _isDirty = true;
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onUserEdited);
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _refreshSettings() async {
    try {
      final s = await SystemSecurityService.instance.fetchSettings();
      if (!mounted) return;
      setState(() {
        _updatedAtUtc = s.updatedAtUtc;
        _updatedBy = s.updatedBy;
        if (!_isDirty) {
          _maintenanceMode = s.maintenanceMode;
          _lockTournamentCreation = s.lockTournamentCreation;
          _lockTournamentRegistration = s.lockTournamentRegistration;
          _lockResultSubmission = s.lockResultSubmission;
          _lockDraftPicks = s.lockDraftPicks;
          _messageController.text = s.message ?? '';
        }
      });
    } catch (_) {
      // Falha silenciosa, mantém valores em cache
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final updated = SystemSecuritySettings(
        lockResultSubmission: _lockResultSubmission,
        lockTournamentRegistration: _lockTournamentRegistration,
        lockTournamentCreation: _lockTournamentCreation,
        lockDraftPicks: _lockDraftPicks,
        maintenanceMode: _maintenanceMode,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
        isResultSubmissionLocked: _maintenanceMode || _lockResultSubmission,
        isTournamentRegistrationLocked:
            _maintenanceMode || _lockTournamentRegistration,
        isTournamentCreationLocked:
            _maintenanceMode || _lockTournamentCreation,
        isDraftPicksLocked: _maintenanceMode || _lockDraftPicks,
      );

      await SystemSecurityService.instance.updateSettings(updated);

      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        message: 'Travas globais e segurança atualizadas com sucesso!',
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, message: e.message);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        message: 'Erro ao salvar travas de segurança: $e',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      maxWidth: 480,
      icon: Icons.admin_panel_settings_rounded,
      iconColor: AppColors.primaryNeon,
      title: 'SEGURANÇA DO SISTEMA',
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Controle centralizado de travas operacionais e modo de manutenção do ecossistema de torneios.',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),

              // 1. Modo de Manutenção Geral (Destaque Alerta)
              SecurityLockTile(
                icon: Icons.build_circle_rounded,
                title: 'Modo Manutenção Geral',
                subtitle:
                    'Ativa banner persistente e restringe criação, inscrições e homologação de partidas para todos os usuários.',
                value: _maintenanceMode,
                isMaintenance: true,
                onChanged: (v) => setState(() {
                  _isDirty = true;
                  _maintenanceMode = v;
                }),
              ),
              const SizedBox(height: 10),

              // 2. Trava de Criação de Torneios
              SecurityLockTile(
                icon: Icons.add_circle_outline_rounded,
                title: 'Travar Criação de Torneios',
                subtitle:
                    'Desabilita o botão de criação de novos campeonatos em todo o sistema.',
                value: _lockTournamentCreation,
                onChanged: (v) => setState(() {
                  _isDirty = true;
                  _lockTournamentCreation = v;
                }),
              ),
              const SizedBox(height: 10),

              // 3. Trava de Inscrições / Registro de Equipes
              SecurityLockTile(
                icon: Icons.how_to_reg_rounded,
                title: 'Travar Inscrições de Torneios',
                subtitle:
                    'Impede o ingresso de novos jogadores e equipes em campeonatos abertos.',
                value: _lockTournamentRegistration,
                onChanged: (v) => setState(() {
                  _isDirty = true;
                  _lockTournamentRegistration = v;
                }),
              ),
              const SizedBox(height: 10),

              // 4. Trava de Envio de Resultados
              SecurityLockTile(
                icon: Icons.sports_score_rounded,
                title: 'Travar Envio de Resultados',
                subtitle:
                    'Impede o registro, edição e homologação de mapas e partidas.',
                value: _lockResultSubmission,
                onChanged: (v) => setState(() {
                  _isDirty = true;
                  _lockResultSubmission = v;
                }),
              ),
              const SizedBox(height: 10),

              // 5. Trava de Escolhas de Draft
              SecurityLockTile(
                icon: Icons.groups_rounded,
                title: 'Travar Escolhas de Draft (Picks)',
                subtitle:
                    'Bloqueia a seleção e pick de jogadores em sessões de draft ao vivo.',
                value: _lockDraftPicks,
                onChanged: (v) => setState(() {
                  _isDirty = true;
                  _lockDraftPicks = v;
                }),
              ),
              const SizedBox(height: 14),

              // 6. Campo de Motivo / Comunicado
              AppInput(
                controller: _messageController,
                labelText: 'Comunicado / Motivo do Bloqueio',
                hintText:
                    'Ex: Manutenção no banco de dados. Retorno previsto para 20h.',
              ),

              if (_updatedAtUtc != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Última alteração: ${AppDateFormatter.formatDateTime(_updatedAtUtc)} por ${_updatedBy ?? "SuperAdmin"}',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.65),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          text: 'CANCELAR',
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.medium,
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 8),
        AppButton(
          text: 'SALVAR ALTERAÇÕES',
          variant: AppButtonVariant.primary,
          size: AppButtonSize.medium,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _saveSettings,
        ),
      ],
    );
  }
}
