// lib/features/viewer/model_viewer_embed.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

class ModelViewerEmbed extends StatefulWidget {
  final String assetPath;

  /// If true, shows an overlay button (top-right) to go fullscreen.
  final bool showFullscreenButton;
  final VoidCallback? onFullscreenTap;

  const ModelViewerEmbed({
    super.key,
    required this.assetPath,
    this.showFullscreenButton = false,
    this.onFullscreenTap,
  });

  @override
  State<ModelViewerEmbed> createState() => _ModelViewerEmbedState();
}

class _ModelViewerEmbedState extends State<ModelViewerEmbed> {
  String? _glbUrl;
  HttpServer? _server;
  bool _starting = false;

  bool _withoutHull = false;
  String _currentAsset = '';

  @override
  void initState() {
    super.initState();
    _currentAsset = widget.assetPath;
    _prepareAndServe();
  }

  @override
  void didUpdateWidget(covariant ModelViewerEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _currentAsset = widget.assetPath;
      _restartServer();
    }
  }

  @override
  void dispose() {
    _server?.close(force: true);
    _server = null;
    super.dispose();
  }

  Future<void> _restartServer() async {
    setState(() {
      _glbUrl = null;
    });
    _server?.close(force: true);
    _server = null;
    await _prepareAndServe();
  }

  Future<void> _prepareAndServe() async {
    if (_starting || _server != null) return;
    _starting = true;

    try {
      if (kIsWeb) {
        // Web: model_viewer can usually load assets directly
        // (Make sure the .glb is available in web build assets)
        if (!mounted) return;
        setState(() => _glbUrl = _currentAsset);
        return;
      }

      final docs = await getApplicationDocumentsDirectory();

      final assetToLoad =
          _withoutHull
              ? _currentAsset.replaceRange(
                _currentAsset.lastIndexOf('.glb'),
                _currentAsset.lastIndexOf('.glb'),
                '_WithoutHull',
              )
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

      _server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
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
    });
    _server?.close(force: true);
    _server = null;
    await _prepareAndServe();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _glbUrl != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.white,
              child:
                  !ready
                      ? const Center(child: CircularProgressIndicator())
                      : ModelViewer(
                        src: _glbUrl!,
                        alt: '3D Model',
                        ar: false, // AR is on the dedicated AR page
                        autoRotate: true,
                        cameraControls: true,
                        backgroundColor: Colors.white,
                      ),
            ),
          ),

          // Hull switch (top-left)
          Positioned(
            right: 8,
            top: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAEAEA)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Carter',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Switch(
                      value: _withoutHull,
                      onChanged: _toggleHull,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Fullscreen button (top-right)
          if (widget.showFullscreenButton && widget.onFullscreenTap != null)
            Positioned(
              right: 8,
              bottom: 8,
              child: InkWell(
                onTap: widget.onFullscreenTap,
                borderRadius: BorderRadius.circular(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.fullscreen, size: 20),
                  ),
                ),
              ),
            ),
        ],
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
