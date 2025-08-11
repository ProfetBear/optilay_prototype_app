import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/common/widgets/option_card.dart';
import 'package:optilay_prototype_app/routes/routes.dart';
import 'package:optilay_prototype_app/utils/constants/colors.dart';
import 'package:optilay_prototype_app/utils/constants/text_strings.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(MyTexts.homeAppbarTitle),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              MyTexts.homeWelcome,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OptionCard(
              title: MyTexts.home3DViewerButtonTitle,
              description: MyTexts.home3DViewerButtonDesc,
              icon: Icons.view_in_ar,
              color: MyColors.primary,
              onTap: () {
                Get.toNamed(MyRoutes.modelSelector3D);
              },
            ),
            const SizedBox(height: 20),
            OptionCard(
              title: MyTexts.homeCanvaManagerButtonTitle,
              description: MyTexts.homeCanvaManagerButtonDesc,
              icon: Icons.design_services,
              color: MyColors.secondary,
              onTap: () {
                Get.toNamed(MyRoutes.layoutProjectSelector);
              },
            ),
          ],
        ),
      ),
    );
  }
}
