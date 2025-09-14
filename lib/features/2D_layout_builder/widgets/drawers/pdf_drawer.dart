import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/layout_controller.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/quote_controller.dart';
import 'package:optilay_prototype_app/utils/constants/colors.dart';

class MyPdfDrawer extends StatelessWidget {
  final GlobalKey canvasKey;
  MyPdfDrawer({required this.canvasKey, super.key});

  final layout = Get.find<LayoutController>();
  final quote = Get.find<QuoteController>(); // <- get the quote controller

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Obx(
        () => ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: MyColors.primary),
              child: Text(
                'PDF Tools',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            if (layout.importedLayoutImage.value == null)
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text("Import PDF"),
                onTap: () async {
                  await layout.importPdfAsCanvas();

                  // 👉 If import succeeded, start quoting mode immediately
                  if (layout.importedLayoutImage.value != null) {
                    quote.start();
                    Get.snackbar(
                      'Set Scale',
                      'Drag the quote line to a known distance, then tap "Set Quote".',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.blueGrey.shade700,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 4),
                    );
                  }

                  // close drawer
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            if (layout.importedLayoutImage.value != null)
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text("Export Layout as PDF"),
                enabled:
                    layout.items.isNotEmpty || layout.overlayWidgets.isNotEmpty,
                // lib/features/2D_layout_builder/widgets/drawers/pdf_drawer.dart
                // ...
                onTap:
                    (layout.items.isNotEmpty ||
                            layout.overlayWidgets.isNotEmpty)
                        ? () async {
                          await layout.exportCanvasHighQuality(
                            canvasKey,
                            targetDpi: 300,
                          );
                          if (context.mounted) Navigator.pop(context);
                        }
                        : null,

                // ...
              ),
          ],
        ),
      ),
    );
  }
}
