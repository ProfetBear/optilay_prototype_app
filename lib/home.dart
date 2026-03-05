import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/common/widgets/option_card.dart';
import 'package:optilay_prototype_app/routes/routes.dart';
import 'package:optilay_prototype_app/utils/constants/colors.dart';
import 'package:optilay_prototype_app/utils/constants/text_strings.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool showARSubCards = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          MyTexts.homeAppbarTitle,
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
              MyTexts.homeWelcome,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OptionCard(
              title: MyTexts.beginVisitButtonTitle,
              description: MyTexts.beginVisitButtonDesc,
              icon: Icons.view_in_ar,
              color: MyColors.primary,
              onTap: () {
                Get.toNamed(MyRoutes.productSelector);
              },
            ),
          ],
        ),
      ),
    );
  }
}
