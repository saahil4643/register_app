import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

Future<void> saveAndOpenFile(Uint8List bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final filePath = '${dir.path}/$filename';
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  
  final openResult = await OpenFilex.open(filePath);
  if (openResult.type != ResultType.done) {
    debugPrint('OpenFilex error: ${openResult.message}');
  }
}
