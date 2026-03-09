// lib/features/2D_layout_builder/models/value_objects.dart
import 'package:flutter/material.dart';

class Scale {
  /// meters per scene pixel
  final double metersPerPixel;

  const Scale(this.metersPerPixel);

  double toScenePixels(double meters) => meters / metersPerPixel;
}

class CalibrationLine {
  final Offset topLeftScene;
  final double lengthPx;
  final String label;

  const CalibrationLine({
    required this.topLeftScene,
    required this.lengthPx,
    required this.label,
  });

  CalibrationLine copyWith({
    Offset? topLeftScene,
    double? lengthPx,
    String? label,
  }) {
    return CalibrationLine(
      topLeftScene: topLeftScene ?? this.topLeftScene,
      lengthPx: lengthPx ?? this.lengthPx,
      label: label ?? this.label,
    );
  }
}
