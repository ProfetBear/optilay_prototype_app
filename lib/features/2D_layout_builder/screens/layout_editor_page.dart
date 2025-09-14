import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/data/pdf_export.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/data/pdf_import.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/data/pdf_picker.dart';

import 'package:optilay_prototype_app/utils/constants/text_strings.dart';
import '../controllers/layout_controller.dart';
import '../controllers/quote_controller.dart';
import '../controllers/placement_controller.dart';

// servizi IO per l'injection del LayoutController
import '../widgets/painters/quote_line_painter.dart';
import '../widgets/drawers/pdf_drawer.dart';

class LayoutEditorPage extends StatefulWidget {
  const LayoutEditorPage({super.key});

  @override
  State<LayoutEditorPage> createState() => _LayoutEditorPageState();
}

class _LayoutEditorPageState extends State<LayoutEditorPage> {
  late final LayoutController layout;
  late final QuoteController quote;
  late final PlacementController place;

  final TransformationController viewerController = TransformationController();
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // Inietto i servizi nel LayoutController
    layout = Get.put(
      LayoutController(
        PdfImportService(),
        FilePickerService(),
        ExportService(),
      ),
    );
    quote = Get.put(QuoteController(layout));
    place = Get.put(PlacementController(layout));
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
      quote.setRealLengthMeters(realLength!);
    }
  }

  // Mappa un punto viewport -> coordinate scena (per confermare il placement al centro)
  Offset _viewportToScene(Offset viewportPoint) {
    final matrix = viewerController.value;
    final inverse = Matrix4.inverted(matrix);
    return MatrixUtils.transformPoint(inverse, viewportPoint);
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
              // ---------- Canvas con zoom/pan ----------
              InteractiveViewer(
                transformationController: viewerController,
                minScale: 0.5,
                maxScale: 4.0,
                child: Obx(
                  () => RepaintBoundary(
                    key: _canvasKey,
                    child: Stack(
                      children: [
                        // Fondo canvas
                        Positioned.fill(
                          child: Container(color: Colors.grey.shade200),
                        ),

                        // Background PDF importato (se presente)
                        if (layout.importedLayoutImage.value != null)
                          Positioned.fill(
                            child: Image.memory(
                              layout.importedLayoutImage.value!,
                              fit: BoxFit.contain,
                            ),
                          ),

                        // Layer macchinari + overlay fissi
                        ...[
                          for (final m in layout.items)
                            Positioned(
                              left: m.topLeftScene.dx,
                              top: m.topLeftScene.dy,
                              child: SizedBox(
                                width: layout.pixelSizeFor(
                                  m.realWorldSizeMeters,
                                ),
                                height: layout.pixelSizeFor(
                                  m.realWorldSizeMeters,
                                ),
                                child: SvgPicture.asset(
                                  m.assetPath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ...layout.overlayWidgets,
                        ],

                        // Strumento di quoting interattivo
                        if (quote.quotingMode.value)
                          Positioned(
                            left: quote.quotePosition.value.dx,
                            top: quote.quotePosition.value.dy,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                quote.quotePosition.value += details.delta;
                              },
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  SizedBox(
                                    width: quote.quoteLengthPx.value,
                                    height: 30,
                                  ),
                                  CustomPaint(
                                    painter: QuotePainter(
                                      quote.quoteLengthPx.value,
                                      label: quote.realLabel.value,
                                    ),
                                    child: SizedBox(
                                      width: quote.quoteLengthPx.value,
                                      height: 30,
                                    ),
                                  ),
                                  // Handle sinistro
                                  Positioned(
                                    left: -10,
                                    child: GestureDetector(
                                      onPanUpdate: (d) {
                                        final newLength =
                                            quote.quoteLengthPx.value -
                                            d.delta.dx;
                                        if (newLength >= 50) {
                                          quote.quoteLengthPx.value = newLength;
                                          quote.quotePosition.value += Offset(
                                            d.delta.dx,
                                            0,
                                          );
                                        }
                                      },
                                      behavior: HitTestBehavior.translucent,
                                      child: const SizedBox(
                                        width: 20,
                                        height: 20,
                                      ),
                                    ),
                                  ),
                                  // Handle destro
                                  Positioned(
                                    right: -10,
                                    child: GestureDetector(
                                      onPanUpdate: (d) {
                                        final newLength =
                                            quote.quoteLengthPx.value +
                                            d.delta.dx;
                                        if (newLength >= 50) {
                                          quote.quoteLengthPx.value = newLength;
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

              // ---------- Placement HUD: anteprima centrata che scala con lo zoom ----------
              AnimatedBuilder(
                animation: viewerController,
                builder: (_, __) {
                  final staged = place.staging.value;
                  if (staged == null) return const SizedBox.shrink();

                  final scenePixels = layout.pixelSizeFor(
                    staged.realWorldSizeMeters,
                  );
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
                            child: SvgPicture.asset(
                              staged.assetPath,
                              fit: BoxFit.contain,
                            ),
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
        if (quote.quotingMode.value) {
          return FloatingActionButton.extended(
            icon: const Icon(Icons.straighten),
            label: const Text('Set Quote'),
            onPressed: _showQuoteInputDialog,
          );
        }

        // Placement Mode: Confirm / Cancel
        if (place.staging.value != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'confirm_place',
                icon: const Icon(Icons.check),
                label: const Text('Confirm'),
                onPressed: () {
                  // Punto scena sotto il centro del viewport
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final size = box.size;
                  final centerViewport = Offset(
                    size.width / 2,
                    size.height / 2,
                  );
                  final scenePoint = _viewportToScene(centerViewport);
                  place.confirmAtSceneCenter(scenePoint);
                },
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'cancel_place',
                backgroundColor: Colors.grey.shade700,
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                onPressed: place.cancel,
              ),
            ],
          );
        }

        // Default: Add Machinery
        return FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text(MyTexts.addMachinery),
          onPressed: () {
            place.startAdd(assetPath: 'assets/crane.svg', sizeMeters: 2.0);
          },
        );
      }),
    );
  }
}
