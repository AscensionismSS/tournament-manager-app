import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/create_invitation_request.dart';
import '../models/invitation_dto.dart';

/// Tipos de filtro para a listagem de convites
enum InvitationFilterTab {
  all('Todos'),
  active('Ativos'),
  used('Usados'),
  revoked('Revogados'),
  expired('Expirados');

  final String label;
  const InvitationFilterTab(this.label);
}

/// Controller responsável pelo estado, busca, filtros, paginação progressiva e ações da gestão de convites.
class InvitationsController extends ChangeNotifier {
  static const int pageSize = 20;

  final TextEditingController searchController = TextEditingController();

  List<InvitationDto> _allInvitations = [];
  List<InvitationDto> _filteredInvitations = [];
  List<InvitationDto> _visibleInvitations = [];

  int _visibleCount = pageSize;
  bool _isLoadingMore = false;
  bool _isDisposed = false;
  int _fetchSeq = 0;
  Timer? _loadMoreTimer;
  Timer? _searchDebounceTimer;

  int _activeCount = 0;
  int _usedCount = 0;
  int _revokedCount = 0;
  int _expiredCount = 0;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _visibleCount < _filteredInvitations.length;
  int get visibleCount => _visibleCount;

  bool _isCreating = false;
  bool get isCreating => _isCreating;

  String? _revokingId;
  String? get revokingId => _revokingId;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  InvitationFilterTab _currentTab = InvitationFilterTab.all;
  InvitationFilterTab get currentTab => _currentTab;

  List<InvitationDto> get invitations => _filteredInvitations;
  List<InvitationDto> get visibleInvitations => _visibleInvitations;
  int get totalCount => _allInvitations.length;

  int get activeCount => _activeCount;
  int get usedCount => _usedCount;
  int get revokedCount => _revokedCount;
  int get expiredCount => _expiredCount;

  InvitationsController() {
    searchController.addListener(_onSearchChanged);
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  void loadMore() {
    if (_isDisposed || _isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    _loadMoreTimer?.cancel();
    _loadMoreTimer = Timer(const Duration(milliseconds: 80), () {
      if (_isDisposed) return;
      _visibleCount = math.min(_visibleCount + pageSize, _filteredInvitations.length);
      _isLoadingMore = false;
      _rebuildVisibleSlice();
      notifyListeners();
    });
  }

  /// Carrega a lista completa de convites a partir do endpoint GET /api/v1/invitations
  Future<void> fetchInvitations() async {
    final int seq = ++_fetchSeq;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final responseJson = await ApiClient.get(
        ApiEndpoints.invitations,
        requiresAuth: true,
      );
      if (_isDisposed || seq != _fetchSeq) return;

      final rawData = responseJson is List
          ? responseJson
          : (responseJson['data'] ?? responseJson['items'] ?? <dynamic>[]);

      final List<dynamic> listData = rawData is List ? rawData : <dynamic>[];

      _allInvitations = listData
          .map((item) => InvitationDto.fromJson(item as Map<String, dynamic>))
          .toList();

      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      if (_isDisposed || seq != _fetchSeq) return;
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      if (_isDisposed || seq != _fetchSeq) return;
      _errorMessage = 'Falha inesperada ao carregar convites.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Altera o filtro ativo (Todos, Ativos, Usados, Revogados, Expirados)
  void setFilterTab(InvitationFilterTab tab) {
    if (_currentTab != tab) {
      _currentTab = tab;
      _applyFilters();
      notifyListeners();
    }
  }

  void _onSearchChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 180), () {
      if (_isDisposed) return;
      _applyFilters();
      notifyListeners();
    });
  }

  bool get hasActiveFilters =>
      _currentTab != InvitationFilterTab.all || searchController.text.trim().isNotEmpty;

  void clearSearch() {
    _searchDebounceTimer?.cancel();
    searchController.clear();
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchDebounceTimer?.cancel();
    searchController.clear();
    _currentTab = InvitationFilterTab.all;
    _applyFilters();
    notifyListeners();
  }

  /// Aplica a busca textual, filtro de status e atualiza contadores em uma única passagem O(N)
  void _applyFilters() {
    _loadMoreTimer?.cancel();
    _visibleCount = pageSize;
    _isLoadingMore = false;

    int pending = 0;
    int used = 0;
    int revoked = 0;
    int expired = 0;

    final query = searchController.text.trim().toLowerCase();
    final filtered = <InvitationDto>[];

    for (final invite in _allInvitations) {
      final st = invite.status;
      switch (st) {
        case InvitationStatus.pending:
          pending++;
          break;
        case InvitationStatus.used:
          used++;
          break;
        case InvitationStatus.revoked:
          revoked++;
          break;
        case InvitationStatus.expired:
          expired++;
          break;
      }

      // 1. Filtro por Aba de Status
      bool tabMatch = true;
      switch (_currentTab) {
        case InvitationFilterTab.all:
          break;
        case InvitationFilterTab.active:
          tabMatch = st == InvitationStatus.pending;
          break;
        case InvitationFilterTab.used:
          tabMatch = st == InvitationStatus.used;
          break;
        case InvitationFilterTab.revoked:
          tabMatch = st == InvitationStatus.revoked;
          break;
        case InvitationFilterTab.expired:
          tabMatch = st == InvitationStatus.expired;
          break;
      }
      if (!tabMatch) continue;

      // 2. Filtro textual por Email, Código ou Papel
      if (query.isNotEmpty) {
        final emailMatch = invite.email.toLowerCase().contains(query);
        final codeMatch = invite.code.toLowerCase().contains(query);
        final roleMatch = invite.targetRole.toLowerCase().contains(query);
        if (!emailMatch && !codeMatch && !roleMatch) continue;
      }

      filtered.add(invite);
    }

    _activeCount = pending;
    _usedCount = used;
    _revokedCount = revoked;
    _expiredCount = expired;
    _filteredInvitations = filtered;
    _rebuildVisibleSlice();
  }

  void _rebuildVisibleSlice() {
    if (_visibleCount >= _filteredInvitations.length) {
      _visibleInvitations = _filteredInvitations;
    } else {
      _visibleInvitations = _filteredInvitations.sublist(0, _visibleCount);
    }
  }

  /// Opções canônicas de expiração permitidas pelo backend (24, 48 ou 72 horas)
  static const List<int> allowedExpirationHours = [24, 48, 72];

  /// Obtém opções de expiração suportadas pelo backend (GET /api/v1/invitations/expiration-options)
  Future<List<int>> fetchExpirationOptions() async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.invitationExpirationOptions,
        requiresAuth: true,
      );
      final rawList = response['data'] ?? response['options'];
      if (rawList is List) {
        return rawList
            .map((e) => int.tryParse(e.toString()))
            .whereType<int>()
            .toList();
      }
    } catch (_) {
      // Fallback seguro para as opções canônicas caso o endpoint esteja indisponível
    }
    return allowedExpirationHours;
  }

  /// Cria um novo convite via POST /api/v1/invitations
  Future<InvitationDto?> createInvitation({
    required String email,
    required int targetRoleIndex,
    int validHours = 24,
  }) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = CreateInvitationRequest(
        email: email,
        targetRole: targetRoleIndex,
        validHours: validHours,
      );

      final responseJson = await ApiClient.post(
        ApiEndpoints.invitations,
        body: request.toJson(),
        requiresAuth: true,
      );
      if (_isDisposed) return null;

      final created = InvitationDto.fromJson(responseJson);

      final existingIndex = _allInvitations.indexWhere((i) => i.id == created.id);
      if (existingIndex >= 0) {
        _allInvitations[existingIndex] = created;
      } else {
        _allInvitations.insert(0, created);
      }

      _applyFilters();
      _isCreating = false;
      notifyListeners();
      return created;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isCreating = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Falha inesperada ao emitir convite: $e';
      _isCreating = false;
      notifyListeners();
      return null;
    }
  }

  /// Desativa/revoga um convite pendente via POST /api/v1/invitations/{id}/revoke
  Future<bool> revokeInvitation(String id) async {
    _revokingId = id;
    notifyListeners();

    try {
      final responseJson = await ApiClient.post(
        ApiEndpoints.invitationRevoke(id),
        requiresAuth: true,
      );
      if (_isDisposed) return false;

      final updated = InvitationDto.fromJson(responseJson);

      final index = _allInvitations.indexWhere((i) => i.id == id);
      if (index >= 0) {
        _allInvitations[index] = updated;
      } else {
        await fetchInvitations();
      }

      _applyFilters();
      _revokingId = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _revokingId = null;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Falha ao revogar convite: $e';
      _revokingId = null;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadMoreTimer?.cancel();
    _searchDebounceTimer?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _allInvitations = [];
    _filteredInvitations = [];
    _visibleInvitations = [];
    super.dispose();
  }
}
