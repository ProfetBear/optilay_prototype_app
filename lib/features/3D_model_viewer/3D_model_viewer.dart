// lib/features/viewer/model_viewer_fullscreen_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/3D_model_viewer/model_viewer_embed.dart';

class ModelViewerFullScreenPage extends StatelessWidget {
  const ModelViewerFullScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments as Map?) ?? {};
    final String productName = (args['productName'] as String?) ?? '3D Viewer';
    final String assetPath =
        (args['assetPath'] as String?) ?? 'assets/model.glb';

    return Scaffold(
      appBar: AppBar(title: Text(productName), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ModelViewerEmbed(
            assetPath: assetPath,
            showFullscreenButton: false,
          ),
        ),
      ),
    );
  }
}
