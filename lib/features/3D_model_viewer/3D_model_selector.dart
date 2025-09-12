import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/common/widgets/option_card.dart';
import 'package:optilay_prototype_app/routes/routes.dart';
import 'package:optilay_prototype_app/utils/constants/colors.dart';
import 'package:optilay_prototype_app/utils/constants/text_strings.dart';

class ModelSelectorPage extends StatelessWidget {
  const ModelSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(MyTexts.projectSelectorTitle),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              MyTexts.projectSelectorHeader,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OptionCard(
              title: MyTexts.standardModel,
              description: MyTexts.projectSelectorNewCanvaDesc,
              icon: Icons.add_circle_outline,
              color: MyColors.green,
              onTap: () {
                Get.toNamed(
                  MyRoutes.modelViewer3D,
                  parameters: {'assetPath': 'assets/default_model.glb'},
                );
              },
            ),
            const SizedBox(height: 20),
            OptionCard(
              title: MyTexts.saw,
              description: MyTexts.projectSelectorRestoreCanvaDesc,
              icon: Icons.cloud_download_outlined,
              color: MyColors.blue,
              onTap: () {
                Get.toNamed(
                  MyRoutes.modelViewer3D,
                  parameters: {'assetPath': 'assets/saw.glb'},
                );
              },
            ),
            const SizedBox(height: 20),
            OptionCard(
              title: MyTexts.drill,
              description: MyTexts.projectSelectorRestoreCanvaDesc,
              icon: Icons.pin,
              color: MyColors.blue,
              onTap: () {
                Get.toNamed(
                  MyRoutes.modelViewer3D,
                  parameters: {'assetPath': 'assets/valiant_rev00.glb'},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
