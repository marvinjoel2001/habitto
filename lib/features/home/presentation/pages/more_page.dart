import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

/// Página "Más" que muestra opciones adicionales para inquilinos
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Más opciones',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                ),
              ),
              const SizedBox(height: 20),
              _buildOptionCard(
                context,
                icon: Icons.favorite_outline,
                title: 'Propiedades favoritas',
                subtitle: 'Ver tus propiedades guardadas',
                onTap: () {
                  Navigator.pushNamed(context, '/favorites');
                },
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                context,
                icon: Icons.history,
                title: 'Historial de búsqueda',
                subtitle: 'Ver tus búsquedas recientes',
                onTap: () {
                  Navigator.pushNamed(context, '/search-history');
                },
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                subtitle: 'Configurar tus notificaciones',
                onTap: () {
                  Navigator.pushNamed(context, '/notifications-settings');
                },
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                context,
                icon: Icons.help_outline,
                title: 'Ayuda y soporte',
                subtitle: 'Preguntas frecuentes y soporte',
                onTap: () {
                  Navigator.pushNamed(context, '/help');
                },
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                context,
                icon: Icons.settings_outlined,
                title: 'Configuración',
                subtitle: 'Ajustes de la aplicación',
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.darkGrayBase.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.darkGrayBase.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.darkGrayBase.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
