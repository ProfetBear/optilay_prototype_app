// lib/features/2D_layout_builder/models/machinery_item.dart
import 'package:flutter/material.dart';

class MachineryItem {
  final String assetPath;

  /// Real-world footprint in meters.
  final double realWorldWidthMeters;
  final double realWorldHeightMeters;

  /// Top-left position in scene pixels.
  final Offset topLeftScene;

  final bool placedWithoutScale;

  const MachineryItem({
    required this.assetPath,
    required this.realWorldWidthMeters,
    required this.realWorldHeightMeters,
    required this.topLeftScene,
    this.placedWithoutScale = false,
  });

  MachineryItem copyWith({
    String? assetPath,
    double? realWorldWidthMeters,
    double? realWorldHeightMeters,
    Offset? topLeftScene,
    bool? placedWithoutScale,
  }) {
    return MachineryItem(
      assetPath: assetPath ?? this.assetPath,
      realWorldWidthMeters: realWorldWidthMeters ?? this.realWorldWidthMeters,
      realWorldHeightMeters:
          realWorldHeightMeters ?? this.realWorldHeightMeters,
      topLeftScene: topLeftScene ?? this.topLeftScene,
      placedWithoutScale: placedWithoutScale ?? this.placedWithoutScale,
    );
  }
}
