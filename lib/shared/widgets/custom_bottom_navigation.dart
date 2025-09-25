import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool showAddButton;

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.showAddButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9), // Semi-transparente
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              context,
              0,
              Icons.home_outlined,
              Icons.home,
              'Home',
            ),
            _buildNavItem(
              context,
              1,
              Icons.search_outlined,
              Icons.search,
              'Buscar',
            ),
            if (showAddButton)
              _buildAddButton(context),
            _buildNavItem(
              context,
              2,
              Icons.chat_bubble_outline,
              Icons.chat_bubble,
              'Chat',
            ),
            _buildNavItem(
              context,
              3,
              Icons.person_outline,
              Icons.person,
              'Perfil',
            ),
          ],
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
        decoration: const BoxDecoration(
          color: Color(0xFFA8E6CE),
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
    String label,
  ) {
    final isSelected = currentIndex == index;
    
    // Si está seleccionado, mostrar el efecto expandido con fondo amarillo
    if (isSelected) {
      return GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEB3B), // Fondo amarillo
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                activeIcon,
                color: Colors.black,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Si no está seleccionado, mostrar solo el ícono circular con fondo transparente
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2), // Fondo semi-transparente
          shape: BoxShape.circle,
        ),
        child: Icon(
          inactiveIcon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}