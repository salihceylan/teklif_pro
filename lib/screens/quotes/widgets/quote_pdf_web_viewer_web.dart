import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

bool get supportsQuotePdfWebViewer => true;

class QuotePdfWebViewer extends StatefulWidget {
  final Uint8List bytes;
  final String fileName;

  const QuotePdfWebViewer({
    super.key,
    required this.bytes,
    required this.fileName,
  });

  @override
  State<QuotePdfWebViewer> createState() => _QuotePdfWebViewerState();
}

class _QuotePdfWebViewerState extends State<QuotePdfWebViewer> {
  late final String _viewType;
  late final String _objectUrl;

  @override
  void initState() {
    super.initState();
    _viewType =
        'quote-pdf-viewer-${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(this)}';
    final blob = web.Blob(
      [widget.bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    _objectUrl = web.URL.createObjectURL(blob);

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final iframe = web.HTMLIFrameElement()
        ..src = _objectUrl
        ..title = widget.fileName
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = '0'
        ..style.backgroundColor = '#FFFFFF';
      return iframe;
    });
  }

  @override
  void dispose() {
    web.URL.revokeObjectURL(_objectUrl);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
