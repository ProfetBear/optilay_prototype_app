// lib/features/2D_layout_builder/screens/layout_procedure_page.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/data/pdf_export.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/data/pdf_import.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/data/pdf_picker.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/widgets/painters/quote_line_painter.dart';
import 'package:optilay_prototype_app/utils/constants/colors.dart';

class LayoutProcedurePage extends StatefulWidget {
  const LayoutProcedurePage({
    super.key,
    this.productName,
    this.machineDrawingAssetPath,
    this.machineWidthMeters,
    this.machineHeightMeters,
  });

  final String? productName;
  final String? machineDrawingAssetPath;
  final double? machineWidthMeters;
  final double? machineHeightMeters;

  @override
  State<LayoutProcedurePage> createState() => _LayoutProcedurePageState();
}

class _LayoutProcedurePageState extends State<LayoutProcedurePage> {
  final FilePickerService _picker = FilePickerService();
  final PdfImportService _pdfImport = PdfImportService();
  final ExportService _export = ExportService();

  final GlobalKey _exportKey = GlobalKey();

  int _currentStep = 0;
  final Set<int> _completedSteps = {};

  String? _selectedOption;
  Uint8List? _pdfBytes;
  Size? _pdfSize;

  Offset _quotePosition = const Offset(120, 120);
  double _quoteLengthPx = 240;
  String _quoteLabel = '';
  double? _metersPerPixel;

  // 0 = horizontal, pi/2 = vertical
  double _quoteAngleRad = 0;

  Offset _machineTopLeft = const Offset(240, 240);
  double _machineRotationRad = 0;

  bool _boardFullscreen = false;

  String get _productName {
    final args = (Get.arguments as Map?) ?? {};
    return widget.productName ?? (args['productName'] as String?) ?? 'Product';
  }

  String get _machineDrawingAssetPath {
    final args = (Get.arguments as Map?) ?? {};
    return widget.machineDrawingAssetPath ??
        (args['machineDrawingAssetPath'] as String?) ??
        'assets/crane.svg';
  }

  double get _machineWidthMeters {
    final args = (Get.arguments as Map?) ?? {};
    return widget.machineWidthMeters ??
        (args['machineWidthMeters'] as num?)?.toDouble() ??
        2.0;
  }

  double get _machineHeightMeters {
    final args = (Get.arguments as Map?) ?? {};
    return widget.machineHeightMeters ??
        (args['machineHeightMeters'] as num?)?.toDouble() ??
        2.0;
  }

  bool get _hasPdf => _pdfBytes != null && _pdfSize != null;
  bool get _hasScale => _metersPerPixel != null;
  bool get _canPlaceMachine => _hasPdf && _hasScale;

  double get _machineWidthPx {
    if (_metersPerPixel == null) return 200;
    return _machineWidthMeters / _metersPerPixel!;
  }

  double get _machineHeightPx {
    if (_metersPerPixel == null) return 200;
    return _machineHeightMeters / _metersPerPixel!;
  }

  Offset get _quoteAxisUnit =>
      Offset(math.cos(_quoteAngleRad), math.sin(_quoteAngleRad));

  Future<void> _importPdf() async {
    final file = await _picker.pickPdf();
    if (file == null) return;

    final bytes = await _pdfImport.firstPageAsPngBytes(file);
    if (bytes == null) return;

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    setState(() {
      _pdfBytes = bytes;
      _pdfSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      _quotePosition = const Offset(120, 120);
      _quoteLengthPx = (_pdfSize!.width * 0.25).clamp(180.0, 360.0);
      _quoteAngleRad = 0;
      _machineTopLeft = Offset(
        (_pdfSize!.width - 240) / 2,
        (_pdfSize!.height - 240) / 2,
      );
      _machineRotationRad = 0;
    });
  }

  Future<void> _setQuoteScale() async {
    final formKey = GlobalKey<FormState>();
    String inputValue = '';

    await Get.dialog(
      AlertDialog(
        title: const Text('Real-world Length'),
        content: Form(
          key: formKey,
          child: TextFormField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Length (m)'),
            onChanged: (value) => inputValue = value,
            validator: (value) {
              final input = double.tryParse(value ?? '');
              if (input == null || input <= 0) {
                return 'Enter a valid number > 0';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Get.back(result: double.parse(inputValue));
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    ).then((result) {
      final double? realLength = result is num ? result.toDouble() : null;
      if (realLength == null) return;

      if (!mounted) return;
      setState(() {
        _metersPerPixel = realLength / _quoteLengthPx;
        _quoteLabel = '${realLength.toStringAsFixed(2)} m';
      });
    });
  }

  Future<void> _exportProcedurePdf() async {
    final boundary =
        _exportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    if (boundary.debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 30));
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    await _export.exportPngToPdfAndShareHQ(
      byteData.buffer.asUint8List(),
      filename: 'layout_procedure_export.pdf',
    );
  }

  bool _isStepReady(int step) {
    switch (step) {
      case 0:
        return _selectedOption != null;
      case 1:
        return _hasPdf;
      case 2:
        return _hasScale;
      case 3:
        return _canPlaceMachine;
      case 4:
        return true;
      default:
        return false;
    }
  }

  void _saveCurrentStep() {
    if (!_isStepReady(_currentStep)) {
      Get.snackbar(
        'Step incomplete',
        _stepValidationMessage(_currentStep),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _completedSteps.add(_currentStep);

      // When leaving quote step and entering placement step,
      // re-center machine using the calibrated size.
      if (_currentStep == 2 && _hasPdf && _hasScale && _pdfSize != null) {
        final centeredX = (_pdfSize!.width - _machineWidthPx) / 2;
        final centeredY = (_pdfSize!.height - _machineHeightPx) / 2;

        _machineTopLeft = Offset(
          centeredX.clamp(
            0.0,
            math.max(0.0, _pdfSize!.width - _machineWidthPx),
          ),
          centeredY.clamp(
            0.0,
            math.max(0.0, _pdfSize!.height - _machineHeightPx),
          ),
        );
      }

      if (_currentStep < 4) {
        _currentStep += 1;
      }
    });
  }

  String _stepValidationMessage(int step) {
    switch (step) {
      case 0:
        return 'Select one configuration option first.';
      case 1:
        return 'Import a customer PDF first.';
      case 2:
        return 'Set the quote using a known measurement first.';
      case 3:
        return 'Place and rotate the machinery before saving.';
      default:
        return 'Complete the current step first.';
    }
  }

  bool get _stepUsesBoard => _currentStep >= 1 && _currentStep <= 4;

  void _toggleQuoteOrientation() {
    setState(() {
      _quoteAngleRad = _quoteAngleRad == 0 ? math.pi / 2 : 0;
    });
  }

  void _moveQuote(Offset delta) {
    setState(() {
      _quotePosition += delta;
    });
  }

  void _dragLeftQuoteHandle(Offset dragDelta) {
    final projection =
        dragDelta.dx * _quoteAxisUnit.dx + dragDelta.dy * _quoteAxisUnit.dy;
    final newLength = _quoteLengthPx - projection;
    if (newLength < 80) return;

    setState(() {
      _quoteLengthPx = newLength;
      _quotePosition += Offset(
        _quoteAxisUnit.dx * projection,
        _quoteAxisUnit.dy * projection,
      );
    });
  }

  void _dragRightQuoteHandle(Offset dragDelta) {
    final projection =
        dragDelta.dx * _quoteAxisUnit.dx + dragDelta.dy * _quoteAxisUnit.dy;
    final newLength = _quoteLengthPx + projection;
    if (newLength < 80) return;

    setState(() {
      _quoteLengthPx = newLength;
    });
  }

  void _moveMachine(Offset delta) {
    if (_pdfSize == null) return;

    final next = _machineTopLeft + delta;

    setState(() {
      _machineTopLeft = Offset(
        next.dx.clamp(
          -_machineWidthPx * 0.5,
          _pdfSize!.width - _machineWidthPx * 0.5,
        ),
        next.dy.clamp(
          -_machineHeightPx * 0.5,
          _pdfSize!.height - _machineHeightPx * 0.5,
        ),
      );
    });
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _StepScaffoldCard(
          title: '1. Configure your machine',
          subtitle:
              'Temporary placeholder step. Select one option to continue the procedure.',
          child: Column(
            children: [
              RadioListTile<String>(
                value: 'Option 1',
                groupValue: _selectedOption,
                title: const Text('Option 1'),
                subtitle: const Text('Placeholder machine configuration'),
                onChanged: (value) {
                  setState(() => _selectedOption = value);
                },
              ),
              RadioListTile<String>(
                value: 'Option 2',
                groupValue: _selectedOption,
                title: const Text('Option 2'),
                subtitle: const Text('Alternative placeholder configuration'),
                onChanged: (value) {
                  setState(() => _selectedOption = value);
                },
              ),
            ],
          ),
        );
      case 1:
        return _StepScaffoldCard(
          title: '2. Import the customer PDF',
          subtitle:
              'Load the customer planimetry. Once imported, save to continue.',
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _importPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(_hasPdf ? 'Replace PDF' : 'Import PDF'),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _PdfStageBoard(
                  pdfBytes: _pdfBytes,
                  pdfSize: _pdfSize,
                  showQuote: false,
                  quotePosition: _quotePosition,
                  quoteLengthPx: _quoteLengthPx,
                  quoteLabel: _quoteLabel,
                  showMachine: false,
                  machineAssetPath: _machineDrawingAssetPath,
                  machineTopLeft: _machineTopLeft,
                  machineWidthPx: _machineWidthPx,
                  machineHeightPx: _machineHeightPx,
                  machineRotationRad: _machineRotationRad,
                ),
              ),
            ],
          ),
        );
      case 2:
        return _StepScaffoldCard(
          title: '3. Set the quote',
          subtitle:
              'Drag the line and its handles over a known dimension, switch orientation when needed, then set the real-world length.',
          child: Column(
            children: [
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _hasPdf ? _setQuoteScale : null,
                    icon: const Icon(Icons.straighten),
                    label: const Text('Set quote'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: _hasPdf ? _toggleQuoteOrientation : null,
                    icon: Icon(
                      _quoteAngleRad == 0 ? Icons.swap_vert : Icons.swap_horiz,
                    ),
                    label: Text(
                      _quoteAngleRad == 0 ? 'Vertical' : 'Horizontal',
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_hasScale)
                    Chip(
                      label: Text(_quoteLabel),
                      backgroundColor: Colors.green.shade50,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _PdfStageBoard(
                  pdfBytes: _pdfBytes,
                  pdfSize: _pdfSize,
                  showQuote: true,
                  quotePosition: _quotePosition,
                  quoteLengthPx: _quoteLengthPx,
                  quoteLabel: _quoteLabel,
                  onMoveQuote: _moveQuote,
                  onDragLeftHandle: (dx) {
                    setState(() {
                      final newLength = _quoteLengthPx - dx;
                      if (newLength < 80) return;

                      _quoteLengthPx = newLength;
                      _quotePosition += Offset(dx, 0);
                    });
                  },

                  onDragRightHandle: (dx) {
                    setState(() {
                      final newLength = _quoteLengthPx + dx;
                      if (newLength < 80) return;

                      _quoteLengthPx = newLength;
                    });
                  },
                  showMachine: false,
                  machineAssetPath: _machineDrawingAssetPath,
                  machineTopLeft: _machineTopLeft,
                  machineWidthPx: _machineWidthPx,
                  machineHeightPx: _machineHeightPx,
                  machineRotationRad: _machineRotationRad,
                ),
              ),
            ],
          ),
        );
      case 3:
        return _StepScaffoldCard(
          title: '4. Place and rotate the machinery',
          subtitle:
              'Move the machine footprint on the calibrated plan and adjust rotation before saving.',
          child: Column(
            children: [
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed:
                        _canPlaceMachine
                            ? () {
                              setState(() {
                                _machineRotationRad -= math.pi / 12;
                              });
                            }
                            : null,
                    icon: const Icon(Icons.rotate_left),
                    label: const Text('Rotate'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed:
                        _canPlaceMachine
                            ? () {
                              setState(() {
                                _machineRotationRad += math.pi / 12;
                              });
                            }
                            : null,
                    icon: const Icon(Icons.rotate_right),
                    label: const Text('Rotate'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _PdfStageBoard(
                  pdfBytes: _pdfBytes,
                  pdfSize: _pdfSize,
                  showQuote: true,
                  quotePosition: _quotePosition,
                  quoteLengthPx: _quoteLengthPx,
                  quoteLabel: _quoteLabel,
                  showMachine: true,
                  machineAssetPath: _machineDrawingAssetPath,
                  machineTopLeft: _machineTopLeft,
                  machineWidthPx: _machineWidthPx,
                  machineHeightPx: _machineHeightPx,
                  machineRotationRad: _machineRotationRad,
                  onMoveMachine: _moveMachine,
                ),
              ),
            ],
          ),
        );
      default:
        return _StepScaffoldCard(
          title: '5. Export',
          subtitle:
              'Review the final composition and export the layout preview as PDF.',
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _hasPdf ? _exportProcedurePdf : null,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Export PDF'),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RepaintBoundary(
                  key: _exportKey,
                  child: _PdfStageBoard(
                    pdfBytes: _pdfBytes,
                    pdfSize: _pdfSize,
                    showQuote: true,
                    quotePosition: _quotePosition,
                    quoteLengthPx: _quoteLengthPx,
                    quoteLabel: _quoteLabel,
                    showMachine: true,
                    machineAssetPath: _machineDrawingAssetPath,
                    machineTopLeft: _machineTopLeft,
                    machineWidthPx: _machineWidthPx,
                    machineHeightPx: _machineHeightPx,
                    machineRotationRad: _machineRotationRad,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Configure machine',
      'Import PDF',
      'Set quote',
      'Place machinery',
      'Export',
    ];

    final bool hideChecklist = _boardFullscreen && _stepUsesBoard;

    return Scaffold(
      appBar: AppBar(
        title: Text('$_productName Layout Procedure'),
        backgroundColor: MyColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!hideChecklist) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ProcedureChecklist(
                  labels: steps,
                  currentStep: _currentStep,
                  completedSteps: _completedSteps,
                  onStepTap: (index) {
                    final canOpen =
                        index <= _currentStep ||
                        _completedSteps.contains(index - 1);
                    if (!canOpen) return;
                    setState(() => _currentStep = index);
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  hideChecklist ? 0 : 16,
                  0,
                  hideChecklist ? 0 : 16,
                  16,
                ),
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            if (_currentStep > 0)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _currentStep -= 1);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              )
            else
              const SizedBox.shrink(),
            const Spacer(),
            if (_currentStep < 4)
              FilledButton.icon(
                onPressed: _saveCurrentStep,
                icon: const Icon(Icons.save),
                label: const Text('Save & Next'),
              )
            else
              FilledButton.icon(
                onPressed: _exportProcedurePdf,
                icon: const Icon(Icons.ios_share),
                label: const Text('Export'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProcedureChecklist extends StatelessWidget {
  const _ProcedureChecklist({
    required this.labels,
    required this.currentStep,
    required this.completedSteps,
    required this.onStepTap,
  });

  final List<String> labels;
  final int currentStep;
  final Set<int> completedSteps;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(labels.length, (index) {
        final completed = completedSteps.contains(index);
        final active = currentStep == index;

        return Padding(
          padding: EdgeInsets.only(bottom: index == labels.length - 1 ? 0 : 10),
          child: InkWell(
            onTap: () => onStepTap(index),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color:
                    active ? MyColors.primary.withOpacity(0.10) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      active
                          ? MyColors.primary
                          : completed
                          ? Colors.green
                          : const Color(0xFFE5E7EB),
                  width: active ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        completed
                            ? Colors.green
                            : active
                            ? MyColors.primary
                            : const Color(0xFFE5E7EB),
                    child:
                        completed
                            ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                            : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: active ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? MyColors.primary : Colors.black87,
                      ),
                    ),
                  ),
                  if (active)
                    const Icon(Icons.chevron_right, color: MyColors.primary),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _StepScaffoldCard extends StatelessWidget {
  const _StepScaffoldCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.of(context).size.width < 700;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 16,
        compact ? 12 : 16,
        compact ? 12 : 16,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 0 : 18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: compact ? 0 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _PdfStageBoard extends StatelessWidget {
  const _PdfStageBoard({
    required this.pdfBytes,
    required this.pdfSize,
    required this.showQuote,
    required this.quotePosition,
    required this.quoteLengthPx,
    required this.quoteLabel,
    required this.showMachine,
    required this.machineAssetPath,
    required this.machineTopLeft,
    required this.machineWidthPx,
    required this.machineHeightPx,
    required this.machineRotationRad,
    this.onMoveQuote,
    this.onDragLeftHandle,
    this.onDragRightHandle,
    this.onMoveMachine,
  });

  final Uint8List? pdfBytes;
  final Size? pdfSize;

  final bool showQuote;
  final Offset quotePosition;
  final double quoteLengthPx;
  final String quoteLabel;

  final ValueChanged<Offset>? onMoveQuote;
  final ValueChanged<double>? onDragLeftHandle;
  final ValueChanged<double>? onDragRightHandle;

  final bool showMachine;
  final String machineAssetPath;
  final Offset machineTopLeft;
  final double machineWidthPx;
  final double machineHeightPx;
  final double machineRotationRad;

  final ValueChanged<Offset>? onMoveMachine;

  @override
  Widget build(BuildContext context) {
    if (pdfBytes == null || pdfSize == null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        alignment: Alignment.center,
        child: const Text('No PDF imported yet'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InteractiveViewer(
        minScale: 0.4,
        maxScale: 6.0,
        boundaryMargin: const EdgeInsets.all(500),
        child: FittedBox(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: pdfSize!.width,
            height: pdfSize!.height,
            child: Stack(
              children: [
                /// PDF BACKGROUND
                Positioned.fill(
                  child: Image.memory(pdfBytes!, fit: BoxFit.fill),
                ),

                /// QUOTE LINE
                if (showQuote)
                  Positioned(
                    left: quotePosition.dx,
                    top: quotePosition.dy,
                    child: GestureDetector(
                      onPanUpdate:
                          onMoveQuote == null
                              ? null
                              : (details) => onMoveQuote!(details.delta),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          SizedBox(width: quoteLengthPx, height: 30),

                          CustomPaint(
                            painter: QuotePainter(
                              quoteLengthPx,
                              label: quoteLabel,
                            ),
                            child: SizedBox(width: quoteLengthPx, height: 30),
                          ),

                          if (onDragLeftHandle != null)
                            Positioned(
                              left: -10,
                              child: GestureDetector(
                                onPanUpdate:
                                    (d) => onDragLeftHandle!(d.delta.dx),
                                behavior: HitTestBehavior.translucent,
                                child: const SizedBox(width: 20, height: 20),
                              ),
                            ),

                          if (onDragRightHandle != null)
                            Positioned(
                              right: -10,
                              child: GestureDetector(
                                onPanUpdate:
                                    (d) => onDragRightHandle!(d.delta.dx),
                                behavior: HitTestBehavior.translucent,
                                child: const SizedBox(width: 20, height: 20),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                /// MACHINE OVERLAY
                if (showMachine)
                  Positioned(
                    left: machineTopLeft.dx,
                    top: machineTopLeft.dy,
                    child: GestureDetector(
                      onPanUpdate:
                          onMoveMachine == null
                              ? null
                              : (details) => onMoveMachine!(details.delta),
                      child: Transform.rotate(
                        alignment: Alignment.center,
                        angle: machineRotationRad,
                        child: SizedBox(
                          width: machineWidthPx,
                          height: machineHeightPx,
                          child: SvgPicture.asset(
                            machineAssetPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
