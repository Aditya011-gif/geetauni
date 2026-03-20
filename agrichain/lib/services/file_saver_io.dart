import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class FileSaverHelper {
  Future<String> _getDownloadPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/Downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<void> saveBytes(Uint8List bytes, String filename, String mimeType) async {
    final path = await _getDownloadPath();
    final file = File('$path/$filename');
    await file.writeAsBytes(bytes);
  }
}
