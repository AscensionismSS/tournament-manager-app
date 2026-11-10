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

/// Controller responsável pelo estado, busca, filtros e ações da gestão de convites.
class InvitationsController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  List<InvitationDto> _allInvitations = [];
  List<InvitationDto> _filteredInvitations = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCreating = false;
  bool get isCreating => _isCreating;

  String? _revokingId;
  String? get revokingId => _revokingId;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  InvitationFilterTab _currentTab = InvitationFilterTab.all;
  InvitationFilterTab get currentTab => _currentTab;

  List<InvitationDto> get invitations => _filteredInvitations;
  int get totalCount => _allInvitations.length;

  int get activeCount =>
      _allInvitations.where((i) => i.status == InvitationStatus.pending).length;

  int get usedCount =>
      _allInvitations.where((i) => i.status == InvitationStatus.used).length;

  int get revokedCount =>
      _allInvitations.where((i) => i.status == InvitationStatus.revoked).length;

  int get expiredCount =>
      _allInvitations.where((i) => i.status == InvitationStatus.expired).length;

  InvitationsController() {
    searchController.addListener(_onSearchChanged);
  }

  /// Carrega a lista completa de convites a partir do endpoint GET /api/v1/invitations
  Future<void> fetchInvitations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final responseJson = await ApiClient.get(
        ApiEndpoints.invitations,
        requiresAuth: true,
      );

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
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Falha inesperada ao carregar convites: $e';
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
    _applyFilters();
    notifyListeners();
  }

  bool get hasActiveFilters =>
      _currentTab != InvitationFilterTab.all || searchController.text.trim().isNotEmpty;

  void clearSearch() {
    searchController.clear();
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    searchController.clear();
    _currentTab = InvitationFilterTab.all;
    _applyFilters();
    notifyListeners();
  }

  /// Aplica a busca textual e o filtro de status selecionado
  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    _filteredInvitations = _allInvitations.where((invite) {
      // 1. Filtro por Aba de Status
      switch (_currentTab) {
        case InvitationFilterTab.all:
          break;
        case InvitationFilterTab.active:
          if (invite.status != InvitationStatus.pending) return false;
          break;
        case InvitationFilterTab.used:
          if (invite.status != InvitationStatus.used) return false;
          break;
        case InvitationFilterTab.revoked:
          if (invite.status != InvitationStatus.revoked) return false;
          break;
        case InvitationFilterTab.expired:
          if (invite.status != InvitationStatus.expired) return false;
          break;
      }

      // 2. Filtro textual por Email, Código ou Papel
      if (query.isNotEmpty) {
        final emailMatch = invite.email.toLowerCase().contains(query);
        final codeMatch = invite.code.toLowerCase().contains(query);
        final roleMatch = invite.targetRole.toLowerCase().contains(query);

        if (!emailMatch && !codeMatch && !roleMatch) {
          return false;
        }
      }

      return true;
    }).toList();
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

      final created = InvitationDto.fromJson(responseJson);

      // Atualiza lista local ou insere no topo
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
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }
}
