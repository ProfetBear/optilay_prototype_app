// 📁 lib/features/2D_layout_builder/screens/layout_editor_page.dart
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
      body: InteractiveViewer(
        transformationController: viewerController,
        minScale: 0.5,
        maxScale: 4.0,
        child: Obx(
          () => RepaintBoundary(
            key: _canvasKey,
            child: Stack(
              children: [
                // Canvas background
                Positioned.fill(child: Container(color: Colors.grey.shade200)),
                // PDF background
                if (controller.importedLayotImage.value != null)
                  Positioned.fill(
                    child: Image.memory(
                      controller.importedLayotImage.value!,
                      fit: BoxFit.contain,
                    ),
                  ),
                // Placed SVGs
                ...controller.placedSvgObjects,
                // Quoting tool
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
                              label: controller.realMeasurementLabel.value,
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
                                    controller.quoteLength.value - d.delta.dx;
                                if (newLength >= 50) {
                                  controller.quoteLength.value = newLength;
                                  controller.quotePosition.value += Offset(
                                    d.delta.dx,
                                    0,
                                  );
                                }
                              },
                              behavior: HitTestBehavior.translucent,
                              child: const SizedBox(width: 20, height: 20),
                            ),
                          ),
                          // Right handle
                          Positioned(
                            right: -10,
                            child: GestureDetector(
                              onPanUpdate: (d) {
                                final newLength =
                                    controller.quoteLength.value + d.delta.dx;
                                if (newLength >= 50) {
                                  controller.quoteLength.value = newLength;
                                }
                              },
                              behavior: HitTestBehavior.translucent,
                              child: const SizedBox(width: 20, height: 20),
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
      floatingActionButton: Obx(
        () =>
            controller.quotingMode.value
                ? FloatingActionButton.extended(
                  icon: const Icon(Icons.straighten),
                  label: const Text('Set Quote'),
                  onPressed: _showQuoteInputDialog,
                )
                : FloatingActionButton.extended(
                  icon: const Icon(Icons.add),
                  label: const Text(MyTexts.addMachinery),
                  onPressed:
                      () => controller.addSvgMachinery('assets/crane.svg', 2.0),
                ),
      ),
    );
  }
}
