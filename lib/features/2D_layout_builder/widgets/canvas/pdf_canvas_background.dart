// presentation/widgets/canvas/pdf_canvas_background.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';

class PdfCanvasBackground extends StatelessWidget {
  final Uint8List? bytes;
  const PdfCanvasBackground({super.key, this.bytes});

  @override
  Widget build(BuildContext context) {
    if (bytes == null) return const SizedBox.shrink();
    return Positioned.fill(child: Image.memory(bytes!, fit: BoxFit.contain));
  }
}
