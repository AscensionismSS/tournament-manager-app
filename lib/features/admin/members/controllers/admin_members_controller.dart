import 'dart:async';
import 'dart:math' as math;
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
  static const int pageSize = 15;

  final TextEditingController searchController = TextEditingController();
  final TextEditingController requestsSearchController = TextEditingController();

  AdminMembersTab _activeTab = AdminMembersTab.members;
  AdminMembersTab get activeTab => _activeTab;

  // Estados de Membros
  List<MemberDto> _members = [];
  List<MemberDto> _visibleMembers = [];
  Map<String, MemberDto> _membersById = {};
  List<MemberDto> get members => _members;

  int _visibleCount = pageSize;
  bool _isLoadingMore = false;
  bool _isDisposed = false;
  int _membersFetchSeq = 0;
  int _requestsFetchSeq = 0;
  Timer? _loadMoreTimer;
  Timer? _requestsDebounceTimer;

  int get visibleCount => _visibleCount;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreMembers => _visibleCount < _members.length;

  /// Membros visíveis pré-fatiados em O(1) para Infinite Scroll sem realocação por linha
  List<MemberDto> get visibleMembers => _visibleMembers;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  void _rebuildMemberIndices() {
    _membersById = {for (final m in _members) m.userId: m};
    _rebuildVisibleMembers();
  }

  void _rebuildVisibleMembers() {
    if (_visibleCount >= _members.length) {
      _visibleMembers = _members;
    } else {
      _visibleMembers = _members.sublist(0, _visibleCount);
    }
  }

  /// Carrega o próximo lote de membros de forma progressiva
  void loadMoreMembers() {
    if (_isDisposed || _isLoadingMore || !hasMoreMembers) return;
    _isLoadingMore = true;
    notifyListeners();

    _loadMoreTimer?.cancel();
    _loadMoreTimer = Timer(const Duration(milliseconds: 80), () {
      if (_isDisposed) return;
      _visibleCount = math.min(_visibleCount + pageSize, _members.length);
      _isLoadingMore = false;
      _rebuildVisibleMembers();
      notifyListeners();
    });
  }

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
  List<RecoveryRequestDto> _filteredRecoveryRequests = [];
  int _pendingRequestsCount = 0;
  List<RecoveryRequestDto> get recoveryRequests => _recoveryRequests;

  /// Solicitações PENDENTES pré-filtradas em O(1)
  List<RecoveryRequestDto> get filteredRecoveryRequests => _filteredRecoveryRequests;

  void _rebuildFilteredRequests() {
    final pendingOnly = _recoveryRequests.where((r) => r.isPending).toList();
    _pendingRequestsCount = pendingOnly.length;
    final query = requestsSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _filteredRecoveryRequests = pendingOnly;
      return;
    }
    _filteredRecoveryRequests = pendingOnly.where((r) {
      return r.displayName.toLowerCase().contains(query) ||
          r.email.toLowerCase().contains(query);
    }).toList();
  }

  /// Busca o membro correspondente em O(1) via índice em memória
  MemberDto? getMemberByUserId(String userId) => _membersById[userId];

  bool _isLoadingRequests = false;
  bool get isLoadingRequests => _isLoadingRequests;

  String? _requestsError;
  String? get requestsError => _requestsError;

  String? _processingUserId;
  String? get processingUserId => _processingUserId;

  String? _processingRequestId;
  String? get processingRequestId => _processingRequestId;

  // Quantidade de solicitações pendentes
  int get pendingRequestsCount => _pendingRequestsCount;

  AdminMembersController({AdminMembersTab initialTab = AdminMembersTab.members})
      : _activeTab = initialTab {
    requestsSearchController.addListener(_onRequestsSearchChanged);
  }

  void _onRequestsSearchChanged() {
    _requestsDebounceTimer?.cancel();
    _requestsDebounceTimer = Timer(const Duration(milliseconds: 180), () {
      if (_isDisposed) return;
      _rebuildFilteredRequests();
      notifyListeners();
    });
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
    final int seq = ++_membersFetchSeq;
    _loadMoreTimer?.cancel();
    _isLoadingMembers = true;
    _membersError = null;
    _visibleCount = pageSize;
    _isLoadingMore = false;
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
      if (_isDisposed || seq != _membersFetchSeq) return;

      final rawData = responseJson is List
          ? responseJson
          : (responseJson['data'] ?? responseJson['items'] ?? <dynamic>[]);

      final List<dynamic> listData = rawData is List ? rawData : <dynamic>[];

      _members = listData
          .map((item) => MemberDto.fromJson(item as Map<String, dynamic>))
          .toList();
      _rebuildMemberIndices();

      _isLoadingMembers = false;
      notifyListeners();
    } on ApiException catch (e) {
      if (_isDisposed || seq != _membersFetchSeq) return;
      _membersError = e.message;
      _isLoadingMembers = false;
      notifyListeners();
    } catch (_) {
      if (_isDisposed || seq != _membersFetchSeq) return;
      _membersError = 'Não foi possível carregar a lista de membros.';
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
      if (_isDisposed) return false;

      final updated = MemberDto.fromJson(responseJson);

      final index = _members.indexWhere((m) => m.userId == userId);
      if (index >= 0) {
        _members[index] = updated;
        _rebuildMemberIndices();
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
    final int seq = ++_requestsFetchSeq;
    _isLoadingRequests = true;
    _requestsError = null;
    notifyListeners();

    try {
      final responseJson = await ApiClient.get(
        ApiEndpoints.authRecoveryRequests,
        requiresAuth: true,
      );
      if (_isDisposed || seq != _requestsFetchSeq) return;

      final rawData = responseJson is List
          ? responseJson
          : (responseJson['data'] ?? responseJson['items'] ?? <dynamic>[]);

      final List<dynamic> listData = rawData is List ? rawData : <dynamic>[];

      _recoveryRequests = listData
          .map((item) => RecoveryRequestDto.fromJson(item as Map<String, dynamic>))
          .toList();
      _rebuildFilteredRequests();

      _isLoadingRequests = false;
      notifyListeners();
    } on ApiException catch (e) {
      if (_isDisposed || seq != _requestsFetchSeq) return;
      _requestsError = e.message;
      _isLoadingRequests = false;
      notifyListeners();
    } catch (_) {
      if (_isDisposed || seq != _requestsFetchSeq) return;
      _requestsError = 'Não foi possível carregar as solicitações.';
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
      if (_isDisposed) return false;

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
        _rebuildFilteredRequests();
      }

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
      if (_isDisposed) return false;

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
        _rebuildFilteredRequests();
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
    _isDisposed = true;
    _loadMoreTimer?.cancel();
    _requestsDebounceTimer?.cancel();
    requestsSearchController.removeListener(_onRequestsSearchChanged);
    searchController.dispose();
    requestsSearchController.dispose();
    _members = [];
    _visibleMembers = [];
    _membersById = {};
    _recoveryRequests = [];
    _filteredRecoveryRequests = [];
    super.dispose();
  }
}
