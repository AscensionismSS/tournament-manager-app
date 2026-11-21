import 'package:flutter/foundation.dart';

/// Catálogo centralizado de endpoints da API (Single-Tenant).
///
/// Reflete com fidelidade estrita as rotas expostas pelo backend TournamentCreator
/// (Host/TournamentCreator.WebApi/Controllers/v1).
class ApiEndpoints {
  ApiEndpoints._();

  /// URL Base configurável:
  /// - Em desenvolvimento local (debug): http://localhost:5000/api/v1
  /// - Em produção (release): https://tournament-manager-api-34p7.onrender.com/api/v1
  /// - Sobrescrito se fornecido via --dart-define=API_BASE_URL=...
  static String baseUrl = _resolveDefaultBaseUrl();

  static String _resolveDefaultBaseUrl() {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return _enforceReleaseHttps(fromEnv);
    }
    if (kDebugMode) {
      return 'http://localhost:5000/api/v1';
    }
    return 'https://tournament-manager-api-34p7.onrender.com/api/v1';
  }

  /// Impede downgrade acidental para HTTP em compilação de produção (exceto loopback local)
  static String _enforceReleaseHttps(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (!kReleaseMode) return trimmed;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return 'https://tournament-manager-api-34p7.onrender.com/api/v1';
    final isLocalhost = uri.host == 'localhost' || uri.host == '127.0.0.1';
    if (!isLocalhost && uri.scheme == 'http') {
      return uri.replace(scheme: 'https').toString();
    }
    return trimmed;
  }

  /// Helper para alternar porta e protocolo exclusivamente durante o desenvolvimento local
  static void configurePort(int port, {bool isHttps = false}) {
    if (!kDebugMode) return;
    final scheme = isHttps ? 'https' : 'http';
    baseUrl = '$scheme://localhost:$port/api/v1';
  }

  /// URL Base do Hub SignalR (Padrão: http://localhost:5000/hubs/v1/tournament-draft)
  static String get tournamentDraftHubUrl {
    final uri = Uri.parse(baseUrl);
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$portPart/hubs/v1/tournament-draft';
  }

  /// Resolve caminhos relativos de mídia (ex: /uploads/banners/...) validando esquema seguro
  static String? resolveMediaUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final clean = rawUrl.trim();
    final parsed = Uri.tryParse(clean);
    if (parsed != null && parsed.hasScheme) {
      final scheme = parsed.scheme.toLowerCase();
      if (scheme != 'https' && !(kDebugMode && scheme == 'http')) {
        return null;
      }
      return clean;
    }
    final uri = Uri.parse(baseUrl);
    final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
    return clean.startsWith('/') ? '$origin$clean' : '$origin/$clean';
  }

  // ==========================================
  // 1. Autenticação & Sessão (AuthController)
  // ==========================================
  static String get authLogin => '$baseUrl/auth/login';
  static String get authRegisterInvite => '$baseUrl/auth/register-invite';
  static String get authMe => '$baseUrl/auth/me';
  static String get authUpdateRoles => '$baseUrl/auth/roles';
  static String get authForgotPassword => '$baseUrl/auth/forgot-password';
  static String get authResetPassword => '$baseUrl/auth/reset-password';
  static String get authForgotLogin => '$baseUrl/auth/forgot-login';
  static String authRecoverLogin(String token) =>
      '$baseUrl/auth/recover-login?token=${Uri.encodeComponent(token)}';
  static String get authRecoveryRequests => '$baseUrl/auth/recovery-requests';
  static String approveRecoveryRequest(String id) => '$baseUrl/auth/recovery-requests/$id/approve-steam';
  static String rejectRecoveryRequest(String id) => '$baseUrl/auth/recovery-requests/$id/reject-steam';

  // ==========================================
  // 2. Integração Steam (Steam Identity)
  // ==========================================
  static String previewSteam(String identifier) =>
      '$baseUrl/auth/preview-steam?identifier=${Uri.encodeComponent(identifier.trim())}';
  static String get linkSteam => '$baseUrl/auth/link-steam';
  static String unlockSteamUser(String userId) => '$baseUrl/auth/users/$userId/unlock-steam';
  static String get requestSteamUnlock => '$baseUrl/auth/request-steam-unlock';

  // ==========================================
  // 3. Usuários e Membros (Users / Members)
  // ==========================================
  static String get usersList => '$baseUrl/users';
  static String get membersList => '$baseUrl/members';
  static String userById(String id) => '$baseUrl/users/$id';
  static String updateUserStatus(String userId) => '$baseUrl/users/$userId/status';

  static String members({
    String? search,
    String? role,
    bool? hasSteam,
    bool? isActive,
  }) {
    final params = <String, String>{};
    if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
    if (role != null && role.trim().isNotEmpty) params['role'] = role.trim();
    if (hasSteam != null) params['hasSteam'] = hasSteam.toString();
    if (isActive != null) params['isActive'] = isActive.toString();

    if (params.isEmpty) return '$baseUrl/members';
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$baseUrl/members?$query';
  }

  // ==========================================
  // 3. Torneios (TournamentsController)
  // ==========================================
  static String tournaments({String? status}) =>
      status != null ? '$baseUrl/tournaments?status=$status' : '$baseUrl/tournaments';
  static String tournamentOptions({int? teamCount}) => teamCount != null
      ? '$baseUrl/tournaments/options?teamCount=$teamCount'
      : '$baseUrl/tournaments/options';
  static String get tournamentUploadBanner => '$baseUrl/tournaments/upload-banner';
  static String tournamentById(String id) => '$baseUrl/tournaments/$id';
  static String tournamentMatches(String id) => '$baseUrl/tournaments/$id/matches';
  static String tournamentStandings(String id) => '$baseUrl/tournaments/$id/standings';
  static String tournamentTeams(String id) => '$baseUrl/tournaments/$id/teams';
  static String tournamentCloseRegistrations(String id) =>
      '$baseUrl/tournaments/$id/registrations/close';
  static String tournamentOpenRegistrations(String id) =>
      '$baseUrl/tournaments/$id/registrations/open';
  static String tournamentLockResults(String id) =>
      '$baseUrl/tournaments/$id/results/lock';
  static String tournamentUnlockResults(String id) =>
      '$baseUrl/tournaments/$id/results/unlock';
  static String tournamentStart(String id) => '$baseUrl/tournaments/$id/start';
  static String tournamentCancel(String id) => '$baseUrl/tournaments/$id/cancel';
  static String tournamentAdvanceToPlayoffs(String id) =>
      '$baseUrl/tournaments/$id/playoffs/generate';
  static String tournamentRevertToGroupStage(String id) =>
      '$baseUrl/tournaments/$id/playoffs/revert';
  static String tournamentSync(String id, {int? knownVersion}) =>
      knownVersion != null
          ? '$baseUrl/tournaments/$id/sync?knownVersion=$knownVersion'
          : '$baseUrl/tournaments/$id/sync';
  static String get tournamentEventsGlobal => '$baseUrl/tournaments/events';
  static String tournamentEventsById(String id) => '$baseUrl/tournaments/$id/events';

  // ==========================================
  // 4. Draft Sessions (DraftController)
  // ==========================================
  static String draftSnapshot(String draftSessionId) => '$baseUrl/draft/$draftSessionId';
  static String draftPool(String draftSessionId) => '$baseUrl/draft/$draftSessionId/pool';
  static String draftLatePlayer(String draftSessionId) =>
      '$baseUrl/draft/$draftSessionId/late-players';
  static String draftCaptain(String draftSessionId) => '$baseUrl/draft/$draftSessionId/captain';
  static String draftRemoveCaptain(String draftSessionId, String teamId, int expectedVersion) =>
      '$baseUrl/draft/$draftSessionId/captain/$teamId?expectedVersion=$expectedVersion';
  static String draftAdvanceToOrderSelection(String draftSessionId) =>
      '$baseUrl/draft/$draftSessionId/advance-to-order-selection';
  static String draftFinalizeOrder(String draftSessionId) =>
      '$baseUrl/draft/$draftSessionId/finalize-order';
  static String draftRenameTeam(String draftSessionId) =>
      '$baseUrl/draft/$draftSessionId/team/rename';
  static String draftPick(String draftSessionId) => '$baseUrl/draft/$draftSessionId/pick';
  static String draftReserve(String draftSessionId) => '$baseUrl/draft/$draftSessionId/reserve';
  static String draftRemoveReserve(
    String draftSessionId,
    String teamId,
    String playerId,
    int expectedVersion,
  ) =>
      '$baseUrl/draft/$draftSessionId/teams/$teamId/reserves/$playerId?expectedVersion=$expectedVersion';
  static String draftStartSubstitution(String draftSessionId) =>
      '$baseUrl/draft/$draftSessionId/substitution/start';
  static String draftConfirmSubstitution(String draftSessionId) =>
      '$baseUrl/draft/$draftSessionId/substitution/confirm';
  static String draftCancelSubstitution(String draftSessionId) =>
      '$baseUrl/draft/$draftSessionId/substitution/cancel';
  static String draftAdvanceToSubstitutes(String draftSessionId) =>
      '$baseUrl/draft/$draftSessionId/advance-to-substitutes';
  static String draftComplete(String draftSessionId) => '$baseUrl/draft/$draftSessionId/complete';

  // ==========================================
  // 5. Partidas (MatchesController)
  // ==========================================
  static String matchById(String id) => '$baseUrl/matches/$id';
  static String matchManualResult(String id) => '$baseUrl/matches/$id/result/manual';
  static String matchWalkoverResult(String id) => '$baseUrl/matches/$id/result/walkover';
  static String matchReplay(String id) => '$baseUrl/matches/$id/replay';
  static String matchReplayResult(String id) => '$baseUrl/matches/$id/replay/result';
  static String matchGame(String id, int gameNumber) => '$baseUrl/matches/$id/games/$gameNumber';
  static String matchGameReplay(String id, int gameNumber) => '$baseUrl/matches/$id/games/$gameNumber/replay';
  static String matchGameWalkover(String id, int gameNumber) => '$baseUrl/matches/$id/games/$gameNumber/walkover';
  static String matchRemoveLastGame(String id) => '$baseUrl/matches/$id/games/last';
  static String matchRollback(String id) => '$baseUrl/matches/$id/rollback';

  // ==========================================
  // 6. Convites (InvitationsController)
  // ==========================================
  static String get invitations => '$baseUrl/invitations';
  static String get invitationExpirationOptions => '$baseUrl/invitations/expiration-options';
  static String invitationRevoke(String id) => '$baseUrl/invitations/$id/revoke';
  static String invitationValidate(String code) =>
      '$baseUrl/invitations/validate/${Uri.encodeComponent(code.trim())}';

  // ==========================================
  // 7. Preferências de Admin (AdminPreferencesController)
  // ==========================================
  static String get adminPreferences => '$baseUrl/admin/preferences';

  // ==========================================
  // 8. Segurança e Travas Globais (AdminSecuritySettingsController)
  // ==========================================
  static String get systemSecuritySettings => '$baseUrl/admin/security-settings';
  static String get publicSecuritySettings => '$baseUrl/system/security-settings';

  // ==========================================
  // 9. Cenário Pro (ProMatchesController)
  // ==========================================
  static String get proMatchesOverview => '$baseUrl/pro-matches';
}


