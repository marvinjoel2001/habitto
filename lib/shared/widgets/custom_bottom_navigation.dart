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
  });

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation> {
  bool _isFloatingMenuVisible = false;
  OverlayEntry? _ownerOverlayEntry;
  OverlayEntry? _tenantOverlayEntry;

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
  }

  void _showOwnerOverlay() {
    if (_ownerOverlayEntry != null) return;
    _ownerOverlayEntry = OverlayEntry(
      builder: (ctx) => FloatingActionMenu(
        isVisible: true,
        onHomeTap: () {
          _hideOwnerOverlay();
          widget.onHomeTap();
        },
        onMoreTap: () {
          _hideOwnerOverlay();
          widget.onMoreTap();
        },
        onClose: _hideOwnerOverlay,
        onSocialAreasTap: () {
          _hideOwnerOverlay();
          Navigator.pushNamed(ctx, '/social-areas');
        },
        onAlertHistoryTap: () {
          _hideOwnerOverlay();
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
                  child: Container(
                    height: 84,
                    margin:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 0),
                    decoration: BoxDecoration(
                      gradient: AppTheme.getCardGradient(opacity: 0.28),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: AppTheme.darkGrayBase.withValues(alpha: 0.30),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          spreadRadius: 0,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;
                        final itemWidth =
                            totalWidth / 5; // Divide equally among 5 items

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: Center(
                                child: _buildNavItem(
                                    context,
                                    0,
                                    Icons.favorite_outline,
                                    Icons.favorite,
                                    'Likes'),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: Center(
                                child: _buildNavItem(
                                    context,
                                    1,
                                    Icons.search_outlined,
                                    Icons.search,
                                    'Buscar'),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: Center(
                                child: widget.isOwnerOrAgent
                                    ? _buildCenterButtonForOwners(context)
                                    : _buildNavItem(
                                        context,
                                        2,
                                        Icons.credit_card,
                                        Icons.credit_card,
                                        '',
                                        color: AppTheme.primaryColor),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: Center(
                                child: _buildNavItem(
                                    context,
                                    3,
                                    Icons.chat_bubble_outline,
                                    Icons.chat_bubble,
                                    'Chat'),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: Center(
                                child: _buildNavItem(
                                    context,
                                    4,
                                    Icons.person_outline,
                                    Icons.person,
                                    'Perfil'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Overlays ahora se insertan usando OverlayEntry a nivel de app,
        // no dentro del bottom navigation
      ],
    );
  }

  Widget _buildCenterButtonForOwners(BuildContext context) {
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);

    return Semantics(
      button: true,
      label: _isFloatingMenuVisible ? 'Cerrar menú' : 'Abrir menú',
      child: InkWell(
        onTap: () {
          // First call the onTap callback to let the parent know
          widget.onTap(2);
          // Then toggle the floating menu
          _toggleFloatingMenu();
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
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);

    if (isSelected) {
      return Semantics(
        button: true,
        label: '$label activo',
        selected: true,
        child: InkWell(
          onTap: () => widget.onTap(index),
          borderRadius: BorderRadius.circular(25),
          splashColor: itemColor.withValues(alpha: 0.7),
          highlightColor: itemColor.withValues(alpha: 0.6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: itemColor.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: itemColor.withValues(alpha: 0.5),
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
                  Icon(activeIcon, color: Colors.white, size: 18),
                  if (label.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
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
        onTap: () => widget.onTap(index),
        borderRadius: BorderRadius.circular(28),
        splashColor: Colors.white.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(inactiveIcon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
