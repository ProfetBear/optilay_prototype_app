// lib/features/2D_layout_builder/controllers/layout_controller.dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/models/value_objects.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart';

import 'package:optilay_prototype_app/features/2D_layout_builder/data/pdf_export.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/data/pdf_import.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/data/pdf_picker.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/models/machinery_item.dart';

class LayoutController extends GetxController {
  LayoutController(this.pdfService, this.picker, this.exporter);

  final PdfImportService pdfService;
  final FilePickerService picker;
  final ExportService exporter;

  final importedLayoutImage = Rxn<Uint8List>();
  final items = <MachineryItem>[].obs;

  final scaleSet = false.obs;
  final referenceScale = Rx<Scale?>(null);
  final calibrationLine = Rxn<CalibrationLine>();

  String? _importedPdfPath;
  ui.Size? _scenePixelSize;

  static const ui.Size _defaultSceneSize = ui.Size(2000, 2000);

  ui.Size get scenePixelSize => _scenePixelSize ?? _defaultSceneSize;

  void setScale(Scale s) {
    referenceScale.value = s;
    scaleSet.value = true;
  }

  void setCalibrationLine(CalibrationLine? line) {
    calibrationLine.value = line;
  }

  double pixelSizeFor(double meters) {
    final scale = referenceScale.value;
    if (scale == null) return 100.0;
    return scale.toScenePixels(meters);
  }

  Size sceneSizeFor(MachineryItem item) {
    return Size(
      pixelSizeFor(item.realWorldWidthMeters),
      pixelSizeFor(item.realWorldHeightMeters),
    );
  }

  Future<void> importPdfAsCanvas() async {
    final file = await picker.pickPdf();
    if (file == null) return;

    final bytes = await pdfService.firstPageAsPngBytes(file);
    if (bytes == null) return;

    importedLayoutImage.value = bytes;
    _importedPdfPath = file.path;

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    _scenePixelSize = ui.Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
  }

  Future<void> exportCanvas(GlobalKey canvasKey) async {
    final boundary =
        canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    if (boundary.debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 20));
    }

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    await exporter.exportPngToPdfAndShare(byteData.buffer.asUint8List());
  }

  Future<void> exportCanvasHighQuality(
    GlobalKey canvasKey, {
    double targetDpi = 300,
  }) async {
    if (_importedPdfPath == null || _scenePixelSize == null) {
      await exportCanvas(canvasKey);
      return;
    }

    final doc = await PdfDocument.openFile(_importedPdfPath!);
    final page = await doc.getPage(1);

    final bgWidthPx = (page.width * targetDpi / 72.0).round();
    final bgHeightPx = (page.height * targetDpi / 72.0).round();

    final pageImage = await page.render(
      width: bgWidthPx.toDouble(),
      height: bgHeightPx.toDouble(),
      format: PdfPageImageFormat.png,
      backgroundColor: '#ffffff',
    );

    await page.close();
    await doc.close();

    if (pageImage == null) {
      await exportCanvas(canvasKey);
      return;
    }

    final pdfDoc = pw.Document();
    final widthPts = bgWidthPx * 72.0 / targetDpi;
    final heightPts = bgHeightPx * 72.0 / targetDpi;
    final pageFormat = pdf.PdfPageFormat(widthPts, heightPts);

    final ratio = bgWidthPx / _scenePixelSize!.width;
    final bgMem = pw.MemoryImage(pageImage.bytes);

    final widgets = <pw.Widget>[
      pw.Positioned.fill(
        child: pw.Image(
          bgMem,
          width: widthPts,
          height: heightPts,
          fit: pw.BoxFit.cover,
        ),
      ),
    ];

    final fixedQuote = calibrationLine.value;
    if (fixedQuote != null) {
      final leftPt = fixedQuote.topLeftScene.dx * ratio * 72.0 / targetDpi;
      final topPt = fixedQuote.topLeftScene.dy * ratio * 72.0 / targetDpi;
      final lineWidthPt = fixedQuote.lengthPx * ratio * 72.0 / targetDpi;

      widgets.add(
        pw.Positioned(
          left: leftPt,
          top: topPt,
          child: pw.Container(
            width: lineWidthPt,
            height: 24,
            child: pw.Stack(
              children: [
                pw.Positioned(
                  left: 0,
                  right: 0,
                  top: 11,
                  child: pw.Container(height: 2, color: pdf.PdfColors.blue900),
                ),
                pw.Positioned(
                  left: 0,
                  top: 5,
                  child: pw.Container(
                    width: 2,
                    height: 14,
                    color: pdf.PdfColors.blue900,
                  ),
                ),
                pw.Positioned(
                  right: 0,
                  top: 5,
                  child: pw.Container(
                    width: 2,
                    height: 14,
                    color: pdf.PdfColors.blue900,
                  ),
                ),
                pw.Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: pw.Center(
                    child: pw.Container(
                      color: pdf.PdfColors.white,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      child: pw.Text(
                        fixedQuote.label,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: pdf.PdfColors.blue900,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    for (final m in items) {
      final size = sceneSizeFor(m);

      final leftPx = m.topLeftScene.dx * ratio;
      final topPx = m.topLeftScene.dy * ratio;
      final widthPx = size.width * ratio;
      final heightPx = size.height * ratio;

      final leftPt = leftPx * 72.0 / targetDpi;
      final topPt = topPx * 72.0 / targetDpi;
      final widthPt = widthPx * 72.0 / targetDpi;
      final heightPt = heightPx * 72.0 / targetDpi;

      final svgStr = await rootBundle.loadString(m.assetPath);

      widgets.add(
        pw.Positioned(
          left: leftPt,
          top: topPt,
          child: pw.SizedBox(
            width: widthPt,
            height: heightPt,
            child: pw.SvgImage(svg: svgStr),
          ),
        ),
      );
    }

    pdfDoc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (_) => pw.Stack(children: widgets),
      ),
    );

    final bytes = await pdfDoc.save();
    await exporter.sharePdfBytes(bytes, filename: 'layout_export_hq.pdf');
  }
}
