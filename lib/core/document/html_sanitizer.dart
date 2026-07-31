/// Sanitizador Puramente Funcional para Conversão de XHTML/HTML em Texto Limpo para TTS.
class HtmlSanitizer {
  static const Map<String, String> _htmlEntities = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&mdash;': '—',
    '&ndash;': '–',
    '&hellip;': '...',
  };

  /// Sanitiza um fragmento de documento XHTML/HTML e retorna o texto limpo e formatado em parágrafos.
  static String sanitize(String html) {
    if (html.trim().isEmpty) return '';

    String text = html;

    // 1. Remover blocos <style> e <script> completos
    text = text.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false), ' ');
    text = text.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false), ' ');

    // 2. Converter tags de bloco (<p>, <div>, <h1>-<h6>, <br>, <li>) em quebras de parágrafo \n\n
    text = text.replaceAll(RegExp(r'<\/(p|div|h[1-6]|li)>\s*', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<br\s*\/?>\s*', caseSensitive: false), '\n');

    // 3. Remover todas as demais tags HTML (<...>)
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // 4. Decodificar Entidades HTML
    _htmlEntities.forEach((entity, replacement) {
      text = text.replaceAll(entity, replacement);
    });

    // Decodificação numérica de entidades XML (ex: &#160; -> " ")
    text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final int code = int.tryParse(match.group(1)!) ?? 32;
      return String.fromCharCode(code);
    });

    // 5. Normalizar espaçamentos e remover espaços soltos antes de pontuações
    final List<String> paragraphs = text
        .split(RegExp(r'\n+'))
        .map((p) => p
            .replaceAll(RegExp(r'\s+'), ' ')
            .replaceAllMapped(RegExp(r'\s+([.,!?:;])'), (m) => m.group(1)!)
            .trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return paragraphs.join('\n\n');
  }

  /// Extrai o título do capítulo de tags <h1>, <h2> ou <title> no HTML bruto.
  static String extractTitle(String html, {String fallbackTitle = 'Capítulo'}) {
    final RegExp titleRegex = RegExp(r'<(h[1-3]|title)[^>]*>(.*?)<\/(h[1-3]|title)>', caseSensitive: false);
    final Match? match = titleRegex.firstMatch(html);

    if (match != null && match.group(2) != null) {
      final String raw = match.group(2)!;
      final String clean = sanitize(raw);
      if (clean.isNotEmpty) return clean;
    }

    return fallbackTitle;
  }
}
