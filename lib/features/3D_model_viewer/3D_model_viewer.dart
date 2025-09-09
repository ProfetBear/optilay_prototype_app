// lib/screens/model_viewer_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:optilay_prototype_app/routes/routes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

class ModelViewerPage extends StatefulWidget {
  final String filename; // e.g. 'assets/saw.glb'
  const ModelViewerPage({super.key, required this.filename});

  @override
  State<ModelViewerPage> createState() => _ModelViewerPageState();
}

class _ModelViewerPageState extends State<ModelViewerPage> {
  String? _glbUrl; // http://127.0.0.1:<port>/saw.glb
  HttpServer? _server;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _prepareAndServe();
  }

  @override
  void dispose() {
    // Close the server so the port is freed when leaving the page.
    _server?.close(force: true);
    _server = null;
    super.dispose();
  }

  Future<void> _prepareAndServe() async {
    if (_starting || _server != null) return;
    _starting = true;

    try {
      final docs = await getApplicationDocumentsDirectory();

      // ---- Copy GLB from assets to app docs ----
      final glbData = await rootBundle.load(widget.filename);
      final glbBytes = glbData.buffer.asUint8List();
      final glbPath = '${docs.path}/saw.glb';
      final glbFile = await compute(_writeFileIsolate, {
        'bytes': glbBytes,
        'path': glbPath,
      });

      final handler = shelf.Pipeline().addHandler((
        shelf.Request request,
      ) async {
        final bytes = await glbFile.readAsBytes();
        return shelf.Response.ok(
          bytes,
          headers: {
            'Content-Type': 'model/gltf-binary',
            'Access-Control-Allow-Origin': '*',
          },
        );
      });
      // Bind to port 0 (let the OS pick a free one). No need for shared:true now.
      _server = await shelf_io.serve(
        handler,
        InternetAddress.loopbackIPv4,
        0,
        // shared: true, // only if you truly need multiple listeners on the same port
      );

      final base = 'http://${_server!.address.host}:${_server!.port}';

      if (!mounted) return;
      setState(() {
        _glbUrl = '$base/saw.glb';
      });
    } finally {
      _starting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _glbUrl != null;
    final srcForPlatform = (_glbUrl ?? '');

    return Scaffold(
      appBar: AppBar(),
      body:
          !ready
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  // Expanded cannot be used inside Stack; use a direct child or Positioned.fill
                  Positioned.fill(
                    child: ModelViewer(
                      src: srcForPlatform,
                      alt: '3D Model',
                      ar: true,
                      arModes: const ['quick-look', 'webxr', 'scene-viewer'],
                      autoRotate: true,
                      cameraControls: true,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.toNamed(MyRoutes.modelViewer3D),
                      icon: const Icon(Icons.map),
                      label: const Text('AR'),
                    ),
                  ),
                ],
              ),
    );
  }
}

// Works in isolate — no platform channels here
Future<File> _writeFileIsolate(Map<String, dynamic> args) async {
  final List<int> bytes = args['bytes'];
  final String path = args['path'];
  final file = File(path);
  await file.writeAsBytes(bytes);
  return file;
}
