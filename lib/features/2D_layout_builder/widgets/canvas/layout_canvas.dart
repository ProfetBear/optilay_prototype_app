// lib/features/2D_layout_builder/widgets/layout_canvas.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/layout_controller.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/placement_controller.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/quote_controller.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/widgets/painters/quote_line_painter.dart';

class LayoutCanvas extends StatelessWidget {
  const LayoutCanvas({
    super.key,
    required this.layout,
    required this.quote,
    required this.place,
    required this.viewerController,
    required this.canvasKey,
  });

  final LayoutController layout;
  final QuoteController quote;
  final PlacementController place;
  final TransformationController viewerController;
  final GlobalKey canvasKey;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: viewerController,
      minScale: 0.2,
      maxScale: 8.0,
      boundaryMargin: const EdgeInsets.all(1500),
      clipBehavior: Clip.none,
      child: Obx(() {
        final sceneSize = layout.scenePixelSize;
        final fixedQuote = layout.calibrationLine.value;
        final staged = place.staging.value;

        return RepaintBoundary(
          key: canvasKey,
          child: SizedBox(
            width: sceneSize.width,
            height: sceneSize.height,
            child: Stack(
              children: [
                Positioned.fill(child: Container(color: Colors.grey.shade200)),

                Positioned.fill(child: CustomPaint(painter: _GridPainter())),

                if (layout.importedLayoutImage.value != null)
                  Positioned.fill(
                    child: Image.memory(
                      layout.importedLayoutImage.value!,
                      fit: BoxFit.fill,
                    ),
                  ),

                for (final m in layout.items)
                  Builder(
                    builder: (_) {
                      final size = layout.sceneSizeFor(m);

                      return Positioned(
                        left: m.topLeftScene.dx,
                        top: m.topLeftScene.dy,
                        child: Container(
                          width: size.width,
                          height: size.height,
                          decoration:
                              m.placedWithoutScale
                                  ? BoxDecoration(
                                    border: Border.all(
                                      color: Colors.orange.shade700,
                                      width: 1.5,
                                    ),
                                  )
                                  : null,
                          child: SvgPicture.asset(
                            m.assetPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),

                if (fixedQuote != null)
                  Positioned(
                    left: fixedQuote.topLeftScene.dx,
                    top: fixedQuote.topLeftScene.dy,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: QuotePainter(
                          fixedQuote.lengthPx,
                          label: fixedQuote.label,
                        ),
                        child: SizedBox(width: fixedQuote.lengthPx, height: 30),
                      ),
                    ),
                  ),

                if (quote.quotingMode.value)
                  Positioned(
                    left: quote.quotePosition.value.dx,
                    top: quote.quotePosition.value.dy,
                    child: GestureDetector(
                      onPanUpdate:
                          (details) => quote.moveWholeQuote(details.delta),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          SizedBox(
                            width: quote.quoteLengthPx.value,
                            height: 30,
                          ),
                          CustomPaint(
                            painter: QuotePainter(
                              quote.quoteLengthPx.value,
                              label: quote.realLabel.value,
                            ),
                            child: SizedBox(
                              width: quote.quoteLengthPx.value,
                              height: 30,
                            ),
                          ),
                          Positioned(
                            left: -10,
                            child: GestureDetector(
                              onPanUpdate:
                                  (d) => quote.dragLeftHandle(d.delta.dx),
                              behavior: HitTestBehavior.translucent,
                              child: const SizedBox(width: 20, height: 20),
                            ),
                          ),
                          Positioned(
                            right: -10,
                            child: GestureDetector(
                              onPanUpdate:
                                  (d) => quote.dragRightHandle(d.delta.dx),
                              behavior: HitTestBehavior.translucent,
                              child: const SizedBox(width: 20, height: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                AnimatedBuilder(
                  animation: viewerController,
                  builder: (_, __) {
                    if (staged == null) return const SizedBox.shrink();

                    final sceneWidth = layout.pixelSizeFor(
                      staged.realWorldWidthMeters,
                    );
                    final sceneHeight = layout.pixelSizeFor(
                      staged.realWorldHeightMeters,
                    );

                    final zoom = viewerController.value.getMaxScaleOnAxis();

                    return Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: SizedBox(
                            width: sceneWidth * zoom,
                            height: sceneHeight * zoom,
                            child: Opacity(
                              opacity: 0.92,
                              child: SvgPicture.asset(
                                staged.assetPath,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 100.0;

    final minorPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.04)
          ..strokeWidth = 1;

    final majorPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.08)
          ..strokeWidth = 1.2;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        (x % (step * 5) == 0) ? majorPaint : minorPaint,
      );
    }

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        (y % (step * 5) == 0) ? majorPaint : minorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
