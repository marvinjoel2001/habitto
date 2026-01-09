import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class PropertyCardSkeleton extends StatefulWidget {
  final double overlayBottomSpace;
  final double outerHorizontalPadding;
  final double outerTopPadding;

  const PropertyCardSkeleton({
    super.key,
    this.overlayBottomSpace = 16.0,
    this.outerHorizontalPadding = 16.0,
    this.outerTopPadding = 16.0,
  });

  @override
  State<PropertyCardSkeleton> createState() => _PropertyCardSkeletonState();
}

class _PropertyCardSkeletonState extends State<PropertyCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient get _shimmerGradient => LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.1),
        ],
        stops: const [0.1, 0.5, 0.9],
        begin: const Alignment(-1.0, -0.3),
        end: const Alignment(1.0, 0.3),
        transform: _SlidingGradientTransform(percent: _controller.value),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            widget.outerHorizontalPadding,
            widget.outerTopPadding,
            widget.outerHorizontalPadding,
            0,
          ),
          child: SizedBox.expand(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: const Border.fromBorderSide(
                  BorderSide(color: Colors.white, width: 2),
                ),
                color: Colors.black.withValues(alpha: 0.2), // Base color
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Main Shimmer Background (Image placeholder)
                    Container(
                      decoration: BoxDecoration(
                        gradient: _shimmerGradient,
                      ),
                    ),

                    // Top Indicators Placeholder
                    Positioned(
                      top: 36,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == 0 ? 42 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Distance Chip Placeholder
                    Positioned(
                      top: 26,
                      left: 12,
                      child: Container(
                        width: 80,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                    // Bottom Content Placeholder
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
                              bottom: widget.overlayBottomSpace < 0
                                  ? 16.0
                                  : widget.overlayBottomSpace,
                              left: 16,
                              right: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.15),
                                  Colors.white.withValues(alpha: 0.05),
                                ],
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Title and Price Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 80,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Tags Row
                                Row(
                                  children: List.generate(
                                    3,
                                    (index) => Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      width: 60,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.1)),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    height: widget.overlayBottomSpace < 0
                                        ? 16.0
                                        : 16.0),
                              ],
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
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.percent,
  });

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0, 0);
  }
}
