// lib/features/2D_layout_builder/screens/layout_editor_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/layout_controller.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/placement_controller.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/quote_controller.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/data/pdf_export.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/data/pdf_import.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/data/pdf_picker.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/widgets/canvas/machineries_layers.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/widgets/canvas/placement_hud.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/widgets/drawers/pdf_drawer.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/widgets/painters/quote_line_painter.dart';
import 'package:optilay_prototype_app/utils/constants/text_strings.dart';

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
  final GlobalKey canvasKey = GlobalKey();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  bool _didHandleInitialArgs = false;

  @override
  void initState() {
    super.initState();

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
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didHandleInitialArgs) return;
    _didHandleInitialArgs = true;

    final args = (Get.arguments as Map?) ?? {};
    final bool autoImportPdf = (args['autoImportPdf'] as bool?) ?? false;

    if (autoImportPdf) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await layout.importPdfAsCanvas();
      });
    }
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                realLength = double.parse(inputController.text);
                Get.back();
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );

    inputController.dispose();

    if (realLength != null) {
      quote.setRealLengthMeters(realLength!);
    }
  }

  Offset _viewportToScene(Offset viewportPoint) {
    final matrix = viewerController.value;
    final inverse = Matrix4.inverted(matrix);
    return MatrixUtils.transformPoint(inverse, viewportPoint);
  }

  void _confirmPlacement() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = box.size;
    final centerViewport = Offset(size.width / 2, size.height / 2);
    final scenePoint = _viewportToScene(centerViewport);
    place.confirmAtSceneCenter(scenePoint);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      endDrawer: MyPdfDrawer(canvasKey: canvasKey),
      appBar: AppBar(
        title: const Text(MyTexts.layoutEditorTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: Obx(
        () => Stack(
          children: [
            InteractiveViewer(
              transformationController: viewerController,
              minScale: 0.2,
              maxScale: 8.0,
              boundaryMargin: const EdgeInsets.all(1500),
              clipBehavior: Clip.none,
              child: RepaintBoundary(
                key: canvasKey,
                child: SizedBox(
                  width: layout.scenePixelSize.width,
                  height: layout.scenePixelSize.height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(color: Colors.grey.shade200),
                      ),
                      Positioned.fill(
                        child: CustomPaint(painter: _GridPainter()),
                      ),
                      if (layout.importedLayoutImage.value != null)
                        Positioned.fill(
                          child: Image.memory(
                            layout.importedLayoutImage.value!,
                            fit: BoxFit.fill,
                          ),
                        ),
                      MachineriesLayer(layout: layout),
                      if (quote.quotingMode.value)
                        Positioned(
                          left: quote.quotePosition.value.dx,
                          top: quote.quotePosition.value.dy,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              quote.moveWholeQuote(details.delta);
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
                                Positioned(
                                  left: -10,
                                  child: GestureDetector(
                                    onPanUpdate: (d) {
                                      quote.dragLeftHandle(d.delta.dx);
                                    },
                                    behavior: HitTestBehavior.translucent,
                                    child: const SizedBox(
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -10,
                                  child: GestureDetector(
                                    onPanUpdate: (d) {
                                      quote.dragRightHandle(d.delta.dx);
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
            PlacementHud(
              pc: place,
              viewerController: viewerController,
              widthPixelsFor: layout.pixelSizeFor,
              heightPixelsFor: layout.pixelSizeFor,
            ),
          ],
        ),
      ),
      floatingActionButton: Obx(() {
        if (quote.quotingMode.value) {
          return FloatingActionButton.extended(
            heroTag: 'set_quote',
            icon: const Icon(Icons.straighten),
            label: const Text('Set Quote'),
            onPressed: _showQuoteInputDialog,
          );
        }

        if (place.staging.value != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'confirm_place',
                icon: const Icon(Icons.check),
                label: const Text('Confirm'),
                onPressed: _confirmPlacement,
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

        return FloatingActionButton.extended(
          heroTag: 'add_machine',
          icon: const Icon(Icons.add),
          label: const Text(MyTexts.addMachinery),
          onPressed: () {
            place.startAdd(
              assetPath: 'assets/crane.svg',
              widthMeters: 2.0,
              heightMeters: 2.0,
            );
          },
        );
      }),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 100.0;

    final minorPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.04)
          ..strokeWidth = 1;

    final majorPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.08)
          ..strokeWidth = 1.2;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        (x % (step * 5) == 0) ? majorPaint : minorPaint,
      );
    }

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        (y % (step * 5) == 0) ? majorPaint : minorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
