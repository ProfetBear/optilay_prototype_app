import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/utils/constants/colors.dart';
import 'package:optilay_prototype_app/utils/constants/sizes.dart';
import 'package:optilay_prototype_app/utils/constants/text_strings.dart';

class NewCanvaPage extends StatefulWidget {
  const NewCanvaPage({super.key});

  @override
  State<NewCanvaPage> createState() => _NewCanvaPageState();
}

class _NewCanvaPageState extends State<NewCanvaPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createNewCanva() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      Get.snackbar(
        "Nome richiesto",
        "Inserisci un nome per la nuova Canva",
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }
    final layoutId = LayoutIdGenerator.generate(1);
    // TODO: Logica per creare la canva o salvare su Firebase
    Get.toNamed('/layout_editor/$layoutId', arguments: {'canvaName': name});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(MyTexts.newCanvaTitle),
        centerTitle: true,
        backgroundColor: MyColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(MySizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nome della Canva",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: MySizes.spacing),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: "Es. Progetto Cucina",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: MySizes.spacing * 2),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createNewCanva,
                icon: const Icon(Icons.check),
                label: const Text("Crea Canva"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LayoutIdGenerator {
  static String generate(int count, {int revision = 0}) {
    final id = count.toString().padLeft(5, '0');
    final rev = revision.toString().padLeft(2, '0');
    return 'LAY$id.rev$rev';
  }
}
