// domain/models/machinery_item.dart
import 'package:flutter/material.dart';

class MachineryItem {
  final String assetPath;
  final double realWorldSizeMeters;
  final Offset topLeftScene; // coordinate scena (px)
  final bool placedWithoutScale;

  const MachineryItem({
    required this.assetPath,
    required this.realWorldSizeMeters,
    required this.topLeftScene,
    this.placedWithoutScale = false,
  });

  MachineryItem copyWith({
    String? assetPath,
    double? realWorldSizeMeters,
    Offset? topLeftScene,
    bool? placedWithoutScale,
  }) => MachineryItem(
    assetPath: assetPath ?? this.assetPath,
    realWorldSizeMeters: realWorldSizeMeters ?? this.realWorldSizeMeters,
    topLeftScene: topLeftScene ?? this.topLeftScene,
    placedWithoutScale: placedWithoutScale ?? this.placedWithoutScale,
  );
}
