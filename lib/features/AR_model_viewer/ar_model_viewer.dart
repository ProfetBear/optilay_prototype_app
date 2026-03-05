import 'dart:math' as math;

import 'package:arkit_plugin/arkit_plugin.dart';
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

/// Centralized movement remap.
/// Change this to match what "feels correct" in your current model coordinate situation.
enum _MovementAxisMode {
  /// Joystick X -> world X, Joystick Y -> world Z
  standardXZ,

  /// Joystick X -> world Y, Joystick Y -> world Z  (your current "X is Y really" feeling)
  swapXY_keepZ,

  /// Joystick X -> world X, Joystick Y -> world Y
  xyPlane,

  /// Joystick X -> world Z, Joystick Y -> world X
  swapXZ,
}

class _ManipulationPageState extends State<ManipulationPage> {
  late ARKitController arkitController;

  bool _withoutHull = false;

  _ScaleMode _scaleMode = _ScaleMode.coffeeTable;

  ARKitNode? _containerNode;
  ARKitGltfNode? _glbNode;

  bool _hasAnyPlane = false;
  final Map<String, _PlaneViz> _planes = {};

  // Bottom controls state
  bool _showSizePanel = false;
  bool _showCompass = false;
  bool _showJoystick = false;
  bool _showHeight = false;

  // Rotation (applied to X axis as requested earlier)
  double _angleX = 0.0;

  // Height slider value in meters (applied to chosen "height axis")
  double _heightMeters = 0.0;

  // ---------- TUNABLES ----------
  static const double _coffeeTableLargestMeters = 0.15;

  // Increase movement speed in Move mode
  // (was 0.008 — bumping a lot; tune freely)
  double _moveSpeed = 0.03;

  // Axis mapping for joystick movement
  _MovementAxisMode _movementAxisMode = _MovementAxisMode.swapXY_keepZ;

  // Height axis: you said "X(which is Y really)". Keep as X for now (can change below).
  // If you want height to be world Y instead, change to: _applyHeightOnWorldY
  final bool _applyHeightOnWorldX = true;

  final Map<String, double> _realisticLargestByAsset = const {
    'assets/ValiantRev11.glb': 10.0,
    'assets/XBladeRev1.glb': 15.0,
    'assets/GeminiRev0.glb': 12.0,
  };

  String _withoutHullAsset(String assetPath) {
    final extIndex = assetPath.lastIndexOf('.glb');
    if (extIndex == -1) return assetPath;
    return assetPath.replaceRange(extIndex, extIndex, '_WithoutHull');
  }

  String _currentAssetPath() {
    return _withoutHull
        ? _withoutHullAsset(widget.assetPath)
        : widget.assetPath;
  }

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  Future<void> _replaceModel() async {
    if (_containerNode == null) return;

    if (_glbNode != null) {
      await arkitController.remove(_glbNode!.name);
    }

    final asset = _currentAssetPath();

    _glbNode = ARKitGltfNode(
      name: asset,
      assetType: AssetType.flutterAsset,
      url: asset,
      position: vector.Vector3.zero(),
      scale: vector.Vector3.all(1.0),
    );

    await arkitController.add(_glbNode!, parentNodeName: _containerNode!.name);

    Future.delayed(const Duration(milliseconds: 260), () async {
      if (!mounted || _glbNode == null) return;
      await _applyScaleMode();
    });
  }

  void _closeOtherPanels(String keep) {
    setState(() {
      if (keep != 'size') _showSizePanel = false;
      if (keep != 'rotate') _showCompass = false;
      if (keep != 'move') _showJoystick = false;
      if (keep != 'height') _showHeight = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

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
                  setState(() => _withoutHull = value);
                  if (_containerNode != null) {
                    await _replaceModel();
                  }
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
            enableTapRecognizer: false,
            enablePinchRecognizer: false,
            enablePanRecognizer: false,
            enableRotationRecognizer: false,
            onARKitViewCreated: _onARKitViewCreated,
          ),

          // Banner
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + bottomSafe + 72, // keep above controls
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: 1.0,
              child:
                  _hasAnyPlane
                      ? _Banner(
                        color: Colors.green.withOpacity(0.9),
                        text:
                            _containerNode == null
                                ? 'Plane detected — placing model…'
                                : 'Use controls to rotate/move/scale',
                        icon: Icons.grid_on,
                      )
                      : _Banner(
                        color: Colors.black.withOpacity(0.7),
                        text: 'Move your device to detect a horizontal surface',
                        icon: Icons.phone_iphone,
                      ),
            ),
          ),

          // Panels (bottom-center, above buttons)
          if (_showSizePanel)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomSafe + 72 + 14,
              child: Center(
                child: _SizePanel(
                  mode: _scaleMode,
                  enabled: _containerNode != null,
                  onSelect: (m) async {
                    setState(() => _scaleMode = m);
                    await _applyScaleMode();
                  },
                ),
              ),
            ),

          if (_showCompass)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomSafe + 72 + 14,
              child: Center(
                child: _CompassControl(
                  yaw: _angleX,
                  enabled: _containerNode != null,
                  onYawChanged: (a) => _setAngleX(a),
                ),
              ),
            ),

          if (_showHeight)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomSafe + 72 + 14,
              child: Center(
                child: _HeightPanel(
                  enabled: _containerNode != null,
                  valueMeters: _heightMeters,
                  onChanged: (v) => _setHeightMeters(v),
                  onReset: () => _setHeightMeters(0.0),
                ),
              ),
            ),

          if (_showJoystick)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomSafe + 72 + 14,
              child: Center(
                child: _JoystickControl(
                  enabled: _containerNode != null,
                  onChange: (offset, active) {
                    if (!active) return;
                    _applyJoystickTranslation(offset);
                  },
                ),
              ),
            ),

          // Bottom-center control bar
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomSafe + 14,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionPillButton(
                      icon: Icons.straighten,
                      label: 'Size',
                      active: _showSizePanel,
                      onTap: () {
                        setState(() => _showSizePanel = !_showSizePanel);
                        _closeOtherPanels(_showSizePanel ? 'size' : '');
                      },
                    ),
                    const SizedBox(width: 10),
                    _ActionPillButton(
                      icon: Icons.explore,
                      label: 'Rotate',
                      active: _showCompass,
                      onTap: () {
                        setState(() => _showCompass = !_showCompass);
                        _closeOtherPanels(_showCompass ? 'rotate' : '');
                      },
                    ),
                    const SizedBox(width: 10),
                    _ActionPillButton(
                      icon: Icons.sports_esports,
                      label: 'Move',
                      active: _showJoystick,
                      onTap: () {
                        setState(() => _showJoystick = !_showJoystick);
                        _closeOtherPanels(_showJoystick ? 'move' : '');
                      },
                    ),
                    const SizedBox(width: 10),
                    _ActionPillButton(
                      icon: Icons.height,
                      label: 'Height',
                      active: _showHeight,
                      onTap: () {
                        setState(() => _showHeight = !_showHeight);
                        _closeOtherPanels(_showHeight ? 'height' : '');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onARKitViewCreated(ARKitController controller) {
    arkitController = controller;

    arkitController.onAddNodeForAnchor = (anchor) async {
      if (anchor is! ARKitPlaneAnchor) return;
      _addPlaneViz(anchor);

      if (_containerNode == null) {
        await _placeOnPlaneAnchor(anchor);
      }
    };

    arkitController.onUpdateNodeForAnchor = (anchor) {
      if (anchor is! ARKitPlaneAnchor) return;
      _updatePlaneViz(anchor);
    };
  }

  void _addPlaneViz(ARKitPlaneAnchor anchor) {
    final plane = ARKitPlane(
      width: anchor.extent.x,
      height: anchor.extent.z,
      materials: [
        ARKitMaterial(
          transparency: 0.30,
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

  Future<void> _placeOnPlaneAnchor(ARKitPlaneAnchor anchor) async {
    _containerNode = ARKitNode(
      name: 'model_container',
      position: vector.Vector3(anchor.center.x, 0, anchor.center.z),
      eulerAngles: vector.Vector3(_angleX, 0, 0),
    );

    await arkitController.add(_containerNode!, parentNodeName: anchor.nodeName);

    final asset = _currentAssetPath();
    _glbNode = ARKitGltfNode(
      name: asset,
      assetType: AssetType.flutterAsset,
      url: asset,
      position: vector.Vector3.zero(),
      scale: vector.Vector3.all(1.0),
    );

    await arkitController.add(_glbNode!, parentNodeName: _containerNode!.name);

    _planes.forEach((_, viz) => arkitController.remove(viz.node.name));
    _planes.clear();

    Future.delayed(const Duration(milliseconds: 300), () async {
      if (!mounted || _glbNode == null) return;
      await _applyScaleMode();
      if (mounted) setState(() {});
    });

    setState(() {});
  }

  double _realisticTargetLargestMetersFor(String assetPath) {
    final exact = _realisticLargestByAsset[assetPath];
    if (exact != null) return exact;

    final lower = assetPath.toLowerCase();
    if (lower.contains('valiant')) return 10.0;
    if (lower.contains('xblade')) return 15.0;
    if (lower.contains('gemini')) return 12.0;

    return 2.0;
  }

  Future<void> _applyScaleMode() async {
    if (_glbNode == null) return;

    final assetKey = _glbNode!.name;
    final targetLargest =
        _scaleMode == _ScaleMode.coffeeTable
            ? _coffeeTableLargestMeters
            : _realisticTargetLargestMetersFor(assetKey);

    _glbNode!.scale = vector.Vector3.all(1.0);
    _glbNode!.position = vector.Vector3.zero();

    final bbox = await _getBoundingBoxWithRetries(_glbNode!, retries: 8);
    if (bbox == null || bbox.length < 2) return;

    final min = bbox[0];
    final max = bbox[1];

    final sx = (max.x - min.x).abs();
    final sy = (max.y - min.y).abs();
    final sz = (max.z - min.z).abs();

    final largest = [sx, sy, sz].reduce((a, b) => a > b ? a : b);
    if (largest <= 1e-6) return;

    final s = (targetLargest / largest).clamp(0.0005, 120.0);
    _glbNode!.scale = vector.Vector3.all(s);

    final yShift = (-min.y * s);
    _glbNode!.position = vector.Vector3(0, yShift, 0);

    HapticFeedback.selectionClick();
    if (mounted) setState(() {});
  }

  Future<List<vector.Vector3>?> _getBoundingBoxWithRetries(
    ARKitNode node, {
    int retries = 6,
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        final bbox = await arkitController.getNodeBoundingBox(node);
        if (bbox.length >= 2) return bbox;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 140));
    }
    return null;
  }

  void _setAngleX(double angle) {
    if (_containerNode == null) return;

    final normalized = _normalizeRadians(angle);
    _containerNode!.eulerAngles = vector.Vector3(
      normalized,
      _containerNode!.eulerAngles.y,
      _containerNode!.eulerAngles.z,
    );

    setState(() => _angleX = normalized);
  }

  double _normalizeRadians(double a) {
    var x = a;
    while (x > math.pi) x -= 2 * math.pi;
    while (x < -math.pi) x += 2 * math.pi;
    return x;
  }

  void _setHeightMeters(double newHeight) {
    if (_containerNode == null) {
      setState(() => _heightMeters = newHeight);
      return;
    }

    final delta = newHeight - _heightMeters;
    final pos = _containerNode!.position;

    // Apply delta on world X (or change to world Y if you prefer)
    _containerNode!.position =
        _applyHeightOnWorldX
            ? vector.Vector3(pos.x + delta, pos.y, pos.z)
            : vector.Vector3(pos.x, pos.y + delta, pos.z);

    setState(() => _heightMeters = newHeight);
  }

  // ✅ This is where you change the axis of movement.
  // Pick the mapping that feels right for your model frame.
  void _applyJoystickTranslation(Offset offset) {
    if (_containerNode == null) return;

    final pos = _containerNode!.position;
    final s = _moveSpeed;

    // NOTE: dy is offset.dy in screen space. If you want "up" to go forward, invert it:
    // final oy = -offset.dy;
    final ox = offset.dx;
    final oy = offset.dy;

    switch (_movementAxisMode) {
      case _MovementAxisMode.standardXZ:
        {
          final dx = ox * s;
          final dz = oy * s;
          _containerNode!.position = vector.Vector3(
            pos.x + dx,
            pos.y,
            pos.z + dz,
          );
          break;
        }
      case _MovementAxisMode.swapXY_keepZ:
        {
          final dy = ox * s;
          final dz = oy * s;
          _containerNode!.position = vector.Vector3(
            pos.x,
            pos.y + dy,
            pos.z + dz,
          );
          break;
        }
      case _MovementAxisMode.xyPlane:
        {
          final dx = ox * s;
          final dy = oy * s;
          _containerNode!.position = vector.Vector3(
            pos.x + dx,
            pos.y + dy,
            pos.z,
          );
          break;
        }
      case _MovementAxisMode.swapXZ:
        {
          final dz = ox * s;
          final dx = oy * s;
          _containerNode!.position = vector.Vector3(
            pos.x + dx,
            pos.y,
            pos.z + dz,
          );
          break;
        }
    }
  }
}

class _PlaneViz {
  _PlaneViz({required this.plane, required this.node});
  final ARKitPlane plane;
  final ARKitNode node;
}

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
            color: Colors.white.withOpacity(active ? 0.0 : 0.12),
          ),
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
  const _SizePanel({
    required this.mode,
    required this.enabled,
    required this.onSelect,
  });

  final _ScaleMode mode;
  final bool enabled;
  final ValueChanged<_ScaleMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(enabled ? 0.95 : 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
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
                  enabled: enabled,
                  onTap: () => onSelect(_ScaleMode.realistic),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DualChoiceButton(
                  title: 'Coffee',
                  subtitle: '~0.15m max',
                  selected: mode == _ScaleMode.coffeeTable,
                  enabled: enabled,
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
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.black : Colors.white;
    final fg = selected ? Colors.white : Colors.black;

    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: InkWell(
        onTap: enabled ? onTap : null,
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
      ),
    );
  }
}

class _HeightPanel extends StatelessWidget {
  const _HeightPanel({
    required this.enabled,
    required this.valueMeters,
    required this.onChanged,
    required this.onReset,
  });

  final bool enabled;
  final double valueMeters;
  final ValueChanged<double> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(enabled ? 0.95 : 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Height',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: enabled ? onReset : null,
                child: const Text('Reset'),
              ),
            ],
          ),
          Text(
            '${valueMeters.toStringAsFixed(2)} m',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          Slider(
            value: valueMeters.clamp(-1.0, 1.0),
            min: -1.0,
            max: 1.0,
            divisions: 200,
            onChanged: enabled ? onChanged : null,
          ),
        ],
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
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(enabled ? 0.95 : 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
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
                widget.enabled ? 'Rotate' : 'Place\nfirst',
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

    final a = yaw - math.pi / 2;
    final tip = center + Offset(math.cos(a), math.sin(a)) * (r - 22);
    canvas.drawLine(center, tip, pointerPaint);

    final knobPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.black.withOpacity(enabled ? 0.9 : 0.35);
    canvas.drawCircle(tip, 8, knobPaint);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.yaw != yaw || oldDelegate.enabled != enabled;
}

class _JoystickControl extends StatefulWidget {
  const _JoystickControl({required this.enabled, required this.onChange});

  final bool enabled;
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
                  setState(() => _knob = Offset.zero);
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
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) =>
      oldDelegate.enabled != enabled;
}
