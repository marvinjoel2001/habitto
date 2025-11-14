import '../../../../core/services/api_service.dart';

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
}