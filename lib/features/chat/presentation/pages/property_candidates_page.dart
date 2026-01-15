import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../features/matching/data/services/matching_service.dart';
import '../../../../features/home/presentation/pages/home_page.dart';
import '../../../../shared/widgets/match_modal.dart';
import 'package:habitto/config/app_config.dart';
import 'package:habitto/shared/theme/app_theme.dart';

class PropertyCandidatesPage extends StatefulWidget {
  final Map<String, dynamic> property;
  final List<Map<String, dynamic>> requests;

  const PropertyCandidatesPage({
    super.key,
    required this.property,
    required this.requests,
  });

  @override
  State<PropertyCandidatesPage> createState() => _PropertyCandidatesPageState();
}

class _PropertyCandidatesPageState extends State<PropertyCandidatesPage> {
  final MatchingService _matchingService = MatchingService();
  late List<HomePropertyCardData> _cards;
  final bool _isLoading =
      false; // Data is passed in, so initial loading is false
  final GlobalKey<PropertySwipeDeckState> _deckKey =
      GlobalKey<PropertySwipeDeckState>();

  @override
  void initState() {
    super.initState();
    _initCards();
  }

  void _initCards() {
    _cards = widget.requests.map((req) {
      final match = req['match'] as Map<String, dynamic>? ?? {};
      final interestedUser =
          req['interested_user'] as Map<String, dynamic>? ?? {};

      final userName =
          '${interestedUser['first_name'] ?? ''} ${interestedUser['last_name'] ?? ''}'
              .trim();
      final userUsername = interestedUser['username'] as String? ?? 'Usuario';
      final displayName = userName.isNotEmpty ? userName : userUsername;

      String resolveAvatar(String? url) {
        final u = (url ?? '').trim().replaceAll('`', '').replaceAll('"', '');
        if (u.isEmpty) return '';
        if (u.startsWith('http://') || u.startsWith('https://')) return u;
        final base = Uri.parse(AppConfig.baseUrl);
        final abs = Uri(
            scheme: base.scheme,
            host: base.host,
            port: base.port == 0 ? null : base.port,
            path: u.startsWith('/') ? u : '/$u');
        return abs.toString();
      }

      final avatarUrl =
          resolveAvatar(interestedUser['profile_picture'] as String?);
      final score = match['score'] is num ? (match['score'] as num).round() : 0;
      final matchId = match['id'] is num ? (match['id'] as num).toInt() : 0;

      return HomePropertyCardData(
        id: matchId,
        title: displayName,
        priceLabel: '$score% Match',
        images: [avatarUrl],
        distanceKm: 0.0,
        tags: ['Interesado'],
      );
    }).toList();
  }

  void _removeCard(int matchId) {
    setState(() {
      _cards.removeWhere((c) => c.id == matchId);
    });
    if (_cards.isEmpty) {
      Navigator.pop(context, true); // Return true to indicate list changed
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.property['title'] ?? 'Candidatos',
          style: TextStyle(
            color: onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _cards.isEmpty
          ? Center(
              child: Text(
                'No hay más candidatos',
                style: TextStyle(color: onSurface),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: LayoutBuilder(builder: (ctx, constraints) {
                    const double actionRowHeight = 80.0;
                    const double extraBottomSpacing = 85.0;
                    final pad = MediaQuery.of(ctx).padding;
                    final double reservedBottom = actionRowHeight +
                        extraBottomSpacing +
                        (pad.bottom > 0 ? pad.bottom : 0.0);
                    const double sizeReduction = 20.0;
                    final double availableHeight =
                        constraints.maxHeight - reservedBottom - sizeReduction;
                    final double cardHeight = math.max(availableHeight, 400.0);

                    return SizedBox(
                      height: cardHeight,
                      child: PropertySwipeDeck(
                        key: _deckKey,
                        properties: _cards,
                        overlayBottomSpace: -(actionRowHeight / 2),
                        onLike: (p) async {
                          final res =
                              await _matchingService.acceptMatchRequest(p.id);
                          if (res['success'] != true) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Error: ${res['error'] ?? 'Desconocido'}')),
                              );
                            }
                          } else {
                            if (mounted) {
                              _showMatchModal(p);
                              _removeCard(p.id);
                            }
                          }
                        },
                        onReject: (p) async {
                          final res =
                              await _matchingService.rejectMatchRequest(p.id);
                          if (res['success'] != true) {
                            // Error handling
                          } else {
                            _removeCard(p.id);
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  void _showMatchModal(HomePropertyCardData candidate) {
    // Extract property image from widget.property
    String propertyImage = '';
    if (widget.property['photos'] != null &&
        (widget.property['photos'] as List).isNotEmpty) {
      propertyImage = widget.property['photos'][0]['image'] ?? '';
    }

    MatchModal.show(
      context,
      userImageUrl: candidate.images.isNotEmpty ? candidate.images.first : '',
      propertyImageUrl: propertyImage,
      propertyTitle: widget.property['title'] ?? '',
    );
  }
}
