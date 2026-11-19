import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../models/member_dto.dart';

/// Controller da Feature de Membros da Comunidade / Times.
/// Responsável pelo ciclo de vida da busca, gerenciamento de filtros de função e rank,
/// paginação em memória O(1) para Infinite Scroll e orquestração segura de requisições à API.
class MembersController extends ChangeNotifier {
  static const int pageSize = 18;

  final TextEditingController searchController = TextEditingController();

  List<MemberDto> _allMembers = [];
  List<MemberDto> _filteredMembers = [];
  MemberDto? _myMember;
  List<MemberDto> _otherMembers = [];
  List<MemberDto> _visibleOtherMembers = [];

  int _visibleCount = pageSize;
  bool _isLoadingMore = false;
  bool _isDisposed = false;
  Timer? _loadMoreTimer;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _visibleCount < _otherMembers.length;
  int get visibleCount => _visibleCount;

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

  /// Card do usuário autenticado atual (pré-computado O(1))
  MemberDto? get myMember => _myMember;

  /// Demais membros da comunidade (pré-computado O(1))
  List<MemberDto> get otherMembers => _otherMembers;

  /// Lista paginada para Infinite Scroll de alta performance (pré-computado O(1))
  List<MemberDto> get visibleOtherMembers => _visibleOtherMembers;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  /// Carrega o próximo lote no Infinite Scroll
  void loadMore() {
    if (_isDisposed || _isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    _loadMoreTimer?.cancel();
    _loadMoreTimer = Timer(const Duration(milliseconds: 80), () {
      if (_isDisposed) return;
      _visibleCount = math.min(_visibleCount + pageSize, _otherMembers.length);
      _isLoadingMore = false;
      _rebuildVisibleSlice();
      notifyListeners();
    });
  }

  MembersController() {
    _initCurrentUser();
  }

  Future<void> _initCurrentUser() async {
    final profile = await TokenStorage.getUserProfile();
    if (_isDisposed) return;
    if (_currentUserId != profile?.userId) {
      _currentUserId = profile?.userId;
      _rebuildDerivedPartitions();
      notifyListeners();
    }
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
      if (_isDisposed) return;

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
    } catch (_) {
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
    _loadMoreTimer?.cancel();
    _visibleCount = pageSize;
    _isLoadingMore = false;
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

    _rebuildDerivedPartitions();
  }

  void _rebuildDerivedPartitions() {
    MemberDto? me;
    final others = <MemberDto>[];

    for (final m in _filteredMembers) {
      if (_currentUserId != null && m.userId == _currentUserId && me == null) {
        me = m;
      } else {
        others.add(m);
      }
    }

    _myMember = me;
    _otherMembers = others;
    _rebuildVisibleSlice();
  }

  void _rebuildVisibleSlice() {
    if (_visibleCount >= _otherMembers.length) {
      _visibleOtherMembers = _otherMembers;
    } else {
      _visibleOtherMembers = _otherMembers.sublist(0, _visibleCount);
    }
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
    _isDisposed = true;
    _loadMoreTimer?.cancel();
    searchController.dispose();
    _allMembers = [];
    _filteredMembers = [];
    _otherMembers = [];
    _visibleOtherMembers = [];
    super.dispose();
  }
}
