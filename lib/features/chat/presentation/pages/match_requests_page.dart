import 'package:flutter/material.dart';
import '../../../../features/matching/data/services/matching_service.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/custom_network_image.dart';
import 'property_candidates_page.dart';
import 'package:habitto/config/app_config.dart';

import '../../../../features/properties/data/services/photo_service.dart';
import '../../../../core/services/api_service.dart';

class MatchRequestsPage extends StatefulWidget {
  const MatchRequestsPage({super.key});

  @override
  State<MatchRequestsPage> createState() => _MatchRequestsPageState();
}

class _MatchRequestsPageState extends State<MatchRequestsPage> {
  final MatchingService _matchingService = MatchingService();
  late final PhotoService _photoService;

  List<Map<String, dynamic>> _groupedRequests = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _photoService = PhotoService(ApiService());
    _loadMatchRequests();
  }

  Future<void> _loadMatchRequests() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final result = await _matchingService.getPendingMatchRequests();

      if (!mounted) return;

      if (result['success']) {
        final requests = (result['data'] as List<dynamic>?) ?? [];
        final Map<int, Map<String, dynamic>> grouped = {};

        for (final req in requests) {
          final property = req['property'] as Map<String, dynamic>? ?? {};
          final propId = property['id'] as int? ?? 0;
          if (propId == 0) continue;

          if (!grouped.containsKey(propId)) {
            grouped[propId] = {
              'property': property,
              'requests': <Map<String, dynamic>>[],
            };
          }
          grouped[propId]!['requests'].add(req);
        }

        setState(() {
          _groupedRequests = grouped.values.toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error: ${result['error']}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar solicitudes: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _resolveImageUrl(Map<String, dynamic> property) {
    if (property['photos'] != null && (property['photos'] as List).isNotEmpty) {
      final photos = property['photos'] as List;
      final first = photos[0];
      if (first is Map) {
        final url = first['image'] as String? ?? first['file'] as String?;
        if (url != null) return AppConfig.sanitizeUrl(url);
      } else if (first is String) {
        return AppConfig.sanitizeUrl(first);
      }
    }
    // Fallback: intentar main_photo si existe en el root
    if (property['main_photo'] is String) {
      return AppConfig.sanitizeUrl(property['main_photo']);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Propiedades con Interés',
          style: TextStyle(
            color: onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: onSurface),
            onPressed: _loadMatchRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: onSurface.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(_error, style: TextStyle(color: onSurface)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMatchRequests,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _groupedRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home_work_outlined,
                              size: 64, color: onSurface.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes solicitudes pendientes',
                            style: TextStyle(
                                color: onSurface.withOpacity(0.6),
                                fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                          top: 16, left: 16, right: 16, bottom: 120),
                      itemCount: _groupedRequests.length,
                      itemBuilder: (context, index) {
                        final item = _groupedRequests[index];
                        final property =
                            item['property'] as Map<String, dynamic>;
                        final requests =
                            item['requests'] as List<Map<String, dynamic>>;
                        final requestCount = requests.length;

                        final title =
                            property['title'] as String? ?? 'Propiedad';
                        final address = property['address'] as String? ?? '';
                        final price = property['price']?.toString() ?? '0';
                        final bedrooms =
                            property['bedrooms']?.toString() ?? '0';
                        final bathrooms =
                            property['bathrooms']?.toString() ?? '0';
                        final area = property['area']?.toString() ?? '0';
                        final propertyId = property['id'] as int? ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PropertyCandidatesPage(
                                    property: property,
                                    requests: requests,
                                  ),
                                ),
                              ).then((_) => _loadMatchRequests());
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagen
                                SizedBox(
                                  height: 180,
                                  width: double.infinity,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    child: FutureBuilder<Map<String, dynamic>>(
                                      future: _photoService
                                          .getPropertyPhotos(propertyId),
                                      builder: (context, snapshot) {
                                        String imageUrl =
                                            _resolveImageUrl(property);

                                        if (imageUrl.isEmpty &&
                                            snapshot.hasData &&
                                            snapshot.data!['success'] == true) {
                                          final photos = (snapshot.data!['data']
                                                      ['photos']
                                                  as List<dynamic>? ??
                                              []);
                                          if (photos.isNotEmpty) {
                                            final first = photos.first;
                                            final url =
                                                (first.image as String?) ?? '';
                                            if (url.isNotEmpty) {
                                              imageUrl =
                                                  AppConfig.sanitizeUrl(url);
                                            }
                                          }
                                        }

                                        return imageUrl.isNotEmpty
                                            ? CustomNetworkImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                    Icons.image_not_supported,
                                                    size: 48,
                                                    color: Colors.grey),
                                              );
                                      },
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              address,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Text(
                                            '\$$price USD',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          const Spacer(),
                                          _buildFeature(Icons.bed_outlined,
                                              '$bedrooms habs'),
                                          const SizedBox(width: 12),
                                          _buildFeature(Icons.bathtub_outlined,
                                              '$bathrooms baños'),
                                          const SizedBox(width: 12),
                                          _buildFeature(
                                              Icons.square_foot, '$area m²'),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.favorite,
                                              color: AppTheme.secondaryColor,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$requestCount interesados',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Ver personas',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_ios,
                                              size: 12,
                                              color: Colors.grey[600]),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}
