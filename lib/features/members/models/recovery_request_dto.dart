import '../../../core/utils/app_date_formatter.dart';

/// DTO que representa uma solicitação de recuperação/troca de Steam (GET /api/v1/auth/recovery-requests).
class RecoveryRequestDto {
  final String id;
  final String userId;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? steamId;
  final String? personaName;
  final String type;
  final DateTime createdAtUtc;
  final bool isUsed;
  final DateTime? usedAtUtc;

  const RecoveryRequestDto({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.steamId,
    this.personaName,
    required this.type,
    required this.createdAtUtc,
    this.isUsed = false,
    this.usedAtUtc,
  });

  /// Indica se a solicitação está pendente de aprovação
  bool get isPending => !isUsed;

  /// Verifica se possui Steam vinculada informada no DTO
  bool get isSteamLinked => steamId != null && steamId!.trim().isNotEmpty;

  /// URL direta do perfil na comunidade Steam
  String? get computedSteamProfileUrl {
    if (steamId != null && steamId!.trim().isNotEmpty) {
      return 'https://steamcommunity.com/profiles/${steamId!.trim()}';
    }
    return null;
  }

  /// Nome formatado do tipo de solicitação
  String get typeLabel {
    switch (type) {
      case 'SteamUnlockRequest':
        return 'Troca de Conta Steam';
      case 'PasswordReset':
        return 'Redefinição de Senha';
      default:
        return type;
    }
  }

  /// Data de criação formatada em horário local (Dumb UI pura)
  String get formattedCreatedAt => AppDateFormatter.formatDateTime(createdAtUtc);

  factory RecoveryRequestDto.fromJson(Map<String, dynamic> json) {
    final target = json['data'] is Map<String, dynamic>
        ? (json['data'] as Map<String, dynamic>)
        : json;

    final createdAt = AppDateFormatter.tryParse(
          target['createdAtUtc'],
          fallback: DateTime.now(),
        )!;
    final usedAt = AppDateFormatter.tryParse(target['usedAtUtc']);

    final bool isUsed = target['isUsed'] == true ||
        target['isUsed']?.toString().toLowerCase() == 'true';

    return RecoveryRequestDto(
      id: target['id']?.toString() ?? '',
      userId: target['userId']?.toString() ?? '',
      displayName: target['displayName']?.toString() ??
          target['userName']?.toString() ??
          'Jogador',
      email: target['email']?.toString() ?? '',
      avatarUrl: target['avatarUrl']?.toString(),
      steamId: target['steamId']?.toString() ?? target['currentSteamId']?.toString(),
      personaName: target['personaName']?.toString() ?? target['currentPersonaName']?.toString(),
      type: target['type']?.toString() ?? 'SteamUnlockRequest',
      createdAtUtc: createdAt,
      isUsed: isUsed,
      usedAtUtc: usedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'displayName': displayName,
        'email': email,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (steamId != null) 'steamId': steamId,
        if (personaName != null) 'personaName': personaName,
        'type': type,
        'createdAtUtc': createdAtUtc.toIso8601String(),
        'isUsed': isUsed,
        if (usedAtUtc != null) 'usedAtUtc': usedAtUtc!.toIso8601String(),
      };
}
