// lib/features/2D_layout_builder/controllers/layout_controller.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;

import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/svg.dart' as svg;
import 'package:pdfx/pdfx.dart';

import 'package:optilay_prototype_app/features/2D_layout_builder/data/pdf_export.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/data/pdf_import.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/data/pdf_picker.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/models/machinery_item.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/models/value_objects.dart';

class LayoutController extends GetxController {
  final PdfImportService pdfService;
  final FilePickerService picker;
  final ExportService exporter;

  LayoutController(this.pdfService, this.picker, this.exporter);

  final importedLayoutImage = Rxn<Uint8List>();
  final items = <MachineryItem>[].obs;
  final overlayWidgets = <Widget>[].obs;

  final scaleSet = false.obs;
  final referenceScale = Rx<Scale?>(null);

  // NEW: remember original PDF path + the "scene" pixel size (pixels of the imported image)
  String? _importedPdfPath;
  ui.Size? _scenePixelSize;

  void setScale(Scale s) {
    referenceScale.value = s;
    scaleSet.value = true;
  }

  double pixelSizeFor(double meters) =>
      referenceScale.value == null
          ? 100.0
          : referenceScale.value!.toScenePixels(meters);

  Future<void> importPdfAsCanvas() async {
    final file = await picker.pickPdf();
    if (file == null) return;

    final bytes = await pdfService.firstPageAsPngBytes(
      file,
    ); // your existing 2x render
    if (bytes != null) {
      importedLayoutImage.value = bytes;

      // remember original file path for HQ export
      _importedPdfPath = file.path;

      // detect the imported image size => defines your scene coordinate space
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _scenePixelSize = ui.Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
    }
  }

  /// Legacy export (kept as fallback)
  Future<void> exportCanvas(GlobalKey canvasKey) async {
    final boundary =
        canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    if (boundary.debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    // keep 2.0 here as the low-res fallback
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    await exporter.exportPngToPdfAndShare(byteData.buffer.asUint8List());
  }

  /// HIGH-QUALITY export:
  /// 1) Re-render original PDF at [targetDpi] (crisp text/lines).
  /// 2) Draw each machinery SVG on top at the correct mapped coordinates/size.
  /// 3) Generate a PDF page sized to the bitmap at [targetDpi] (no downscaling).
  Future<void> exportCanvasHighQuality(
    GlobalKey canvasKey, {
    double targetDpi = 300,
  }) async {
    if (_importedPdfPath == null || _scenePixelSize == null) {
      await exportCanvas(canvasKey);
      return;
    }

    // 1) High-DPI background from source PDF (INT width/height required here)
    final doc = await PdfDocument.openFile(_importedPdfPath!);
    final page = await doc.getPage(1);

    final bgWidthPx = (page.width * targetDpi / 72.0).round(); // int
    final bgHeightPx = (page.height * targetDpi / 72.0).round(); // int

    final pageImage = await page.render(
      width: bgWidthPx.toDouble(), // <- keep as int
      height: bgHeightPx.toDouble(), // <- keep as int
      format: PdfPageImageFormat.png,
      backgroundColor: '#ffffff',
    );

    await page.close();
    await doc.close();

    if (pageImage == null) {
      await exportCanvas(canvasKey);
      return;
    }

    // 2) Build the final PDF (vector SVG overlays on top of high-DPI background)
    final pdfDoc = pw.Document();

    // page size in POINTS (1pt = 1/72")
    final widthPts = bgWidthPx * 72.0 / targetDpi;
    final heightPts = bgHeightPx * 72.0 / targetDpi;
    final pageFormat = pdf.PdfPageFormat(widthPts, heightPts);

    // scene(px) -> export(px) mapping
    final ratio = bgWidthPx / _scenePixelSize!.width;

    // Background as image
    final bgMem = pw.MemoryImage(pageImage.bytes);

    // Build positioned SVG overlays
    final overlayWidgets = <pw.Widget>[];
    for (final m in items) {
      final leftPx = m.topLeftScene.dx * ratio;
      final topPx = m.topLeftScene.dy * ratio;
      final sizePx = pixelSizeFor(m.realWorldSizeMeters) * ratio;

      // convert px -> points
      final leftPt = leftPx * 72.0 / targetDpi;
      final topPt = topPx * 72.0 / targetDpi;
      final sizePt = sizePx * 72.0 / targetDpi;

      // load the SVG asset as text once per item
      final svgStr = await rootBundle.loadString(m.assetPath);

      overlayWidgets.add(
        pw.Positioned(
          left: leftPt,
          top: topPt,
          child: pw.SizedBox(
            width: sizePt,
            height: sizePt,
            child: pw.SvgImage(svg: svgStr), // stays vector in the PDF
          ),
        ),
      );
    }

    pdfDoc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build:
            (_) => pw.Stack(
              children: [
                pw.Positioned.fill(
                  child: pw.Image(
                    bgMem,
                    width: widthPts,
                    height: heightPts,
                    fit: pw.BoxFit.cover,
                  ),
                ),
                ...overlayWidgets,
              ],
            ),
      ),
    );

    final bytes = await pdfDoc.save();
    await exporter.sharePdfBytes(bytes, filename: 'layout_export_hq.pdf');
  }
}
