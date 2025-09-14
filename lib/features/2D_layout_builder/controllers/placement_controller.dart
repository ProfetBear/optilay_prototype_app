// application/controllers/placement_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/models/machinery_item.dart';
import 'layout_controller.dart';

class PlacementController extends GetxController {
  final LayoutController layout;
  PlacementController(this.layout);

  final staging = Rxn<MachineryItem>();

  void startAdd({required String assetPath, required double sizeMeters}) {
    staging.value = MachineryItem(
      assetPath: assetPath,
      realWorldSizeMeters: sizeMeters,
      topLeftScene: Offset.zero,
    );
  }

  void cancel() => staging.value = null;

  void confirmAtSceneCenter(Offset scenePoint) {
    final staged = staging.value;
    if (staged == null) return;

    final px = layout.pixelSizeFor(staged.realWorldSizeMeters);
    final topLeft = scenePoint - Offset(px / 2, px / 1.6);

    layout.items.add(
      staged.copyWith(
        topLeftScene: topLeft,
        placedWithoutScale: !layout.scaleSet.value,
      ),
    );
    staging.value = null;
  }
}
