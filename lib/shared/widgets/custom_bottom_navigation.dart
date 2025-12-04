// Top-level (imports)
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/app_theme.dart';

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
    if (widget.userMode != 'inquilino' && index == 0)
      return true; // Candidatos/Leads
    if (widget.userMode == 'propietario' && index == 1)
      return true; // Propiedades
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
    return Stack(
      children: [
        if (_isWhiteMode())
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 110,
              color: Colors.white,
            ),
          ),
        // Main navigation container with SafeArea
        SafeArea(
          top: false,
          child: Stack(
            children: [
              // Main navigation container
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: AnimatedContainer(
                    duration: _animDuration,
                    curve: _animCurve,
                    height: 72,
                    margin:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 0),
                    decoration: BoxDecoration(
                      gradient: _isWhiteMode()
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.72),
                                Colors.white.withValues(alpha: 0.62),
                              ],
                            )
                          : AppTheme.getCardGradient(opacity: 0.28),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: _isWhiteMode()
                            ? AppTheme.darkGrayBase.withValues(alpha: 0.12)
                            : AppTheme.darkGrayBase.withValues(alpha: 0.30),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isWhiteMode()
                              ? Colors.black.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.12),
                          spreadRadius: 0,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;
                        final selectedIndex = widget.currentIndex;
                        const double extraSelectedWidth = 38.0;
                        const double spacing = 8.0;
                        const int itemCount = 4;
                        const double totalSpacing = spacing * (itemCount - 1);
                        final double baseWidth =
                            ((totalWidth - totalSpacing - extraSelectedWidth) /
                                    itemCount)
                                .floorToDouble();

                        return ClipRect(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: _animDuration,
                                  curve: _animCurve,
                                  width: baseWidth +
                                      (selectedIndex == 0
                                          ? extraSelectedWidth
                                          : 0),
                                  child: Center(
                                    child: _buildNavItem(
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
                                            ? 'Explorar'
                                            : widget.userMode == 'propietario'
                                                ? 'Candidatos'
                                                : 'Leads'),
                                  ),
                                ),
                                const SizedBox(width: spacing),
                                AnimatedContainer(
                                  duration: _animDuration,
                                  curve: _animCurve,
                                  width: baseWidth +
                                      (selectedIndex == 1
                                          ? extraSelectedWidth
                                          : 0),
                                  child: Center(
                                    child: _buildNavItem(
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
                                            ? 'Mapa'
                                            : widget.userMode == 'propietario'
                                                ? 'Propiedades'
                                                : 'Portafolio'),
                                  ),
                                ),
                                const SizedBox(width: spacing),
                                AnimatedContainer(
                                  duration: _animDuration,
                                  curve: _animCurve,
                                  width: baseWidth +
                                      (selectedIndex == 2
                                          ? extraSelectedWidth
                                          : 0),
                                  child: Center(
                                    child: _buildNavItem(
                                        context,
                                        2,
                                        Icons.chat_bubble_outline,
                                        Icons.chat_bubble,
                                        widget.userMode == 'agente'
                                            ? 'Buzón'
                                            : 'Chat'),
                                  ),
                                ),
                                const SizedBox(width: spacing),
                                AnimatedContainer(
                                  duration: _animDuration,
                                  curve: _animCurve,
                                  width: baseWidth +
                                      (selectedIndex == 3
                                          ? extraSelectedWidth
                                          : 0),
                                  child: Center(
                                    child: _buildNavItem(
                                        context,
                                        3,
                                        Icons.person_outline,
                                        Icons.person,
                                        widget.userMode == 'agente'
                                            ? 'Perfil Prof.'
                                            : 'Perfil'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCenterButtonForOwners(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    return Semantics(
      button: true,
      label: _isFloatingMenuVisible ? 'Cerrar menú' : 'Abrir menú',
      child: InkWell(
        onTap: () {
          if (_isFloatingMenuVisible) {
            // Si el menú está visible, cerrarlo
            _closeFloatingMenu();
          } else {
            // Si no está visible, notificar al padre y abrir
            widget.onTap(2);
            _toggleFloatingMenu();
          }
        },
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.white.withValues(alpha: 0.3),
        highlightColor: Colors.white.withValues(alpha: 0.2),
        child: Container(
          width: 48 * textScaleFactor.clamp(0.9, 1.1),
          height: 48 * textScaleFactor.clamp(0.9, 1.1),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                spreadRadius: 0,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              _isFloatingMenuVisible ? Icons.close : Icons.home,
              color: Colors.white,
              size: 24 * textScaleFactor.clamp(0.9, 1.1),
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
    final itemColor = color ?? Theme.of(context).colorScheme.primary;
    final bool labelBlack = _isLabelBlackMode(index);
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    if (isSelected) {
      return Semantics(
        button: true,
        label: '$label activo',
        selected: true,
        child: InkWell(
          onTap: () {
            _closeFloatingMenu();
            widget.onTap(index);
          },
          borderRadius: BorderRadius.circular(25),
          splashColor: itemColor.withValues(alpha: 0.7),
          highlightColor: itemColor.withValues(alpha: 0.6),
          child: AnimatedContainer(
            duration: _animDuration,
            curve: _animCurve,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    activeIcon,
                    color: labelBlack ? AppTheme.darkGrayBase : Colors.white,
                    size: 18,
                  ),
                  if (label.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color:
                            labelBlack ? AppTheme.darkGrayBase : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12 * textScaleFactor.clamp(0.8, 1.2),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () {
          _closeFloatingMenu();
          widget.onTap(index);
        },
        borderRadius: BorderRadius.circular(28),
        splashColor: Colors.white.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: _animDuration,
          curve: _animCurve,
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(100),
            color: _isWhiteMode()
                ? Colors.white.withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: 0.18),
            border: Border.all(
              color: _isWhiteMode()
                  ? AppTheme.darkGrayBase.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.22),
              width: 0.9,
            ),
          ),
          child: Center(
            child: Icon(
              inactiveIcon,
              color: _isWhiteMode() ? AppTheme.darkGrayBase : Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
