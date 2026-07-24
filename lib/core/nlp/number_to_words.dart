/// Conversor puramente funcional de numerais cardinais e ordinais para grafia por extenso em PT-BR.
class NumberToWords {
  static const List<String> _unidades = [
    'zero', 'um', 'dois', 'três', 'quatro', 'cinco', 'seis', 'sete', 'oito', 'nove',
    'dez', 'onze', 'doze', 'treze', 'quatorze', 'quinze', 'dezesseis', 'dezessete', 'dezoito', 'dezenove'
  ];

  static const List<String> _dezenas = [
    '', '', 'vinte', 'trinta', 'quarenta', 'cinquenta', 'sessenta', 'setenta', 'oitenta', 'noventa'
  ];

  static const List<String> _centenas = [
    '', 'cento', 'duzentos', 'trezentos', 'quatrocentos', 'quinhentos',
    'seiscentos', 'setecentos', 'oitocentos', 'novecentos'
  ];

  static const List<String> _ordinaisUnidadesMasc = [
    '', 'primeiro', 'segundo', 'terceiro', 'quarto', 'quinto', 'sexto', 'sétimo', 'oitavo', 'nono'
  ];

  static const List<String> _ordinaisUnidadesFem = [
    '', 'primeira', 'segunda', 'terceira', 'quarta', 'quinta', 'sexta', 'sétima', 'oitava', 'nona'
  ];

  static const List<String> _ordinaisDezenasMasc = [
    '', 'décimo', 'vigésimo', 'trigésimo', 'quadragésimo', 'quinquagésimo',
    'sexagésimo', 'septuagésimo', 'octogésimo', 'nonagésimo'
  ];

  static const List<String> _ordinaisDezenasFem = [
    '', 'décima', 'vigésima', 'trigésima', 'quadragésima', 'quinquagésima',
    'sexagésima', 'septuagésima', 'octogésima', 'nonagésima'
  ];

  static const List<String> _ordinaisCentenasMasc = [
    '', 'centésimo', 'ducentésimo', 'trecentésimo', 'quadringentésimo', 'quingentésimo',
    'seiscentésimo', 'septingentésimo', 'octingentésimo', 'nongentésimo'
  ];

  static const List<String> _ordinaisCentenasFem = [
    '', 'centésima', 'ducentésima', 'trecentésima', 'quadringentésima', 'quingentésima',
    'seiscentésima', 'septingentésima', 'octingentésima', 'nongentésima'
  ];

  /// Converte um número inteiro cardinal [number] para sua grafia por extenso.
  static String cardinal(int number) {
    if (number < 0) return 'menos ${cardinal(-number)}';
    if (number < 20) return _unidades[number];
    if (number == 100) return 'cem';

    if (number < 100) {
      final int dez = number ~/ 10;
      final int rest = number % 10;
      return rest == 0 ? _dezenas[dez] : '${_dezenas[dez]} e ${_unidades[rest]}';
    }

    if (number < 1000) {
      final int cent = number ~/ 100;
      final int rest = number % 100;
      return rest == 0 ? _centenas[cent] : '${_centenas[cent]} e ${cardinal(rest)}';
    }

    if (number < 1000000) {
      final int mil = number ~/ 1000;
      final int rest = number % 1000;
      final String prefix = (mil == 1) ? 'mil' : '${cardinal(mil)} mil';
      
      if (rest == 0) return prefix;
      if (rest < 100 || rest % 100 == 0) return '$prefix e ${cardinal(rest)}';
      return '$prefix ${cardinal(rest)}';
    }

    if (number < 1000000000) {
      final int milhao = number ~/ 1000000;
      final int rest = number % 1000000;
      final String prefix = (milhao == 1) ? 'um milhão' : '${cardinal(milhao)} milhões';

      if (rest == 0) return prefix;
      if (rest < 100 || rest % 100 == 0) return '$prefix e ${cardinal(rest)}';
      return '$prefix ${cardinal(rest)}';
    }

    return number.toString();
  }

  /// Converte um número ordinal (ex: `1` para `1º` ou `1ª`) para o extenso correspondente.
  static String ordinal(int number, {bool isFeminine = false}) {
    if (number <= 0 || number >= 1000) return number.toString();

    final List<String> u = isFeminine ? _ordinaisUnidadesFem : _ordinaisUnidadesMasc;
    final List<String> d = isFeminine ? _ordinaisDezenasFem : _ordinaisDezenasMasc;
    final List<String> c = isFeminine ? _ordinaisCentenasFem : _ordinaisCentenasMasc;

    final List<String> parts = [];

    final int cent = number ~/ 100;
    final int restCent = number % 100;
    if (cent > 0) parts.add(c[cent]);

    final int dez = restCent ~/ 10;
    final int uni = restCent % 10;
    if (dez > 0) parts.add(d[dez]);
    if (uni > 0) parts.add(u[uni]);

    return parts.join(' ');
  }

  /// Expressão regular para identificar numerais ordinais como "1º", "2ª", "10º".
  static final RegExp _ordinalRegex = RegExp(r'(\b\d+)([ºª])');

  /// Expressão regular para números isolados em um texto.
  static final RegExp _cardinalRegex = RegExp(r'\b\d+\b');

  /// Substitui ordinais em uma string pelo extenso.
  static String replaceOrdinalsInText(String text) {
    return text.replaceAllMapped(_ordinalRegex, (match) {
      final int val = int.tryParse(match.group(1)!) ?? 0;
      final bool isFem = match.group(2) == 'ª';
      return ordinal(val, isFeminine: isFem);
    });
  }

  /// Substitui cardinais inteiros em uma string pelo extenso.
  static String replaceCardinalsInText(String text) {
    return text.replaceAllMapped(_cardinalRegex, (match) {
      final int val = int.tryParse(match.group(0)!) ?? 0;
      return cardinal(val);
    });
  }
}
