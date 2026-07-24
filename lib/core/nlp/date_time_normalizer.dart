import 'number_to_words.dart';

/// Conversor de formatos de datas (DD/MM/AAAA) e horários (HH:MM) para extenso em PT-BR.
class DateTimeNormalizer {
  static const List<String> _meses = [
    '', 'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
  ];

  /// Expressão regular para datas nos formatos `DD/MM/AAAA` ou `DD/MM/AA`.
  static final RegExp _dateRegex = RegExp(
    r'\b(0?[1-9]|[12]\d|3[01])\/(0?[1-9]|1[02])\/(19\d{2}|20\d{2}|\d{2})\b',
  );

  /// Expressão regular para horários nos formatos `HH:MM` ou `HHhMM`.
  static final RegExp _timeRegex = RegExp(
    r'\b([01]?\d|2[0-3])[:hH]([0-5]\d)\b',
  );

  /// Converte todas as ocorrências de datas e horários em um texto para extensão em Português.
  static String normalize(String text) {
    // 1. Normalizar Horários primeiro
    String result = text.replaceAllMapped(_timeRegex, (match) {
      final int horas = int.parse(match.group(1)!);
      final int minutos = int.parse(match.group(2)!);

      final String termoHoras = (horas == 1) ? 'uma hora' : '${NumberToWords.cardinal(horas)} horas';

      if (minutos == 0) {
        return termoHoras;
      }

      final String termoMinutos = (minutos == 1) ? 'um minuto' : '${NumberToWords.cardinal(minutos)} minutos';
      return '$termoHoras e $termoMinutos';
    });

    // 2. Normalizar Datas
    result = result.replaceAllMapped(_dateRegex, (match) {
      final int dia = int.parse(match.group(1)!);
      final int mes = int.parse(match.group(2)!);
      int ano = int.parse(match.group(3)!);

      if (ano < 100) {
        ano += (ano >= 50) ? 1900 : 2000;
      }

      final String termoDia = (dia == 1) ? 'primeiro' : NumberToWords.cardinal(dia);
      final String termoMes = _meses[mes];
      final String termoAno = NumberToWords.cardinal(ano);

      return '$termoDia de $termoMes de $termoAno';
    });

    return result;
  }
}
