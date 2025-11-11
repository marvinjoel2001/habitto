import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final VoidCallback? onClose;
  final bool enableSwipeDownToClose;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.onClose,
    this.enableSwipeDownToClose = true,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late final PageController _controller;
  late int _index;
  bool _isZoomed = false;
  double _verticalDrag = 0.0;
  late final TransformationController _transformController;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, (widget.images.isNotEmpty ? widget.images.length - 1 : 0));
    _controller = PageController(initialPage: _index);
    _transformController = TransformationController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.images.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              hasImages
                  ? PageView.builder(
                      controller: _controller,
                      physics: _isZoomed
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
                      onPageChanged: (i) => setState(() => _index = i),
                      itemCount: widget.images.length,
                      itemBuilder: (context, i) {
                        final url = widget.images[i];
                        return Container(
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onDoubleTap: () {
                              final scale = _transformController.value.getMaxScaleOnAxis();
                              final zooming = scale > 1.01;
                              if (zooming) {
                                // Reset a escala 1
                                _transformController.value = Matrix4.identity();
                                setState(() => _isZoomed = false);
                              } else {
                                // Zoom centrado
                                _transformController.value = Matrix4.identity()..scale(2.0);
                                setState(() => _isZoomed = true);
                              }
                            },
                            child: InteractiveViewer(
                              clipBehavior: Clip.hardEdge,
                              panEnabled: _isZoomed,
                              scaleEnabled: true,
                              minScale: 1.0,
                              maxScale: 4.0,
                              boundaryMargin: const EdgeInsets.symmetric(vertical: 160.0, horizontal: 0.0),
                              transformationController: _transformController,
                              onInteractionUpdate: (_) {
                                final scale = _transformController.value.getMaxScaleOnAxis();
                                final zooming = scale > 1.01;
                                if (zooming != _isZoomed) {
                                  setState(() {
                                    _isZoomed = zooming;
                                  });
                                }
                              },
                              onInteractionEnd: (_) {
                                final scale = _transformController.value.getMaxScaleOnAxis();
                                final zooming = scale > 1.01;
                                if (zooming != _isZoomed) {
                                  setState(() {
                                    _isZoomed = zooming;
                                  });
                                }
                              },
                              child: Center(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final width = constraints.maxWidth;
                                    return Image.network(
                                      url,
                                      width: width,
                                      fit: BoxFit.fitWidth,
                                      alignment: Alignment.center,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return const Center(
                                            child: CircularProgressIndicator(
                                                color: Colors.white));
                                      },
                                      errorBuilder: (context, error, stack) {
                                        return const Center(
                                          child: Icon(Icons.broken_image,
                                              color: Colors.white70, size: 64),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(Icons.image_not_supported,
                          color: Colors.white70, size: 64),
                    ),
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      hasImages ? widget.images.length : 1, (i) {
                    final active = i == _index;
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
                  }),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    widget.onClose?.call();
                    Navigator.of(context).maybePop();
                  },
                  tooltip: 'Cerrar',
                ),
              ),
            ],
          ),
        ),
    );
  }
}