import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/common/widgets/option_card.dart';
import 'package:optilay_prototype_app/routes/routes.dart';
import 'package:optilay_prototype_app/utils/constants/colors.dart';

final List<Map<String, String>> arModels = [
  {'name': 'Valiant', 'asset': 'assets/ValiantRev11.glb'},
  {'name': 'XBlade', 'asset': 'assets/XBladeRev1.glb'},
  {'name': 'Gemini', 'asset': 'assets/GeminiRev0.glb'},
];

class ARModelSelectorPage extends StatelessWidget {
  const ARModelSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Models', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: MyColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              arModels
                  .map(
                    (model) => Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: OptionCard(
                        title: model['name']!,
                        description: 'Open in AR',
                        icon: Icons.view_in_ar,
                        color: MyColors.primary,
                        onTap: () {
                          Get.toNamed(
                            MyRoutes.modelViewerAR,
                            arguments: {'assetPath': model['asset']},
                          );
                        },
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}
