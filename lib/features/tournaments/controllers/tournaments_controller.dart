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
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      notifyListeners();
    });
  }

  void onSearchSubmitted(String _) {
    _debounceTimer?.cancel();
    notifyListeners();
  }

  bool get hasActiveFilters =>
      _selectedRegistrationOpen != null ||
      _selectedStatus != null ||
      searchController.text.trim().isNotEmpty;

  /// Lista de torneios filtrada por busca, status de inscrição (aberta/fechada) e fase
  List<TournamentDto> get filteredTournaments {
    final query = searchController.text.trim().toLowerCase();

    final filtered = _tournaments.where((t) {
      // 1. Filtro de Inscrição Aberta / Fechada
      if (_selectedRegistrationOpen != null) {
        if (_selectedRegistrationOpen == true && !t.isRegistrationOpen) {
          return false;
        }
        if (_selectedRegistrationOpen == false && !t.isRegistrationClosed) {
          return false;
        }
      }

      // 2. Filtro de Fase / Status específico
      if (_selectedStatus != null && t.status != _selectedStatus) {
        return false;
      }

      // 3. Busca textual
      if (query.isEmpty) return true;
      return t.name.toLowerCase().contains(query) ||
          t.formatLabel.toLowerCase().contains(query) ||
          t.playoffFormatLabel.toLowerCase().contains(query) ||
          t.status.label.toLowerCase().contains(query) ||
          t.registrationStatusLabel.toLowerCase().contains(query) ||
          (t.championName?.toLowerCase().contains(query) ?? false);
    }).toList();

    // Ordena priorizando campeonatos com inscrições abertas e mais recentes
    filtered.sort((a, b) {
      if (a.isRegistrationOpen != b.isRegistrationOpen) {
        return a.isRegistrationOpen ? -1 : 1;
      }
      return b.createdAtUtc.compareTo(a.createdAtUtc);
    });

    return filtered;
  }

  /// Torneios filtrados que estão com inscrições abertas
  List<TournamentDto> get openRegistrationTournaments =>
      filteredTournaments.where((t) => t.isRegistrationOpen).toList();

  /// Torneios filtrados que estão com inscrições fechadas (em andamento ou concluídos)
  List<TournamentDto> get closedRegistrationTournaments =>
      filteredTournaments.where((t) => t.isRegistrationClosed).toList();

  /// Carrega todos os campeonatos da arena via GET /api/v1/tournaments
  Future<void> fetchTournaments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = ApiEndpoints.tournaments(
        status: _selectedStatus?.value.toString(),
      );
      final responseJson = await ApiClient.get(url, requiresAuth: true);

      final rawData = responseJson['data'] ?? responseJson['items'] ?? responseJson;
      final List<dynamic> listData = rawData is List ? rawData : <dynamic>[];

      _tournaments = listData
          .map((item) => TournamentDto.fromJson(item as Map<String, dynamic>))
          .where((t) => t.status != TournamentStatus.draft)
          .toList();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Não foi possível carregar os campeonatos da arena: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Define o filtro de status de inscrição (Aberta = true, Fechada = false, Todas = null)
  void setRegistrationFilter(bool? isOpen) {
    if (_selectedRegistrationOpen != isOpen) {
      _selectedRegistrationOpen = isOpen;
      notifyListeners();
    }
  }

  /// Define o filtro de fase/status do campeonato
  void setStatusFilter(TournamentStatus? status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
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
    notifyListeners();
    if (hadServerStatusFilter) {
      fetchTournaments();
    }
  }
}

