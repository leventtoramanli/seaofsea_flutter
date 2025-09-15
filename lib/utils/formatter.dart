// basit ID biçimlendirici
String formatJobId(dynamic id, {int minWidth = 6, String prefix = '#'}) {
  if (id == null) return '—';
  final s = id.toString();
  return '$prefix${s.padLeft(minWidth, '0')}';
}
