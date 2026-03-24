import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<bool> downloadPdfFileImpl(Uint8List bytes, String filename) async {
  final pdfFile = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final pdfUrl = web.URL.createObjectURL(pdfFile);
  final link = web.HTMLAnchorElement()
    ..href = pdfUrl
    ..download = filename
    ..style.display = 'none';

  web.document.body?.append(link);
  link.click();
  link.remove();
  return true;
}
