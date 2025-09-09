import 'dart:math' as math;
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class LoadGltfOrGlbFilePage extends StatefulWidget {
  const LoadGltfOrGlbFilePage({super.key});
  @override
  State<LoadGltfOrGlbFilePage> createState() => _LoadGltfOrGlbFilePageState();
}

class _LoadGltfOrGlbFilePageState extends State<LoadGltfOrGlbFilePage> {
  late ARKitController arkitController;

  ARKitGltfNode? modelNode;

  // Baselines for the *current* gesture
  vector.Vector3? _panBasePosition;
  double? _rotationBaseYaw;

  // for sanity checks / debugging
  bool _placedOnPlane = false;

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(backgroundColor: Colors.transparent),
    body: ARKitSceneView(
      // --- IMPORTANT: world tracking + plane detection ---
      planeDetection: ARPlaneDetection.horizontal,
      worldAlignment: ARWorldAlignment.gravity,
      configuration: ARKitConfiguration.worldTracking,
      // ---------------------------------------------------
      showFeaturePoints: true,
      showWorldOrigin: false,
      debug: true,
      forceUserTapOnCenter: false, // be explicit (default is false)
      // gestures must be explicitly enabled
      enableTapRecognizer: true,
      enablePanRecognizer: true,
      enableRotationRecognizer: true,
      enablePinchRecognizer: true,

      onARKitViewCreated: onARKitViewCreated,
    ),
  );

  void onARKitViewCreated(ARKitController controller) {
    arkitController = controller;

    // 1) TAP to place ON A PLANE ANCHOR (locks in world space)
    arkitController.onARTap = (hits) {
      final planeHit = hits.firstWhereOrNull(
        (h) => h.type == ARKitHitTestResultType.existingPlaneUsingExtent,
      );
      if (planeHit == null || planeHit.anchor == null) {
        // No plane yet — ignore (or fallback to feature point if you want)
        return;
      }
      _placeOnPlane(planeHit);
    };

    // 2) PINCH to scale
    arkitController.onNodePinch = (events) {
      if (!_placedOnPlane || modelNode == null || events.isEmpty) return;
      final s = events.first.scale.clamp(0.01, 10.0);
      modelNode!.scale = vector.Vector3.all(s);
    };

    // 3) TWO-FINGER ROTATE (yaw only, rotate around vertical axis)
    arkitController.onNodeRotation = (events) {
      if (!_placedOnPlane || modelNode == null || events.isEmpty) return;
      final delta = events.first.rotation; // radians, delta since gesture start
      if (_rotationBaseYaw == null || delta.abs() < 1e-6) {
        _rotationBaseYaw = modelNode!.eulerAngles.y;
      }
      final e = modelNode!.eulerAngles;
      modelNode!.eulerAngles = vector.Vector3(
        e.x,
        (_rotationBaseYaw ?? 0) + delta,
        e.z,
      );
    };

    // 4) ONE-FINGER PAN to drag across the horizontal plane (X/Z only)
    arkitController.onNodePan = (events) {
      if (!_placedOnPlane || modelNode == null || events.isEmpty) return;
      final t = events.first.translation; // Vector2 delta since gesture start

      // When delta ~ 0, treat as new gesture and capture base position.
      if (_panBasePosition == null || (t.x * t.x + t.y * t.y) < 1e-8) {
        _panBasePosition = modelNode!.position;
      }

      // Tune this to your liking (depends on device + model scale):
      const dragSensitivity = 0.0015;
      final dx = t.x * dragSensitivity;
      final dz = t.y * dragSensitivity; // screen up/down -> forward/back

      modelNode!.position = vector.Vector3(
        _panBasePosition!.x + dx,
        _panBasePosition!.y, // keep same height -> stays on plane
        _panBasePosition!.z + dz,
      );
    };

    // (Optional) See which node names ARKit reports on touch:
    arkitController.onNodeTap = (names) {
      // print('Tapped node(s): $names');
    };
  }

  // Place or move the model as a CHILD of the plane anchor.
  // Use localTransform (relative to anchor) so it sits on the plane surface.
  void _placeOnPlane(ARKitTestResult planeHit) {
    final Matrix4 local = planeHit.localTransform; // relative to plane anchor
    final vector.Vector3 localPos = vector.Vector3(
      local.getColumn(3).x,
      0.0, // keep exactly on the plane surface
      local.getColumn(3).z,
    );

    if (modelNode == null) {
      modelNode = ARKitGltfNode(
        name: 'model_root',
        assetType: AssetType.flutterAsset,
        url: 'assets/valiant_rev00.glb',
        // Start reasonably big so it’s easy to hit with a finger:
        scale: vector.Vector3(0.1, 0.1, 0.1),
        position: localPos,
      );
      // 👇 anchor parenting is the key: the object will NOT follow the camera.
      arkitController.add(
        modelNode!,
        parentNodeName: planeHit.anchor!.nodeName,
      );
      _placedOnPlane = true;
    } else {
      modelNode!.position = localPos;
      _placedOnPlane = true;
    }

    // Reset gesture baselines after a fresh placement:
    _panBasePosition = null;
    _rotationBaseYaw = modelNode!.eulerAngles.y;
  }
}
