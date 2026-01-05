import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

class CustomChoiceChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const CustomChoiceChip({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected?.call(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                : AppTheme.lightGrayishDark,
            width: 1,
          ),
          boxShadow: [
            if (!selected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: selected ? AppTheme.primaryColor : Colors.black87,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.primaryColor : Colors.black87,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
