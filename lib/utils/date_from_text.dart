/// Extrait des dates probables à partir du texte OCR (formats courants en Europe).
List<DateTime> extractDatesFromText(String raw) {
  final text = raw.replaceAll(RegExp(r'\s+'), ' ');
  final found = <DateTime>{};

  void addIfValid(int y, int m, int d) {
    if (m < 1 || m > 12 || d < 1 || d > 31) return;
    if (y < 1990 || y > 2100) return;
    try {
      found.add(DateTime(y, m, d));
    } on Object {
      // date invalide (ex. 31 février)
    }
  }

  int expandYear(int yy) {
    if (yy >= 100) return yy;
    return yy >= 70 ? 1900 + yy : 2000 + yy;
  }

  // JJ/MM/AAAA ou JJ-MM-AAAA ou JJ.MM.AA
  final dmy = RegExp(
    r'\b(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2,4})\b',
    caseSensitive: false,
  );
  for (final m in dmy.allMatches(text)) {
    final d = int.parse(m.group(1)!);
    final mo = int.parse(m.group(2)!);
    var y = int.parse(m.group(3)!);
    y = expandYear(y);
    addIfValid(y, mo, d);
  }

  // AAAA-MM-JJ
  final ymd = RegExp(r'\b(\d{4})[/.\-](\d{1,2})[/.\-](\d{1,2})\b');
  for (final m in ymd.allMatches(text)) {
    final y = int.parse(m.group(1)!);
    final mo = int.parse(m.group(2)!);
    final d = int.parse(m.group(3)!);
    addIfValid(y, mo, d);
  }

  final list = found.toList()..sort();
  return list;
}
