import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../models/member_dto.dart';

/// Controller da Feature de Membros da Comunidade / Times.
/// Responsável pelo ciclo de vida da busca, gerenciamento de filtros de função e rank,
/// e orquestração de requisições à API.
class MembersController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  List<MemberDto> _allMembers = [];
  List<MemberDto> _filteredMembers = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _selectedRole;
  String? get selectedRole => _selectedRole;

  int? _selectedRankTier;
  int? get selectedRankTier => _selectedRankTier;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  List<MemberDto> get members => _filteredMembers;
  int get totalCount => _allMembers.length;
  int get filteredCount => _filteredMembers.length;

  /// Card do usuário autenticado atual (se presente nos resultados filtrados)
  MemberDto? get myMember {
    if (_currentUserId == null) return null;
    for (final m in _filteredMembers) {
      if (m.userId == _currentUserId) return m;
    }
    return null;
  }

  /// Demais membros da comunidade (excluindo o usuário autenticado)
  List<MemberDto> get otherMembers {
    if (_currentUserId == null) return _filteredMembers;
    return _filteredMembers.where((m) => m.userId != _currentUserId).toList();
  }

  MembersController() {
    _initCurrentUser();
  }

  Future<void> _initCurrentUser() async {
    final profile = await TokenStorage.getUserProfile();
    _currentUserId = profile?.userId;
    notifyListeners();
  }

  /// Carrega a lista completa de membros a partir do endpoint GET /api/v1/users
  Future<void> fetchMembers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final responseJson = await ApiClient.get(
        ApiEndpoints.usersList,
        requiresAuth: true,
      );

      final rawData = responseJson['data'] ?? responseJson['items'] ?? responseJson['users'];
      final List<dynamic> listData = rawData is List ? rawData : [];

      _allMembers = listData
          .map((item) => MemberDto.fromJson(item as Map<String, dynamic>))
          .toList();

      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Falha inesperada ao carregar membros da arena.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Indica se há algum filtro de busca, função ou medalha ativo
  bool get hasActiveFilters =>
      searchController.text.trim().isNotEmpty ||
      _selectedRole != null ||
      _selectedRankTier != null;

  /// Atualiza o texto de busca (acionado com debounce pelo AppSearchBar)
  void onSearchChanged(String query) {
    _applyFilters();
    notifyListeners();
  }

  /// Filtro por Função / Posição Dota 2 (Pos 1 a Pos 5)
  void setRoleFilter(String? role) {
    _selectedRole = role;
    _applyFilters();
    notifyListeners();
  }

  /// Filtro por Medalha / Tier Dota 2 (1: Herald .. 8: Immortal)
  void setRankTierFilter(int? tier) {
    _selectedRankTier = tier;
    _applyFilters();
    notifyListeners();
  }

  /// Limpa todos os filtros ativos
  void clearFilters() {
    searchController.clear();
    _selectedRole = null;
    _selectedRankTier = null;
    _applyFilters();
    notifyListeners();
  }

  /// Aplicação combinada de todos os filtros de busca
  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    _filteredMembers = _allMembers.where((member) {
      // 1. Filtro textual por Nome, Nickname Steam, SteamID ou Friend ID
      if (query.isNotEmpty) {
        final nameMatch = member.displayName.toLowerCase().contains(query);
        final personaMatch =
            (member.personaName ?? '').toLowerCase().contains(query);
        final steamMatch = (member.steamId ?? '').toLowerCase().contains(query);
        final friendMatch =
            (member.dotaFriendId ?? '').toLowerCase().contains(query);

        if (!nameMatch && !personaMatch && !steamMatch && !friendMatch) {
          return false;
        }
      }

      // 2. Filtro por Função / Posição Dota (Carry, Mid, Offlane, Soft Sup, Hard Sup)
      if (_selectedRole != null) {
        final target = _selectedRole!.toLowerCase();
        final matchesRoleList = member.roles.any((r) =>
            r.toLowerCase().contains(target) ||
            _roleAliasMatch(r.toLowerCase(), target));
        final matchesPreferred = member.preferredRole != null &&
            (member.preferredRole!.toLowerCase().contains(target) ||
                _roleAliasMatch(member.preferredRole!.toLowerCase(), target));

        if (!matchesRoleList && !matchesPreferred) {
          return false;
        }
      }

      // 3. Filtro por Tier de Rank (1..8)
      if (_selectedRankTier != null) {
        if (_selectedRankTier == 0) {
          if (member.tierNumber != 0) return false;
        } else {
          if (member.tierNumber != _selectedRankTier) return false;
        }
      }

      return true;
    }).toList();
  }

  /// Mapeador auxiliar de sinônimos de posições
  bool _roleAliasMatch(String current, String target) {
    if (target.contains('pos 1') || target.contains('carry')) {
      return current.contains('pos 1') || current.contains('pos1') || current.contains('carry');
    }
    if (target.contains('pos 2') || target.contains('mid')) {
      return current.contains('pos 2') || current.contains('pos2') || current.contains('mid');
    }
    if (target.contains('pos 3') || target.contains('offlane')) {
      return current.contains('pos 3') || current.contains('pos3') || current.contains('offlane');
    }
    if (target.contains('pos 4') || target.contains('soft')) {
      return current.contains('pos 4') || current.contains('pos4') || current.contains('soft');
    }
    if (target.contains('pos 5') || target.contains('hard')) {
      return current.contains('pos 5') || current.contains('pos5') || current.contains('hard');
    }
    return false;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
