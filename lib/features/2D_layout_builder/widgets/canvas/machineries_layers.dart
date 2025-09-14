// presentation/widgets/canvas/machineries_layer.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/layout_controller.dart';

class MachineriesLayer extends StatelessWidget {
  final LayoutController layout;
  const MachineriesLayer({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Stack(
        children: [
          for (final m in layout.items)
            Positioned(
              left: m.topLeftScene.dx,
              top: m.topLeftScene.dy,
              child: SizedBox(
                width: layout.pixelSizeFor(m.realWorldSizeMeters),
                height: layout.pixelSizeFor(m.realWorldSizeMeters),
                child: SvgPicture.asset(m.assetPath, fit: BoxFit.contain),
              ),
            ),
          ...layout.overlayWidgets,
        ],
      ),
    );
  }
}
