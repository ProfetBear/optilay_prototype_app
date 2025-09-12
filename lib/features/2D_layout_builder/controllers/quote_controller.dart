import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/models/value_objects.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/widgets/painters/quote_line_painter.dart';
import 'layout_controller.dart';

class QuoteController extends GetxController {
  final LayoutController layout;
  QuoteController(this.layout);

  final quotingMode = false.obs;
  final quotePosition = const Offset(100, 100).obs;
  final quoteLengthPx = 150.0.obs; // in pixel scena
  final realLabel = ''.obs;

  // Used to uniquely identify/replace the fixed overlay when scale is set again
  final GlobalKey _fixedQuoteKey = GlobalKey();

  void start() {
    quotingMode.value = true;
    realLabel.value = '';
    // (optional) reset defaults when starting the tool:
    // quotePosition.value = const Offset(100, 100);
    // quoteLengthPx.value = 150.0;
  }

  void stop() => quotingMode.value = false;

  void setRealLengthMeters(double meters) {
    // 1) set/compute scale
    final metersPerPixel = meters / quoteLengthPx.value;
    layout.setScale(Scale(metersPerPixel));
    realLabel.value = '${meters.toStringAsFixed(2)} m';

    // 2) build a permanent visual overlay of the quote and add it to the canvas
    // remove previous fixed quote (if any) by key
    layout.overlayWidgets.removeWhere((w) => w.key == _fixedQuoteKey);

    final visualQuote = Positioned(
      key: _fixedQuoteKey,
      left: quotePosition.value.dx,
      top: quotePosition.value.dy,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          SizedBox(width: quoteLengthPx.value, height: 30),
          CustomPaint(
            painter: QuotePainter(quoteLengthPx.value, label: realLabel.value),
            child: SizedBox(width: quoteLengthPx.value, height: 30),
          ),
        ],
      ),
    );

    layout.overlayWidgets.add(visualQuote);

    // 3) exit interactive mode
    stop();
  }
}
