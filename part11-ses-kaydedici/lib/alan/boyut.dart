/// Dosya boyu: `0,3 MB`, `1,2 MB`. 0,1 MB'tan küçükse `48 KB`.
String boyutYaz(int bayt) {
  if (bayt <= 0) return '0 KB';
  const kb = 1024, mb = 1024 * 1024;
  if (bayt < mb ~/ 10) return '${(bayt / kb).ceil()} KB';
  return '${(bayt / mb).toStringAsFixed(1).replaceAll('.', ',')} MB';
}
