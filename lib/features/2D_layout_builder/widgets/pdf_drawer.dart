// 📁 lib/features/2D_layout_builder/widgets/pdf_drawer.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/layout_editor_controller.dart';

class MyPdfDrawer extends StatelessWidget {
  final GlobalKey canvasKey;
  MyPdfDrawer({required this.canvasKey, super.key});

  final controller = Get.find<LayoutEditorController>();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Obx(
        () => ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'PDF Tools',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            if (controller.importedLayotImage.value == null)
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text("Import PDF"),
                onTap: () async {
                  await controller.importPdfAsCanvas();
                  Navigator.pop(context);
                },
              ),
            if (controller.importedLayotImage.value != null)
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text("Export Layout as PDF"),
                enabled: controller.canExport,
                onTap:
                    controller.canExport
                        ? () {
                          controller.exportCanvasAsPdf(canvasKey);
                          Navigator.pop(context);
                        }
                        : null,
              ),
          ],
        ),
      ),
    );
  }
}
