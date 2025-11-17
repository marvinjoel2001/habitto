import 'dart:ui' as ui;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../theme/app_theme.dart';

class SwipePropertyCard extends StatefulWidget {
  final List<String> images;
  final String title;
  final String priceLabel;
  final List<String> tags;
  final double? distanceKm;
  final double likeProgress; // 0..1 para overlay corazón
  final bool isDragging; // feedback visual al arrastrar
  final ValueChanged<int>? onOpenImage; // índice del image tap

  final double sidePadding;
  final double imageTopPadding;
  final double overlayBottomSpace;
  final double outerHorizontalPadding;
  final double outerTopPadding;

  const SwipePropertyCard({
    super.key,
    required this.images,
    required this.title,
    required this.priceLabel,
    required this.tags,
    this.distanceKm,
    required this.likeProgress,
    this.isDragging = false,
    this.onOpenImage,
    this.sidePadding = 0.0,
    this.imageTopPadding = 0.0,
    this.overlayBottomSpace = 16.0,
    this.outerHorizontalPadding = 16.0,
    this.outerTopPadding = 16.0,
  });

  @override
  State<SwipePropertyCard> createState() => _SwipePropertyCardState();
}

class _SwipePropertyCardState extends State<SwipePropertyCard> {
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _noImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 56, color: Colors.black54),
          SizedBox(height: 8),
          Text(
            'Sin imagen',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.outerHorizontalPadding,
        widget.outerTopPadding,
        widget.outerHorizontalPadding,
        0,
      ),
      child: SizedBox.expand(
        child: AnimatedScale(
          scale: widget.isDragging ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: const Border.fromBorderSide(
              BorderSide(color: Colors.white, width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(widget.isDragging ? 0.35 : 0.0),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Carrusel de imágenes
                PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.images.isNotEmpty ? widget.images.length : 1,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    if (widget.images.isEmpty) {
                      return _noImagePlaceholder();
                    }
                    final url = widget.images[i];
                    return Padding(
                      padding: EdgeInsets.only(
                        top: widget.imageTopPadding,
                        left: 0,
                        right: 0,
                        bottom: 10,
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: Colors.black12,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stack) => _noImagePlaceholder(),
                            ),
                          ),
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final w = constraints.maxWidth;
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (details) {
                                    final dx = details.localPosition.dx;
                                    final rightZone = dx > w * 0.66;
                                    final leftZone = dx < w * 0.34;
                                    if (rightZone) {
                                      if (_page < (widget.images.length - 1)) {
                                        _pageController.animateToPage(
                                          _page + 1,
                                          duration: const Duration(milliseconds: 220),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    } else if (leftZone) {
                                      if (_page > 0) {
                                        _pageController.animateToPage(
                                          _page - 1,
                                          duration: const Duration(milliseconds: 220),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    } else {
                                      widget.onOpenImage?.call(_page);
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Indicadores del carrusel
                Positioned(
                  top: 36,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.images.isNotEmpty ? widget.images.length : 1,
                      (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 42 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(active ? 0.9 : 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Chip superior (distancia) opcional
                if (widget.distanceKm != null)
                  Positioned(
                    top: 26,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_outlined, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.distanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Overlay inferior: blur + gradiente con mismo padding lateral que la imagen
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        padding: EdgeInsets.only(top: 16, bottom: widget.overlayBottomSpace),
                        decoration: BoxDecoration(
                          gradient: AppTheme.getCardGradient(opacity: 0.10),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.15),
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: AutoSizeText(
                                      widget.title,
                                      maxLines: 3,
                                      minFontSize: 18,
                                      stepGranularity: 1,
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Text(
                                    widget.priceLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.tags.map((t) => _GlassTag(label: t)).toList(),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Overlay de corazón (like) cuando arrastra a la derecha
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Opacity(
                    opacity: widget.likeProgress,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite, color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}

class _GlassTag extends StatelessWidget {
  final String label;
  const _GlassTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}