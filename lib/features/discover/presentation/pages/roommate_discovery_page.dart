import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:habitto/core/services/api_service.dart';
import 'package:habitto/shared/theme/app_theme.dart';

class RoommateDiscoveryPage extends StatefulWidget {
  const RoommateDiscoveryPage({super.key});

  @override
  State<RoommateDiscoveryPage> createState() => _RoommateDiscoveryPageState();
}

class _RoommateDiscoveryPageState extends State<RoommateDiscoveryPage> {
  final ApiService _apiService = ApiService();
  final List<_RoomieItem> _items = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadRoomies();
  }

  Future<void> _loadRoomies() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final res = await _apiService
          .get('/api/recommendations/', queryParameters: {'type': 'roommate'});
      if (res['success'] != true || res['data'] == null) {
        setState(() {
          _error = res['error']?.toString() ?? 'No se pudo cargar roomies';
          _isLoading = false;
        });
        return;
      }
      final envelope = res['data'];
      final dynamic payload = (envelope is Map && envelope['data'] != null)
          ? envelope['data']
          : envelope;
      final List<dynamic> results = payload is Map && payload['results'] is List
          ? List<dynamic>.from(payload['results'] as List)
          : (payload is List ? List<dynamic>.from(payload) : <dynamic>[]);
      final parsed = <_RoomieItem>[];
      for (final raw in results) {
        if (raw is! Map<String, dynamic>) continue;
        final match = raw['match'] is Map<String, dynamic>
            ? raw['match'] as Map<String, dynamic>
            : <String, dynamic>{};
        final details = match['metadata'] is Map &&
                (match['metadata'] as Map)['details'] is Map
            ? Map<String, dynamic>.from((match['metadata'] as Map)['details'])
            : <String, dynamic>{};
        final sid = match['subject_id'];
        final profileId = sid is int ? sid : int.tryParse(sid?.toString() ?? '');
        if (profileId == null) continue;
        final scoreRaw = match['score'];
        final score = scoreRaw is num
            ? scoreRaw.toDouble()
            : double.tryParse(scoreRaw?.toString() ?? '') ?? 0.0;
        final name = (details['full_name'] ??
                details['name'] ??
                details['username'] ??
                'Roomie #$profileId')
            .toString();
        final zone = (details['preferred_zone'] ??
                details['zone'] ??
                details['city'] ??
                '')
            .toString();
        final budget = (details['budget'] ?? details['budget_per_person'] ?? '')
            .toString();
        parsed.add(_RoomieItem(
          profileId: profileId,
          name: name,
          score: score,
          zone: zone,
          budget: budget,
        ));
      }
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(parsed);
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

  void _showRoomieDetails(_RoomieItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.getCardGradient(opacity: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Compatibilidad: ${item.score.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.zone.isNotEmpty ? 'Zona preferida: ${item.zone}' : 'Zona preferida: No especificada',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.budget.isNotEmpty
                          ? 'Presupuesto por persona: ${item.budget}'
                          : 'Presupuesto por persona: No especificado',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Puedes conectar por Chat cuando haya match',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Encuentra Roomies'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoomies,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _items.isEmpty
                  ? const Center(
                      child: Text('No hay recomendaciones de roomies por ahora'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                              child: Material(
                                color: Colors.white.withValues(alpha: 0.10),
                                child: InkWell(
                                  onTap: () => _showRoomieDetails(item),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.28),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor
                                                .withValues(alpha: 0.18),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.people_alt,
                                              color: Colors.white),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item.zone.isNotEmpty
                                                    ? item.zone
                                                    : 'Zona no especificada',
                                                style: const TextStyle(
                                                    color: Colors.white70),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            '${item.score.toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
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

class _RoomieItem {
  final int profileId;
  final String name;
  final double score;
  final String zone;
  final String budget;

  const _RoomieItem({
    required this.profileId,
    required this.name,
    required this.score,
    required this.zone,
    required this.budget,
  });
}
