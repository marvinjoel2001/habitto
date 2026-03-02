import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../config/app_config.dart';

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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 170,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.blackColor.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _PropertyImage(imageUrl: imageUrl),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.5),
                            width: 1),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
    final isAsset = imageUrl.startsWith('assets/');
    final placeholder = Container(
      color: AppTheme.grayColor,
      alignment: Alignment.center,
      child: Icon(
        Icons.home,
        color: AppTheme.whiteColor.withValues(alpha: 0.7),
        size: 32,
      ),
    );

    if (isAsset) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    return Image.network(
      AppConfig.sanitizeUrl(imageUrl),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
