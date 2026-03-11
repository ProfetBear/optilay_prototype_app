// lib/features/2D_layout_builder/widgets/technical_drawing_embed.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TechnicalDrawingEmbed extends StatelessWidget {
  const TechnicalDrawingEmbed({
    super.key,
    required this.assetPath,
    this.showFullscreenButton = false,
    this.onFullscreenTap,
  });

  final String assetPath;
  final bool showFullscreenButton;
  final VoidCallback? onFullscreenTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.white,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 6,
                boundaryMargin: const EdgeInsets.all(300),
                clipBehavior: Clip.none,
                child: Container(
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SvgPicture.asset(
                        assetPath,
                        fit: BoxFit.contain,
                        placeholderBuilder:
                            (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showFullscreenButton && onFullscreenTap != null)
            Positioned(
              right: 8,
              bottom: 8,
              child: InkWell(
                onTap: onFullscreenTap,
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
