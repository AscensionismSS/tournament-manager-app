import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/theme.dart';
import '../controllers/invitations_controller.dart';

/// Modal dialog oficial para criação de novo convite de acesso.
/// Proporção enxuta (maxWidth: 400), com switch de 3 horários (24h/48h/72h),
/// botões compactos de papéis com (i) integrado e scroll seguro contra overflow.
class CreateInvitationDialog extends StatefulWidget {
  final InvitationsController controller;

  const CreateInvitationDialog({
    super.key,
    required this.controller,
  });

  static Future<bool?> show(
    BuildContext context, {
    required InvitationsController controller,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateInvitationDialog(controller: controller),
    );
  }

  @override
  State<CreateInvitationDialog> createState() => _CreateInvitationDialogState();
}

class _CreateInvitationDialogState extends State<CreateInvitationDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();

  int _selectedRoleIndex = 0; // 0 = User, 1 = TournamentAdmin, 2 = SuperAdmin
  int _selectedHours = 24; // 24, 48 ou 72
  bool _isSuperAdmin = false;
  bool _isSubmitting = false;

  static const List<int> _allowedHours = [24, 48, 72];

  @override
  void initState() {
    super.initState();
    _checkSuperAdminStatus();
  }

  Future<void> _checkSuperAdminStatus() async {
    final profile = await TokenStorage.getUserProfile();
    if (mounted) {
      setState(() {
        _isSuperAdmin = profile?.isSuperAdmin ?? false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _formKey.currentState?.validate();
      AppFeedback.showError(
        context,
        title: 'CAMPO OBRIGATÓRIO',
        message: 'Por favor, informe o e-mail do convidado.',
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _formKey.currentState?.validate();
      AppFeedback.showError(
        context,
        title: 'E-MAIL INVÁLIDO',
        message: 'Por favor, informe um endereço de e-mail válido.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await widget.controller.createInvitation(
      email: email,
      targetRoleIndex: _selectedRoleIndex,
      validHours: _selectedHours,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result != null) {
      Navigator.of(context).pop(true);
      AppFeedback.showSuccess(
        context,
        message: 'Convite criado com sucesso para $email (${_selectedHours}h)!',
      );
    } else {
      final error = widget.controller.errorMessage ?? 'Não foi possível emitir o convite.';
      AppFeedback.showError(context, message: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      maxWidth: 440,
      icon: Icons.mark_email_unread_outlined,
      iconColor: AppColors.primaryNeon,
      title: 'NOVO CONVITE DE ACESSO',
      contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Campo de E-mail com floating label padronizado
            AppInput(
              controller: _emailController,
              focusNode: _emailFocus,
              labelText: 'E-mail do convidado',
              hintText: 'exemplo@email.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.alternate_email_rounded,
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),

            // 2. Seletor de Permissão (3 botões horizontais compactos com 'i' integrado)
            const Text(
              'NÍVEL DE ACESSO',
              style: TextStyle(
                fontFamily: 'Oswald',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: _buildRoleChip(
                    roleIndex: 0,
                    label: 'Jogador',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildRoleChip(
                    roleIndex: 1,
                    label: 'Admin Torneio',
                    isLocked: !_isSuperAdmin,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildRoleChip(
                    roleIndex: 2,
                    label: 'SuperAdmin',
                    isLocked: !_isSuperAdmin,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Caixa de tamanho fixo com o texto descritivo adaptativo do papel selecionado
            _buildRoleDescriptionBox(),
            const SizedBox(height: 10),

            // 3. Validade do Convite (Switch de 3 horários: 24h, 48h, 72h)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'VALIDADE DO CONVITE',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _selectedHours == 24
                      ? '1 dia'
                      : (_selectedHours == 48 ? '2 dias' : '3 dias'),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dotaGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            _buildHoursSwitch(),
          ],
        ),
      ),
      actions: [
        AppCancelButton(
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppConfirmButton(
          label: 'GERAR CONVITE',
          icon: Icons.send_rounded,
          isLoading: _isSubmitting,
          backgroundColor: AppColors.primary,
          onPressed: _handleSubmit,
        ),
      ],
    );
  }

  /// Caixa de tamanho fixo com o texto descritivo adaptativo do papel selecionado
  Widget _buildRoleDescriptionBox() {
    String roleName;
    String description;
    IconData icon;

    switch (_selectedRoleIndex) {
      case 1:
        roleName = 'Admin de Torneio';
        description =
            'Permite criar e gerenciar competições, chaves, drafts de capitães e homologar resultados.';
        icon = Icons.admin_panel_settings_outlined;
        break;
      case 2:
        roleName = 'Super Administrador';
        description =
            'Acesso irrestrito: emitir convites para novos administradores e gerenciar configurações globais.';
        icon = Icons.shield_outlined;
        break;
      case 0:
      default:
        roleName = 'Jogador';
        description =
            'Acesso padrão da comunidade para participar de torneios, integrar equipes e buscar partidas.';
        icon = Icons.sports_esports_outlined;
        break;
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.dotaGold,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 140),
              child: Text(
                '$roleName: $description',
                key: ValueKey<int>(_selectedRoleIndex),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Switch segmentado de 3 botões para os horários canônicos (24h, 48h, 72h)
  Widget _buildHoursSwitch() {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
          width: 1.0,
        ),
      ),
      child: Row(
        children: _allowedHours.map((hours) {
          final isSelected = _selectedHours == hours;
          final days = hours ~/ 24;
          final tooltip = '$hours horas ($days dia${days > 1 ? "s" : ""})';

          return Expanded(
            child: Tooltip(
              message: tooltip,
              child: InkWell(
                onTap: () => setState(() => _selectedHours = hours),
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${hours}h',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Chip compacto de papel (seleção direta sem ícone de info ou tooltip)
  Widget _buildRoleChip({
    required int roleIndex,
    required String label,
    bool isLocked = false,
  }) {
    final isSelected = _selectedRoleIndex == roleIndex;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLocked ? null : () => setState(() => _selectedRoleIndex = roleIndex),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isLocked
                ? AppColors.surfaceHighlight.withValues(alpha: 0.25)
                : isSelected
                    ? AppColors.primary.withValues(alpha: 0.16)
                    : AppColors.canvasSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLocked
                  ? AppColors.border.withValues(alpha: 0.3)
                  : isSelected
                      ? AppColors.primaryNeon
                      : AppColors.border.withValues(alpha: 0.6),
              width: isSelected ? 1.2 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLocked) ...[
                Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isLocked
                        ? AppColors.textSecondary.withValues(alpha: 0.5)
                        : isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe o e-mail do convidado.';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text)) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }
}
