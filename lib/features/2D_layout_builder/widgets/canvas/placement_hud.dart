// presentation/widgets/canvas/placement_hud.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/placement_controller.dart';

class PlacementHud extends StatelessWidget {
  final PlacementController pc;
  final TransformationController viewerController;
  final double Function(double meters) pixelsFor;

  const PlacementHud({
    super.key,
    required this.pc,
    required this.viewerController,
    required this.pixelsFor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewerController,
      builder: (_, __) {
        final staged = pc.staging.value;
        if (staged == null) return const SizedBox.shrink();

        final scenePx = pixelsFor(staged.realWorldSizeMeters);
        final zoom = viewerController.value.getMaxScaleOnAxis();
        final screenPx = scenePx * zoom;

        return Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: SizedBox(
                width: screenPx,
                height: screenPx,
                child: Opacity(
                  opacity: 0.95,
                  child: SvgPicture.asset(staged.assetPath),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
