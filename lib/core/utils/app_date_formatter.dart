import 'package:intl/intl.dart';

/// Utilitário centralizado de datas da aplicação utilizando o pacote oficial `intl`.
/// Elimina parsing manual redundante, previne erros de nulo e padroniza a conversão
/// para o horário local do usuário.
class AppDateFormatter {
  AppDateFormatter._();

  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// Converte com segurança qualquer tipo dinâmico retornado pela API (String, DateTime ou null)
  /// para [DateTime]. Retorna [fallback] se o valor for nulo ou inválido.
  static DateTime? tryParse(dynamic value, {DateTime? fallback}) {
    if (value == null) return fallback;
    if (value is DateTime) return value;
    final str = value.toString().trim();
    if (str.isEmpty) return fallback;
    return DateTime.tryParse(str) ?? fallback;
  }

  /// Formata como "26/10/2026 11:40". Se [dateTime] for nulo, retorna [placeholder].
  static String formatDateTime(DateTime? dateTime, {String placeholder = '-'}) {
    if (dateTime == null) return placeholder;
    return _dateTimeFormat.format(dateTime.toLocal());
  }

  /// Formata como "26/10/2026". Se [dateTime] for nulo, retorna [placeholder].
  static String formatDate(DateTime? dateTime, {String placeholder = '-'}) {
    if (dateTime == null) return placeholder;
    return _dateFormat.format(dateTime.toLocal());
  }

  /// Formata como "11:40". Se [dateTime] for nulo, retorna [placeholder].
  static String formatTime(DateTime? dateTime, {String placeholder = '-'}) {
    if (dateTime == null) return placeholder;
    return _timeFormat.format(dateTime.toLocal());
  }

  /// Formata de forma relativa e amigável (ex: "Agora", "há 15 min", "há 2 horas", "Ontem às 14:00")
  static String formatRelative(DateTime? dateTime, {String placeholder = '-'}) {
    if (dateTime == null) return placeholder;
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final difference = now.difference(local);

    if (difference.isNegative) {
      return formatDateTime(local);
    }

    if (difference.inSeconds < 60) {
      return 'Agora há pouco';
    } else if (difference.inMinutes < 60) {
      final min = difference.inMinutes;
      return 'há $min ${min == 1 ? 'minuto' : 'minutos'}';
    } else if (difference.inHours < 24 && local.day == now.day) {
      final hours = difference.inHours;
      return 'há $hours ${hours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inDays == 1 || (difference.inDays == 0 && local.day != now.day)) {
      return 'Ontem às ${formatTime(local)}';
    }

    return formatDate(local);
  }
}
