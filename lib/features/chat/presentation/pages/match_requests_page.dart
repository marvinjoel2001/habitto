import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../../features/matching/data/services/matching_service.dart';
import 'package:habitto/core/services/token_storage.dart';

class MatchRequestsPage extends StatefulWidget {
  const MatchRequestsPage({super.key});

  @override
  State<MatchRequestsPage> createState() => _MatchRequestsPageState();
}

class _MatchRequestsPageState extends State<MatchRequestsPage> {
  final MatchingService _matchingService = MatchingService();
  List<dynamic> _matchRequests = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadMatchRequests();
  }

  Future<void> _loadMatchRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final result = await _matchingService.getPendingMatchRequests();
      
      if (result['success']) {
        final requests = (result['data'] as List<dynamic>?) ?? [];
        setState(() {
          _matchRequests = requests;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error: ${result['error']}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar solicitudes: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptMatchRequest(int matchId) async {
    try {
      final result = await _matchingService.acceptMatchRequest(matchId);
      if (result['success']) {
        // Remove the accepted request from the list
        setState(() {
          _matchRequests.removeWhere((request) => request['match']['id'] == matchId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud de match aceptada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aceptar: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _rejectMatchRequest(int matchId) async {
    try {
      final result = await _matchingService.rejectMatchRequest(matchId);
      if (result['success']) {
        // Remove the rejected request from the list
        setState(() {
          _matchRequests.removeWhere((request) => request['match']['id'] == matchId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud de match rechazada'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al rechazar: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Solicitudes de Match',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadMatchRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _error.isNotEmpty
                    ? Center(
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
                              _error,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMatchRequests,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _matchRequests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tienes solicitudes de match pendientes',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Las nuevas solicitudes aparecerán aquí',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadMatchRequests,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: _matchRequests.length,
                              itemBuilder: (context, index) {
                                final request = _matchRequests[index];
                                return _buildMatchRequestTile(request);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchRequestTile(Map<String, dynamic> request) {
    final match = request['match'] as Map<String, dynamic>? ?? {};
    final property = request['property'] as Map<String, dynamic>? ?? {};
    final interestedUser = request['interested_user'] as Map<String, dynamic>? ?? {};
    
    final matchId = match['id'] as int? ?? 0;
    final propertyTitle = property['title'] as String? ?? 'Propiedad sin título';
    final propertyAddress = property['address'] as String? ?? 'Dirección no especificada';
    final userName = '${interestedUser['first_name'] ?? ''} ${interestedUser['last_name'] ?? ''}'.trim();
    final userUsername = interestedUser['username'] as String? ?? 'Usuario';
    final displayName = userName.isNotEmpty ? userName : userUsername;
    final score = match['score'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar del usuario interesado
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Información del usuario
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@$userUsername',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Score de compatibilidad
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$score%',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Información de la propiedad
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        propertyTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        propertyAddress,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _rejectMatchRequest(matchId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          foregroundColor: Colors.red[700],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.red.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Rechazar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _acceptMatchRequest(matchId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                          foregroundColor: Colors.green[700],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.green.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Aceptar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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