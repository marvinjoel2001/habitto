import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../data/services/property_service.dart';
import '../../domain/entities/property.dart';
import '../../data/services/photo_service.dart';
import '../../../../core/services/api_service.dart';
import 'package:habitto/config/app_config.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/property_image_grid.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../../shared/theme/app_theme.dart';
import 'edit_property_page.dart';
import 'property_detail_page.dart';
import '../../../../features/matching/data/services/matching_service.dart';
import '../../../../../generated/l10n.dart';

class PropertiesListPage extends StatefulWidget {
  final String userMode;

  const PropertiesListPage({super.key, required this.userMode});

  @override
  State<PropertiesListPage> createState() => _PropertiesListPageState();
}

class _PropertiesListPageState extends State<PropertiesListPage> {
  final PropertyService _propertyService = PropertyService();
  final PhotoService _photoService = PhotoService(ApiService());
  final MatchingService _matchingService = MatchingService();
  List<Property> _properties = [];
  bool _isLoading = true;
  String? _error;
  int _pendingMatches = 0;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> response;
      if (widget.userMode == 'inquilino') {
        response = await _propertyService.getProperties(
          orderByMatch: true,
          matchScore: 70,
          pageSize: 50,
        );
      } else if (widget.userMode == 'agente') {
        response = await _propertyService.getAgentProperties(pageSize: 50);
      } else {
        response = await _propertyService.getMyProperties(pageSize: 50);
      }

      if (response['success']) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final properties = data['properties'] as List<Property>? ?? [];
        int pendingMatches = 0;
        if (widget.userMode != 'inquilino') {
          final matchRes = await _matchingService.getPendingMatchRequests();
          if (matchRes['success'] == true && matchRes['data'] is List) {
            pendingMatches = (matchRes['data'] as List).length;
          }
        }
        setState(() {
          _properties = properties;
          _pendingMatches = pendingMatches;
        });
      } else {
        setState(() {
          _error = response['error'] ?? S.of(context).loadPropertiesError;
        });
      }
    } catch (e) {
      setState(() {
        _error = S.of(context).connectionError(e.toString());
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTenant = widget.userMode == 'inquilino';
    final isAgent = widget.userMode == 'agente';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isTenant
              ? S.of(context).navProperties
              : isAgent
                  ? S.of(context).assignedPropertiesTitleMixed
                  : S.of(context).myPropertiesTitle,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: isTenant || isAgent
            ? []
            : [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.black),
                  onPressed: () {
                    Navigator.pushNamed(context, '/add-property').then((_) {
                      _loadProperties();
                    });
                  },
                ),
              ],
      ),
      body: _buildBody(),
      floatingActionButton: isTenant || isAgent
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/add-property').then((_) {
                    _loadProperties();
                  });
                },
                backgroundColor: AppTheme.primaryColor,
                child: const Icon(Icons.add),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: S.of(context).retryButton,
              onPressed: _loadProperties,
              backgroundColor: AppTheme.primaryColor,
            ),
          ],
        ),
      );
    }

    if (_properties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.userMode == 'inquilino'
                  ? 'No hay propiedades disponibles'
                  : S.of(context).noPropertiesRegistered,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.userMode != 'inquilino') ...[
              const SizedBox(height: 8),
              Text(
                S.of(context).addFirstProperty,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: S.of(context).addPropertyButton,
                onPressed: () {
                  Navigator.pushNamed(context, '/add-property').then((_) {
                    _loadProperties();
                  });
                },
                backgroundColor: AppTheme.primaryColor,
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProperties,
      child: ListView.builder(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        itemCount: _properties.length + (widget.userMode == 'inquilino' ? 0 : 1),
        itemBuilder: (context, index) {
          if (widget.userMode != 'inquilino' && index == 0) {
            return _buildStatsHeader();
          }
          final property = _properties[
              widget.userMode == 'inquilino' ? index : index - 1];
          return widget.userMode == 'inquilino'
              ? _buildTenantPropertyCard(property)
              : _buildPropertyCard(property);
        },
      ),
    );
  }

  Widget _buildStatsHeader() {
    final total = _properties.length;
    final active = _properties.where((p) => p.isActive).length;
    final inactive = total - active;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _buildStatItem('Total', '$total'),
          _buildStatItem('Activas', '$active'),
          _buildStatItem('Inactivas', '$inactive'),
          _buildStatItem('Matches', '$_pendingMatches'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditPropertyPage(property: property),
          ),
        ).then((_) {
          _loadProperties(); // Reload to reflect any changes
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.85),
                    Colors.white.withValues(alpha: 0.65),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.address,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: property.tenant != null
                              ? AppTheme.primaryColor.withValues(alpha: 0.1)
                              : (property.isActive
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFEBEE)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: property.tenant != null
                                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                                : (property.isActive
                                    ? Colors.green.withValues(alpha: 0.5)
                                    : Colors.red.withValues(alpha: 0.5)),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          property.tenant != null
                              ? "Ocupada"
                              : (property.isActive
                                  ? S.of(context).activeStatus
                                  : S.of(context).inactiveStatus),
                          style: TextStyle(
                            color: property.tenant != null
                                ? AppTheme.primaryColor
                                : (property.isActive
                                    ? Colors.green[700]
                                    : Colors.red[700]),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _photoService.getPropertyPhotos(property.id),
                    builder: (context, snapshot) {
                      List<String> urls = [];
                      if (property.mainPhoto != null &&
                          property.mainPhoto!.isNotEmpty) {
                        urls.add(AppConfig.sanitizeUrl(property.mainPhoto!));
                      }
                      if (snapshot.hasData &&
                          snapshot.data!['success'] == true) {
                        final photos = (snapshot.data!['data']['photos']
                                    as List<dynamic>? ??
                                [])
                            .map((p) => (p.image as String?) ?? '')
                            .where((s) => s.isNotEmpty)
                            .map((s) => AppConfig.sanitizeUrl(s))
                            .toList();
                        urls.addAll(photos);
                      }

                      // Eliminar duplicados
                      urls = urls.toSet().toList();

                      return PropertyImageGrid(
                        imageUrls: urls,
                        height: 240,
                        borderRadius: 12,
                        onImageTap: (index) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImageViewer(
                                images: urls,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTenantPropertyCard(Property property) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailPage(propertyId: property.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.address.isNotEmpty
                      ? property.address
                      : S.of(context).propertyNoAddress,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                FutureBuilder<Map<String, dynamic>>(
                  future: _photoService.getPropertyPhotos(property.id),
                  builder: (context, snapshot) {
                    List<String> urls = [];
                    if (property.mainPhoto != null &&
                        property.mainPhoto!.isNotEmpty) {
                      urls.add(AppConfig.sanitizeUrl(property.mainPhoto!));
                    }
                    if (snapshot.hasData &&
                        snapshot.data!['success'] == true) {
                      final photos = (snapshot.data!['data']['photos']
                                  as List<dynamic>? ??
                              [])
                          .map((p) => (p.image as String?) ?? '')
                          .where((s) => s.isNotEmpty)
                          .map((s) => AppConfig.sanitizeUrl(s))
                          .toList();
                      urls.addAll(photos);
                    }
                    urls = urls.toSet().toList();
                    return PropertyImageGrid(
                      imageUrls: urls,
                      height: 200,
                      borderRadius: 12,
                      onImageTap: (index) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(
                              images: urls,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Bs ${property.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${property.bedrooms} ${S.of(context).bedroomsShortLabel}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${property.bathrooms} baños',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
