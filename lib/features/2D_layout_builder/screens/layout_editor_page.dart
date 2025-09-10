import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/widgets/pdf_drawer.dart';
import 'package:optilay_prototype_app/utils/constants/text_strings.dart';

import '../controllers/layout_editor_controller.dart';
import '../widgets/quote_line_painter.dart';

class LayoutEditorPage extends StatefulWidget {
  const LayoutEditorPage({super.key});

  @override
  State<LayoutEditorPage> createState() => _LayoutEditorPageState();
}

class _LayoutEditorPageState extends State<LayoutEditorPage> {
  late final LayoutEditorController controller;
  final TransformationController viewerController = TransformationController();
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    controller = Get.put(LayoutEditorController());
  }

  @override
  void dispose() {
    viewerController.dispose();
    super.dispose();
  }

  Future<void> _showQuoteInputDialog() async {
    final inputController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    double? realLength;

    await Get.dialog(
      AlertDialog(
        title: const Text('Real-world Length'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: inputController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Length (m)'),
            validator: (value) {
              final input = double.tryParse(value ?? '');
              if (input == null || input <= 0) {
                return 'Enter a valid number > 0';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                realLength = double.parse(inputController.text);
                Get.back();
              } else {
                Get.snackbar(
                  'Invalid Input',
                  'Please enter a valid length greater than 0.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.shade600,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );

    // Delay disposal to avoid controller-use-after-dispose error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      inputController.dispose();
    });

    if (realLength != null) {
      controller.setReferenceScale(realLength!);
    }
  }

  // Maps a viewport (screen) point into the canvas (scene) coordinates.
  Offset _viewportToScene(Offset viewportPoint) {
    final matrix = viewerController.value;
    final inverse = Matrix4.inverted(matrix);
    final scenePoint = MatrixUtils.transformPoint(inverse, viewportPoint);
    return scenePoint;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: MyPdfDrawer(canvasKey: _canvasKey),
      appBar: AppBar(
        title: const Text(MyTexts.layoutEditorTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );

          return Stack(
            children: [
              InteractiveViewer(
                transformationController: viewerController,
                minScale: 0.5,
                maxScale: 4.0,
                child: Obx(
                  () => RepaintBoundary(
                    key: _canvasKey,
                    child: Stack(
                      children: [
                        // Canvas background
                        Positioned.fill(
                          child: Container(color: Colors.grey.shade200),
                        ),

                        // PDF background
                        if (controller.importedLayotImage.value != null)
                          Positioned.fill(
                            child: Image.memory(
                              controller.importedLayotImage.value!,
                              fit: BoxFit.contain,
                            ),
                          ),

                        // Placed machinery (built from model list)
                        ...controller.buildPlacedMachineryWidgets(),
                        // Quoting tool (interactive)
                        if (controller.quotingMode.value)
                          Positioned(
                            left: controller.quotePosition.value.dx,
                            top: controller.quotePosition.value.dy,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                controller.quotePosition.value += details.delta;
                              },
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  SizedBox(
                                    width: controller.quoteLength.value,
                                    height: 30,
                                  ),
                                  CustomPaint(
                                    painter: QuotePainter(
                                      controller.quoteLength.value,
                                      label:
                                          controller.realMeasurementLabel.value,
                                    ),
                                    child: SizedBox(
                                      width: controller.quoteLength.value,
                                      height: 30,
                                    ),
                                  ),
                                  // Left handle
                                  Positioned(
                                    left: -10,
                                    child: GestureDetector(
                                      onPanUpdate: (d) {
                                        final newLength =
                                            controller.quoteLength.value -
                                            d.delta.dx;
                                        if (newLength >= 50) {
                                          controller.quoteLength.value =
                                              newLength;
                                          controller
                                              .quotePosition
                                              .value += Offset(d.delta.dx, 0);
                                        }
                                      },
                                      behavior: HitTestBehavior.translucent,
                                      child: const SizedBox(
                                        width: 20,
                                        height: 20,
                                      ),
                                    ),
                                  ),
                                  // Right handle
                                  Positioned(
                                    right: -10,
                                    child: GestureDetector(
                                      onPanUpdate: (d) {
                                        final newLength =
                                            controller.quoteLength.value +
                                            d.delta.dx;
                                        if (newLength >= 50) {
                                          controller.quoteLength.value =
                                              newLength;
                                        }
                                      },
                                      behavior: HitTestBehavior.translucent,
                                      child: const SizedBox(
                                        width: 20,
                                        height: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ---- Placement HUD (overlay) ----
              // Appears when a machinery is being staged. It is drawn in viewport
              // coordinates (on top of the InteractiveViewer) so the user can pan/zoom
              // the canvas underneath to position the machinery relatively.
              Obx(() {
                final staged = controller.stagingItem.value;
                if (staged == null) return const SizedBox.shrink();

                final px = controller.pixelSizeFor(staged.realWorldSize);
                return Positioned.fill(
                  child: IgnorePointer(
                    ignoring:
                        false, // allow taps to pass except on our HUD area
                    child: Stack(
                      children: [
                        // Guidance banner
                        Positioned(
                          left: 16,
                          right: 16,
                          top: 16,
                          child: Material(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                controller.scaleSet.value
                                    ? 'Drag the canvas to line up the machinery, then press Confirm.'
                                    : 'You can pan/zoom. Import a PDF and set a scale to use real sizing.',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),

                        // Centered preview "ghost" + crosshair
                        Center(
                          child: IgnorePointer(
                            ignoring: true,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // crosshair
                                CustomPaint(
                                  size: Size(px + 40, px + 40),
                                  painter: _CrosshairPainter(),
                                ),
                                // ghost machinery preview
                                Opacity(
                                  opacity: 0.9,
                                  child: SizedBox(
                                    width: px,
                                    height: px,
                                    child: controller.buildSvgFor(staged),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
      // ---- FABs ----
      floatingActionButton: Obx(() {
        // Quoting Mode: ask for real-world length
        if (controller.quotingMode.value) {
          return FloatingActionButton.extended(
            icon: const Icon(Icons.straighten),
            label: const Text('Set Quote'),
            onPressed: _showQuoteInputDialog,
          );
        }

        // Placement Mode: Confirm / Cancel
        if (controller.stagingItem.value != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'confirm_place',
                icon: const Icon(Icons.check),
                label: const Text('Confirm'),
                onPressed: () {
                  // Convert viewport center to scene coordinate
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;

                  final viewportSize = renderBox.size;
                  final centerViewport = Offset(
                    viewportSize.width / 2,
                    viewportSize.height / 2,
                  );
                  final scenePoint = _viewportToScene(centerViewport);

                  controller.confirmPlacementAtSceneCenter(
                    scenePoint: scenePoint,
                  );
                },
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'cancel_place',
                backgroundColor: Colors.grey.shade700,
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                onPressed: controller.cancelPlacement,
              ),
            ],
          );
        }

        // Default: Add Machinery
        return FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text(MyTexts.addMachinery),
          onPressed: () {
            // You can swap these params with a picker later
            controller.startAddMachinery(
              assetPath: 'assets/crane.svg',
              realWorldSizeMeters: 2.0,
            );
          },
        );
      }),
    );
  }
}

// Simple crosshair painter for the placement HUD
class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black54
          ..strokeWidth = 1;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Outer box (light)
    final boxPaint =
        Paint()
          ..color = Colors.black26
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width,
        height: size.height,
      ),
      boxPaint,
    );

    // Crosshair lines
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
