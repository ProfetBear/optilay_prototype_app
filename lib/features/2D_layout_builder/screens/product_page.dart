// lib/features/product/product_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/screens/layout_procedure_page.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/widgets/technical_drawing_embed.dart';
import 'package:optilay_prototype_app/features/3D_model_viewer/3D_model_viewer_embed.dart';
import 'package:optilay_prototype_app/routes/routes.dart';
import 'package:optilay_prototype_app/utils/constants/colors.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  bool _show2D = false;

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments as Map?) ?? {};
    final String productName = (args['productName'] as String?) ?? 'Product';
    final String assetPath =
        (args['assetPath'] as String?) ?? 'assets/model.glb';

    final String drawingAssetPath =
        (args['drawingAssetPath'] as String?) ?? 'assets/crane.svg';

    final double drawingWidthMeters =
        (args['drawingWidthMeters'] as num?)?.toDouble() ?? 2.0;
    final double drawingHeightMeters =
        (args['drawingHeightMeters'] as num?)?.toDouble() ?? 2.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(productName, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: MyColors.primary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child:
                          _show2D
                              ? TechnicalDrawingEmbed(
                                assetPath: drawingAssetPath,
                                showFullscreenButton: true,
                                onFullscreenTap: () {
                                  Get.toNamed(
                                    MyRoutes.layoutViewer2D,
                                    arguments: {
                                      'title':
                                          '$productName - Technical Drawing',
                                      'assetPath': drawingAssetPath,
                                      'productName': productName,
                                    },
                                  );
                                },
                              )
                              : ModelViewerEmbed(
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
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _ViewerModeSwitch(
                        show2D: _show2D,
                        onChanged: (value) {
                          setState(() => _show2D = value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                          Get.to(
                            () => LayoutProcedurePage(
                              productName: productName,
                              machineDrawingAssetPath: drawingAssetPath,
                              machineWidthMeters: drawingWidthMeters,
                              machineHeightMeters: drawingHeightMeters,
                            ),
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

class _ViewerModeSwitch extends StatelessWidget {
  const _ViewerModeSwitch({required this.show2D, required this.onChanged});

  final bool show2D;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeChip(
            label: '3D',
            selected: !show2D,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 4),
          _ModeChip(
            label: '2D',
            selected: show2D,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 48,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? MyColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
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
