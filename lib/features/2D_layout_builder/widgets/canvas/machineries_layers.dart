// lib/features/2D_layout_builder/widgets/canvas/machineries_layer.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/layout_controller.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/widgets/painters/quote_line_painter.dart';

class MachineriesLayer extends StatelessWidget {
  const MachineriesLayer({super.key, required this.layout});

  final LayoutController layout;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Stack(
        children: [
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
                    child: SvgPicture.asset(m.assetPath, fit: BoxFit.contain),
                  ),
                );
              },
            ),
          if (layout.calibrationLine.value != null)
            Positioned(
              left: layout.calibrationLine.value!.topLeftScene.dx,
              top: layout.calibrationLine.value!.topLeftScene.dy,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: QuotePainter(
                    layout.calibrationLine.value!.lengthPx,
                    label: layout.calibrationLine.value!.label,
                  ),
                  child: SizedBox(
                    width: layout.calibrationLine.value!.lengthPx,
                    height: 30,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
