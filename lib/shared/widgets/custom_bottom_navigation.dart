// Top-level (imports)
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/app_theme.dart';
import '../../generated/l10n.dart';

import 'tenant_floating_menu.dart';

class CustomBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool showTenantFloatingMenu;
  final VoidCallback onTenantMenuClose;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onGoBack;
  final String userMode; // 'inquilino' | 'propietario' | 'agente'

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showTenantFloatingMenu = false,
    required this.onTenantMenuClose,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onGoBack,
    required this.userMode,
  });

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation> {
  OverlayEntry? _tenantOverlayEntry;

  void _closeFloatingMenu() {
    _hideTenantOverlay();
  }

  void _showTenantOverlay() {
    if (_tenantOverlayEntry != null) return;
    _tenantOverlayEntry = OverlayEntry(
      builder: (ctx) => TenantFloatingMenu(
        isVisible: true,
        onClose: () {
          _hideTenantOverlay();
          widget.onTenantMenuClose();
        },
        onSwipeLeft: () {
          _hideTenantOverlay();
          widget.onSwipeLeft();
        },
        onSwipeRight: () {
          _hideTenantOverlay();
          widget.onSwipeRight();
        },
        onGoBack: () {
          _hideTenantOverlay();
          widget.onGoBack();
        },
      ),
    );
    Overlay.of(context).insert(_tenantOverlayEntry!);
  }

  void _hideTenantOverlay() {
    _tenantOverlayEntry?.remove();
    _tenantOverlayEntry = null;
  }

  @override
  void didUpdateWidget(CustomBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _closeFloatingMenu();
    }
    if (widget.showTenantFloatingMenu && _tenantOverlayEntry == null) {
      _showTenantOverlay();
    } else if (!widget.showTenantFloatingMenu && _tenantOverlayEntry != null) {
      _hideTenantOverlay();
    }
  }

  @override
  void dispose() {
    _hideTenantOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    const double navHeight = 70.0;
    final strings = Localizations.of<S>(context, S);

    return SizedBox(
      height: navHeight + bottomPadding,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Background with Curve
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: navHeight + bottomPadding,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: CustomPaint(
                  painter: _NavCurvePainter(
                    color: Colors.white.withValues(alpha: 0.85),
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                    hasNotch: false,
                  ),
                ),
              ),
            ),
          ),

          // Navigation Items
          Positioned(
            bottom: bottomPadding,
            left: 0,
            right: 0,
            height: navHeight,
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    context,
                    0,
                    Icons.favorite_border,
                    Icons.favorite_border,
                    strings?.menuMatchs ?? 'Matches',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    context,
                    1,
                    widget.userMode == 'inquilino'
                        ? Icons.explore_outlined
                        : Icons.home_work_outlined,
                    widget.userMode == 'inquilino'
                        ? Icons.explore
                        : Icons.home_work_outlined,
                    widget.userMode == 'inquilino'
                        ? 'Descubre'
                        : (strings?.navProperties ?? 'Propiedades'),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    context,
                    2,
                    Icons.chat_bubble_outline,
                    Icons.chat_bubble_outline,
                    strings?.navChat ?? 'Chat',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    context,
                    3,
                    Icons.person_outline,
                    Icons.person_outline,
                    strings?.navProfile ?? 'Perfil',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = widget.currentIndex == index;
    final strings = Localizations.of<S>(context, S);
    // High contrast for accessibility
    const activeColor = AppTheme.primaryColor;
    const inactiveColor = Colors.black54;

    return Semantics(
      button: true,
      label: isSelected
          ? (strings?.navItemActive(label) ?? 'Activo: $label')
          : label,
      selected: isSelected,
      child: InkWell(
        onTap: () {
          _closeFloatingMenu();
          widget.onTap(index);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textScaler: const TextScaler.linear(1.0),
                style: TextStyle(
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: isSelected ? 10 : 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCurvePainter extends CustomPainter {
  final Color color;
  final Color shadowColor;
  final bool hasNotch;

  _NavCurvePainter({
    required this.color,
    required this.shadowColor,
    this.hasNotch = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);

    if (hasNotch) {
      // Aumentamos el radio de influencia para suavizar la curva (hacerla menos "puntiaguda")
      const double curveWidth = 55.0;
      final double center = size.width / 2;
      const double notchDepth = 38.0;

      // Empezar la curva más lejos del centro
      path.lineTo(center - curveWidth * 1.6, 0);

      // Cubic bezier más suave y amplio
      path.cubicTo(
        center - curveWidth, 0, // CP1: Mantiene la horizontalidad más tiempo
        center - curveWidth * 0.5, notchDepth, // CP2: Baja suavemente
        center, notchDepth, // End: Centro fondo
      );

      path.cubicTo(
        center + curveWidth * 0.5, notchDepth, // CP1: Sube suavemente
        center + curveWidth, 0, // CP2: Recupera horizontalidad
        center + curveWidth * 1.6, 0, // End: Fin de la curva
      );
    }

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw Shadow
    canvas.drawShadow(path, shadowColor, 10.0, true);

    // Draw Shape
    canvas.drawPath(path, paint);

    // Draw Top Border
    final borderPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final borderPath = Path();
    borderPath.moveTo(0, 0);

    if (hasNotch) {
      const double curveWidth = 55.0;
      final double center = size.width / 2;
      const double notchDepth = 38.0;

      borderPath.lineTo(center - curveWidth * 1.6, 0);

      borderPath.cubicTo(
        center - curveWidth,
        0,
        center - curveWidth * 0.5,
        notchDepth,
        center,
        notchDepth,
      );

      borderPath.cubicTo(
        center + curveWidth * 0.5,
        notchDepth,
        center + curveWidth,
        0,
        center + curveWidth * 1.6,
        0,
      );
    }

    borderPath.lineTo(size.width, 0);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _NavCurvePainter oldDelegate) =>
      color != oldDelegate.color ||
      shadowColor != oldDelegate.shadowColor ||
      hasNotch != oldDelegate.hasNotch;
}
