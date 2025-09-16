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
          'Select 3D Model',
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
              description: 'Show Valiant',
              icon: Icons.precision_manufacturing,
              color: MyColors.primary,
              onTap: () {
                Get.toNamed(
                  MyRoutes.modelViewer3D,
                  arguments: {'assetPath': 'assets/ValiantRev11.glb'},
                );
              },
            ),
            const SizedBox(height: 20),
            OptionCard(
              title: 'XBlade',
              description: 'Show XBlade',
              icon: Icons.precision_manufacturing,
              color: MyColors.primary,
              onTap: () {
                Get.toNamed(
                  MyRoutes.modelViewer3D,
                  arguments: {'assetPath': 'assets/XBladeRev1.glb'},
                );
              },
            ),
            const SizedBox(height: 20),
            OptionCard(
              title: 'Gemini',
              description: 'Show Gemini',
              icon: Icons.precision_manufacturing,
              color: MyColors.primary,
              onTap: () {
                Get.toNamed(
                  MyRoutes.modelViewer3D,
                  arguments: {'assetPath': 'assets/GeiminiRev0.glb'},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
