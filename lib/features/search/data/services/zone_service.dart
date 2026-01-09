import '../../../../core/services/api_service.dart';

class ZoneService {
  final ApiService _apiService;

  ZoneService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<Map<String, dynamic>> getZonesGeoJson() async {
    try {
      final response = await _apiService.get('/api/map/zones/');
      return response;
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching zones: $e',
      };
    }
  }
}
