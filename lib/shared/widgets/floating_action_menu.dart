import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FloatingActionMenu extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onHomeTap;
  final VoidCallback onMoreTap;
  final VoidCallback onClose;
  final VoidCallback? onSocialAreasTap;
  final VoidCallback? onAlertHistoryTap;

  const FloatingActionMenu({
    super.key,
    required this.isVisible,
    required this.onHomeTap,
    required this.onMoreTap,
    required this.onClose,
    this.onSocialAreasTap,
    this.onAlertHistoryTap,
  });

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FloatingActionMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Fullscreen overlay with 50% opacity
          GestureDetector(
            onTap: widget.onClose,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  color: Colors.black
                      .withValues(alpha: _fadeAnimation.value * 0.5),
                  width: double.infinity,
                  height: double.infinity,
                );
              },
            ),
          ),
          // Main content area with centered action buttons
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  alignment: Alignment.bottomCenter,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final buttonSize =
                                constraints.maxWidth < 360 ? 80.0 : 96.0;
                            final iconSize =
                                constraints.maxWidth < 360 ? 32.0 : 40.0;
                            final fontSize =
                                constraints.maxWidth < 360 ? 12.0 : 14.0;

                            return Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 32,
                              runSpacing: 24,
                              children: [
                                _buildActionButton(
                                  icon: Icons.favorite,
                                  label: 'Matchs',
                                  color: AppTheme.secondaryColor,
                                  onTap: widget.onHomeTap,
                                  buttonSize: buttonSize,
                                  iconSize: iconSize,
                                  fontSize: fontSize,
                                ),
                                _buildActionButton(
                                  icon: Icons.add_circle,
                                  label: 'Agregar propiedad',
                                  color: AppTheme.primaryColor,
                                  onTap: widget.onMoreTap,
                                  buttonSize: buttonSize,
                                  iconSize: iconSize,
                                  fontSize: fontSize,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Close button at bottom center
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: _buildCloseButton(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required double buttonSize,
    required double iconSize,
    required double fontSize,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    spreadRadius: 0,
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: iconSize,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.close,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
