// lib/features/2D_layout_builder/controllers/quote_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/models/value_objects.dart';

import 'layout_controller.dart';

class QuoteController extends GetxController {
  QuoteController(this.layout);

  final LayoutController layout;

  final quotingMode = false.obs;
  final quotePosition = const Offset(100, 100).obs;
  final quoteLengthPx = 150.0.obs;
  final realLabel = ''.obs;

  void start() {
    quotingMode.value = true;
    realLabel.value = '';
  }

  void stop() => quotingMode.value = false;

  void moveWholeQuote(Offset delta) {
    quotePosition.value += delta;
  }

  void dragLeftHandle(double deltaX) {
    final newLength = quoteLengthPx.value - deltaX;
    if (newLength < 50) return;

    quoteLengthPx.value = newLength;
    quotePosition.value += Offset(deltaX, 0);
  }

  void dragRightHandle(double deltaX) {
    final newLength = quoteLengthPx.value + deltaX;
    if (newLength < 50) return;

    quoteLengthPx.value = newLength;
  }

  void setRealLengthMeters(double meters) {
    final metersPerPixel = meters / quoteLengthPx.value;
    layout.setScale(Scale(metersPerPixel));
    realLabel.value = '${meters.toStringAsFixed(2)} m';

    layout.setCalibrationLine(
      CalibrationLine(
        topLeftScene: quotePosition.value,
        lengthPx: quoteLengthPx.value,
        label: realLabel.value,
      ),
    );

    stop();
  }
}
