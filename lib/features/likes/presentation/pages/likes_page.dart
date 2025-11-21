import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

/// Página de Likes para mostrar propiedades que han gustado al usuario
class LikesPage extends StatelessWidget {
  const LikesPage({super.key});

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
                'Tus Likes',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Propiedades que te han gustado',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.darkGrayBase.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_outline,
                        size: 64,
                        color: AppTheme.darkGrayBase.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aún no has dado like a ninguna propiedad',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.darkGrayBase.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Explora y descubre tu próximo hogar',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.darkGrayBase.withValues(alpha: 0.4),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}