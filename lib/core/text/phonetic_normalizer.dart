/// Prepara texto em português para engines que possuem conversão grafema-
/// fonema própria, como o Sherpa-ONNX configurado com espeak-ng-data.
///
/// Esta camada deliberadamente não remove acentos nem troca grafemas por
/// aproximações fonéticas. Regras desse tipo só devem entrar acompanhadas de
/// um caso A/B, pois uma substituição que melhora uma palavra pode prejudicar
/// várias outras.
class PhoneticNormalizer {
  const PhoneticNormalizer._();

  static String prepare(String input) {
    return input
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
