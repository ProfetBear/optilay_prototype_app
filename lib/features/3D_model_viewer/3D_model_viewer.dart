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
  /// Path to your GLB asset in /assets (e.g. 'assets/saw.glb')
  final String filename;

  const ModelViewerPage({super.key, required this.filename});

  @override
  State<ModelViewerPage> createState() => _ModelViewerPageState();
}

class _ModelViewerPageState extends State<ModelViewerPage> {
  String? _glbUrl; // http://127.0.0.1:8080/saw.glb
  String? _usdzUrl; // http://127.0.0.1:8080/saw.usdz

  // OPTIONAL: for Android Scene Viewer in production, host GLB on HTTPS and set this:
  static const String? kAndroidGlbHttps = null;

  @override
  void initState() {
    super.initState();
    _prepareAndServe();
  }

  Future<void> _prepareAndServe() async {
    final docs = await getApplicationDocumentsDirectory();

    // ---- Copy GLB from assets to app docs ----
    final glbData = await rootBundle.load(widget.filename); // 'assets/saw.glb'
    final glbBytes = glbData.buffer.asUint8List();
    final glbPath = '${docs.path}/saw.glb';
    final glbFile = await compute(_writeFileIsolate, {
      'bytes': glbBytes,
      'path': glbPath,
    });

    // ---- Copy USDZ from assets to app docs ----
    final usdzData = await rootBundle.load('assets/saw.usdz');
    final usdzBytes = usdzData.buffer.asUint8List();
    final usdzPath = '${docs.path}/saw.usdz';
    final usdzFile = await compute(_writeFileIsolate, {
      'bytes': usdzBytes,
      'path': usdzPath,
    });

    // ---- Shelf handler with logging + CORS + HEAD/OPTIONS ----
    Future<shelf.Response> _okHead(String mime) async => shelf.Response.ok(
      '',
      headers: {
        'Content-Type': mime,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,HEAD,OPTIONS',
      },
    );

    final handler = const shelf.Pipeline()
        .addMiddleware((inner) {
          return (shelf.Request req) async {
            debugPrint('[shelf] ${req.method} /${req.url.path}');
            if (req.method == 'OPTIONS') {
              return shelf.Response(
                204,
                headers: {
                  'Access-Control-Allow-Origin': '*',
                  'Access-Control-Allow-Methods': 'GET,HEAD,OPTIONS',
                  'Access-Control-Allow-Headers':
                      'Origin, Content-Type, Accept',
                },
              );
            }
            return inner(req);
          };
        })
        .addHandler((shelf.Request request) async {
          switch (request.url.path) {
            case 'saw.glb':
              if (request.method == 'HEAD') return _okHead('model/gltf-binary');
              return shelf.Response.ok(
                await glbFile.readAsBytes(),
                headers: {
                  'Content-Type': 'model/gltf-binary',
                  'Access-Control-Allow-Origin': '*',
                  'Access-Control-Allow-Methods': 'GET,HEAD,OPTIONS',
                },
              );
            case 'saw.usdz':
              if (request.method == 'HEAD')
                return _okHead('model/vnd.usdz+zip');
              return shelf.Response.ok(
                await usdzFile.readAsBytes(),
                headers: {
                  'Content-Type':
                      'model/vnd.usdz+zip', // critical for Quick Look
                  'Access-Control-Allow-Origin': '*',
                  'Access-Control-Allow-Methods': 'GET,HEAD,OPTIONS',
                },
              );
            default:
              return shelf.Response.notFound(
                'Not found',
                headers: {
                  'Access-Control-Allow-Origin': '*',
                  'Access-Control-Allow-Methods': 'GET,HEAD,OPTIONS',
                },
              );
          }
        });

    final server = await shelf_io.serve(handler, '127.0.0.1', 8080);
    final base = 'http://${server.address.host}:${server.port}';

    setState(() {
      _glbUrl = '$base/saw.glb';
      _usdzUrl = '$base/saw.usdz';
    });
  }

  @override
  Widget build(BuildContext context) {
    final ready = _glbUrl != null && _usdzUrl != null;
    final isAndroid = Platform.isAndroid;

    final srcForPlatform =
        isAndroid && kAndroidGlbHttps != null
            ? kAndroidGlbHttps!
            : (_glbUrl ?? '');

    return Scaffold(
      appBar: AppBar(title: const Text('3D Model Viewer')),
      body:
          !ready
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: ModelViewer(
                      src: srcForPlatform, // GLB inline
                      alt: '3D Model',
                      ar: true,
                      arModes: const ['quick-look', 'webxr', 'scene-viewer'],
                      iosSrc: _usdzUrl!, // USDZ for iOS Quick Look
                      autoRotate: true,
                      cameraControls: true,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () => Get.toNamed(MyRoutes.modelViewer3D),
                      icon: const Icon(Icons.map),
                      label: const Text('Go to Layout Screen'),
                    ),
                  ),
                ],
              ),
    );
  }
}

// ✅ Works in isolate — no platform channels here
Future<File> _writeFileIsolate(Map<String, dynamic> args) async {
  final List<int> bytes = args['bytes'];
  final String path = args['path'];
  final file = File(path);
  await file.writeAsBytes(bytes);
  return file;
}
