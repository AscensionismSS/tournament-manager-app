import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/system_security_service.dart';
import '../../../tournaments/models/tournament_dto.dart';
import '../../../tournaments/models/tournament_status.dart';
import '../models/create_tournament_request.dart';
import '../models/tournament_options_dto.dart';

/// Controller oficial responsável pelo estado, filtros, busca e criação de torneios
/// no Painel Administrativo Tsurus Plus+.
class AdminTournamentsController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  List<TournamentDto> _tournaments = [];
  List<TournamentDto> get tournaments => _tournaments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  TournamentStatus? _selectedStatus;
  TournamentStatus? get selectedStatus => _selectedStatus;

  bool? _selectedRegistrationOpen;
  bool? get selectedRegistrationOpen => _selectedRegistrationOpen;

  bool _isCreating = false;
  bool get isCreating => _isCreating;

  Timer? _debounceTimer;
  bool _isDisposed = false;

  AdminTournamentsController() {
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
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      notifyListeners();
    });
  }

  bool get hasActiveFilters =>
      _selectedRegistrationOpen != null ||
      _selectedStatus != null ||
      searchController.text.trim().isNotEmpty;

  /// Retorna os torneios filtrados por texto da busca, inscrição e pelo status selecionado
  List<TournamentDto> get filteredTournaments {
    final query = searchController.text.trim().toLowerCase();
    return _tournaments.where((t) {
      if (_selectedRegistrationOpen != null) {
        if (_selectedRegistrationOpen == true && !t.isRegistrationOpen) return false;
        if (_selectedRegistrationOpen == false && !t.isRegistrationClosed) return false;
      }

      final matchesStatus = _selectedStatus == null || t.status == _selectedStatus;
      if (!matchesStatus) return false;

      if (query.isEmpty) return true;
      return t.name.toLowerCase().contains(query) ||
          t.formatLabel.toLowerCase().contains(query) ||
          t.registrationStatusLabel.toLowerCase().contains(query) ||
          (t.championName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Busca a lista de torneios da API
  Future<void> fetchTournaments() async {
    _isLoading = true;
    _error = null;
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
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Não foi possível carregar a lista de campeonatos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atualiza o filtro de inscrição aberta/fechada
  void setRegistrationFilter(bool? isOpen) {
    if (_selectedRegistrationOpen != isOpen) {
      _selectedRegistrationOpen = isOpen;
      notifyListeners();
    }
  }

  /// Atualiza o filtro de status selecionado
  void setStatusFilter(TournamentStatus? status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      notifyListeners();
      fetchTournaments();
    }
  }

  /// Limpa busca e filtros ativos
  void clearFilters() {
    searchController.clear();
    _selectedRegistrationOpen = null;
    _selectedStatus = null;
    notifyListeners();
    fetchTournaments();
  }

  /// Consulta opções de formatos válidas no backend (GET /api/v1/tournaments/options?teamCount=X)
  Future<TournamentConfigurationOptionsDto?> fetchFormatOptions(int teamCount) async {
    try {
      final url = ApiEndpoints.tournamentOptions(teamCount: teamCount);
      final responseJson = await ApiClient.get(url, requiresAuth: false);
      return TournamentConfigurationOptionsDto.fromJson(responseJson);
    } catch (_) {
      return null;
    }
  }

  /// Envia payload de criação de torneio para o backend
  Future<bool> createTournament(CreateTournamentRequest request) async {
    if (SystemSecurityService.instance.isTournamentCreationLocked) {
      return false;
    }

    _isCreating = true;
    notifyListeners();

    try {
      await ApiClient.post(
        ApiEndpoints.tournaments(),
        body: request.toJson(),
        requiresAuth: true,
      );
      await fetchTournaments();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  /// Realiza o upload do banner do campeonato para o backend
  Future<String?> uploadTournamentBanner(List<int> bytes, String fileName) async {
    final response = await ApiClient.uploadMultipart(
      ApiEndpoints.tournamentUploadBanner,
      fileField: 'file',
      fileBytes: bytes,
      fileName: fileName,
      requiresAuth: true,
    );

    final url = response['bannerUrl'] ?? response['url'] ?? response['path'] ?? response['data'];
    if (url is String && url.isNotEmpty) {
      return url;
    }
    return null;
  }
}
