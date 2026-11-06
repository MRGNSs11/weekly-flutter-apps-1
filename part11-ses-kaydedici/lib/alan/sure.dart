/// Ekranda süre: `03:07`, bir saati geçince `1:02:03`. Eksi süre `00:00`.
String sureYaz(Duration d) {
  final s = d.isNegative ? 0 : d.inSeconds;
  final saat = s ~/ 3600;
  final dk = (s % 3600) ~/ 60;
  final sn = s % 60;
  final dkSn = '${_iki(dk)}:${_iki(sn)}';
  return saat > 0 ? '$saat:$dkSn' : dkSn;
}

String _iki(int n) => n.toString().padLeft(2, '0');
