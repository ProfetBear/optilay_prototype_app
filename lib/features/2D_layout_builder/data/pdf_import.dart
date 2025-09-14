// data/services/pdf_import_service.dart
import 'dart:typed_data';
import 'dart:io';
import 'package:pdfx/pdfx.dart';

class PdfImportService {
  Future<Uint8List?> firstPageAsPngBytes(File pdf, {double scale = 2}) async {
    final doc = await PdfDocument.openFile(pdf.path);
    final page = await doc.getPage(1);
    final img = await page.render(
      width: page.width * scale,
      height: page.height * scale,
      format: PdfPageImageFormat.png,
      backgroundColor: '#ffffff',
    );
    await page.close();
    await doc.close();
    return img?.bytes;
  }
}
