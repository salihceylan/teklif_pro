import 'dart:typed_data';

import 'browser_file_download_stub.dart'
    if (dart.library.js_interop) 'browser_file_download_web.dart';

Future<bool> downloadPdfFile(Uint8List bytes, String filename) {
  return downloadPdfFileImpl(bytes, filename);
}
