import '../../../../core/services/api_service.dart';
import '../../../../core/services/token_storage.dart';
import '../../../properties/data/services/property_service.dart';
import '../../../properties/domain/entities/property.dart';

class MatchingService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getPropertyRecommendations() async {
    try {
      final response = await _apiService.get('/api/recommendations/', queryParameters: {'type': 'property'});
      if (response['success'] == true) {
        final results = (response['data']?['results'] as List?) ?? [];
        final items = results.map((e) => {
          'matchId': e['match']?['id'],
          'propertyId': e['match']?['subject_id'],
          'score': e['match']?['score'],
          'status': e['match']?['status'],
        }).where((m) => m['matchId'] != null && m['propertyId'] != null).toList();
        return {'success': true, 'data': items};
      }
      return {'success': false, 'error': response['error'] ?? 'Error obteniendo recomendaciones', 'data': null};
    } catch (e) {
      return {'success': false, 'error': 'Error obteniendo recomendaciones: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> likeMatch(int matchId) async {
    try {
      final response = await _apiService.post('/api/matches/$matchId/like/', {});
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'error': response['error'] ?? 'Error al hacer like', 'data': null};
    } catch (e) {
      return {'success': false, 'error': 'Error al hacer like: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> rejectMatch(int matchId) async {
    try {
      final response = await _apiService.post('/api/matches/$matchId/reject/', {});
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'error': response['error'] ?? 'Error al rechazar match', 'data': null};
    } catch (e) {
      return {'success': false, 'error': 'Error al rechazar match: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> sendFeedback({required int matchId, required String feedbackType, String? reason}) async {
    try {
      final payload = {'match': matchId, 'feedback_type': feedbackType, if (reason != null) 'reason': reason};
      final response = await _apiService.post('/api/match_feedback/', payload);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'error': response['error'] ?? 'Error enviando feedback', 'data': null};
    } catch (e) {
      return {'success': false, 'error': 'Error enviando feedback: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> getCurrentSearchProfileId() async {
    try {
      final tokenUserId = await TokenStorage().getCurrentUserId();
      if (tokenUserId == null) {
        return {'success': false, 'error': 'Usuario no autenticado', 'data': null};
      }
      final resp = await _apiService.get('/api/search_profiles/', queryParameters: {'user_id': int.parse(tokenUserId)});
      if (resp['success'] == true && resp['data'] != null) {
        final envelope = resp['data'];
        List<dynamic> results = [];
        if (envelope is Map && envelope['data'] is Map && (envelope['data'] as Map)['results'] is List) {
          results = List<dynamic>.from((envelope['data'] as Map)['results'] as List);
        } else if (envelope is Map && envelope['results'] is List) {
          results = List<dynamic>.from(envelope['results'] as List);
        } else if (envelope is List) {
          results = List<dynamic>.from(envelope);
        }
        if (results.isNotEmpty) {
          final id = (results.first as Map)['id'];
          return {'success': true, 'data': id};
        }
        return {'success': false, 'error': 'No hay SearchProfile', 'data': null};
      }
      return {'success': false, 'error': resp['error'] ?? 'Error obteniendo SearchProfile', 'data': null};
    } catch (e) {
      return {'success': false, 'error': 'Error obteniendo SearchProfile: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> likeProperty(int propertyId) async {
    try {
      final response = await _apiService.post('/api/properties/$propertyId/like/', {});
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'error': response['error'] ?? 'Error al hacer like a la propiedad', 'data': null};
    } catch (e) {
      return {'success': false, 'error': 'Error al hacer like a la propiedad: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> rejectProperty(int propertyId) async {
    try {
      final response = await _apiService.post('/api/properties/$propertyId/reject/', {});
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'error': response['error'] ?? 'Error al rechazar la propiedad', 'data': null};
    } catch (e) {
      return {'success': false, 'error': 'Error al rechazar la propiedad: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> getPendingMatchRequests() async {
    try {
      final resp = await _apiService.get('/api/matches/pending_requests/', queryParameters: {
        'type': 'property',
      });
      if (resp['success'] == true) {
        final envelope = resp['data'];
        List<dynamic> results = [];
        if (envelope is Map && envelope['data'] is Map && (envelope['data'] as Map)['results'] is List) {
          results = List<dynamic>.from((envelope['data'] as Map)['results'] as List);
        } else if (envelope is Map && envelope['results'] is List) {
          results = List<dynamic>.from(envelope['results'] as List);
        } else if (envelope is List) {
          results = List<dynamic>.from(envelope);
        }

        // Usar datos provistos por el backend; evitar llamadas adicionales
        final propertyService = PropertyService();
        final List<Map<String, dynamic>> enriched = [];
        for (final item in results) {
          final match = (item is Map && item.containsKey('match')) ? item['match'] : item;
          Map<String, dynamic> propertyJson = {};
          Map<String, dynamic> interestedUserJson = {};
          // Preferir la propiedad incluida en la respuesta si está disponible
          if (item is Map && item['property'] is Map) {
            final prop = Map<String, dynamic>.from(item['property'] as Map);
            propertyJson = {
              'title': (prop['address'] ?? '').toString(),
              'address': (prop['address'] ?? '').toString(),
              'id': int.tryParse((prop['id'] ?? '0').toString()) ?? 0,
            };
          } else if (match is Map && match['subject_id'] != null) {
            final sid = (match['subject_id'] is num) ? (match['subject_id'] as num).toInt() : int.tryParse(match['subject_id'].toString());
            if (sid != null) {
              // Fallback mínimo si el backend no incluyera property
              final pr = await propertyService.getPropertyById(sid);
              if (pr['success'] == true && pr['data'] != null) {
                final p = pr['data'];
                propertyJson = {
                  'title': (p is Property ? p.address : (p['address'] ?? '')).toString(),
                  'address': (p is Property ? p.address : (p['address'] ?? '')).toString(),
                  'id': p is Property ? p.id : (int.tryParse((p['id'] ?? '0').toString()) ?? 0),
                };
              }
            }
          }

          // Usuario interesado incluido por el backend (si existe)
          if (item is Map && item['interested_user'] is Map) {
            interestedUserJson = Map<String, dynamic>.from(item['interested_user'] as Map);
            // Evitar enriquecimiento adicional: el backend ya retorna nombre y foto
          }
          enriched.add({
            'match': match,
            'property': propertyJson,
            'interested_user': interestedUserJson,
          });
        }
        return {'success': true, 'data': enriched};
      }
      return {'success': false, 'error': resp['error'] ?? 'Error obteniendo solicitudes de match', 'data': null};
    } catch (e) {
      return {'success': false, 'error': 'Error obteniendo solicitudes de match: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> acceptMatchRequest(int matchId) async {
    try {
      final response = await _apiService.post('/api/matches/$matchId/accept/', {});
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'error': response['error'] ?? 'Error al aceptar solicitud', 'data': null};
    } catch (e) {
      return {'success': false, 'error': 'Error al aceptar solicitud: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> rejectMatchRequest(int matchId) async {
    try {
      final response = await _apiService.post('/api/matches/$matchId/reject/', {});
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'error': response['error'] ?? 'Error al rechazar solicitud', 'data': null};
    } catch (e) {
      return {'success': false, 'error': 'Error al rechazar solicitud: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> getOrCreateMatchIdForProperty(int propertyId) async {
    try {
      final sp = await getCurrentSearchProfileId();
      if (sp['success'] != true || sp['data'] == null) {
        return {'success': false, 'error': sp['error'] ?? 'No se pudo obtener SearchProfile', 'data': null};
      }
      final spId = sp['data'] as int;
      final resp = await _apiService.get('/api/search_profiles/$spId/matches/', queryParameters: {'type': 'property'});
      if (resp['success'] == true && resp['data'] != null) {
        final envelope = resp['data'];
        List<dynamic> results = [];
        if (envelope is Map && envelope['data'] is Map && (envelope['data'] as Map)['results'] is List) {
          results = List<dynamic>.from((envelope['data'] as Map)['results'] as List);
        } else if (envelope is Map && envelope['results'] is List) {
          results = List<dynamic>.from(envelope['results'] as List);
        } else if (envelope is List) {
          results = List<dynamic>.from(envelope);
        }
        for (final m in results) {
          final mm = m as Map<String, dynamic>;
          final subjectId = mm['subject_id'];
          if (subjectId is int && subjectId == propertyId) {
            return {'success': true, 'data': mm['id']};
          }
        }
        // Si no existe, intentar crearlo
        final createResp = await _apiService.post('/api/search_profiles/$spId/matches/', {
          'type': 'property',
          'subject_id': propertyId,
        });
        if (createResp['success'] == true && createResp['data'] != null) {
          final d = createResp['data'];
          if (d is Map && d['id'] is int) {
            return {'success': true, 'data': d['id']};
          }
          // Algunos backends envuelven la respuesta en { data: {...} }
          if (d is Map && d['data'] is Map && (d['data'] as Map)['id'] is int) {
            return {'success': true, 'data': (d['data'] as Map)['id']};
          }
        }
        return {
          'success': false,
          'error': createResp['error'] ?? 'No se pudo crear match para la propiedad',
          'data': null,
        };
      }
      return {'success': false, 'error': resp['error'] ?? 'Error obteniendo matches', 'data': null};
    } catch (e) {
      return {'success': false, 'error': 'Error obteniendo match: $e', 'data': null};
    }
  }
}
