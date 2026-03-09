// lib/features/2D_layout_builder/widgets/drawers/pdf_drawer.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/layout_controller.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/placement_controller.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/controllers/quote_controller.dart';

class MyPdfDrawer extends StatelessWidget {
  const MyPdfDrawer({super.key, required this.canvasKey});

  final GlobalKey canvasKey;

  @override
  Widget build(BuildContext context) {
    final layout = Get.find<LayoutController>();
    final quote = Get.find<QuoteController>();
    final place = Get.find<PlacementController>();

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const ListTile(
              title: Text(
                'Layout Tools',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Import PDF'),
              onTap: () async {
                Navigator.of(context).pop();
                await layout.importPdfAsCanvas();
              },
            ),
            ListTile(
              leading: const Icon(Icons.straighten),
              title: const Text('Start Calibration'),
              onTap: () {
                Navigator.of(context).pop();
                quote.start();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Add Machinery'),
              subtitle: const Text('Sample crane.svg 2m x 2m'),
              onTap: () {
                Navigator.of(context).pop();
                place.startAdd(
                  assetPath: 'assets/crane.svg',
                  widthMeters: 2.0,
                  heightMeters: 2.0,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: const Text('Export HQ PDF'),
              onTap: () async {
                Navigator.of(context).pop();
                await layout.exportCanvasHighQuality(canvasKey);
              },
            ),
          ],
        ),
      ),
    );
  }
}
