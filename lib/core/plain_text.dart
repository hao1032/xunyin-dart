String plainText(String value) {
  final withoutBlocks = value.replaceAll(
    RegExp(
      r'<(script|style)\b[^>]*>.*?</\1>',
      caseSensitive: false,
      dotAll: true,
    ),
    ' ',
  );
  final withBreaks = withoutBlocks
      .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</\s*p\s*>', caseSensitive: false), '\n');
  final withoutTags = withBreaks.replaceAll(RegExp(r'<[^>]+>'), ' ');
  return _decodeHtmlEntities(withoutTags)
      .replaceAll(RegExp(r'[ \t\r\f\v]+'), ' ')
      .replaceAll(RegExp(r' *\n+ *'), '\n')
      .trim();
}

String? plainTextOrNull(String? value) {
  if (value == null) return null;
  final text = plainText(value);
  return text.isEmpty ? null : text;
}

String _decodeHtmlEntities(String value) {
  return value
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");
}
