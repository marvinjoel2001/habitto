import 'dart:ui' as ui;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../generated/l10n.dart';

class SwipePropertyCard extends StatefulWidget {
  final List<String> images;
  final String title;
  final String priceLabel;
  final List<String> tags;
  final double? distanceKm;
  final double likeProgress; // 0..1 para overlay corazón
  final bool isDragging; // feedback visual al arrastrar
  final ValueChanged<int>? onOpenImage; // índice del image tap
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
    this.onOpenImage,
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
    print('SwipePropertyCard: images length ${widget.images.length}');
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
                  color:
                      Colors.white.withOpacity(widget.isDragging ? 0.35 : 0.0),
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
                                errorBuilder: (context, error, stack) =>
                                    _noImagePlaceholder(),
                                semanticLabel: 'property-image',
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
                                    } else {
                                      widget.onOpenImage?.call(_page);
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
                              color:
                                  Colors.white.withOpacity(active ? 0.9 : 0.6),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
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
                            const Icon(Icons.place_outlined,
                                color: Colors.white, size: 16),
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
                          padding: EdgeInsets.only(
                              top: 16,
                              // Si es negativo (solapamiento), usamos 0 o un valor positivo pequeño para el padding real,
                              // ya que el margen visual lo da el Positioned bottom.
                              // Pero aquí 'overlayBottomSpace' se pasaba como padding bottom directo.
                              // Si viene negativo, debemos ignorarlo en el padding y manejarlo de otra forma o usar 0.
                              bottom: widget.overlayBottomSpace < 0
                                  ? 16.0
                                  : widget.overlayBottomSpace),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.25),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withOpacity(0.25),
                                width: 1,
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
                                      padding:
                                          const EdgeInsets.only(left: 16.0),
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
                                  children: widget.tags
                                      .map((t) => _GlassTag(label: t))
                                      .toList(),
                                ),
                              ),
                              // Si el espacio inferior es negativo (para solapar botones),
                              // necesitamos asegurar un espacio mínimo para que el contenido no se corte
                              // pero permitiendo que el overlay "suba" visualmente.
                              // Usamos math.max para que nunca sea negativo el SizedBox.
                              SizedBox(
                                  height: widget.overlayBottomSpace < 0
                                      ? 16.0 // Padding mínimo visual si hay solapamiento
                                      : 16.0),
                            ],
                          ),
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
                                  color:
                                      AppTheme.secondaryColor.withOpacity(0.35),
                                  blurRadius: 36,
                                  spreadRadius: 10,
                                ),
                              ],
                              border: Border.all(
                                color:
                                    AppTheme.secondaryColor.withOpacity(0.65),
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: AppTheme.secondaryColor,
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
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 140,
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
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}
