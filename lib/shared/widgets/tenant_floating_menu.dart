import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TenantFloatingMenu extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onGoBack;
  final VoidCallback onAddFavorite;

  const TenantFloatingMenu({
    super.key,
    required this.isVisible,
    required this.onClose,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onGoBack,
    required this.onAddFavorite,
  });

  @override
  State<TenantFloatingMenu> createState() => _TenantFloatingMenuState();
}

class _TenantFloatingMenuState extends State<TenantFloatingMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200), // Faster animation
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isVisible) {
      // Start animation immediately without delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(TenantFloatingMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      // Start animation immediately when becoming visible
      _controller.forward(from: 0.0);
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.reverse(from: 1.0);
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
          // Semi-transparent overlay (50% opacity)
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Menu positioned exactly above the navigation button
          Positioned(
            bottom: 100, // Positioned exactly above navigation bar
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
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.getCardGradient(opacity: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.darkGrayBase.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              spreadRadius: 0,
                              blurRadius: 25,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmallScreen = constraints.maxWidth < 320;
                            final buttonSize = isSmallScreen ? 48.0 : 64.0;
                            final iconSize = isSmallScreen ? 24.0 : 28.0;
                            final spacing = isSmallScreen ? 8.0 : 12.0;
                            
                            return Wrap(
                              spacing: spacing,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildActionButton(
                                  icon: Icons.rotate_left,
                                  color: Colors.amber,
                                  onTap: widget.onGoBack,
                                  label: 'Deshacer',
                                  buttonSize: buttonSize,
                                  iconSize: iconSize,
                                ),
                                _buildActionButton(
                                  icon: Icons.close,
                                  color: Colors.redAccent,
                                  onTap: widget.onSwipeLeft,
                                  label: 'Rechazar',
                                  buttonSize: buttonSize,
                                  iconSize: iconSize,
                                ),
                                _buildActionButton(
                                  icon: Icons.favorite,
                                  color: AppTheme.secondaryColor,
                                  onTap: widget.onSwipeRight,
                                  label: 'Like',
                                  buttonSize: buttonSize,
                                  iconSize: iconSize,
                                ),
                                _buildActionButton(
                                  icon: Icons.star,
                                  color: Colors.blueAccent,
                                  onTap: widget.onAddFavorite,
                                  label: 'Favorito',
                                  buttonSize: buttonSize,
                                  iconSize: iconSize,
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
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
    double buttonSize = 64.0,
    double iconSize = 28.0,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}