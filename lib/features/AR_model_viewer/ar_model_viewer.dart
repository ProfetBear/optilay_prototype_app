import 'dart:math' as math;
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ManipulationPage extends StatefulWidget {
  const ManipulationPage({super.key});

  @override
  State<ManipulationPage> createState() => _ManipulationPageState();
}

class _ManipulationPageState extends State<ManipulationPage> {
  late ARKitController arkitController;

  // We use a container anchored in world space; the GLB is a child of this.
  ARKitNode? containerNode;
  ARKitGltfNode? glbNode;

  // Gesture baselines
  vector.Vector3? _panBasePosition; // container position at gesture start
  double? _rotationBaseYaw; // container yaw at gesture start

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Manipulation Sample')),
    body: ARKitSceneView(
      planeDetection: ARPlaneDetection.horizontal, // detect horizontal plane
      showFeaturePoints: true,
      enableTapRecognizer: true, // tap to place
      enablePinchRecognizer: true, // pinch to scale
      enablePanRecognizer: true, // 1-finger pan
      enableRotationRecognizer: true, // 2-finger rotate
      onARKitViewCreated: onARKitViewCreated,
    ),
  );

  void onARKitViewCreated(ARKitController controller) {
    arkitController = controller;

    // TAP: place container at the world-space plane hit, add (or move) the GLB
    arkitController.onARTap = (hits) {
      ARKitTestResult? planeHit;
      for (final h in hits) {
        if (h.type == ARKitHitTestResultType.existingPlaneUsingExtent) {
          planeHit = h;
          break;
        }
      }
      if (planeHit == null) return;
      _placeAtWorldPoint(planeHit.worldTransform);
    };

    // PINCH: scale the GLB (not the container)
    arkitController.onNodePinch = (events) {
      if (glbNode == null || events.isEmpty) return;
      final s = events.first.scale.clamp(0.01, 10.0);
      glbNode!.scale = vector.Vector3.all(s);
    };

    // ROTATE (two-finger twist): yaw around Y on the container
    arkitController.onNodeRotation = (events) {
      if (containerNode == null || events.isEmpty) return;
      final delta = events.first.rotation; // radians since gesture start
      if (_rotationBaseYaw == null || delta.abs() < 1e-6) {
        _rotationBaseYaw = containerNode!.eulerAngles.y;
      }
      final e = containerNode!.eulerAngles;
      containerNode!.eulerAngles = vector.Vector3(
        e.x,
        (_rotationBaseYaw ?? 0) + delta,
        e.z,
      );
    };

    // PAN (one finger): translate the container in X/Z (keep Y)
    arkitController.onNodePan = (events) {
      if (containerNode == null || events.isEmpty) return;
      final t = events.first.translation; // Vector2 delta since gesture start

      // New gesture if delta ~ 0
      if (_panBasePosition == null || (t.x * t.x + t.y * t.y) < 1e-8) {
        _panBasePosition = containerNode!.position;
      }

      const dragSensitivity = 0.0015; // tune to taste
      final dx = t.x * dragSensitivity;
      final dz = t.y * dragSensitivity;

      containerNode!.position = vector.Vector3(
        _panBasePosition!.x + dx,
        _panBasePosition!.y, // lock height
        _panBasePosition!.z + dz,
      );
    };
  }

  // Place/move using a WORLD transform (stable in room space).
  void _placeAtWorldPoint(Matrix4 world) async {
    final pos = vector.Vector3(
      world.getColumn(3).x,
      world.getColumn(3).y,
      world.getColumn(3).z,
    );

    // Create or move container at the world point
    if (containerNode == null) {
      containerNode = ARKitNode(name: 'model_container', position: pos);
      await arkitController.add(containerNode!); // add to scene root
    } else {
      containerNode!.position = pos;
    }

    // Create GLB once as a child of the container (local origin)
    if (glbNode == null) {
      glbNode = ARKitGltfNode(
        name: 'DES66672-REV02 MXXXXX SZOVIKER',
        assetType: AssetType.flutterAsset,
        url: 'assets/ValiantRev11_WithoutHull.glb',
        position: vector.Vector3.zero(), // local to container
        eulerAngles: vector.Vector3(0, math.pi / 2, 0), // face 90° on Y
        scale: vector.Vector3.all(0.01), // start small
      );
      await arkitController.add(glbNode!, parentNodeName: containerNode!.name);
      _autoScaleToLargest(
        glbNode!,
        targetLargestDimensionMeters: 0.7,
      ); // optional
    }

    // Reset gesture baselines on fresh placement
    _panBasePosition = null;
    _rotationBaseYaw = containerNode!.eulerAngles.y;
  }

  // Scale very large/small assets to a reasonable size (helps stability).
  void _autoScaleToLargest(
    ARKitGltfNode node, {
    double targetLargestDimensionMeters = 0.6,
  }) {
    arkitController
        .getNodeBoundingBox(node)
        .then((bbox) {
          if (bbox.length < 2) return;
          final min = bbox[0];
          final max = bbox[1];
          final size = vector.Vector3(
            max.x - min.x,
            max.y - min.y,
            max.z - min.z,
          );
          final largest = [
            size.x.abs(),
            size.y.abs(),
            size.z.abs(),
          ].reduce((a, b) => a > b ? a : b);
          if (largest <= 1e-6) return;
          final s = targetLargestDimensionMeters / largest;
          node.scale = vector.Vector3(s, s, s);
        })
        .catchError((_) {
          // ignore if bounding box isn't available yet
        });
  }
}
