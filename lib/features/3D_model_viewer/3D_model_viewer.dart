// lib/screens/model_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter/services.dart';
import 'package:optilay_prototype_app/routes/routes.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:flutter/foundation.dart';

class ModelViewerPage extends StatefulWidget {
  final String filename;

  const ModelViewerPage({super.key, required this.filename});

  @override
  State<ModelViewerPage> createState() => _ModelViewerPageState();
}

class _ModelViewerPageState extends State<ModelViewerPage> {
  String? localUrl;

  @override
  void initState() {
    super.initState();
    _prepareModel(widget.filename);
  }

  Future<void> _prepareModel(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final fileBytes = byteData.buffer.asUint8List();
    final filename = assetPath.split('/').last;
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';

    // Pass only primitive types to isolate
    final modelFile = await compute(_writeFileIsolate, {
      'bytes': fileBytes,
      'path': filePath,
    });

    final handler = shelf.Pipeline().addHandler((shelf.Request request) async {
      if (request.url.path == 'model') {
        final bytes = await modelFile.readAsBytes();
        return shelf.Response.ok(
          bytes,
          headers: {
            'Content-Type': 'model/gltf+json',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }
      return shelf.Response.notFound(
        'Not found',
        headers: {'Access-Control-Allow-Origin': '*'},
      );
    });

    final server = await shelf_io.serve(handler, '127.0.0.1', 8080);
    setState(() {
      localUrl = 'http://${server.address.host}:${server.port}/model';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('3D Model Viewer')),
      body:
          localUrl == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: ModelViewer(
                      src: localUrl!,
                      alt: '3D Model',
                      ar: true,
                      arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                      autoRotate: true,
                      cameraControls: true,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed(MyRoutes.modelViewer3D);
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Go to Layout Screen'),
                    ),
                  ),
                ],
              ),
    );
  }
}

// ✅ This can run in isolate — platform stuff already done
Future<File> _writeFileIsolate(Map<String, dynamic> args) async {
  final List<int> bytes = args['bytes'];
  final String path = args['path'];
  final file = File(path);
  await file.writeAsBytes(bytes);
  return file;
}
