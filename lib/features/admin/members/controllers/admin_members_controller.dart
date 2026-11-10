import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../members/models/member_dto.dart';
import '../../../members/models/recovery_request_dto.dart';

/// Aba ativa no painel administrativo de gestão
enum AdminMembersTab {
  members('Gestão de Membros'),
  recoveryRequests('Solicitações de Troca de Steam');

  final String label;
  const AdminMembersTab(this.label);
}

/// Controller responsável pelo estado, filtros e ações da tela de Gestão Administrativa de Membros.
class AdminMembersController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController requestsSearchController = TextEditingController();

  AdminMembersTab _activeTab = AdminMembersTab.members;
  AdminMembersTab get activeTab => _activeTab;

  // Estados de Membros
  List<MemberDto> _members = [];
  List<MemberDto> get members => _members;

  bool _isLoadingMembers = false;
  bool get isLoadingMembers => _isLoadingMembers;

  String? _membersError;
  String? get membersError => _membersError;

  // Filtros de Membros (Padronização canônica com null = todos)
  String? _selectedRole;
  String? get selectedRole => _selectedRole;

  bool? _selectedHasSteam;
  bool? get selectedHasSteam => _selectedHasSteam;

  bool? _selectedIsActive;
  bool? get selectedIsActive => _selectedIsActive;

  // Estados de Solicitações de Recuperação (Troca de Steam)
  List<RecoveryRequestDto> _recoveryRequests = [];
  List<RecoveryRequestDto> get recoveryRequests => _recoveryRequests;

  /// Solicitações PENDENTES (filtradas por busca textual de nome ou e-mail)
  List<RecoveryRequestDto> get filteredRecoveryRequests {
    final pendingOnly = _recoveryRequests.where((r) => r.isPending).toList();
    final query = requestsSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return pendingOnly;
    return pendingOnly.where((r) {
      return r.displayName.toLowerCase().contains(query) ||
          r.email.toLowerCase().contains(query);
    }).toList();
  }

  /// Busca o membro correspondente para complementar dados de Steam se necessário
  MemberDto? getMemberByUserId(String userId) {
    try {
      return _members.firstWhere((m) => m.userId == userId);
    } catch (_) {
      return null;
    }
  }

  bool _isLoadingRequests = false;
  bool get isLoadingRequests => _isLoadingRequests;

  String? _requestsError;
  String? get requestsError => _requestsError;

  String? _processingUserId;
  String? get processingUserId => _processingUserId;

  String? _processingRequestId;
  String? get processingRequestId => _processingRequestId;

  // Quantidade de solicitações pendentes
  int get pendingRequestsCount =>
      _recoveryRequests.where((r) => r.isPending).length;

  AdminMembersController({AdminMembersTab initialTab = AdminMembersTab.members})
      : _activeTab = initialTab {
    requestsSearchController.addListener(_onRequestsSearchChanged);
  }

  void _onRequestsSearchChanged() {
    notifyListeners();
  }

  void setActiveTab(AdminMembersTab tab) {
    if (_activeTab != tab) {
      _activeTab = tab;
      notifyListeners();
      if (tab == AdminMembersTab.recoveryRequests && _recoveryRequests.isEmpty) {
        fetchRecoveryRequests();
      }
    }
  }

  void onSearchChanged(String query) {
    fetchMembers();
  }

  void setRoleFilter(String? role) {
    if (_selectedRole != role) {
      _selectedRole = role;
      notifyListeners();
      fetchMembers();
    }
  }

  void setHasSteamFilter(bool? value) {
    if (_selectedHasSteam != value) {
      _selectedHasSteam = value;
      notifyListeners();
      fetchMembers();
    }
  }

  void setIsActiveFilter(bool? value) {
    if (_selectedIsActive != value) {
      _selectedIsActive = value;
      notifyListeners();
      fetchMembers();
    }
  }

  bool get hasActiveMemberFilters =>
      searchController.text.trim().isNotEmpty ||
      _selectedRole != null ||
      _selectedHasSteam != null ||
      _selectedIsActive != null;

  void clearFilters() {
    searchController.clear();
    _selectedRole = null;
    _selectedHasSteam = null;
    _selectedIsActive = null;
    notifyListeners();
    fetchMembers();
  }

  /// Busca membros aplicando filtros de backend
  Future<void> fetchMembers() async {
    _isLoadingMembers = true;
    _membersError = null;
    notifyListeners();

    try {
      final search = searchController.text.trim();
      final role = _selectedRole;
      final bool? hasSteam = _selectedHasSteam;
      final bool? isActive = _selectedIsActive;

      final url = ApiEndpoints.members(
        search: search.isNotEmpty ? search : null,
        role: role,
        hasSteam: hasSteam,
        isActive: isActive,
      );

      final responseJson = await ApiClient.get(url, requiresAuth: true);

      final rawData = responseJson is List
          ? responseJson
          : (responseJson['data'] ?? responseJson['items'] ?? <dynamic>[]);

      final List<dynamic> listData = rawData is List ? rawData : <dynamic>[];

      _members = listData
          .map((item) => MemberDto.fromJson(item as Map<String, dynamic>))
          .toList();

      _isLoadingMembers = false;
      notifyListeners();
    } on ApiException catch (e) {
      _membersError = e.message;
      _isLoadingMembers = false;
      notifyListeners();
    } catch (e) {
      _membersError = 'Falha ao buscar membros: $e';
      _isLoadingMembers = false;
      notifyListeners();
    }
  }

  /// Ativa ou Desativa o login de um membro (PATCH /api/v1/users/{userId}/status)
  Future<bool> updateUserStatus(String userId, {
    required bool isActive,
    String? reason,
  }) async {
    _processingUserId = userId;
    notifyListeners();

    try {
      final url = ApiEndpoints.updateUserStatus(userId);
      final responseJson = await ApiClient.patch(
        url,
        body: {
          'isActive': isActive,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
        requiresAuth: true,
      );

      final updated = MemberDto.fromJson(responseJson);

      final index = _members.indexWhere((m) => m.userId == userId);
      if (index >= 0) {
        _members[index] = updated;
      }

      _processingUserId = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _membersError = e.message;
      _processingUserId = null;
      notifyListeners();
      return false;
    } catch (e) {
      _membersError = 'Erro ao alterar status da conta: $e';
      _processingUserId = null;
      notifyListeners();
      return false;
    }
  }


  /// Carrega as solicitações de troca de Steam (GET /api/v1/auth/recovery-requests)
  Future<void> fetchRecoveryRequests() async {
    _isLoadingRequests = true;
    _requestsError = null;
    notifyListeners();

    try {
      final responseJson = await ApiClient.get(
        ApiEndpoints.authRecoveryRequests,
        requiresAuth: true,
      );

      final rawData = responseJson is List
          ? responseJson
          : (responseJson['data'] ?? responseJson['items'] ?? <dynamic>[]);

      final List<dynamic> listData = rawData is List ? rawData : <dynamic>[];

      _recoveryRequests = listData
          .map((item) => RecoveryRequestDto.fromJson(item as Map<String, dynamic>))
          .toList();

      _isLoadingRequests = false;
      notifyListeners();
    } on ApiException catch (e) {
      _requestsError = e.message;
      _isLoadingRequests = false;
      notifyListeners();
    } catch (e) {
      _requestsError = 'Falha ao buscar solicitações: $e';
      _isLoadingRequests = false;
      notifyListeners();
    }
  }

  /// Aprova a solicitação de troca de Steam (POST /api/v1/auth/recovery-requests/{id}/approve-steam)
  Future<bool> approveSteamUnlock(String requestId) async {
    _processingRequestId = requestId;
    notifyListeners();

    try {
      await ApiClient.post(
        ApiEndpoints.approveRecoveryRequest(requestId),
        requiresAuth: true,
      );

      // Atualiza localmente o item para isUsed = true
      final index = _recoveryRequests.indexWhere((r) => r.id == requestId);
      if (index >= 0) {
        final current = _recoveryRequests[index];
        _recoveryRequests[index] = RecoveryRequestDto(
          id: current.id,
          userId: current.userId,
          displayName: current.displayName,
          email: current.email,
          type: current.type,
          createdAtUtc: current.createdAtUtc,
          isUsed: true,
          usedAtUtc: DateTime.now().toUtc(),
        );
      }

      // Atualiza também os membros caso a Steam de algum deles tenha sido desvinculada
      await fetchMembers();

      _processingRequestId = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _requestsError = e.message;
      _processingRequestId = null;
      notifyListeners();
      return false;
    } catch (e) {
      _requestsError = 'Falha ao aprovar troca de Steam: $e';
      _processingRequestId = null;
      notifyListeners();
      return false;
    }
  }

  /// Recusa a solicitação de troca de Steam (POST /api/v1/auth/recovery-requests/{id}/reject-steam)
  Future<bool> rejectSteamUnlock(String requestId, {String? reason}) async {
    _processingRequestId = requestId;
    notifyListeners();

    try {
      await ApiClient.post(
        ApiEndpoints.rejectRecoveryRequest(requestId),
        body: {
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
        requiresAuth: true,
      );

      // Marca como used localmente para sumir da lista de pendentes mantendo integridade
      final index = _recoveryRequests.indexWhere((r) => r.id == requestId);
      if (index >= 0) {
        final current = _recoveryRequests[index];
        _recoveryRequests[index] = RecoveryRequestDto(
          id: current.id,
          userId: current.userId,
          displayName: current.displayName,
          email: current.email,
          avatarUrl: current.avatarUrl,
          steamId: current.steamId,
          personaName: current.personaName,
          type: current.type,
          createdAtUtc: current.createdAtUtc,
          isUsed: true,
          usedAtUtc: DateTime.now().toUtc(),
        );
      }

      _processingRequestId = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _requestsError = e.message;
      _processingRequestId = null;
      notifyListeners();
      return false;
    } catch (e) {
      _requestsError = 'Falha ao recusar solicitação: $e';
      _processingRequestId = null;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    requestsSearchController.removeListener(_onRequestsSearchChanged);
    searchController.dispose();
    requestsSearchController.dispose();
    super.dispose();
  }
}
