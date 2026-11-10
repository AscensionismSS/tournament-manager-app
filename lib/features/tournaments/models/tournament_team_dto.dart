/// DTO de equipe inscrita em um torneio (Tournaments.Contracts/Tournaments/TournamentTeamDto).
class TournamentTeamDto {
  final String id;
  final String name;

  const TournamentTeamDto({
    required this.id,
    required this.name,
  });

  factory TournamentTeamDto.fromJson(Map<String, dynamic> json) {
    return TournamentTeamDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Equipe',
    );
  }
}
