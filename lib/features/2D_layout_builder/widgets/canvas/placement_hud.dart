// lib/features/2D_layout_builder/widgets/canvas/placement_hud.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/placement_controller.dart';

class PlacementHud extends StatelessWidget {
  const PlacementHud({
    super.key,
    required this.pc,
    required this.viewerController,
    required this.widthPixelsFor,
    required this.heightPixelsFor,
  });

  final PlacementController pc;
  final TransformationController viewerController;
  final double Function(double meters) widthPixelsFor;
  final double Function(double meters) heightPixelsFor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewerController,
      builder: (_, __) {
        final staged = pc.staging.value;
        if (staged == null) return const SizedBox.shrink();

        final sceneWidth = widthPixelsFor(staged.realWorldWidthMeters);
        final sceneHeight = heightPixelsFor(staged.realWorldHeightMeters);
        final zoom = viewerController.value.getMaxScaleOnAxis();

        return Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: SizedBox(
                width: sceneWidth * zoom,
                height: sceneHeight * zoom,
                child: Opacity(
                  opacity: 0.95,
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
    );
  }
}
