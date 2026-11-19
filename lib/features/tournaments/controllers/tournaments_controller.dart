import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/tournament_dto.dart';
import '../models/tournament_status.dart';

/// Controller oficial da tela de Torneios do Modo Jogador (SRP).
/// Gerencia listagem da API, busca textual debounced e filtros de Inscrição (Aberta/Fechada) e Fase.
class TournamentsController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  List<TournamentDto> _tournaments = [];
  List<TournamentDto> _filteredTournaments = [];
  List<TournamentDto> _openTournaments = [];
  List<TournamentDto> _closedTournaments = [];
  List<TournamentDto> get tournaments => _tournaments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Filtro de inscrição: null = Todas, true = Abertas, false = Fechadas
  bool? _selectedRegistrationOpen;
  bool? get selectedRegistrationOpen => _selectedRegistrationOpen;

  /// Filtro de fase/status do campeonato
  TournamentStatus? _selectedStatus;
  TournamentStatus? get selectedStatus => _selectedStatus;

  Timer? _debounceTimer;
  bool _isDisposed = false;
  int _fetchSeq = 0;

  TournamentsController() {
    searchController.addListener(_onSearchChanged);
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _tournaments = [];
    _filteredTournaments = [];
    _openTournaments = [];
    _closedTournaments = [];
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _rebuildFilteredLists();
      notifyListeners();
    });
  }

  void onSearchSubmitted(String _) {
    _debounceTimer?.cancel();
    _rebuildFilteredLists();
    notifyListeners();
  }

  bool get hasActiveFilters =>
      _selectedRegistrationOpen != null ||
      _selectedStatus != null ||
      searchController.text.trim().isNotEmpty;

  /// Lista de torneios pré-filtrada em O(1)
  List<TournamentDto> get filteredTournaments => _filteredTournaments;

  /// Torneios filtrados que estão com inscrições abertas (pré-computado O(1))
  List<TournamentDto> get openRegistrationTournaments => _openTournaments;

  /// Torneios filtrados que estão com inscrições fechadas (pré-computado O(1))
  List<TournamentDto> get closedRegistrationTournaments => _closedTournaments;

  void _rebuildFilteredLists() {
    final query = searchController.text.trim().toLowerCase();

    final filtered = _tournaments.where((t) {
      if (_selectedRegistrationOpen != null) {
        if (_selectedRegistrationOpen == true && !t.isRegistrationOpen) {
          return false;
        }
        if (_selectedRegistrationOpen == false && !t.isRegistrationClosed) {
          return false;
        }
      }

      if (_selectedStatus != null && t.status != _selectedStatus) {
        return false;
      }

      if (query.isEmpty) return true;
      return t.name.toLowerCase().contains(query) ||
          t.formatLabel.toLowerCase().contains(query) ||
          t.playoffFormatLabel.toLowerCase().contains(query) ||
          t.status.label.toLowerCase().contains(query) ||
          t.registrationStatusLabel.toLowerCase().contains(query) ||
          (t.championName?.toLowerCase().contains(query) ?? false);
    }).toList();

    filtered.sort((a, b) {
      if (a.isRegistrationOpen != b.isRegistrationOpen) {
        return a.isRegistrationOpen ? -1 : 1;
      }
      return b.createdAtUtc.compareTo(a.createdAtUtc);
    });

    final open = <TournamentDto>[];
    final closed = <TournamentDto>[];
    for (final t in filtered) {
      if (t.isRegistrationOpen) {
        open.add(t);
      } else if (t.isRegistrationClosed) {
        closed.add(t);
      }
    }

    _filteredTournaments = filtered;
    _openTournaments = open;
    _closedTournaments = closed;
  }

  /// Carrega todos os campeonatos da arena via GET /api/v1/tournaments
  Future<void> fetchTournaments() async {
    final int seq = ++_fetchSeq;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = ApiEndpoints.tournaments(
        status: _selectedStatus?.value.toString(),
      );
      final responseJson = await ApiClient.get(url, requiresAuth: true);
      if (_isDisposed || seq != _fetchSeq) return;

      final rawData = responseJson['data'] ?? responseJson['items'] ?? responseJson;
      final List<dynamic> listData = rawData is List ? rawData : <dynamic>[];

      _tournaments = listData
          .map((item) => TournamentDto.fromJson(item as Map<String, dynamic>))
          .where((t) => t.status != TournamentStatus.draft)
          .toList();
      _rebuildFilteredLists();
    } on ApiException catch (e) {
      if (_isDisposed || seq != _fetchSeq) return;
      _errorMessage = e.message;
    } catch (_) {
      if (_isDisposed || seq != _fetchSeq) return;
      _errorMessage = 'Não foi possível carregar os campeonatos da arena.';
    } finally {
      if (!_isDisposed && seq == _fetchSeq) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Define o filtro de status de inscrição (Aberta = true, Fechada = false, Todas = null)
  void setRegistrationFilter(bool? isOpen) {
    if (_selectedRegistrationOpen != isOpen) {
      _selectedRegistrationOpen = isOpen;
      _rebuildFilteredLists();
      notifyListeners();
    }
  }

  /// Define o filtro de fase/status do campeonato
  void setStatusFilter(TournamentStatus? status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      _rebuildFilteredLists();
      notifyListeners();
      fetchTournaments();
    }
  }

  /// Limpa todos os filtros e busca
  void clearFilters() {
    final hadServerStatusFilter = _selectedStatus != null;
    searchController.clear();
    _selectedRegistrationOpen = null;
    _selectedStatus = null;
    _rebuildFilteredLists();
    notifyListeners();
    if (hadServerStatusFilter) {
      fetchTournaments();
    }
  }
}

