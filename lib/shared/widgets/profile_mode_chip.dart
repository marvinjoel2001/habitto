// Top-level (imports)
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class ProfileModeChip extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const ProfileModeChip({
    Key? key,
    required this.text,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.35)
                  : Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                    : Colors.white.withOpacity(0.40),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
