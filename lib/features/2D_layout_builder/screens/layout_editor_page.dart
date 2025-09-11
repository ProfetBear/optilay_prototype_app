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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      inputController.dispose();
    });

    if (realLength != null) {
      controller.setReferenceScale(realLength!);
    }
  }

  // Map a viewport (screen) point into the canvas (scene) coordinates.
  Offset _viewportToScene(Offset viewportPoint) {
    final matrix = viewerController.value;
    final inverse = Matrix4.inverted(matrix);
    return MatrixUtils.transformPoint(inverse, viewportPoint);
  }

  // Current zoom factor applied by InteractiveViewer (uniform).
  double _currentZoom() {
    // Matrix4.getMaxScaleOnAxis() is available in vector_math.
    return viewerController.value.getMaxScaleOnAxis();
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
          return Stack(
            children: [
              // ---------- Canvas with zoom/pan ----------
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

                        // Placed machinery (transformed by InteractiveViewer)
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

              // ---------- Placement HUD: centered preview that scales with zoom ----------
              AnimatedBuilder(
                animation: viewerController, // listens to pan/zoom changes
                builder: (_, __) {
                  final staged = controller.stagingItem.value;
                  if (staged == null) return const SizedBox.shrink();

                  // Size in scene pixels based on your quote scale
                  final scenePixels = controller.pixelSizeFor(
                    staged.realWorldSize,
                  );

                  // Current zoom from the InteractiveViewer matrix
                  final zoom = viewerController.value.getMaxScaleOnAxis();
                  final screenPixels = scenePixels * zoom;

                  return Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Center(
                        child: SizedBox(
                          width: screenPixels,
                          height: screenPixels,
                          child: Opacity(
                            opacity: 0.95,
                            child: controller.buildSvgFor(staged),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),

      // ---------- FABs ----------
      floatingActionButton: Obx(() {
        // Quoting Mode
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
                  // Put item at the scene point under the viewport center
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final size = box.size;
                  final centerViewport = Offset(
                    size.width / 2,
                    size.height / 2,
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
