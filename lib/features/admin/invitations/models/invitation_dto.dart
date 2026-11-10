import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/app_date_formatter.dart';

/// DTO oficial de Convite de Acesso (/api/v1/invitations).
/// Reflete rigorosamente o contrato do backend Identity.Contracts.Invitations.InvitationDto.
/// Fornece propriedades calculadas de apresentação prontas para a View (Dumb UI pura).
class InvitationDto {
  final String id;
  final String code;
  final String email;
  final String targetRole;
  final String createdByUserId;
  final DateTime createdAtUtc;
  final DateTime expiresAtUtc;
  final bool isUsed;
  final DateTime? usedAtUtc;
  final bool isRevoked;
  final DateTime? revokedAtUtc;
  final int? validHours;

  const InvitationDto({
    required this.id,
    required this.code,
    required this.email,
    required this.targetRole,
    required this.createdByUserId,
    required this.createdAtUtc,
    required this.expiresAtUtc,
    required this.isUsed,
    this.usedAtUtc,
    this.isRevoked = false,
    this.revokedAtUtc,
    this.validHours,
  });

  /// Verifica se o convite já expirou pelo tempo de validade
  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAtUtc);

  /// Indica se o convite pode ser revogado
  bool get canBeRevoked => !isUsed && !isRevoked && !isExpired;

  /// Status consolidado para a UI
  InvitationStatus get status {
    if (isRevoked) return InvitationStatus.revoked;
    if (isUsed) return InvitationStatus.used;
    if (isExpired) return InvitationStatus.expired;
    return InvitationStatus.pending;
  }

  /// Link completo de convite para a rota de cadastro/onboarding
  String get inviteLink {
    try {
      final base = Uri.base;
      if (base.hasAuthority && !base.scheme.startsWith('file')) {
        return '${base.origin}/register?code=$code';
      }
    } catch (_) {}
    return 'https://arena.tournament.local/register?code=$code';
  }

  /// Código truncado para visualização em tabela desktop
  String get maskedCode => code.length > 16 ? '${code.substring(0, 16)}...' : code;

  /// Data de criação formatada em horário local
  String get formattedCreatedAt => AppDateFormatter.formatDateTime(createdAtUtc);

  /// Data de validade formatada em horário local
  String get formattedExpiresAt => AppDateFormatter.formatDateTime(expiresAtUtc);

  /// Descrição contextual de status/validade (Zero ternário na View)
  String get validityDescription {
    if (isUsed) {
      final usedDate = AppDateFormatter.formatDateTime(usedAtUtc, placeholder: formattedCreatedAt);
      return 'Ativado em $usedDate';
    }
    if (isRevoked) return 'Revogado';
    if (isExpired) return 'Expirado';
    return 'Válido até $formattedExpiresAt';
  }

  /// Data da segunda linha pura (DD/MM/AAAA HH:mm) perfeitamente alinhada com a primeira data
  String get secondLineDate {
    if (isUsed && usedAtUtc != null) return AppDateFormatter.formatDateTime(usedAtUtc);
    if (isRevoked && revokedAtUtc != null) return AppDateFormatter.formatDateTime(revokedAtUtc);
    return formattedExpiresAt;
  }

  /// Cor associada ao papel do convite
  Color get roleColor {
    final lower = targetRole.toLowerCase();
    if (lower.contains('super')) return AppColors.dotaGold;
    if (lower.contains('admin')) return AppColors.primaryNeon;
    return AppColors.textSecondary;
  }

  /// Ícone temático associado ao papel do convite
  IconData get roleIcon {
    final lower = targetRole.toLowerCase();
    if (lower.contains('super')) return Icons.shield_rounded;
    if (lower.contains('admin')) return Icons.admin_panel_settings_rounded;
    return Icons.sports_esports_rounded;
  }

  /// Inicial para avatar do convidado
  String get initial {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  /// Nome amigável do papel
  String get roleDisplayLabel {
    final lower = targetRole.toLowerCase();
    if (lower.contains('super')) return 'SUPERADMIN';
    if (lower.contains('admin')) return 'ADMIN TORNEIO';
    return 'JOGADOR';
  }

  factory InvitationDto.fromJson(Map<String, dynamic> json) {
    final target = json['data'] is Map<String, dynamic>
        ? (json['data'] as Map<String, dynamic>)
        : json;

    return InvitationDto(
      id: (target['id'] ?? target['Id'] ?? '').toString(),
      code: (target['code'] ?? target['Code'] ?? '').toString(),
      email: (target['email'] ?? target['Email'] ?? '').toString(),
      targetRole: (target['targetRole'] ?? target['TargetRole'] ?? 'User').toString(),
      createdByUserId: (target['createdByUserId'] ?? target['CreatedByUserId'] ?? '').toString(),
      createdAtUtc: AppDateFormatter.tryParse(
        target['createdAtUtc'] ?? target['CreatedAtUtc'],
        fallback: DateTime.now().toUtc(),
      )!,
      expiresAtUtc: AppDateFormatter.tryParse(
        target['expiresAtUtc'] ?? target['ExpiresAtUtc'],
        fallback: DateTime.now().toUtc().add(const Duration(days: 7)),
      )!,
      isUsed: target['isUsed'] == true ||
          target['IsUsed'] == true ||
          target['isUsed']?.toString().toLowerCase() == 'true',
      usedAtUtc: AppDateFormatter.tryParse(target['usedAtUtc'] ?? target['UsedAtUtc']),
      isRevoked: target['isRevoked'] == true ||
          target['IsRevoked'] == true ||
          target['isRevoked']?.toString().toLowerCase() == 'true',
      revokedAtUtc: AppDateFormatter.tryParse(target['revokedAtUtc'] ?? target['RevokedAtUtc']),
      validHours: target['validHours'] is int
          ? (target['validHours'] as int)
          : (target['ValidHours'] is int
              ? (target['ValidHours'] as int)
              : int.tryParse(target['validHours']?.toString() ?? target['ValidHours']?.toString() ?? '')),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'email': email,
        'targetRole': targetRole,
        'createdByUserId': createdByUserId,
        'createdAtUtc': createdAtUtc.toIso8601String(),
        'expiresAtUtc': expiresAtUtc.toIso8601String(),
        'isUsed': isUsed,
        'usedAtUtc': usedAtUtc?.toIso8601String(),
        'isRevoked': isRevoked,
        'revokedAtUtc': revokedAtUtc?.toIso8601String(),
        'validHours': validHours,
      };
}

/// Enums de status com cores e ícones prontos
enum InvitationStatus {
  pending('Pendente', Icons.hourglass_top_rounded, AppColors.dotaGold),
  used('Utilizado', Icons.check_circle_rounded, AppColors.primaryNeon),
  revoked('Revogado', Icons.block_rounded, AppColors.primary),
  expired('Expirado', Icons.schedule_rounded, AppColors.textSecondary);

  final String label;
  final IconData icon;
  final Color color;

  const InvitationStatus(this.label, this.icon, this.color);
}
