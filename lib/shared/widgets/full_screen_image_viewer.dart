import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, (widget.images.isNotEmpty ? widget.images.length - 1 : 0));
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.images.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (!widget.enableSwipeDownToClose) return;
            if (_isZoomed) return;
            _verticalDrag += details.delta.dy;
          },
          onVerticalDragEnd: (details) {
            if (!widget.enableSwipeDownToClose) return;
            if (_isZoomed) return;
            if (_verticalDrag > 100) {
              widget.onClose?.call();
              Navigator.of(context).maybePop();
            }
            _verticalDrag = 0.0;
          },
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
                          child: InteractiveViewer(
                            clipBehavior: Clip.none,
                            panEnabled: true,
                            minScale: 1.0,
                            maxScale: 4.0,
                            onInteractionUpdate: (details) {
                              final scale = details.scale;
                              final zooming = scale > 1.02;
                              if (zooming != _isZoomed) {
                                setState(() {
                                  _isZoomed = zooming;
                                });
                              }
                            },
                            onInteractionEnd: (_) {
                              if (_isZoomed) {
                                setState(() {
                                  _isZoomed = false;
                                });
                              }
                            },
                            child: Image.network(
                              url,
                              fit: BoxFit.contain,
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
      ),
    );
  }
}