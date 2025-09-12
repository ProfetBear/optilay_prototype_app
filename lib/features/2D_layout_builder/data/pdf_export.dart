// lib/features/2D_layout_builder/data/pdf_export.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf; // <-- ADD THIS
import 'package:printing/printing.dart';

class ExportService {
  Future<File> exportPngToPdfAndShare(Uint8List png) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(build: (_) => pw.Center(child: pw.Image(pw.MemoryImage(png)))),
    );
    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/layout_export.pdf');
    final bytes = await doc.save();
    await file.writeAsBytes(bytes);
    await Printing.sharePdf(bytes: bytes, filename: 'layout_export.pdf');
    return file;
  }

  /// High-quality: size the PDF page to match the bitmap at the desired DPI
  Future<File> exportPngToPdfAndShareHQ(
    Uint8List png, {
    double targetDpi = 300.0,
    String filename = 'layout_export_hq.pdf',
  }) async {
    // Decode PNG to get pixel dimensions
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final wPx = frame.image.width.toDouble();
    final hPx = frame.image.height.toDouble();

    // Pixels -> PDF points (1 pt = 1/72")
    final widthPts = wPx * 72.0 / targetDpi;
    final heightPts = hPx * 72.0 / targetDpi;

    final doc = pw.Document();
    final img = pw.MemoryImage(png);
    final pageFormat = pdf.PdfPageFormat(widthPts, heightPts); // <-- FIX

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (_) => pw.Image(img, width: widthPts, height: heightPts),
      ),
    );

    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/$filename');
    final bytes = await doc.save();
    await file.writeAsBytes(bytes);
    await Printing.sharePdf(bytes: bytes, filename: filename);
    return file;
  }

  Future<File> sharePdfBytes(
    Uint8List bytes, {
    String filename = 'layout_export.pdf',
  }) async {
    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/$filename');
    await file.writeAsBytes(bytes);
    await Printing.sharePdf(bytes: bytes, filename: filename);
    return file;
  }
}
