import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/utils/constants/text_strings.dart';

class LayoutViewerPage extends StatelessWidget {
  const LayoutViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(MyTexts.layoutViewerTitle)),
      body: Center(
        child: InteractiveViewer(
          // zoom & pan
          minScale: 0.2,
          maxScale: 8.0,
          panEnabled: true,
          scaleEnabled: true,
          // let user pan even if the SVG is smaller than the screen
          boundaryMargin: const EdgeInsets.all(1000),
          clipBehavior: Clip.none,
          child: SvgPicture.asset(
            'assets/crane.svg',
            // give it a reasonable base size; adjust if you want
            width: 400,
            height: 400,
            fit: BoxFit.contain,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text('Importa PDF'),
        onPressed: () => Get.toNamed('/layout_editor'),
      ),
    );
  }
}
