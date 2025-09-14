import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

class ModelViewerPage extends StatefulWidget {
  final String filename;
  const ModelViewerPage({super.key, required this.filename});

  @override
  State<ModelViewerPage> createState() => _ModelViewerPageState();
}

class _ModelViewerPageState extends State<ModelViewerPage> {
  String? _glbUrl;
  HttpServer? _server;
  bool _starting = false;
  String _currentAsset = '';
  bool _withoutHull = false;

  @override
  void initState() {
    super.initState();
    _currentAsset = Get.arguments?['assetPath'] ?? widget.filename;
    _prepareAndServe();
  }

  @override
  void dispose() {
    _server?.close(force: true);
    _server = null;
    super.dispose();
  }

  Future<void> _prepareAndServe() async {
    if (_starting || _server != null) return;
    _starting = true;

    try {
      final docs = await getApplicationDocumentsDirectory();
      final assetToLoad = _withoutHull
          ? _currentAsset.replaceRange(
              _currentAsset.lastIndexOf('.glb'),
              _currentAsset.lastIndexOf('.glb'),
              '_WithoutHull')
          : _currentAsset;
      final glbData = await rootBundle.load(assetToLoad);
      final glbBytes = glbData.buffer.asUint8List();
      final glbName = assetToLoad.split('/').last;
      final glbPath = '${docs.path}/$glbName';
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

      _server = await shelf_io.serve(
        handler,
        InternetAddress.loopbackIPv4,
        0,
      );

      final base = 'http://${_server!.address.host}:${_server!.port}';

      if (!mounted) return;
      setState(() {
        _glbUrl = '$base/$glbName';
      });
    } finally {
      _starting = false;
    }
  }

  void _toggleHull(bool value) async {
    setState(() {
      _withoutHull = value;
      _glbUrl = null;
      _server?.close(force: true);
      _server = null;
    });
    await _prepareAndServe();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _glbUrl != null;
    final srcForPlatform = (_glbUrl ?? '');

    return Scaffold(
      appBar: AppBar(
        actions: [
          Row(
            children: [
              Text('Hull', style: TextStyle(color: Colors.white)),
              Switch(
                value: _withoutHull,
                onChanged: _toggleHull,
              ),
            ],
          ),
        ],
      ),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : ModelViewer(
              src: srcForPlatform,
              alt: '3D Model',
              ar: true,
              arModes: const ['quick-look', 'webxr', 'scene-viewer'],
              autoRotate: true,
              cameraControls: true,
              backgroundColor: Colors.white,
            ),
    );
  }
}

Future<File> _writeFileIsolate(Map<String, dynamic> args) async {
  final List<int> bytes = args['bytes'];
  final String path = args['path'];
  final file = File(path);
  await file.writeAsBytes(bytes);
  return file;
}