import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../features/matching/data/services/matching_service.dart';
import '../../../../features/properties/data/services/property_service.dart';
import '../../../../features/properties/domain/entities/property.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/custom_network_image.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/token_storage.dart';
import 'property_candidates_page.dart';
import 'package:habitto/config/app_config.dart';

class MatchRequestsPage extends StatefulWidget {
  final String userMode;

  const MatchRequestsPage({super.key, required this.userMode});

  @override
  State<MatchRequestsPage> createState() => _MatchRequestsPageState();
}

class _MatchRequestsPageState extends State<MatchRequestsPage> {
  final MatchingService _matchingService = MatchingService();
  final PropertyService _propertyService = PropertyService();
  final ApiService _apiService = ApiService();

  final List<Map<String, dynamic>> _groupedRequests = [];
  final List<Property> _properties = [];
  final Map<int, int> _pendingCounts = {};
  final Map<int, int> _viewsCounts = {};
  final Map<int, String> _lastViews = {};

  final List<Map<String, dynamic>> _acceptedMatches = [];
  final Set<String> _processedTenantEvents = {};
  WebSocketChannel? _tenantNotificationsChannel;

  bool _isLoading = true;
  String _error = '';

  bool get _isTenant => widget.userMode == 'inquilino';

  @override
  void initState() {
    super.initState();
    if (_isTenant) {
      _loadTenantMatches();
      _connectTenantNotifications();
    } else {
      _loadOwnerDashboard();
    }
  }

  @override
  void dispose() {
    _tenantNotificationsChannel?.sink.close();
    super.dispose();
  }

  Future<void> _loadOwnerDashboard() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final propertiesResult = widget.userMode == 'agente'
          ? await _propertyService.getAgentProperties()
          : await _propertyService.getMyProperties();

      if (!propertiesResult['success']) {
        setState(() {
          _error = propertiesResult['error'] ?? 'Error cargando propiedades';
          _isLoading = false;
        });
        return;
      }

      final properties = propertiesResult['data'] as List<Property>? ?? [];

      final requestsResult = await _matchingService.getPendingMatchRequests();
      final requests = (requestsResult['data'] as List<dynamic>?) ?? [];
      final Map<int, Map<String, dynamic>> grouped = {};
      final Map<int, int> pendingCounts = {};

      for (final req in requests) {
        final property = req['property'] as Map<String, dynamic>? ?? {};
        final propId = property['id'] as int? ?? 0;
        if (propId == 0) continue;
        pendingCounts[propId] = (pendingCounts[propId] ?? 0) + 1;
        if (!grouped.containsKey(propId)) {
          grouped[propId] = {
            'property': property,
            'requests': <Map<String, dynamic>>[],
          };
        }
        grouped[propId]!['requests'].add(req);
      }

      final viewsResult = await _apiService.get('/api/properties/views/');
      final Map<int, int> viewsCounts = {};
      final Map<int, String> lastViews = {};
      final dynamic viewsData = viewsResult['data'];
      final dynamic payload = (viewsData is Map && viewsData['data'] != null)
          ? viewsData['data']
          : viewsData;
      final List<dynamic> viewItems = payload is List
          ? payload
          : (payload is Map && payload['results'] is List)
              ? payload['results'] as List<dynamic>
              : <dynamic>[];

      for (final item in viewItems) {
        if (item is! Map<String, dynamic>) continue;
        final int propertyId = item['property_id'] ?? item['property'] ?? 0;
        if (propertyId == 0) continue;
        final int count =
            item['views'] ?? item['count'] ?? item['views_count'] ?? 0;
        viewsCounts[propertyId] = count;
        final String last = item['last_viewed']?.toString() ??
            item['last_view']?.toString() ??
            '';
        if (last.isNotEmpty) {
          lastViews[propertyId] = last;
        }
      }

      if (!mounted) return;
      setState(() {
        _properties
          ..clear()
          ..addAll(properties);
        _groupedRequests
          ..clear()
          ..addAll(grouped.values);
        _pendingCounts
          ..clear()
          ..addAll(pendingCounts);
        _viewsCounts
          ..clear()
          ..addAll(viewsCounts);
        _lastViews
          ..clear()
          ..addAll(lastViews);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTenantMatches() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final result = await _matchingService.getMyMatches(status: 'accepted');
      final List<dynamic> matches =
          (result['data'] as List<dynamic>?) ?? <dynamic>[];

      final List<Map<String, dynamic>> normalized = matches
          .whereType<Map<String, dynamic>>()
          .map(_normalizeMatch)
          .toList();

      if (!mounted) return;
      setState(() {
        _acceptedMatches
          ..clear()
          ..addAll(_mergeTenantEvents(normalized));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _connectTenantNotifications() async {
    final tokenStorage = TokenStorage();
    final userId = await tokenStorage.getCurrentUserId();
    final token = await tokenStorage.getAccessToken();
    if (userId == null || token == null) return;

    final uri = AppConfig.buildWsUri(
      '/ws/tenant-notifications/$userId/',
      token: token,
    );

    _tenantNotificationsChannel = WebSocketChannel.connect(uri);
    _tenantNotificationsChannel!.stream.listen((event) {
      try {
        final data = json.decode(event.toString()) as Map<String, dynamic>;
        final type = data['type']?.toString() ?? '';
        if (type != 'match_accepted_by_owner') return;
        final id = data['notification_id']?.toString() ??
            '${data['property_id']}-${data['timestamp']}';
        if (_processedTenantEvents.contains(id)) return;
        _processedTenantEvents.add(id);
        final match = _normalizeMatch(data);
        setState(() {
          _acceptedMatches.insert(0, match);
        });
      } catch (_) {}
    });
  }

  List<Map<String, dynamic>> _mergeTenantEvents(
      List<Map<String, dynamic>> matches) {
    final Map<int, Map<String, dynamic>> byPropertyId = {};
    for (final match in matches) {
      final int propertyId = match['propertyId'] ?? 0;
      if (propertyId != 0) {
        byPropertyId[propertyId] = match;
      }
    }
    for (final match in _acceptedMatches) {
      final int propertyId = match['propertyId'] ?? 0;
      if (propertyId != 0 && !byPropertyId.containsKey(propertyId)) {
        byPropertyId[propertyId] = match;
      }
    }
    return byPropertyId.values.toList();
  }

  Map<String, dynamic> _normalizeMatch(Map<String, dynamic> raw) {
    final property = raw['property'] as Map<String, dynamic>? ?? {};
    final int propertyId =
        raw['property_id'] ?? property['id'] ?? raw['property'] ?? 0;
    final String title = raw['property_title']?.toString() ??
        property['title']?.toString() ??
        property['address']?.toString() ??
        'Propiedad';
    final String address = raw['property_address']?.toString() ??
        property['address']?.toString() ??
        '';
    final String status = raw['match_status']?.toString() ??
        raw['status']?.toString() ??
        'accepted';
    final String acceptedAt = raw['accepted_at']?.toString() ??
        raw['updated_at']?.toString() ??
        raw['timestamp']?.toString() ??
        '';
    final Map<String, dynamic> ownerContact =
        raw['owner_contact'] is Map<String, dynamic>
            ? raw['owner_contact'] as Map<String, dynamic>
            : {};
    final Map<String, dynamic> ownerMap =
        raw['owner'] is Map<String, dynamic> ? raw['owner'] : {};
    final String ownerName = raw['owner_name']?.toString() ??
        ownerMap['full_name']?.toString() ??
        ownerMap['username']?.toString() ??
        'Propietario';
    final String email = ownerContact['email']?.toString() ??
        ownerMap['email']?.toString() ??
        '';
    final String phone = ownerContact['phone']?.toString() ??
        ownerMap['phone']?.toString() ??
        '';

    return {
      'propertyId': propertyId,
      'title': title,
      'address': address,
      'status': status,
      'acceptedAt': acceptedAt,
      'ownerName': ownerName,
      'email': email,
      'phone': phone,
    };
  }

  String _getPropertyMainPhoto(Property property) {
    final photoUrl = property.mainPhoto;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return AppConfig.sanitizeUrl(photoUrl);
    }
    return '';
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return 'Sin fecha';
    try {
      final date = DateTime.parse(raw);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _isTenant ? 'Matches' : 'Matches de Propiedades',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isTenant ? _loadTenantMatches : _loadOwnerDashboard,
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
              ? Center(child: Text(_error))
              : _isTenant
                  ? _buildTenantMatches()
                  : _buildOwnerMatches(),
    );
  }

  Widget _buildOwnerMatches() {
    if (_properties.isEmpty) {
      return const Center(child: Text('No hay propiedades registradas'));
    }
    return ListView.builder(
      itemCount: _properties.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final property = _properties[index];
        final pendingCount = _pendingCounts[property.id] ?? 0;
        final viewsCount = _viewsCounts[property.id] ?? 0;
        final lastView = _lastViews[property.id] ?? '';
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: InkWell(
            onTap: () {
              final group = _groupedRequests.firstWhere(
                (g) =>
                    (g['property'] as Map<String, dynamic>?)?['id'] ==
                    property.id,
                orElse: () => {},
              );
              if (group.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyCandidatesPage(
                      property: group['property'] as Map<String, dynamic>,
                      requests: group['requests'] as List<Map<String, dynamic>>,
                    ),
                  ),
                ).then((_) => _loadOwnerDashboard());
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: CustomNetworkImage(
                    imageUrl: _getPropertyMainPhoto(property),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.address,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: property.isActive
                                  ? AppTheme.primaryColor
                                      .withValues(alpha: 0.12)
                                  : Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              property.isActive ? 'Publicado' : 'Inactivo',
                              style: TextStyle(
                                color: property.isActive
                                    ? AppTheme.primaryColor
                                    : Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Bs ${property.price.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildMetricItem(
                            Icons.favorite_border,
                            'Matches activos',
                            '$pendingCount',
                          ),
                          const SizedBox(width: 12),
                          _buildMetricItem(
                            Icons.visibility_outlined,
                            'Visibilidad',
                            '$viewsCount',
                          ),
                        ],
                      ),
                      if (lastView.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Última vista: ${_formatDate(lastView)}',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantMatches() {
    if (_acceptedMatches.isEmpty) {
      return const Center(child: Text('Aún no tienes matches aceptados'));
    }
    return ListView.builder(
      itemCount: _acceptedMatches.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final match = _acceptedMatches[index];
        final email = match['email']?.toString() ?? '';
        final phone = match['phone']?.toString() ?? '';
        final contact =
            [email, phone].where((value) => value.isNotEmpty).join(' • ');
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match['ownerName']?.toString() ?? 'Propietario',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  match['title']?.toString() ?? 'Propiedad',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                if ((match['address']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    match['address']?.toString() ?? '',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTenantChip(
                      'Estado',
                      match['status']?.toString() ?? 'accepted',
                    ),
                    const SizedBox(width: 12),
                    _buildTenantChip(
                      'Aceptado',
                      _formatDate(match['acceptedAt']?.toString() ?? ''),
                    ),
                  ],
                ),
                if (contact.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Contacto: $contact',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTenantChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
