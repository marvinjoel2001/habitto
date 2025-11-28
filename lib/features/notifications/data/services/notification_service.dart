import '../../../../core/services/api_service.dart';

class NotificationService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> list({int page = 1, int pageSize = 50, bool? isRead}) async {
    try {
      final qp = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (isRead != null) 'is_read': isRead.toString(),
      };
      final resp = await _api.get('/api/notifications/', queryParameters: qp);
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
        return {'success': true, 'data': results};
      }
      return {'success': false, 'error': resp['error'] ?? 'Error obteniendo notificaciones', 'data': null};
    } catch (e) {
      return {'success': false, 'error': 'Error obteniendo notificaciones: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> listMyAggregated() async {
    try {
      final resp = await _api.get('/api/notifications/my/');
      if (resp['success'] == true) {
        return {'success': true, 'data': resp['data']};
      }
      return {'success': false, 'error': resp['error'] ?? 'Error obteniendo agregado de notificaciones', 'data': null};
    } catch (e) {
      return {'success': false, 'error': 'Error obteniendo agregado: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> markAsRead(int id) async {
    try {
      final resp = await _api.post('/api/notifications/$id/mark_as_read/', {});
      return resp['success'] == true
          ? {'success': true, 'data': resp['data']}
          : {'success': false, 'error': resp['error'] ?? 'Error al marcar notificación', 'data': null};
    } catch (e) {
      return {'success': false, 'error': 'Error al marcar notificación: $e', 'data': null};
    }
  }

  Future<int> unreadCount() async {
    try {
      final resp = await _api.get('/api/notifications/', queryParameters: {'is_read': false});
      if (resp['success'] == true) {
        final d = resp['data'];
        if (d is Map && d['count'] is int) return d['count'] as int;
        if (d is Map && d['results'] is List) return (d['results'] as List).length;
        if (d is List) return d.length;
      }
    } catch (_) {}
    return 0;
  }
}

