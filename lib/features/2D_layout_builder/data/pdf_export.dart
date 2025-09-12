// data/services/export_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportService {
  Future<File> exportPngToPdfAndShare(Uint8List png) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(build: (_) => pw.Center(child: pw.Image(pw.MemoryImage(png)))),
    );
    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/layout_export.pdf');
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);
    await Printing.sharePdf(bytes: bytes, filename: 'layout_export.pdf');
    return file;
  }
}
