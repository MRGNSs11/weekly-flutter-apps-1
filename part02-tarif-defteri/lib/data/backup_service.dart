import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/recipe_backup.dart';

/// Yedeği diske yazar ve dosyanın yolunu döndürür.
///
/// Dosya geçici klasöre yazılıyor; kalıcı kopyayı annem paylaşım penceresinden
/// nereye isterse oraya (WhatsApp, Drive, Dosyalar) kendisi koyuyor. Uygulama
/// telefonun depolama iznini istemek zorunda kalmıyor.
///
/// Paylaşım katmanına ait bir tür (`XFile`) döndürmüyor: veri katmanının
/// dosyayı kimin, nasıl gönderdiğinden haberi olmasın.
Future<String> writeBackupFile(BackupData data) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/${backupFileName(DateTime.now())}');
  await file.writeAsString(data.toJsonString());
  return file.path;
}

/// Dosya adında tarih var: annem art arda yedek alırsa hangisinin yeni
/// olduğunu ada bakarak anlayabilsin.
String backupFileName(DateTime now) {
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return 'tarif-defteri-$y-$m-$d.json';
}
