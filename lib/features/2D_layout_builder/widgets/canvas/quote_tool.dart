// presentation/widgets/canvas/quote_tool.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/quote_controller.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/widgets/painters/quote_line_painter.dart';

class QuoteTool extends StatelessWidget {
  final QuoteController qc;
  const QuoteTool({super.key, required this.qc});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!qc.quotingMode.value) return const SizedBox.shrink();
      return Positioned(
        left: qc.quotePosition.value.dx,
        top: qc.quotePosition.value.dy,
        child: _QuoteDraggableLine(qc: qc),
      );
    });
  }
}

class _QuoteDraggableLine extends StatelessWidget {
  final QuoteController qc;
  const _QuoteDraggableLine({required this.qc});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) => qc.quotePosition.value += d.delta,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          SizedBox(width: qc.quoteLengthPx.value, height: 30),
          CustomPaint(
            painter: QuotePainter(
              qc.quoteLengthPx.value,
              label: qc.realLabel.value,
            ),
            child: SizedBox(width: qc.quoteLengthPx.value, height: 30),
          ),
          // handle sx/dx riusati con piccole funzioni
        ],
      ),
    );
  }
}
