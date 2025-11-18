import '../../../../core/services/api_service.dart';
import '../../../../core/services/token_storage.dart';

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
        return {'success': false, 'error': 'No se encontró match para la propiedad', 'data': null};
      }
      return {'success': false, 'error': resp['error'] ?? 'Error obteniendo matches', 'data': null};
    } catch (e) {
      return {'success': false, 'error': 'Error obteniendo match: $e', 'data': null};
    }
  }
}
