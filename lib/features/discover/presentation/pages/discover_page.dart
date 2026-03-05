import 'package:flutter/material.dart';
import 'package:habitto/features/discover/presentation/pages/roommate_discovery_page.dart';
import 'package:habitto/features/likes/presentation/pages/likes_page.dart';
import 'package:habitto/features/profile/presentation/pages/create_search_profile_page.dart';
import 'package:habitto/features/search/presentation/pages/search_page.dart';
import 'package:habitto/shared/theme/app_theme.dart';
import 'package:habitto/shared/widgets/custom_network_image.dart';

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
        imageUrl:
            'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1200&q=80',
        big: true,
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
        imageUrl:
            'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
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
        imageUrl:
            'https://images.unsplash.com/photo-1460317442991-0ec209397118?auto=format&fit=crop&w=1200&q=80',
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
        imageUrl:
            'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1200&q=80',
        big: true,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 12.0;
          final width = constraints.maxWidth;
          final tileWidth = (width - (16 * 2) - spacing) / 2;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: items.map((item) {
                final isBig = item.big;
                return SizedBox(
                  width: isBig ? (tileWidth * 2) + spacing : tileWidth,
                  height: isBig ? 220 : 190,
                  child: _DiscoverImageCard(item: item),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _DiscoverImageCard extends StatelessWidget {
  final _DiscoverItem item;

  const _DiscoverImageCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                placeholder: Container(color: Colors.black12),
                errorWidget:
                    Container(color: item.accent.withValues(alpha: 0.35)),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.38)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.68),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: item.accent.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, color: Colors.white, size: 18),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Color.fromRGBO(0, 0, 0, 0.65),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE9EEF7),
                        shadows: [
                          Shadow(
                            color: Color.fromRGBO(0, 0, 0, 0.70),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
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

class _DiscoverItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String imageUrl;
  final bool big;
  final VoidCallback onTap;

  const _DiscoverItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.imageUrl,
    this.big = false,
    required this.onTap,
  });
}
