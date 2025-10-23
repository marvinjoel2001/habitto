import 'dart:io';
import 'package:dio/dio.dart';
import 'package:habitto/config/app_config.dart';
import 'package:habitto/core/services/token_storage.dart';

/// Cliente HTTP base para toda la aplicación
/// Responsabilidad: Gestionar la conectividad de bajo nivel
/// - Configuración base (Base URL, Timeouts)
/// - Interceptores para autenticación y manejo de errores
/// - Métodos HTTP genéricos
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initializeDio();
  }

  late final Dio _dio;
  final TokenStorage _tokenStorage = TokenStorage();

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Interceptor para añadir token de autenticación
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Manejar error 401 (Unauthorized) con refresh automático
        if (error.response?.statusCode == 401) {
          final refreshResult = await _refreshToken();

          if (refreshResult['success']) {
            // Reintentar la petición original con el nuevo token
            final newToken = refreshResult['access_token'];
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';

            try {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
              handler.next(error);
              return;
            }
          } else {
            // No se pudo refrescar, limpiar tokens
            await _tokenStorage.clearTokens();
            handler.next(DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: DioExceptionType.badResponse,
              error: 'Token expirado y no se pudo refrescar. Por favor, inicia sesión nuevamente.',
            ));
            return;
          }
        }
        handler.next(error);
      },
    ));
  }

  /// Método GET genérico
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParameters);
      return _handleSuccessResponse(response);
    } on DioException catch (e) {
      return _handleErrorResponse(e);
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  /// Método POST genérico
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return _handleSuccessResponse(response);
    } on DioException catch (e) {
      return _handleErrorResponse(e);
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  /// Método PUT genérico
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return _handleSuccessResponse(response);
    } on DioException catch (e) {
      return _handleErrorResponse(e);
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  /// Método PATCH genérico
  Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(endpoint, data: data);
      return _handleSuccessResponse(response);
    } on DioException catch (e) {
      return _handleErrorResponse(e);
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  /// Método DELETE genérico
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return _handleSuccessResponse(response);
    } on DioException catch (e) {
      return _handleErrorResponse(e);
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  /// Upload de archivos con multipart/form-data
  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    String fieldName,
    File file, {
    String method = 'POST',
    Map<String, String>? additionalFields,
  }) async {
    try {
      final formData = FormData();

      // Agregar archivo
      formData.files.add(MapEntry(
        fieldName,
        await MultipartFile.fromFile(file.path),
      ));

      // Agregar campos adicionales si existen
      if (additionalFields != null) {
        for (final entry in additionalFields.entries) {
          formData.fields.add(MapEntry(entry.key, entry.value));
        }
      }

      Response response;
      switch (method.toUpperCase()) {
        case 'POST':
          response = await _dio.post(endpoint, data: formData);
          break;
        case 'PUT':
          response = await _dio.put(endpoint, data: formData);
          break;
        case 'PATCH':
          response = await _dio.patch(endpoint, data: formData);
          break;
        default:
          throw ArgumentError('Método HTTP no soportado para upload: $method');
      }

      return _handleSuccessResponse(response);
    } on DioException catch (e) {
      return _handleErrorResponse(e);
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  /// Refresca el token de acceso usando el refresh token
  Future<Map<String, dynamic>> _refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        return {
          'success': false,
          'error': 'No refresh token available',
        };
      }

      final response = await _dio.post(
        AppConfig.refreshTokenEndpoint,
        data: {'refresh': refreshToken},
        options: Options(
          headers: {'Authorization': null}, // No usar token para refresh
        ),
      );

      final newAccessToken = response.data['access'];
      await _tokenStorage.saveAccessToken(newAccessToken);

      return {
        'success': true,
        'access_token': newAccessToken,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error refreshing token: $e',
      };
    }
  }

  /// Maneja respuestas exitosas
  Map<String, dynamic> _handleSuccessResponse(Response response) {
    return {
      'success': true,
      'data': response.data,
      'statusCode': response.statusCode,
    };
  }

  /// Maneja errores de Dio
  Map<String, dynamic> _handleErrorResponse(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final responseData = error.response?.data;

    String errorMessage = 'Error en la solicitud';
    Map<String, dynamic> errors = {};

    if (responseData != null) {
      if (responseData is Map<String, dynamic>) {
        errorMessage = responseData['message'] ??
                      responseData['detail'] ??
                      responseData['error'] ??
                      errorMessage;
        errors = responseData['errors'] ?? {};
      } else if (responseData is String) {
        errorMessage = responseData;
      }
    } else {
      // Mensajes por defecto según el tipo de error
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Tiempo de conexión agotado';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = 'Tiempo de envío agotado';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Tiempo de recepción agotado';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Error de conexión';
          break;
        case DioExceptionType.badResponse:
          errorMessage = 'Respuesta inválida del servidor';
          break;
        default:
          errorMessage = error.message ?? errorMessage;
      }
    }

    return {
      'success': false,
      'error': errorMessage,
      'errors': errors,
      'statusCode': statusCode,
      'requiresLogin': statusCode == 401,
    };
  }

  /// Maneja errores genéricos
  Map<String, dynamic> _handleGenericError(dynamic error) {
    return {
      'success': false,
      'error': 'Error inesperado: $error',
      'statusCode': 0,
    };
  }

  /// Limpia el token de autenticación (para logout)
  Future<void> clearAuthToken() async {
    await _tokenStorage.clearTokens();
  }
}
