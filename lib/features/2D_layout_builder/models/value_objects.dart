// domain/models/value_objects.dart
class Scale {
  // metri per pixel
  final double metersPerPixel;
  const Scale(this.metersPerPixel);
  double toScenePixels(double meters) => meters / metersPerPixel;
}
