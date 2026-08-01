import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/text/phonetic_normalizer.dart';

void main() {
  test('preserva cedilha, acentos e grafemas portugueses', () {
    const input = 'Ação, coração, desacopladas, execução e síntese.';

    expect(PhoneticNormalizer.prepare(input), equals(input));
  });

  test('remove apenas controles invisíveis e normaliza espaços', () {
    expect(
      PhoneticNormalizer.prepare(' ação\u00A0  e\u200B  órgão '),
      equals('ação e órgão'),
    );
  });
}
