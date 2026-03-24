import 'dart:typed_data';

import 'package:flutter/widgets.dart';

bool get supportsQuotePdfWebViewer => false;

class QuotePdfWebViewer extends StatelessWidget {
  final Uint8List bytes;
  final String fileName;

  const QuotePdfWebViewer({
    super.key,
    required this.bytes,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
