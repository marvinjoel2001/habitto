import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import 'custom_network_image.dart';
import '../theme/app_theme.dart';
import '../../config/app_config.dart';
import '../../generated/l10n.dart';

class SwipePropertyCard extends StatefulWidget {
  final List<String> images;
  final String title;
  final String priceLabel;
  final List<String> tags;
  final double? distanceKm;
  final double likeProgress; // 0..1 para overlay corazón
  final bool isDragging; // feedback visual al arrastrar
  final double dragDx; // posición actual del drag para calcular opacidad

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
    this.dragDx = 0.0,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported,
              size: 56, color: Colors.black54),
          const SizedBox(height: 8),
          Text(
            S.of(context).noImagePlaceholder,
            style: const TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Función para calcular la opacidad del icono de rechazo (X)
  double _rejectProgressFromDx(double dx, double width) {
    // Solo izquierda; progreso en función del ancho
    if (dx >= 0) return 0.0; // No hay rechazo si se arrastra a la derecha
    final required = width * 0.35;
    final p = ((-dx) / required).clamp(0.0, 1.0);
    return p;
  }

  // Función para calcular la opacidad inicial (30%) cuando empieza el drag
  double _calculateInitialOpacity(double progress) {
    if (progress <= 0) return 0.0;
    return (0.3 + (progress * 0.7)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final visibleTags = widget.tags.where((t) => t.trim().isNotEmpty).toList();
    final mainTags = visibleTags.take(3).toList();
    final remainingTags = visibleTags.length - mainTags.length;
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
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white
                      .withValues(alpha: widget.isDragging ? 0.35 : 0.0),
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
                  PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        widget.images.isNotEmpty ? widget.images.length : 1,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) {
                      if (widget.images.isEmpty) {
                        return _noImagePlaceholder();
                      }
                      final url = widget.images[i];
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: CustomNetworkImage(
                                imageUrl: AppConfig.sanitizeUrl(url),
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  color: Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                ),
                                errorWidget: _noImagePlaceholder(),
                              ),
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
                                          duration:
                                              const Duration(milliseconds: 220),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    } else if (leftZone) {
                                      if (_page > 0) {
                                        _pageController.animateToPage(
                                          _page - 1,
                                          duration:
                                              const Duration(milliseconds: 220),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: IgnorePointer(
                        child: Container(
                          color: Colors.black.withValues(
                            alpha: (0.0 + (widget.likeProgress * 0.45))
                                .clamp(0.0, 0.45),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: IgnorePointer(
                        child: Container(
                          color: Colors.white.withValues(
                            alpha: (0.0 +
                                    (_rejectProgressFromDx(widget.dragDx,
                                            MediaQuery.of(context).size.width) *
                                        0.45))
                                .clamp(0.0, 0.45),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      children: List.generate(
                        widget.images.isNotEmpty ? widget.images.length : 1,
                        (i) {
                          final active = i == _page;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(alpha: active ? 0.95 : 0.45),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: EdgeInsets.only(
                            top: 52,
                            bottom: widget.overlayBottomSpace < 0
                                ? 16.0
                                : widget.overlayBottomSpace),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: 0.64),
                              Colors.black.withValues(alpha: 0.92),
                            ],
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
                                      maxLines: 2,
                                      minFontSize: 17,
                                      stepGranularity: 1,
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        shadows: [
                                          Shadow(
                                            color:
                                                Color.fromRGBO(0, 0, 0, 0.72),
                                            blurRadius: 10,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      shadows: [
                                        Shadow(
                                          color: Color.fromRGBO(0, 0, 0, 0.78),
                                          blurRadius: 8,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (mainTags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16.0, right: 16.0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      ...mainTags.map((t) => Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: _GlassTag(label: t),
                                          )),
                                      if (remainingTags > 0)
                                        _GlassTag(label: '+$remainingTags'),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Overlay de corazón (like) cuando arrastra a la derecha (centrado, verde del tema, tamaño grande)
                  Align(
                    alignment: Alignment.center,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: _calculateInitialOpacity(widget.likeProgress),
                        child: Transform.scale(
                          scale: 0.9 + (widget.likeProgress * 0.3),
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.35),
                                  blurRadius: 36,
                                  spreadRadius: 10,
                                ),
                              ],
                              border: Border.all(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.65),
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: AppTheme.primaryColor,
                              size: 88,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Overlay de X (reject) cuando arrastra a la izquierda - SIN fondo circular (centrado, tamaño grande)
                  Align(
                    alignment: Alignment.center,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: _calculateInitialOpacity(_rejectProgressFromDx(
                            widget.dragDx, MediaQuery.of(context).size.width)),
                        child: Transform.scale(
                          scale: 0.9 +
                              (_rejectProgressFromDx(widget.dragDx,
                                      MediaQuery.of(context).size.width) *
                                  0.3),
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.redAccent.withValues(alpha: 0.35),
                                  blurRadius: 36,
                                  spreadRadius: 10,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.65),
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.thumb_down_rounded,
                              color: Colors.redAccent,
                              size: 88,
                            ),
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
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: Color.fromRGBO(0, 0, 0, 0.75),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
