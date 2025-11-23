import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../profile/data/services/profile_service.dart';
import '../../../properties/data/services/property_service.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../profile/domain/entities/profile.dart' as profile_entity;

/// Página de Likes para mostrar propiedades favoritas del usuario
class LikesPage extends StatefulWidget {
  const LikesPage({super.key});

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  final ProfileService _profileService = ProfileService();
  final PropertyService _propertyService = PropertyService();
  
  List<Property> _favoriteProperties = [];
  Map<int, profile_entity.Profile> _ownerProfiles = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavoriteProperties();
  }

  Future<void> _loadFavoriteProperties() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Obtener el perfil del usuario actual para acceder a sus favoritos
      final currentProfileData = await _profileService.getCurrentProfile();
      final profileData = currentProfileData['data'];
      if (profileData == null || profileData['profile'] == null) {
        throw Exception('No se pudo obtener el perfil del usuario');
      }
      final profile = profileData['profile'] as profile_entity.Profile;
      final favoriteIds = profile.favorites;

      if (favoriteIds.isEmpty) {
        setState(() {
          _favoriteProperties = [];
          _isLoading = false;
        });
        return;
      }

      // Cargar las propiedades favoritas
      final properties = <Property>[];
      final ownerIds = <int>{};
      
      for (final propertyId in favoriteIds) {
        try {
          final propertyData = await _propertyService.getPropertyById(propertyId);
          final property = propertyData['data'] as Property;
          properties.add(property);
          ownerIds.add(property.agent ?? property.owner);
        } catch (e) {
          print('Error al cargar propiedad $propertyId: $e');
        }
      }

      // Cargar perfiles de los propietarios/agentes
      final ownerProfiles = <int, profile_entity.Profile>{};
      for (final ownerId in ownerIds) {
        try {
          final ownerProfileData = await _profileService.getProfileByUserId(ownerId);
          final ownerProfile = ownerProfileData['data'] as profile_entity.Profile;
          ownerProfiles[ownerId] = ownerProfile;
        } catch (e) {
          print('Error al cargar perfil del propietario $ownerId: $e');
        }
      }

      setState(() {
        _favoriteProperties = properties;
        _ownerProfiles = ownerProfiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar propiedades favoritas';
        _isLoading = false;
      });
      print('Error al cargar favoritos: $e');
    }
  }

  Future<void> _removeFavorite(Property property) async {
    try {
      HapticFeedback.lightImpact();
      
      await _profileService.removeFavoriteViaApi(property.id);
      
      // Actualizar la lista local
      setState(() {
        _favoriteProperties.remove(property);
      });
      
      // Mostrar feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${property.type} en ${property.address} eliminado de favoritos'),
            backgroundColor: AppTheme.secondaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar de favoritos'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      print('Error al eliminar favorito: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFavoriteProperties,
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.darkGrayBase,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
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
                          color: AppTheme.whiteColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Propiedades que te han gustado',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.whiteColor.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.whiteColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.whiteColor.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadFavoriteProperties,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_favoriteProperties.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_outline,
                          size: 64,
                          color: AppTheme.whiteColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aún no has dado like a ninguna propiedad',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.whiteColor.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explora y descubre tu próximo hogar',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.whiteColor.withValues(alpha: 0.4),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final property = _favoriteProperties[index];
                        final ownerProfile = _ownerProfiles[property.agent ?? property.owner];
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildPropertyCard(property, ownerProfile),
                        );
                      },
                      childCount: _favoriteProperties.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Property property, profile_entity.Profile? ownerProfile) {
    return Container(
      decoration: AppTheme.getGlassCard(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Imagen de fondo
            Positioned.fill(
              child: property.mainPhoto != null
                  ? Image.network(
                      property.mainPhoto!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.mediumGray,
                          child: Icon(
                            Icons.home_outlined,
                            size: 80,
                            color: AppTheme.whiteColor.withValues(alpha: 0.3),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppTheme.mediumGray,
                      child: Icon(
                        Icons.home_outlined,
                        size: 80,
                        color: AppTheme.whiteColor.withValues(alpha: 0.3),
                      ),
                    ),
            ),
            
            // Degradado superior para el avatar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.blackColor.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            // Avatar del agente/propietario
            if (ownerProfile != null)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.whiteColor.withValues(alpha: 0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.blackColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    backgroundImage: ownerProfile.profileImage != null
                        ? NetworkImage(ownerProfile.profileImage!)
                        : null,
                    child: ownerProfile.profileImage == null
                        ? const Icon(
                            Icons.person,
                            color: AppTheme.whiteColor,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              ),
            
            // Contenido inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppTheme.blackColor.withValues(alpha: 0.8),
                      AppTheme.blackColor.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo y precio
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            property.type,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkGrayBase,
                            ),
                          ),
                        ),
                        Text(
                          '\$${property.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.whiteColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Dirección
                    Text(
                      property.address,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.whiteColor.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Detalles
                    Row(
                      children: [
                        Icon(
                          Icons.bed_outlined,
                          size: 16,
                          color: AppTheme.whiteColor.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${property.bedrooms} hab',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.whiteColor.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.shower_outlined,
                          size: 16,
                          color: AppTheme.whiteColor.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${property.bathrooms} baños',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.whiteColor.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.square_foot,
                          size: 16,
                          color: AppTheme.whiteColor.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${property.size.toStringAsFixed(0)}m²',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.whiteColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Botón de eliminar favorito
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => _removeFavorite(property),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.blackColor.withValues(alpha: 0.6),
                    border: Border.all(
                      color: AppTheme.whiteColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}