// lib/features/product/product_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/3D_model_viewer/3D_model_viewer_embed.dart';
import 'package:optilay_prototype_app/routes/routes.dart';
import 'package:optilay_prototype_app/utils/constants/colors.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments as Map?) ?? {};
    final String productName = (args['productName'] as String?) ?? 'Product';
    final String assetPath =
        (args['assetPath'] as String?) ?? 'assets/model.glb';

    return Scaffold(
      appBar: AppBar(
        title: Text(productName, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: MyColors.primary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top 3D viewer (with fullscreen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ModelViewerEmbed(
                  assetPath: assetPath,
                  showFullscreenButton: true,
                  onFullscreenTap: () {
                    Get.toNamed(
                      MyRoutes.modelViewer3D,
                      arguments: {
                        'productName': productName,
                        'assetPath': assetPath,
                      },
                    );
                  },
                ),
              ),
            ),

            // Tech details (brief section)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Tech details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TechDetailRow(label: 'Model', value: productName),
                  const SizedBox(height: 8),
                  const _TechDetailRow(label: 'Revision', value: '—'),
                  const SizedBox(height: 8),
                  const _TechDetailRow(label: 'Working area', value: '—'),
                  const SizedBox(height: 8),
                  const _TechDetailRow(label: 'Options', value: '—'),
                  const SizedBox(height: 20),
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a short product description here.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            // Bottom split actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.toNamed(
                            MyRoutes.modelViewerAR,
                            arguments: {
                              'productName': productName,
                              'assetPath': assetPath,
                            },
                          );
                        },
                        icon: const Icon(Icons.view_in_ar),
                        label: const Text('AR Viewer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.toNamed(
                            MyRoutes.layoutViewer2D,
                            arguments: {
                              'productName': productName,
                              'assetPath': assetPath,
                            },
                          );
                        },
                        icon: const Icon(Icons.grid_view_rounded),
                        label: const Text('Layout Builder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: MyColors.primary,
                          side: BorderSide(color: MyColors.primary, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _TechDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4D4D4D)),
          ),
        ],
      ),
    );
  }
}
