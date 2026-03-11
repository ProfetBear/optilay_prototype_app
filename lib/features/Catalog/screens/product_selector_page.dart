// lib/features/model_selector/model_selector_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/common/widgets/option_card.dart';
import 'package:optilay_prototype_app/routes/routes.dart';
import 'package:optilay_prototype_app/utils/constants/colors.dart';

class ModelSelectorPage extends StatelessWidget {
  const ModelSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Product',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: MyColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OptionCard(
              title: 'Valiant',
              description: 'Open product page',
              icon: Icons.precision_manufacturing,
              color: MyColors.primary,
              onTap: () {
                Get.toNamed(
                  MyRoutes.productPage,
                  arguments: {
                    'productName': 'Valiant',
                    'assetPath': 'assets/ValiantRev11.glb',
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            OptionCard(
              title: 'XBlade',
              description: 'Open product page',
              icon: Icons.precision_manufacturing,
              color: MyColors.primary,
              onTap: () {
                Get.toNamed(
                  MyRoutes.productPage,
                  arguments: {
                    'productName': 'XBlade',
                    'assetPath': 'assets/XBladeRev1.glb',
                    'drawingAssetPath': 'assets/layouts/XB5.svg',
                    'drawingHeightMeters': 21.0,
                    'drawingWidthMeters': 29.7,
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            OptionCard(
              title: 'Gemini',
              description: 'Open product page',
              icon: Icons.precision_manufacturing,
              color: MyColors.primary,
              onTap: () {
                Get.toNamed(
                  MyRoutes.productPage,
                  arguments: {
                    'productName': 'Gemini',
                    'assetPath': 'assets/GeminiRev0.glb',
                    'drawingAssetPath': 'assets/layouts/G32LS.svg',
                    'drawingHeightMeters': 21.0,
                    'drawingWidthMeters': 29.7,
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
