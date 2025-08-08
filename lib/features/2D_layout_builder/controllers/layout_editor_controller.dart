// 📁 lib/features/2D_layout_builder/controllers/layout_editor_controller.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/widgets/quote_line_painter.dart';
import 'package:pdfx/pdfx.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class LayoutEditorController extends GetxController {
  final importedLayotImage = Rxn<Uint8List>();
  final placedSvgObjects = <Widget>[].obs;

  final referenceScale = 1.0.obs;
  final scaleSet = false.obs;
  final quotePosition = Offset(100, 100).obs;
  final quoteLength = 150.0.obs;
  final quotingMode = false.obs;
  final realMeasurementLabel = ''.obs;

  void toggleQuotingMode(bool state) => quotingMode.value = state;

  Future<void> importPdfAsCanvas() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    final file = File(result.files.single.path!);
    final document = await PdfDocument.openFile(file.path);
    final page = await document.getPage(1);
    final pageImage = await page.render(
      width: page.width * 2,
      height: page.height * 2,
      format: PdfPageImageFormat.png,
      backgroundColor: '#ffffff',
    );

    importedLayotImage.value = pageImage?.bytes;
    await page.close();
    await document.close();

    toggleQuotingMode(true);
  }

  void setReferenceScale(double realLength) {
    referenceScale.value = realLength / quoteLength.value;
    realMeasurementLabel.value = "${realLength.toStringAsFixed(2)} m";
    scaleSet.value = true;
    toggleQuotingMode(false);

    // Add permanent quoting line to canvas
    placedSvgObjects.add(
      Positioned(
        left: quotePosition.value.dx,
        top: quotePosition.value.dy,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            SizedBox(width: quoteLength.value, height: 30),
            CustomPaint(
              painter: QuotePainter(
                quoteLength.value,
                label: realMeasurementLabel.value,
              ),
              child: SizedBox(width: quoteLength.value, height: 30),
            ),
          ],
        ),
      ),
    );
  }

  void addSvgMachinery(String assetPath, double realWorldSize) {
    if (!scaleSet.value) {
      Get.snackbar('Warning', 'Set reference scale first!');
      return;
    }

    final pixelSize = realWorldSize / referenceScale.value;
    placedSvgObjects.add(
      Positioned(
        left: 150,
        top: 150,
        child: SvgPicture.asset(assetPath, width: pixelSize, height: pixelSize),
      ),
    );
  }

  Future<void> exportCanvasAsPdf(GlobalKey canvasKey) async {
    try {
      final boundary =
          canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        Get.snackbar('Error', 'Canvas not found');
        return;
      }

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 20));
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        Get.snackbar('Error', 'Failed to get image bytes');
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final pdf = pw.Document();
      final imageProvider = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(build: (context) => pw.Center(child: pw.Image(imageProvider))),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/layout_export.pdf');
      await file.writeAsBytes(await pdf.save());

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'layout_export.pdf',
      );
    } catch (e) {
      Get.snackbar('Error', 'Export failed: $e');
    }
  }
}
