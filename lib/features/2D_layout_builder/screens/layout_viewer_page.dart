// lib/features/2D_layout_builder/pages/layout_viewer_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/utils/constants/text_strings.dart';

class LayoutViewerPage extends StatefulWidget {
  const LayoutViewerPage({super.key});

  @override
  State<LayoutViewerPage> createState() => _LayoutViewerPageState();
}

class _LayoutViewerPageState extends State<LayoutViewerPage> {
  final TransformationController _viewerController = TransformationController();

  @override
  void dispose() {
    _viewerController.dispose();
    super.dispose();
  }

  void _resetView() {
    _viewerController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final assetPath = (args?['assetPath'] as String?) ?? 'assets/crane.svg';
    final title = (args?['title'] as String?) ?? MyTexts.layoutViewerTitle;
    final width = (args?['width'] as double?) ?? 500.0;
    final height = (args?['height'] as double?) ?? 500.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Reset view',
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _resetView,
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          transformationController: _viewerController,
          minScale: 0.2,
          maxScale: 8.0,
          panEnabled: true,
          scaleEnabled: true,
          boundaryMargin: const EdgeInsets.all(1000),
          clipBehavior: Clip.none,
          child: Container(
            width: width + 200,
            height: height + 200,
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: SvgPicture.asset(
              assetPath,
              width: width,
              height: height,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Open Editor'),
        icon: const Icon(Icons.edit),
        onPressed: () => Get.toNamed('/layout_editor'),
      ),
    );
  }
}
