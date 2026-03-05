import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:habitto/features/discover/presentation/pages/roommate_discovery_page.dart';
import 'package:habitto/features/likes/presentation/pages/likes_page.dart';
import 'package:habitto/features/profile/presentation/pages/create_search_profile_page.dart';
import 'package:habitto/features/search/presentation/pages/search_page.dart';
import 'package:habitto/shared/theme/app_theme.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_DiscoverItem>[
      _DiscoverItem(
        title: 'Encuentra Roomies',
        subtitle: 'Descubre personas compatibles para compartir alquiler',
        icon: Icons.people_alt_outlined,
        accent: AppTheme.primaryColor,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoommateDiscoveryPage()),
          );
        },
      ),
      _DiscoverItem(
        title: 'Precios por Zona',
        subtitle: 'Revisa el mapa y compara precios por zonas',
        icon: Icons.map_outlined,
        accent: AppTheme.secondaryColor,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchPage()),
          );
        },
      ),
      _DiscoverItem(
        title: 'Tus Favoritos',
        subtitle: 'Mira y gestiona las propiedades que te interesan',
        icon: Icons.favorite_border,
        accent: AppTheme.accentMint,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LikesPage()),
          );
        },
      ),
      _DiscoverItem(
        title: 'Ajusta tu Búsqueda',
        subtitle: 'Actualiza tus criterios para mejorar los matches',
        icon: Icons.tune,
        accent: Colors.orangeAccent,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSearchProfilePage()),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Descubre'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.10),
                  child: InkWell(
                    onTap: item.onTap,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: Colors.white.withValues(alpha: 0.30)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            item.accent.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0.06),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: item.accent.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Icon(item.icon, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.subtitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DiscoverItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _DiscoverItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });
}
