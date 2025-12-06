import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../data/services/property_service.dart';
import '../../domain/entities/property.dart';
import '../../data/services/photo_service.dart';
import '../../../../core/services/api_service.dart';
import 'package:habitto/config/app_config.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/theme/app_theme.dart';

class PropertiesListPage extends StatefulWidget {
  const PropertiesListPage({super.key});

  @override
  State<PropertiesListPage> createState() => _PropertiesListPageState();
}

class _PropertiesListPageState extends State<PropertiesListPage> {
  final PropertyService _propertyService = PropertyService();
  final PhotoService _photoService = PhotoService(ApiService());
  List<Property> _properties = [];
  bool _isLoading = true;
  String? _error;

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
      final response = await _propertyService.getMyProperties(pageSize: 50);

      if (response['success']) {
        setState(() {
          _properties = response['data']['properties'];
        });
      } else {
        setState(() {
          _error = response['error'] ?? 'Error cargando propiedades';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Mis Propiedades',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/add-property').then((_) {
                _loadProperties(); // Reload properties after adding new one
              });
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/add-property').then((_) {
              _loadProperties(); // Reload properties after adding new one
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
              text: 'Reintentar',
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
              'No tienes propiedades registradas',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primera propiedad para comenzar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Agregar Propiedad',
              onPressed: () {
                Navigator.pushNamed(context, '/add-property').then((_) {
                  _loadProperties();
                });
              },
              backgroundColor: AppTheme.primaryColor,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProperties,
      child: ListView.builder(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        itemCount: _properties.length,
        itemBuilder: (context, index) {
          final property = _properties[index];
          return _buildPropertyCard(property);
        },
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                  Colors.white.withOpacity(0.85),
                  Colors.white.withOpacity(0.65),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.4),
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
                        color: property.isActive
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: property.isActive
                              ? Colors.green.withOpacity(0.5)
                              : Colors.red.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        property.isActive ? 'ACTIVA' : 'INACTIVA',
                        style: TextStyle(
                          color: property.isActive
                              ? Colors.green[700]
                              : Colors.red[700],
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
                    const fallback = 'assets/images/empty.jpg';
                    if (property.mainPhoto != null &&
                        property.mainPhoto!.isNotEmpty) {
                      urls.add(AppConfig.sanitizeUrl(property.mainPhoto!));
                    }
                    if (snapshot.hasData && snapshot.data!['success'] == true) {
                      final photos =
                          (snapshot.data!['data']['photos'] as List<dynamic>? ??
                                  [])
                              .map((p) => (p.image as String?) ?? '')
                              .where((s) => s.isNotEmpty)
                              .map((s) => AppConfig.sanitizeUrl(s))
                              .toList();
                      urls.addAll(photos);
                    }
                    while (urls.length < 6) {
                      urls.add('');
                    }
                    return _buildAlbumCollage(urls, fallback);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumCollage(List<String> urls, String fallbackAsset) {
    String? u(int i) =>
        (i >= 0 && i < urls.length && urls[i].isNotEmpty) ? urls[i] : null;
    Widget tile({String? url, double radius = 14}) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: url != null
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Image.asset(fallbackAsset, fit: BoxFit.cover),
              )
            : Image.asset(fallbackAsset, fit: BoxFit.cover),
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 180,
                child: tile(url: u(0)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  SizedBox(height: 86, child: tile(url: u(1))),
                  const SizedBox(height: 8),
                  SizedBox(height: 86, child: tile(url: u(2))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: SizedBox(height: 100, child: tile(url: u(3)))),
            const SizedBox(width: 8),
            Expanded(child: SizedBox(height: 100, child: tile(url: u(4)))),
            const SizedBox(width: 8),
            Expanded(child: SizedBox(height: 100, child: tile(url: u(5)))),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[200] ?? Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
