import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/widgets/quote_line_painter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart';
import 'package:printing/printing.dart';

class MachineryItem {
  final String assetPath;
  final double realWorldSize; // meters (desired real size)
  final Offset position; // top-left in canvas (scene) coordinates

  MachineryItem({
    required this.assetPath,
    required this.realWorldSize,
    required this.position,
  });

  MachineryItem copyWith({
    String? assetPath,
    double? realWorldSize,
    Offset? position,
  }) {
    return MachineryItem(
      assetPath: assetPath ?? this.assetPath,
      realWorldSize: realWorldSize ?? this.realWorldSize,
      position: position ?? this.position,
    );
  }
}

class LayoutEditorController extends GetxController {
  // Background (PDF imported as image)
  final importedLayotImage = Rxn<Uint8List>();

  // Check if it is woth exporting (i.e. has content):
  bool get canExport => items.isNotEmpty || overlayWidgets.isNotEmpty;

  // Placed machinery (on canvas)
  final items = <MachineryItem>[].obs;

  // A "staged" item being placed (center preview). Null when not in placement mode.
  final stagingItem = Rxn<MachineryItem>();

  // Scaling / quoting
  final referenceScale =
      1.0.obs; // meters-per-pixel; set by setReferenceScale; default 1 m/px.
  final scaleSet = false.obs;

  final quotePosition = const Offset(100, 100).obs;
  final quoteLength = 150.0.obs;
  final quotingMode = false.obs;
  final realMeasurementLabel = ''.obs;

  void toggleQuotingMode(bool state) => quotingMode.value = state;

  // == Import PDF ==
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

    // Prompt for scale immediately after importing a plan
    toggleQuotingMode(true);
    Get.snackbar(
      'Set Scale',
      'Drag the quote line to a known distance, then tap "Set Quote" to enter the real length.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blueGrey.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  // == Quote & scale ==
  void setReferenceScale(double realLengthMeters) {
    // referenceScale = meters-per-pixel
    referenceScale.value = realLengthMeters / quoteLength.value;
    realMeasurementLabel.value = "${realLengthMeters.toStringAsFixed(2)} m";
    scaleSet.value = true;
    toggleQuotingMode(false);

    // Put a permanent (non-interactive) quote line on the canvas
    // (purely visual; does not affect placement)
    final visualQuote = Positioned(
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
    );
    overlayWidgets.add(visualQuote);

    // If we are staging an item, keep staging — its preview will resize automatically
    // because pixelSizeFor() uses the updated referenceScale.
  }

  // Optional overlay widgets (like the permanent quote)
  final overlayWidgets = <Widget>[].obs;

  // == Start placement workflow ==
  void startAddMachinery({
    required String assetPath,
    required double realWorldSizeMeters,
  }) {
    stagingItem.value = MachineryItem(
      assetPath: assetPath,
      realWorldSize: realWorldSizeMeters,
      position: Offset.zero, // position is decided on confirm
    );

    // If no scale yet, we still allow staging; user can see/zoom/pan freely.
    // Once scale is set later, the preview auto-resizes (pixelSizeFor).
  }

  // == Confirm placement at the current viewport center ==
  void confirmPlacementAtSceneCenter({required Offset scenePoint}) {
    final staged = stagingItem.value;
    if (staged == null) return;

    final px = pixelSizeFor(staged.realWorldSize);
    // Store top-left so the visual center matches the viewport crosshair
    final topLeft = scenePoint - Offset(px / 2, px / 2);

    items.add(staged.copyWith(position: topLeft));

    stagingItem.value = null;
  }

  void cancelPlacement() {
    stagingItem.value = null;
  }

  // == Size helper ==
  double pixelSizeFor(double realWorldMeters) {
    // If scale is not set, fall back to a visible preview size
    if (!scaleSet.value) return 100.0;
    // meters / (meters-per-pixel) => pixels
    return realWorldMeters / referenceScale.value;
  }

  // == Widgets builder for placed machinery ==
  List<Widget> buildPlacedMachineryWidgets() {
    return [
      for (final m in items)
        Positioned(
          left: m.position.dx,
          top: m.position.dy,
          child: SizedBox(
            width: pixelSizeFor(m.realWorldSize),
            height: pixelSizeFor(m.realWorldSize),
            child: buildSvgFor(m),
          ),
        ),
      // Any visual overlays (like fixed quote line)
      ...overlayWidgets,
    ];
  }

  // == SVG builder (centralized in case you want to add gestures later) ==
  Widget buildSvgFor(MachineryItem m) {
    return SvgPicture.asset(m.assetPath, fit: BoxFit.contain);
  }

  // == Export ==
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
