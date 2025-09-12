import 'dart:math' as math;
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ManipulationPage extends StatefulWidget {
  const ManipulationPage({super.key});

  @override
  State<ManipulationPage> createState() => _ManipulationPageState();
}

class _ManipulationPageState extends State<ManipulationPage> {
  late ARKitController arkitController;

  // World-anchored container; GLB is a child of this
  ARKitNode? containerNode;
  ARKitGltfNode? glbNode;

  // Gesture baselines
  vector.Vector3? _panBasePosition;
  double? _rotationBaseYaw;

  // Plane visualization & UI state
  bool _hasAnyPlane = false;
  final Map<String, _PlaneViz> _planes = {}; // anchorId -> viz data

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manipulation Sample')),
      body: Stack(
        children: [
          ARKitSceneView(
            planeDetection: ARPlaneDetection.horizontal,
            showFeaturePoints: true,
            enableTapRecognizer: true,
            enablePinchRecognizer: true,
            enablePanRecognizer: true,
            enableRotationRecognizer: true,
            onARKitViewCreated: onARKitViewCreated,
          ),

          // Overlay banner to indicate plane detection status
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: 1.0,
              child:
                  _hasAnyPlane
                      ? _Banner(
                        color: Colors.green.withOpacity(0.9),
                        text:
                            'Plane detected — tap to place, then drag/rotate/pinch',
                        icon: Icons.grid_on,
                      )
                      : _Banner(
                        color: Colors.black.withOpacity(0.7),
                        text: 'Move your device to detect a horizontal surface',
                        icon: Icons.phone_iphone,
                      ),
            ),
          ),
        ],
      ),
    );
  }

  void onARKitViewCreated(ARKitController controller) {
    arkitController = controller;

    // --- Plane anchor callbacks to visualize & track status ---
    arkitController.onAddNodeForAnchor = (anchor) {
      if (anchor is! ARKitPlaneAnchor) return;
      _addPlaneViz(anchor);
    };

    arkitController.onUpdateNodeForAnchor = (anchor) {
      if (anchor is! ARKitPlaneAnchor) return;
      _updatePlaneViz(anchor);
    };

    // --- Tap to place / move at world point on plane ---
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

    // --- Gestures ---
    // Pinch -> scale GLB
    arkitController.onNodePinch = (events) {
      if (glbNode == null || events.isEmpty) return;
      final s = events.first.scale.clamp(0.01, 10.0);
      glbNode!.scale = vector.Vector3.all(s);
    };

    // Two-finger twist -> yaw container
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

    // One-finger drag -> translate container in X/Z
    arkitController.onNodePan = (events) {
      if (containerNode == null || events.isEmpty) return;
      final t = events.first.translation; // Vector2 delta since gesture start
      if (_panBasePosition == null || (t.x * t.x + t.y * t.y) < 1e-8) {
        _panBasePosition = containerNode!.position;
      }
      const dragSensitivity = 0.0015;
      final dx = t.x * dragSensitivity;
      final dz = t.y * dragSensitivity;
      containerNode!.position = vector.Vector3(
        _panBasePosition!.x + dx,
        _panBasePosition!.y,
        _panBasePosition!.z + dz,
      );
    };
  }

  // ---------- Plane visualization helpers ----------

  void _addPlaneViz(ARKitPlaneAnchor anchor) {
    final plane = ARKitPlane(
      width: anchor.extent.x,
      height: anchor.extent.z,
      materials: [
        ARKitMaterial(
          // Semi-transparent grid look
          transparency: 0.35,
          diffuse: ARKitMaterialProperty.color(Colors.white),
        ),
      ],
    );

    final node = ARKitNode(
      name: 'plane_${anchor.identifier}',
      geometry: plane,
      position: vector.Vector3(anchor.center.x, 0, anchor.center.z),
      // Rotate plane geometry to lie flat (SceneKit plane is vertical by default)
      rotation: vector.Vector4(1, 0, 0, -math.pi / 2),
    );

    arkitController.add(node, parentNodeName: anchor.nodeName);

    // First plane? set flag + haptic
    final wasNone = !_hasAnyPlane;
    _planes[anchor.identifier] = _PlaneViz(plane: plane, node: node);
    if (wasNone) {
      setState(() => _hasAnyPlane = true);
      HapticFeedback.mediumImpact();
    }
  }

  void _updatePlaneViz(ARKitPlaneAnchor anchor) {
    final viz = _planes[anchor.identifier];
    if (viz == null) return;

    // Update size & position as ARKit refines the plane
    viz.plane.width.value = anchor.extent.x;
    viz.plane.height.value = anchor.extent.z;
    viz.node.position = vector.Vector3(anchor.center.x, 0, anchor.center.z);
  }

  // ---------- Placement & scaling ----------

  // Place/move using WORLD transform (stable in room space).
  Future<void> _placeAtWorldPoint(Matrix4 world) async {
    final pos = vector.Vector3(
      world.getColumn(3).x,
      world.getColumn(3).y,
      world.getColumn(3).z,
    );

    // If the model hasn't been placed yet...
    if (containerNode == null) {
      // 1. Create the GLB node first (but don't add it to the controller yet).
      glbNode = ARKitGltfNode(
        name: 'DES66672-REV02 MXXXXX SZOVIKER',
        assetType: AssetType.flutterAsset,
        url: 'assets/ValiantRev11_WithoutHull.glb',
        position:
            vector
                .Vector3.zero(), // Position is relative to the parent container
        eulerAngles: vector.Vector3(0, math.pi / 2, 0), // Face 90° on Y
        scale: vector.Vector3.all(0.01), // Start with a default small scale
      );

      // 2. Create the parent container node and immediately give it the GLB node as a child.
      containerNode = ARKitNode(
        name: 'model_container',
        position: pos, // The container is placed at the tap location
      );

      // 3. Add ONLY the container node to the scene. The child comes with it automatically.
      await arkitController.add(containerNode!);

      await arkitController.add(glbNode!, parentNodeName: containerNode!.name);

      // 4. Now that the node is safely in the scene, run the auto-scaling.
      _autoScaleToLargest(glbNode!, targetLargestDimensionMeters: 0.7);
    } else {
      // If the model already exists, just move the container to the new tap position.
      containerNode!.position = pos;
    }

    // Reset gesture baselines for a fresh manipulation
    _panBasePosition = null;
    _rotationBaseYaw = containerNode!.eulerAngles.y;
  }

  // Auto-scale very large/small models to ~target size.
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
          // ignore if bounding box isn't ready yet
        });
  }
}

// Small helper for plane viz bookkeeping
class _PlaneViz {
  _PlaneViz({required this.plane, required this.node});
  final ARKitPlane plane;
  final ARKitNode node;
}

// Simple pill banner widget
class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.text, required this.icon});

  final Color color;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 10),
          Flexible(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
