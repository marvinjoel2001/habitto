// Top-level (imports)
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/app_theme.dart';
import '../../generated/l10n.dart';

import 'floating_action_menu.dart';
import 'tenant_floating_menu.dart';

class CustomBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool showAddButton;
  final bool isOwnerOrAgent;
  final VoidCallback onHomeTap;
  final VoidCallback onMoreTap;
  final bool showTenantFloatingMenu;
  final VoidCallback onTenantMenuClose;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onGoBack;
  final VoidCallback onAddFavorite;
  final VoidCallback? onAiChatTap;
  final String userMode; // 'inquilino' | 'propietario' | 'agente'

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showAddButton = false,
    required this.isOwnerOrAgent,
    required this.onHomeTap,
    required this.onMoreTap,
    this.showTenantFloatingMenu = false,
    required this.onTenantMenuClose,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onGoBack,
    required this.onAddFavorite,
    this.onAiChatTap,
    required this.userMode,
  });

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation> {
  bool _isFloatingMenuVisible = false;
  OverlayEntry? _ownerOverlayEntry;
  OverlayEntry? _tenantOverlayEntry;
  final Duration _animDuration = const Duration(milliseconds: 220);
  final Curve _animCurve = Curves.easeOutCubic;

  bool _isWhiteMode() {
    if (widget.currentIndex == 2) {
      return true; // Chat/Buzón
    }
    if (widget.userMode != 'inquilino') {
      if (widget.currentIndex == 0) return true; // Candidatos/Leads
      if (widget.currentIndex == 1) return true; // Propiedades/Portafolio
    }
    return false;
  }

  bool _isLabelBlackMode(int index) {
    if (index == 2) return true; // Chat
    if (widget.userMode != 'inquilino' && index == 0) {
      return true; // Candidatos/Leads
    }
    if (widget.userMode == 'propietario' && index == 1) {
      return true; // Propiedades
    }
    return false;
  }

  void _toggleFloatingMenu() {
    setState(() {
      _isFloatingMenuVisible = !_isFloatingMenuVisible;
    });
    if (_isFloatingMenuVisible) {
      _showOwnerOverlay();
    } else {
      _hideOwnerOverlay();
    }
  }

  void _closeFloatingMenu() {
    if (_isFloatingMenuVisible) {
      setState(() {
        _isFloatingMenuVisible = false;
      });
    }
    _hideOwnerOverlay();
    _hideTenantOverlay();
  }

  void _showOwnerOverlay() {
    if (_ownerOverlayEntry != null) return;
    _ownerOverlayEntry = OverlayEntry(
      builder: (ctx) => FloatingActionMenu(
        isVisible: true,
        onHomeTap: () {
          _closeFloatingMenu();
          widget.onHomeTap();
        },
        onMoreTap: () {
          _closeFloatingMenu();
          Navigator.pushNamed(ctx, '/add-property');
        },
        onClose: _closeFloatingMenu,
        onAiChatTap: () {
          _closeFloatingMenu();
          widget.onAiChatTap?.call();
        },
        onSocialAreasTap: () {
          _closeFloatingMenu();
          Navigator.pushNamed(ctx, '/social-areas');
        },
        onAlertHistoryTap: () {
          _closeFloatingMenu();
          Navigator.pushNamed(ctx, '/alert-history');
        },
      ),
    );
    Overlay.of(context).insert(_ownerOverlayEntry!);
  }

  void _hideOwnerOverlay() {
    _ownerOverlayEntry?.remove();
    _ownerOverlayEntry = null;
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
        onAddFavorite: () {
          _hideTenantOverlay();
          widget.onAddFavorite();
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
    // Cerrar cualquier overlay al cambiar de página o estado
    if (oldWidget.currentIndex != widget.currentIndex) {
      _closeFloatingMenu();
    }
    if (!widget.isOwnerOrAgent) {
      if (widget.showTenantFloatingMenu && _tenantOverlayEntry == null) {
        _showTenantOverlay();
      } else if (!widget.showTenantFloatingMenu &&
          _tenantOverlayEntry != null) {
        _hideTenantOverlay();
      }
    } else {
      if (_tenantOverlayEntry != null) {
        _hideTenantOverlay();
      }
    }
  }

  @override
  void dispose() {
    _hideOwnerOverlay();
    _hideTenantOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    const double navHeight = 70.0;

    return SizedBox(
      height: navHeight + 40, // Extra space for floating button
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Background with Curve
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: navHeight,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: CustomPaint(
                  painter: _NavCurvePainter(
                    color: Colors.white.withValues(alpha: 0.85),
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
          ),

          // Navigation Items
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: navHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                    context,
                    0,
                    widget.userMode == 'inquilino'
                        ? Icons.style_outlined
                        : widget.userMode == 'propietario'
                            ? Icons.group_outlined
                            : Icons.leaderboard_outlined,
                    widget.userMode == 'inquilino'
                        ? Icons.style
                        : widget.userMode == 'propietario'
                            ? Icons.groups
                            : Icons.leaderboard,
                    widget.userMode == 'inquilino'
                        ? S.of(context).navExplore
                        : widget.userMode == 'propietario'
                            ? S.of(context).navCandidates
                            : S.of(context).navLeads),
                _buildNavItem(
                    context,
                    1,
                    widget.userMode == 'inquilino'
                        ? Icons.map_outlined
                        : widget.userMode == 'propietario'
                            ? Icons.home_work_outlined
                            : Icons.domain_outlined,
                    widget.userMode == 'inquilino'
                        ? Icons.map
                        : widget.userMode == 'propietario'
                            ? Icons.home_work
                            : Icons.domain,
                    widget.userMode == 'inquilino'
                        ? S.of(context).navMap
                        : widget.userMode == 'propietario'
                            ? S.of(context).navProperties
                            : S.of(context).navPortfolio),
                const SizedBox(width: 56), // Space for center button
                _buildNavItem(
                    context,
                    2,
                    Icons.chat_bubble_outline,
                    Icons.chat_bubble,
                    widget.userMode == 'agente'
                        ? S.of(context).navInbox
                        : S.of(context).navChat),
                _buildNavItem(
                    context,
                    3,
                    Icons.person_outline,
                    Icons.person,
                    widget.userMode == 'agente'
                        ? S.of(context).navProfProfile
                        : S.of(context).navProfile),
              ],
            ),
          ),

          // Center Button (Floating)
          Positioned(
            top: 10, // Adjust to sit in the notch
            child: widget.userMode == 'inquilino'
                ? _buildCenterButtonForTenants(context)
                : _buildCenterButtonForOwners(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterButtonForOwners(BuildContext context) {
    return Semantics(
      button: true,
      label: _isFloatingMenuVisible
          ? S.of(context).closeMenu
          : S.of(context).openMenu,
      child: GestureDetector(
        onTap: () {
          if (_isFloatingMenuVisible) {
            _closeFloatingMenu();
          } else {
            widget.onTap(2);
            _toggleFloatingMenu();
          }
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              _isFloatingMenuVisible ? Icons.close : Icons.home,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButtonForTenants(BuildContext context) {
    return Semantics(
      button: true,
      label: S.of(context).navChat,
      child: GestureDetector(
        onTap: widget.onAiChatTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/add-property');
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData inactiveIcon,
    IconData activeIcon,
    String label, {
    Color? color,
  }) {
    final isSelected = widget.currentIndex == index;
    // High contrast for accessibility
    const activeColor = AppTheme.primaryColor;
    const inactiveColor = Colors.black54;

    return Semantics(
      button: true,
      label: isSelected ? S.of(context).navItemActive(label) : label,
      selected: isSelected,
      child: InkWell(
        onTap: () {
          _closeFloatingMenu();
          widget.onTap(index);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: activeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ]
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

  _NavCurvePainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    // Aumentamos el radio de influencia para suavizar la curva (hacerla menos "puntiaguda")
    const double curveWidth = 55.0;
    final double center = size.width / 2;
    const double notchDepth = 38.0;

    path.moveTo(0, 0);
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

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw Shadow
    canvas.drawShadow(path, shadowColor, 10.0, true);

    // Draw Shape
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
