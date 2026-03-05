import 'dart:math' as math;

import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ManipulationPage extends StatefulWidget {
  final String assetPath;
  const ManipulationPage({super.key, required this.assetPath});

  @override
  State<ManipulationPage> createState() => _ManipulationPageState();
}

enum _ScaleMode { realistic, coffeeTable }

class _ManipulationPageState extends State<ManipulationPage> {
  late ARKitController arkitController;

  bool _withoutHull = false;

  // NEW: scale mode toggle
  _ScaleMode _scaleMode = _ScaleMode.coffeeTable;

  // World-anchored container; GLB is a child of this
  ARKitNode? containerNode;
  ARKitGltfNode? glbNode;

  // Gesture baselines
  double? _pinchBaseScale;
  double? _rotationBaseYaw;

  // Plane visualization & UI state
  bool _hasAnyPlane = false;
  final Map<String, _PlaneViz> _planes = {}; // anchorId -> viz data

  // UI: expanded controls
  bool _showSizePanel = false;
  bool _showCompass = false;
  bool _showJoystick = false;

  // Compass state (yaw in radians)
  double _compassYaw = 0.0;

  // Joystick state
  Offset _joystickOffset = Offset.zero;
  bool _joystickActive = false;

  // ------ SIZING STRATEGY (FIXED) ------
  //
  // We NEVER assume "scale = 1.0" is realistic, because GLBs often come in mm/cm,
  // or have baked scale/pivots. Instead:
  // 1) Temporarily set scale=1.0
  // 2) Read bounding box
  // 3) Compute a scale factor so largest dimension == target meters
  // 4) Apply scale
  // 5) "Ground" the model so its bottom sits on the plane (y=0) by shifting child Y.
  //
  // Coffee-table target is smaller than before.
  static const double _coffeeTableLargestMeters = 0.35;

  // Per-model realistic largest dimension (meters). TUNE THESE.
  // If you don't know yet, set approximate real-world "longest side" in meters.
  final Map<String, double> _realisticLargestByAsset = const {
    // You can use exact keys if your asset paths match:
    'assets/ValiantRev11.glb': 7.0,
    'assets/XBladeRev1.glb': 5.0,
    'assets/GeminiRev0.glb': 7.0,
  };

  // Helper to get the "without hull" asset path
  String getWithoutHullAsset(String assetPath) {
    final extIndex = assetPath.lastIndexOf('.glb');
    if (extIndex == -1) return assetPath;
    return assetPath.replaceRange(extIndex, extIndex, '_WithoutHull');
  }

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  // Remove previous GLB and add new one (with or without hull)
  Future<void> replaceModel({required bool withoutHull}) async {
    if (containerNode == null || glbNode == null) return;

    await arkitController.remove(glbNode!.name);

    final newAssetPath =
        withoutHull ? getWithoutHullAsset(widget.assetPath) : widget.assetPath;

    glbNode = ARKitGltfNode(
      name: newAssetPath,
      assetType: AssetType.flutterAsset,
      url: newAssetPath,
      position: vector.Vector3.zero(),
      scale: vector.Vector3.all(
        1.0,
      ), // we will compute correct scale mode after bbox is ready
    );

    await arkitController.add(glbNode!, parentNodeName: containerNode!.name);

    // Apply chosen scale mode once bbox is ready
    Future.delayed(const Duration(milliseconds: 180), () async {
      if (!mounted || glbNode == null) return;
      await _applyScaleMode();
    });

    setState(() {
      _withoutHull = withoutHull;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.15),
        elevation: 0,
        actions: [
          Row(
            children: [
              const Text('Hull', style: TextStyle(color: Colors.white)),
              Switch(
                value: _withoutHull,
                onChanged: (bool value) async {
                  await replaceModel(withoutHull: value);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          ARKitSceneView(
            planeDetection: ARPlaneDetection.horizontal,
            showFeaturePoints: false,
            enableTapRecognizer: true,
            enablePinchRecognizer: true,
            enablePanRecognizer: false, // translation now via joystick
            enableRotationRecognizer: true, // twist rotation for yaw
            onARKitViewCreated: onARKitViewCreated,
          ),

          // Right-side action buttons (expanders)
          Positioned(
            right: 14,
            top: topSafe + 84,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ActionPillButton(
                  icon: Icons.straighten,
                  label: 'Size',
                  active: _showSizePanel,
                  onTap: () {
                    setState(() {
                      _showSizePanel = !_showSizePanel;
                      if (_showSizePanel) {
                        _showCompass = false;
                        _showJoystick = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _ActionPillButton(
                  icon: Icons.explore,
                  label: 'Rotate',
                  active: _showCompass,
                  onTap: () {
                    setState(() {
                      _showCompass = !_showCompass;
                      if (_showCompass) {
                        _showSizePanel = false;
                        _showJoystick = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _ActionPillButton(
                  icon: Icons.sports_esports,
                  label: 'Move',
                  active: _showJoystick,
                  onTap: () {
                    setState(() {
                      _showJoystick = !_showJoystick;
                      if (_showJoystick) {
                        _showSizePanel = false;
                        _showCompass = false;
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          // Size panel (dual buttons)
          if (_showSizePanel)
            Positioned(
              right: 14,
              top: topSafe + 84 + 44,
              child: _SizePanel(
                mode: _scaleMode,
                onSelect: (m) async {
                  setState(() => _scaleMode = m);
                  await _applyScaleMode();
                },
              ),
            ),

          // Compass overlay (rotate around Y)
          if (_showCompass)
            Positioned(
              right: 14,
              top: topSafe + 84 + 44 + 54,
              child: _CompassControl(
                yaw: _compassYaw,
                enabled: containerNode != null,
                onYawChanged: (yaw) {
                  _setYaw(yaw);
                },
              ),
            ),

          // Joystick overlay (translate on X/Z)
          if (_showJoystick)
            Positioned(
              left: 16,
              bottom: 110,
              child: _JoystickControl(
                enabled: containerNode != null,
                onChange: (offset, active) {
                  _joystickOffset = offset;
                  _joystickActive = active;
                  _applyJoystickTranslation(offset, active);
                },
              ),
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
                            'Plane detected — tap to place, then pinch/rotate or use controls',
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
    // Pinch -> scale GLB (manual override)
    arkitController.onNodePinch = (events) {
      if (glbNode == null || events.isEmpty) return;

      final pinch = events.first;

      if (_pinchBaseScale == null || pinch.scale == 1.0) {
        _pinchBaseScale = glbNode!.scale.x;
      }

      final newScale = (_pinchBaseScale! * pinch.scale).clamp(0.0005, 50.0);
      glbNode!.scale = vector.Vector3.all(newScale);

      // After manual scaling, keep it grounded (prevents "floating" while scaling)
      _groundChildOnPlaneBestEffort();
    };

    // Two-finger twist -> yaw container
    arkitController.onNodeRotation = _onRotationHandler;
  }

  // ---------- Plane visualization helpers ----------

  void _addPlaneViz(ARKitPlaneAnchor anchor) {
    final plane = ARKitPlane(
      width: anchor.extent.x,
      height: anchor.extent.z,
      materials: [
        ARKitMaterial(
          transparency: 0.35,
          diffuse: ARKitMaterialProperty.color(Colors.green),
        ),
      ],
    );

    final node = ARKitNode(
      name: 'plane_${anchor.identifier}',
      geometry: plane,
      position: vector.Vector3(anchor.center.x, 0, anchor.center.z),
      rotation: vector.Vector4(1, 0, 0, -math.pi / 2),
    );

    arkitController.add(node, parentNodeName: anchor.nodeName);

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

    viz.plane.width.value = anchor.extent.x;
    viz.plane.height.value = anchor.extent.z;
    viz.node.position = vector.Vector3(anchor.center.x, 0, anchor.center.z);
  }

  // ---------- Placement & scaling ----------

  Future<void> _placeAtWorldPoint(Matrix4 world) async {
    final pos = vector.Vector3(
      world.getColumn(3).x,
      world.getColumn(3).y,
      world.getColumn(3).z,
    );

    if (containerNode == null) {
      final initialAsset =
          _withoutHull
              ? getWithoutHullAsset(widget.assetPath)
              : widget.assetPath;

      glbNode = ARKitGltfNode(
        name: initialAsset,
        assetType: AssetType.flutterAsset,
        url: initialAsset,
        position: vector.Vector3.zero(),
        scale: vector.Vector3.all(1.0), // baseline, we’ll compute proper scale
      );

      containerNode = ARKitNode(name: 'model_container', position: pos);

      await arkitController.add(containerNode!);
      await arkitController.add(glbNode!, parentNodeName: containerNode!.name);

      // Hide planes after placement
      _planes.forEach((_, viz) => arkitController.remove(viz.node.name));
      _planes.clear();

      // Apply scale mode once bbox is ready
      Future.delayed(const Duration(milliseconds: 220), () async {
        if (!mounted || glbNode == null) return;
        await _applyScaleMode();
      });
    } else {
      containerNode!.position = pos;
    }

    _pinchBaseScale = null;

    // Initialize compass yaw from current container yaw
    _rotationBaseYaw = containerNode!.eulerAngles.y;
    _compassYaw = _rotationBaseYaw ?? 0.0;
    setState(() {});
  }

  double _realisticTargetLargestMetersFor(String assetPath) {
    // 1) exact match
    final exact = _realisticLargestByAsset[assetPath];
    if (exact != null) return exact;

    // 2) heuristic by filename
    final lower = assetPath.toLowerCase();
    if (lower.contains('valiant')) return 7.0;
    if (lower.contains('xblade')) return 5.0;
    if (lower.contains('gemini')) return 7.0;

    // 3) fallback (still better than assuming 1.0 scale is correct)
    return 2.0;
  }

  Future<void> _applyScaleMode() async {
    if (glbNode == null) return;

    _pinchBaseScale = null;

    final targetLargest =
        _scaleMode == _ScaleMode.coffeeTable
            ? _coffeeTableLargestMeters
            : _realisticTargetLargestMetersFor(glbNode!.name);

    // IMPORTANT:
    // - We reset to 1.0, read bbox at that baseline, compute absolute scale, apply it
    // - Then we ground the model so it sits on the plane
    glbNode!.scale = vector.Vector3.all(1.0);
    glbNode!.position = vector.Vector3.zero();

    // bbox can be not-ready for a moment; retry a few times
    final bbox = await _getBoundingBoxWithRetries(glbNode!, retries: 6);
    if (bbox == null || bbox.length < 2) return;

    final min = bbox[0];
    final max = bbox[1];

    final size = vector.Vector3(
      (max.x - min.x).abs(),
      (max.y - min.y).abs(),
      (max.z - min.z).abs(),
    );

    final largest = [size.x, size.y, size.z].reduce((a, b) => a > b ? a : b);
    if (largest <= 1e-6) return;

    final s = (targetLargest / largest).clamp(0.0005, 50.0);
    glbNode!.scale = vector.Vector3.all(s);

    // Ground it: shift child node down by its (scaled) minY, so bottom touches y=0 of container
    // Since bbox was taken at scale=1, minY is in baseline units.
    final yShift = (-min.y * s);
    glbNode!.position = vector.Vector3(0, yShift, 0);

    HapticFeedback.selectionClick();
    if (mounted) setState(() {});
  }

  Future<List<vector.Vector3>?> _getBoundingBoxWithRetries(
    ARKitNode node, {
    int retries = 5,
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        final bbox = await arkitController.getNodeBoundingBox(node);
        if (bbox.length >= 2) return bbox;
      } catch (_) {
        // ignore
      }
      await Future.delayed(const Duration(milliseconds: 120));
    }
    return null;
  }

  // Best-effort grounding after user pinch scaling
  void _groundChildOnPlaneBestEffort() {
    if (glbNode == null) return;

    // Fire and forget; if bbox isn't ready, nothing happens.
    () async {
      final bbox = await _getBoundingBoxWithRetries(glbNode!, retries: 2);
      if (bbox == null || bbox.length < 2) return;

      final min = bbox[0];
      // Here bbox is returned in current node space; still, we can use minY * current scale=1 notion.
      // Safer: keep position correction incremental: ensure bottom at y=0.
      //
      // Because glbNode.position is local to container, we can shift by -minY directly.
      // NOTE: Depending on plugin internals, bbox may already include scale. This still works:
      // the "bottom" you see is minY, so shifting by -minY grounds it.
      final yShift = -min.y;
      glbNode!.position = vector.Vector3(0, yShift, 0);
    }();
  }

  // ---------- Rotation (compass + gesture) ----------

  void _setYaw(double yaw) {
    if (containerNode == null) return;

    final normalized = _normalizeRadians(yaw);

    containerNode!.eulerAngles = vector.Vector3(
      containerNode!.eulerAngles.x,
      normalized,
      containerNode!.eulerAngles.z,
    );

    setState(() {
      _compassYaw = normalized;
      _rotationBaseYaw = normalized;
    });
  }

  double _normalizeRadians(double a) {
    var x = a;
    while (x > math.pi) x -= 2 * math.pi;
    while (x < -math.pi) x += 2 * math.pi;
    return x;
  }

  // Incremental rotation handler (two-finger twist)
  void _onRotationHandler(List<ARKitNodeRotationResult> rotationEvents) {
    if (glbNode == null || containerNode == null || rotationEvents.isEmpty)
      return;

    final rotationResult = rotationEvents.firstWhereOrNull(
      (e) => e.nodeName == glbNode!.name,
    );
    if (rotationResult == null) return;

    final delta = rotationResult.rotation;

    if (_rotationBaseYaw == null || delta.abs() < 1e-6) {
      _rotationBaseYaw = containerNode!.eulerAngles.y;
    }

    final newYaw = (_rotationBaseYaw ?? 0.0) + delta;
    _setYaw(newYaw);
  }

  // ---------- Translation (joystick) ----------

  void _applyJoystickTranslation(Offset offset, bool active) {
    if (!active) return;
    if (containerNode == null) return;

    // offset is normalized in [-1..1] per axis
    // Map to world-space X/Z translation (meters)
    const double speed = 0.010; // slightly slower for precision
    final dx = offset.dx * speed;
    final dz = offset.dy * speed;

    final pos = containerNode!.position;
    containerNode!.position = vector.Vector3(pos.x + dx, pos.y, pos.z + dz);
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

class _ActionPillButton extends StatelessWidget {
  const _ActionPillButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? Colors.white : Colors.black.withOpacity(0.55);
    final fg = active ? Colors.black : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                active
                    ? Colors.black.withOpacity(0.08)
                    : Colors.white.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              spreadRadius: 0,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.22),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SizePanel extends StatelessWidget {
  const _SizePanel({required this.mode, required this.onSelect});

  final _ScaleMode mode;
  final ValueChanged<_ScaleMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.22),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Size', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DualChoiceButton(
                  title: 'Realistic',
                  subtitle: '1:1 target',
                  selected: mode == _ScaleMode.realistic,
                  onTap: () => onSelect(_ScaleMode.realistic),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DualChoiceButton(
                  title: 'Coffee',
                  subtitle: '~0.35m max',
                  selected: mode == _ScaleMode.coffeeTable,
                  onTap: () => onSelect(_ScaleMode.coffeeTable),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DualChoiceButton extends StatelessWidget {
  const _DualChoiceButton({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.black : Colors.white;
    final fg = selected ? Colors.white : Colors.black;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: fg, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: fg.withOpacity(0.75),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassControl extends StatelessWidget {
  const _CompassControl({
    required this.yaw,
    required this.enabled,
    required this.onYawChanged,
  });

  final double yaw;
  final bool enabled;
  final ValueChanged<double> onYawChanged;

  @override
  Widget build(BuildContext context) {
    const double size = 170;
    final bg =
        enabled
            ? Colors.white.withOpacity(0.95)
            : Colors.white.withOpacity(0.6);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.22),
          ),
        ],
      ),
      child: _CompassDial(
        yaw: yaw,
        enabled: enabled,
        onYawChanged: onYawChanged,
      ),
    );
  }
}

class _CompassDial extends StatefulWidget {
  const _CompassDial({
    required this.yaw,
    required this.enabled,
    required this.onYawChanged,
  });

  final double yaw;
  final bool enabled;
  final ValueChanged<double> onYawChanged;

  @override
  State<_CompassDial> createState() => _CompassDialState();
}

class _CompassDialState extends State<_CompassDial> {
  double _localYaw = 0.0;

  @override
  void initState() {
    super.initState();
    _localYaw = widget.yaw;
  }

  @override
  void didUpdateWidget(covariant _CompassDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    _localYaw = widget.yaw;
  }

  void _handle(Offset localPos, Size size) {
    if (!widget.enabled) return;

    final center = Offset(size.width / 2, size.height / 2);
    final v = localPos - center;

    // angle 0 is up; atan2 gives angle from +x, so rotate by +pi/2
    final raw = math.atan2(v.dy, v.dx) + math.pi / 2;
    setState(() => _localYaw = raw);
    widget.onYawChanged(raw);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final s = Size(c.maxWidth, c.maxHeight);

        return GestureDetector(
          onPanStart: (d) => _handle(d.localPosition, s),
          onPanUpdate: (d) => _handle(d.localPosition, s),
          child: CustomPaint(
            painter: _CompassPainter(yaw: _localYaw, enabled: widget.enabled),
            child: Center(
              child: Text(
                widget.enabled ? 'Rotate' : 'Place model\nfirst',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(widget.enabled ? 0.8 : 0.5),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({required this.yaw, required this.enabled});

  final double yaw;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;

    final ringPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = Colors.black.withOpacity(enabled ? 0.16 : 0.08);

    canvas.drawCircle(center, r - 8, ringPaint);

    final tickPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.black.withOpacity(enabled ? 0.22 : 0.10);

    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * (2 * math.pi);
      final p1 = center + Offset(math.cos(a), math.sin(a)) * (r - 18);
      final p2 =
          center +
          Offset(math.cos(a), math.sin(a)) * (r - (i % 3 == 0 ? 36 : 28));
      canvas.drawLine(p1, p2, tickPaint);
    }

    final pointerPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = Colors.black.withOpacity(enabled ? 0.85 : 0.35);

    final a = yaw - math.pi / 2; // convert back to standard unit circle
    final tip = center + Offset(math.cos(a), math.sin(a)) * (r - 22);
    canvas.drawLine(center, tip, pointerPaint);

    final knobPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.black.withOpacity(enabled ? 0.9 : 0.35);

    canvas.drawCircle(tip, 8, knobPaint);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.yaw != yaw || oldDelegate.enabled != enabled;
  }
}

class _JoystickControl extends StatefulWidget {
  const _JoystickControl({required this.enabled, required this.onChange});

  final bool enabled;

  /// offset is normalized in [-1..1] (dx,dy). active indicates drag active.
  final void Function(Offset offset, bool active) onChange;

  @override
  State<_JoystickControl> createState() => _JoystickControlState();
}

class _JoystickControlState extends State<_JoystickControl> {
  static const double outer = 140;
  static const double inner = 54;

  Offset _knob = Offset.zero;

  void _emit(bool active) {
    final normalized = Offset(
      (_knob.dx / (outer / 2 - inner / 2)).clamp(-1.0, 1.0),
      (_knob.dy / (outer / 2 - inner / 2)).clamp(-1.0, 1.0),
    );
    widget.onChange(normalized, active);
  }

  Offset _clampToCircle(Offset p) {
    final maxR = (outer / 2) - (inner / 2);
    final dist = p.distance;
    if (dist <= maxR) return p;
    final scale = maxR / dist;
    return Offset(p.dx * scale, p.dy * scale);
  }

  @override
  Widget build(BuildContext context) {
    final bg =
        widget.enabled
            ? Colors.white.withOpacity(0.95)
            : Colors.white.withOpacity(0.6);

    return Container(
      width: outer,
      height: outer,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.22),
          ),
        ],
      ),
      child: GestureDetector(
        onPanStart:
            widget.enabled
                ? (d) {
                  setState(() {
                    _knob = _clampToCircle(
                      d.localPosition - const Offset(outer / 2, outer / 2),
                    );
                  });
                  _emit(true);
                  HapticFeedback.selectionClick();
                }
                : null,
        onPanUpdate:
            widget.enabled
                ? (d) {
                  setState(() {
                    _knob = _clampToCircle(
                      d.localPosition - const Offset(outer / 2, outer / 2),
                    );
                  });
                  _emit(true);
                }
                : null,
        onPanEnd:
            widget.enabled
                ? (_) {
                  setState(() {
                    _knob = Offset.zero;
                  });
                  _emit(false);
                }
                : null,
        child: CustomPaint(
          painter: _JoystickPainter(enabled: widget.enabled),
          child: Center(
            child: Transform.translate(
              offset: _knob,
              child: Container(
                width: inner,
                height: inner,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(widget.enabled ? 0.90 : 0.35),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  _JoystickPainter({required this.enabled});
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;

    final ringPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = Colors.black.withOpacity(enabled ? 0.16 : 0.08);

    canvas.drawCircle(center, r - 10, ringPaint);

    final crossPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.black.withOpacity(enabled ? 0.18 : 0.10);

    canvas.drawLine(
      Offset(center.dx - (r - 18), center.dy),
      Offset(center.dx + (r - 18), center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - (r - 18)),
      Offset(center.dx, center.dy + (r - 18)),
      crossPaint,
    );

    final labelStyle = TextStyle(
      color: Colors.black.withOpacity(enabled ? 0.55 : 0.35),
      fontWeight: FontWeight.w800,
      fontSize: 12,
    );

    final tp = TextPainter(
      text: TextSpan(text: enabled ? 'Move' : 'Place first', style: labelStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) =>
      oldDelegate.enabled != enabled;
}
