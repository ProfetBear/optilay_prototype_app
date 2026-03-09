// lib/features/2D_layout_builder/controllers/placement_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/models/machinery_item.dart';

import 'layout_controller.dart';

class PlacementController extends GetxController {
  PlacementController(this.layout);

  final LayoutController layout;
  final staging = Rxn<MachineryItem>();

  void startAdd({
    required String assetPath,
    required double widthMeters,
    required double heightMeters,
  }) {
    staging.value = MachineryItem(
      assetPath: assetPath,
      realWorldWidthMeters: widthMeters,
      realWorldHeightMeters: heightMeters,
      topLeftScene: Offset.zero,
    );
  }

  void cancel() => staging.value = null;

  void confirmAtSceneCenter(Offset scenePoint) {
    final staged = staging.value;
    if (staged == null) return;

    final widthPx = layout.pixelSizeFor(staged.realWorldWidthMeters);
    final heightPx = layout.pixelSizeFor(staged.realWorldHeightMeters);

    final topLeft = scenePoint - Offset(widthPx / 2, heightPx / 2);

    layout.items.add(
      staged.copyWith(
        topLeftScene: topLeft,
        placedWithoutScale: !layout.scaleSet.value,
      ),
    );
    staging.value = null;
  }
}
