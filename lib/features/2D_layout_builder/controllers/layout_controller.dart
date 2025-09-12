// application/controllers/layout_controller.dart
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
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

  final importedLayoutImage =
      Rxn<Uint8List>(); // <- typo corretto: importedLayoutImage
  final items = <MachineryItem>[].obs;
  final overlayWidgets = <Widget>[].obs;

  final scaleSet = false.obs;
  final referenceScale = Rx<Scale?>(null);

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
    final bytes = await pdfService.firstPageAsPngBytes(file);
    if (bytes != null) {
      importedLayoutImage.value = bytes;
    }
  }

  Future<void> exportCanvas(GlobalKey canvasKey) async {
    final boundary =
        canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    if (boundary.debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    if (byteData == null) return;
    await exporter.exportPngToPdfAndShare(byteData.buffer.asUint8List());
  }
}
