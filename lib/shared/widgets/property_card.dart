import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import 'dart:ui' as ui;


class PropertyCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String status;
  final Color statusColor;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const PropertyCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    required this.status,
    required this.statusColor,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
          color: AppTheme.whiteColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.whiteColor.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.blackColor.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Imagen de la propiedad
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.grayColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _PropertyImage(imageUrl: imageUrl),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Información de la propiedad
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.blackColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.whiteColor.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Estado de la propiedad
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: statusColor,
                            ),
                          ),
                        ),
                        if (showActions) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (onEdit != null)
                                _ActionButton(
                                  icon: Icons.edit,
                                  label: 'Editar',
                                  onTap: onEdit!,
                                  color: AppTheme.primaryColor,
                                ),
                              if (onEdit != null && onDelete != null)
                                const SizedBox(width: 8),
                              if (onDelete != null)
                                _ActionButton(
                                  icon: Icons.delete_outline,
                                  label: 'Eliminar',
                                  onTap: onDelete!,
                                  color: AppTheme.errorColor,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clase auxiliar para diferentes estados de propiedades
class PropertyStatus {
  static const Color disponible = Color(0xFF4CAF50); // Verde
  static const Color alquilado = Color(0xFF2196F3); // Azul
  static const Color mantenimiento = Color(0xFFFF9800); // Naranja
  static const Color inactivo = Color(0xFF9E9E9E); // Gris
  static const Color pendiente = Color(0xFFFFC107); // Amarillo
}
class _PropertyImage extends StatelessWidget {
  final String imageUrl;
  const _PropertyImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isNetwork = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    final placeholder = Container(
      color: AppTheme.grayColor,
      alignment: Alignment.center,
      child: Icon(
        Icons.home,
        color: AppTheme.whiteColor.withValues(alpha: 0.7),
        size: 32,
      ),
    );

    if (isNetwork) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }
    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
