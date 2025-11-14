import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  Future<void> saveAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
  }

  /// Verifica si el token es válido (método requerido por AuthService)
  Future<bool> isTokenValid() async {
    final accessToken = await getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) {
        return false;
      }
      String payload = parts[1];
      String normalizedPayload = payload;
      switch (payload.length % 4) {
        case 1:
          normalizedPayload += '===';
          break;
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }
      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      final Map<String, dynamic> payloadMap = json.decode(decodedString);
      final exp = payloadMap['exp'];
      if (exp == null) {
        return true;
      }
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      const int skew = 30;
      int expSec;
      if (exp is int) {
        expSec = exp;
      } else if (exp is String) {
        expSec = int.tryParse(exp) ?? nowSec;
      } else {
        expSec = nowSec;
      }
      return expSec > (nowSec + skew);
    } catch (_) {
      return true;
    }
  }

  /// Obtiene el ID del usuario actual desde el token JWT
  Future<String?> getCurrentUserId() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return null;
      }

      // Decodificar el JWT (solo el payload, sin verificar la firma)
      final parts = accessToken.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Decodificar el payload (segunda parte del JWT)
      final payload = parts[1];
      
      // Agregar padding si es necesario para base64
      String normalizedPayload = payload;
      switch (payload.length % 4) {
        case 1:
          normalizedPayload += '===';
          break;
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      final Map<String, dynamic> payloadMap = json.decode(decodedString);

      // Obtener el user_id del payload
      final userId = payloadMap['user_id'];
      return userId?.toString();
    } catch (e) {
      print('Error decodificando token: $e');
      return null;
    }
  }
}
