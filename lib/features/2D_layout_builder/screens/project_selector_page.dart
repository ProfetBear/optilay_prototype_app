import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/common/widgets/option_card.dart';
import 'package:optilay_prototype_app/routes/routes.dart';
import 'package:optilay_prototype_app/utils/constants/colors.dart';
import 'package:optilay_prototype_app/utils/constants/text_strings.dart';

class ProjectSelectorPage extends StatelessWidget {
  const ProjectSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          MyTexts.projectSelectorTitle,
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
            const Text(
              MyTexts.projectSelectorHeader,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OptionCard(
              title: MyTexts.newCanvaTitle,
              description: MyTexts.projectSelectorNewCanvaDesc,
              icon: Icons.add_circle_outline,
              color: MyColors.primary,
              onTap: () {
                Get.toNamed(MyRoutes.newCanva);
              },
            ),
            const SizedBox(height: 20),
            OptionCard(
              title: MyTexts.projectSelectorRestoreCanvaTitle,
              description: MyTexts.projectSelectorRestoreCanvaDesc,
              icon: Icons.cloud_download_outlined,
              color: MyColors.blue,
              onTap: () {
                Get.toNamed(MyRoutes.loadCanva);
              },
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }
}
