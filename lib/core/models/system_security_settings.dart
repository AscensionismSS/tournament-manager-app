/// Modelo de Dados para as Configurações Globais de Segurança do Sistema (Dumb UI).
/// Espelha fielmente `Tournaments.Contracts.Security.SystemSecuritySettingsDto`.
class SystemSecuritySettings {
  final bool lockResultSubmission;
  final bool lockTournamentRegistration;
  final bool lockTournamentCreation;
  final bool lockDraftPicks;
  final bool maintenanceMode;
  final String? message;
  final DateTime? updatedAtUtc;
  final String? updatedBy;
  final bool isResultSubmissionLocked;
  final bool isTournamentRegistrationLocked;
  final bool isTournamentCreationLocked;
  final bool isDraftPicksLocked;

  const SystemSecuritySettings({
    required this.lockResultSubmission,
    required this.lockTournamentRegistration,
    required this.lockTournamentCreation,
    required this.lockDraftPicks,
    required this.maintenanceMode,
    this.message,
    this.updatedAtUtc,
    this.updatedBy,
    required this.isResultSubmissionLocked,
    required this.isTournamentRegistrationLocked,
    required this.isTournamentCreationLocked,
    required this.isDraftPicksLocked,
  });

  /// Estado padrão inicial com todas as travas liberadas
  factory SystemSecuritySettings.initial() {
    return const SystemSecuritySettings(
      lockResultSubmission: false,
      lockTournamentRegistration: false,
      lockTournamentCreation: false,
      lockDraftPicks: false,
      maintenanceMode: false,
      message: null,
      updatedAtUtc: null,
      updatedBy: null,
      isResultSubmissionLocked: false,
      isTournamentRegistrationLocked: false,
      isTournamentCreationLocked: false,
      isDraftPicksLocked: false,
    );
  }

  factory SystemSecuritySettings.fromJson(Map<String, dynamic> json) {
    final bool rawMaintenance =
        (json['maintenanceMode'] ?? json['MaintenanceMode']) as bool? ?? false;
    final bool rawResultSubmission =
        (json['lockResultSubmission'] ?? json['LockResultSubmission']) as bool? ?? false;
    final bool rawRegistration =
        (json['lockTournamentRegistration'] ?? json['LockTournamentRegistration']) as bool? ?? false;
    final bool rawCreation =
        (json['lockTournamentCreation'] ?? json['LockTournamentCreation']) as bool? ?? false;
    final bool rawDraftPicks =
        (json['lockDraftPicks'] ?? json['LockDraftPicks']) as bool? ?? false;

    final String? rawUpdated =
        (json['updatedAtUtc'] ?? json['UpdatedAtUtc']) as String?;
    DateTime? updatedAtUtc;
    if (rawUpdated != null && rawUpdated.isNotEmpty) {
      updatedAtUtc = DateTime.tryParse(rawUpdated);
    }

    final bool isResultLocked =
        (json['isResultSubmissionLocked'] ?? json['IsResultSubmissionLocked']) as bool? ??
            (rawMaintenance || rawResultSubmission);
    final bool isRegLocked =
        (json['isTournamentRegistrationLocked'] ?? json['IsTournamentRegistrationLocked']) as bool? ??
            (rawMaintenance || rawRegistration);
    final bool isCreationLocked =
        (json['isTournamentCreationLocked'] ?? json['IsTournamentCreationLocked']) as bool? ??
            (rawMaintenance || rawCreation);
    final bool isDraftLocked =
        (json['isDraftPicksLocked'] ?? json['IsDraftPicksLocked']) as bool? ??
            (rawMaintenance || rawDraftPicks);

    return SystemSecuritySettings(
      lockResultSubmission: rawResultSubmission,
      lockTournamentRegistration: rawRegistration,
      lockTournamentCreation: rawCreation,
      lockDraftPicks: rawDraftPicks,
      maintenanceMode: rawMaintenance,
      message: (json['message'] ?? json['Message']) as String?,
      updatedAtUtc: updatedAtUtc,
      updatedBy: (json['updatedBy'] ?? json['UpdatedBy']) as String?,
      isResultSubmissionLocked: isResultLocked,
      isTournamentRegistrationLocked: isRegLocked,
      isTournamentCreationLocked: isCreationLocked,
      isDraftPicksLocked: isDraftLocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lockResultSubmission': lockResultSubmission,
      'lockTournamentRegistration': lockTournamentRegistration,
      'lockTournamentCreation': lockTournamentCreation,
      'lockDraftPicks': lockDraftPicks,
      'maintenanceMode': maintenanceMode,
      if (message != null && message!.trim().isNotEmpty)
        'message': message!.trim()
      else
        'message': null,
    };
  }

  SystemSecuritySettings copyWith({
    bool? lockResultSubmission,
    bool? lockTournamentRegistration,
    bool? lockTournamentCreation,
    bool? lockDraftPicks,
    bool? maintenanceMode,
    String? message,
    DateTime? updatedAtUtc,
    String? updatedBy,
    bool? isResultSubmissionLocked,
    bool? isTournamentRegistrationLocked,
    bool? isTournamentCreationLocked,
    bool? isDraftPicksLocked,
  }) {
    final effectiveMaintenance = maintenanceMode ?? this.maintenanceMode;
    final effectiveResult = lockResultSubmission ?? this.lockResultSubmission;
    final effectiveReg = lockTournamentRegistration ?? this.lockTournamentRegistration;
    final effectiveCreation = lockTournamentCreation ?? this.lockTournamentCreation;
    final effectiveDraft = lockDraftPicks ?? this.lockDraftPicks;

    return SystemSecuritySettings(
      lockResultSubmission: effectiveResult,
      lockTournamentRegistration: effectiveReg,
      lockTournamentCreation: effectiveCreation,
      lockDraftPicks: effectiveDraft,
      maintenanceMode: effectiveMaintenance,
      message: message ?? this.message,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      updatedBy: updatedBy ?? this.updatedBy,
      isResultSubmissionLocked: isResultSubmissionLocked ??
          (effectiveMaintenance || effectiveResult),
      isTournamentRegistrationLocked: isTournamentRegistrationLocked ??
          (effectiveMaintenance || effectiveReg),
      isTournamentCreationLocked: isTournamentCreationLocked ??
          (effectiveMaintenance || effectiveCreation),
      isDraftPicksLocked: isDraftPicksLocked ??
          (effectiveMaintenance || effectiveDraft),
    );
  }

  /// Verifica se há alguma trava ativa no momento
  bool get hasAnyLock =>
      maintenanceMode ||
      lockResultSubmission ||
      lockTournamentRegistration ||
      lockTournamentCreation ||
      lockDraftPicks;
}
