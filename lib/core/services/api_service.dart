import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  bool _isRefreshing = false;
  Future<Map<String, dynamic>>? _ongoingRefresh;
  int _refreshAttempts = 0;
  static const int _maxRefreshAttempts = 3;

  void _initializeDio() {
    final resolvedBaseUrl = AppConfig.httpBaseUri().toString();
    _dio = Dio(BaseOptions(
      baseUrl: resolvedBaseUrl,
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
        print('ApiService: Preparando petición a ${options.path}');
        final isRefreshPath = options.path == AppConfig.refreshTokenEndpoint ||
            options.path == AppConfig.tokenRefreshEndpoint;
        final pathLower = options.path.toLowerCase();
        final isAuthPath =
            pathLower.contains('login') || pathLower.contains('register');
        if (!isRefreshPath && !isAuthPath) {
          final token = await _tokenStorage.getAccessToken();
          print(
              'ApiService: Token obtenido: ${token != null ? "Token presente (${token.substring(0, 20)}...)" : "No hay token"}');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('ApiService: Header Authorization añadido');
          } else {
            print('ApiService: ADVERTENCIA - No se encontró token de acceso');
          }
        } else if (isRefreshPath) {
          print(
              'ApiService: Petición de refresh detectada, omitiendo Authorization');
        } else if (isAuthPath) {
          print(
              'ApiService: Petición de autenticación detectada, omitiendo Authorization');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Manejar error 401 (Unauthorized) con refresh automático
        // Evitar bucle: si la petición que falló ES el refresh, no intentar refrescar de nuevo
        final isRefreshPath =
            error.requestOptions.path == AppConfig.refreshTokenEndpoint ||
                error.requestOptions.path == AppConfig.tokenRefreshEndpoint;
        final pathLower = error.requestOptions.path.toLowerCase();
        final isAuthPath =
            pathLower.contains('login') || pathLower.contains('register');
        if (error.response?.statusCode == 401 &&
            !isRefreshPath &&
            !isAuthPath) {
          // Limit refresh attempts to prevent infinite loops
          if (_refreshAttempts >= _maxRefreshAttempts) {
            print(
                'ApiService: Maximum refresh attempts reached, clearing tokens');
            await _tokenStorage.clearTokens();
            _refreshAttempts = 0;
            handler.next(DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: DioExceptionType.badResponse,
              error:
                  'Máximo de intentos de refresco alcanzado. Por favor, inicia sesión nuevamente.',
            ));
            return;
          }

          if (_isRefreshing && _ongoingRefresh != null) {
            final refreshResult = await _ongoingRefresh!;
            if (refreshResult['success']) {
              final newToken = refreshResult['access_token'];
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newToken';
              try {
                final response = await _dio.fetch(error.requestOptions);
                handler.resolve(response);
                return;
              } catch (e) {
                handler.next(error);
                return;
              }
            } else {
              _refreshAttempts++;
              await _tokenStorage.clearTokens();
              handler.next(DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: DioExceptionType.badResponse,
                error:
                    'Token expirado y no se pudo refrescar. Por favor, inicia sesión nuevamente.',
              ));
              return;
            }
          }

          _isRefreshing = true;
          _ongoingRefresh = _refreshToken();
          final refreshResult = await _ongoingRefresh!;
          _isRefreshing = false;
          _ongoingRefresh = null;

          if (refreshResult['success']) {
            // Reintentar la petición original con el nuevo token
            final newToken = refreshResult['access_token'];
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            _refreshAttempts = 0; // Reset counter on successful refresh

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
            _refreshAttempts++;
            await _tokenStorage.clearTokens();
            handler.next(DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: DioExceptionType.badResponse,
              error:
                  'Token expirado y no se pudo refrescar. Por favor, inicia sesión nuevamente.',
            ));
            return;
          }
        }
        handler.next(error);
      },
    ));
  }

  /// Método GET genérico
  Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response =
          await _dio.get(endpoint, queryParameters: queryParameters);
      return _handleSuccessResponse(response);
    } on DioException catch (e) {
      return _handleErrorResponse(e);
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  /// Método POST genérico
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
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
  Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> data) async {
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
  Future<Map<String, dynamic>> patch(
      String endpoint, Map<String, dynamic> data) async {
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
        print('ApiService: No refresh token available');
        return {
          'success': false,
          'error': 'No refresh token available',
        };
      }

      print('ApiService: Attempting to refresh token...');

      // Preparar payload compatible
      final payload = {
        'refresh': refreshToken,
        'refresh_token': refreshToken,
      };

      // Usar el endpoint configurado por el backend
      // Preferimos AppConfig.refreshTokenEndpoint; si el backend usa SimpleJWT,
      // AppConfig.tokenRefreshEndpoint puede apuntar al mismo valor.
      Response response;
      try {
        response = await _dio.post(
          AppConfig.refreshTokenEndpoint,
          data: payload,
          options: Options(headers: {'Authorization': null}),
        );
      } on DioException {
        response = await _dio.post(
          AppConfig.tokenRefreshEndpoint,
          data: payload,
          options: Options(headers: {'Authorization': null}),
        );
      }

      // La API puede responder de varias formas:
      // - { success, message, data: { access } }
      // - { access: "..." }
      // - { access_token: "..." }
      final envelope = response.data;
      String? newAccessToken;
      String? newRefreshToken;
      if (envelope is Map<String, dynamic>) {
        if (envelope['access'] is String) {
          newAccessToken = envelope['access'] as String;
        }
        if (envelope['refresh'] is String) {
          newRefreshToken = envelope['refresh'] as String;
        }
        if (envelope['access_token'] is String) {
          newAccessToken = envelope['access_token'] as String;
        }
        if (envelope['data'] is Map) {
          final data = Map<String, dynamic>.from(envelope['data'] as Map);
          final acc = data['access'] ?? data['access_token'];
          final ref = data['refresh'] ?? data['refresh_token'];
          if (acc is String) newAccessToken = acc;
          if (ref is String) newRefreshToken = ref;
        }
      }

      if (newAccessToken == null || (newAccessToken.isEmpty)) {
        return {
          'success': false,
          'error': 'No access token received during refresh',
        };
      }

      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _tokenStorage.saveTokens(newAccessToken, newRefreshToken);
      } else {
        await _tokenStorage.saveAccessToken(newAccessToken);
      }

      return {
        'success': true,
        'access_token': newAccessToken,
        'refresh_token': newRefreshToken,
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

  /// Reconfigura Dio e interceptores; útil tras hot reload
  void reinitialize() {
    final resolvedBaseUrl = AppConfig.httpBaseUri().toString();
    _dio.options
      ..baseUrl = resolvedBaseUrl
      ..connectTimeout = const Duration(seconds: 30)
      ..receiveTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    _dio.interceptors.clear();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('ApiService: Preparando petición a ${options.path}');
        final isRefreshPath = options.path == AppConfig.refreshTokenEndpoint ||
            options.path == AppConfig.tokenRefreshEndpoint;
        final pathLower = options.path.toLowerCase();
        final isAuthPath =
            pathLower.contains('login') || pathLower.contains('register');
        if (!isRefreshPath && !isAuthPath) {
          final token = await _tokenStorage.getAccessToken();
          print(
              'ApiService: Token obtenido: ${token != null ? "Token presente (${token.substring(0, 20)}...)" : "No hay token"}');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('ApiService: Header Authorization añadido');
          } else {
            print('ApiService: ADVERTENCIA - No se encontró token de acceso');
          }
        } else if (isRefreshPath) {
          print(
              'ApiService: Petición de refresh detectada, omitiendo Authorization');
        } else if (isAuthPath) {
          print(
              'ApiService: Petición de autenticación detectada, omitiendo Authorization');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isRefreshPath =
            error.requestOptions.path == AppConfig.refreshTokenEndpoint ||
                error.requestOptions.path == AppConfig.tokenRefreshEndpoint;
        final pathLower = error.requestOptions.path.toLowerCase();
        final isAuthPath =
            pathLower.contains('login') || pathLower.contains('register');
        if (error.response?.statusCode == 401 &&
            !isRefreshPath &&
            !isAuthPath) {
          if (_refreshAttempts >= _maxRefreshAttempts) {
            print(
                'ApiService: Maximum refresh attempts reached, clearing tokens');
            await _tokenStorage.clearTokens();
            _refreshAttempts = 0;
            handler.next(DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: DioExceptionType.badResponse,
              error:
                  'Máximo de intentos de refresco alcanzado. Por favor, inicia sesión nuevamente.',
            ));
            return;
          }

          if (_isRefreshing && _ongoingRefresh != null) {
            final refreshResult = await _ongoingRefresh!;
            if (refreshResult['success']) {
              final newToken = refreshResult['access_token'];
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newToken';
              try {
                final response = await _dio.fetch(error.requestOptions);
                handler.resolve(response);
                return;
              } catch (e) {
                handler.next(error);
                return;
              }
            } else {
              _refreshAttempts++;
              await _tokenStorage.clearTokens();
              handler.next(DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: DioExceptionType.badResponse,
                error:
                    'Token expirado y no se pudo refrescar. Por favor, inicia sesión nuevamente.',
              ));
              return;
            }
          }

          _isRefreshing = true;
          _ongoingRefresh = _refreshToken();
          final refreshResult = await _ongoingRefresh!;
          _isRefreshing = false;
          _ongoingRefresh = null;

          if (refreshResult['success']) {
            final newToken = refreshResult['access_token'];
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            _refreshAttempts = 0;

            try {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
              handler.next(error);
              return;
            }
          } else {
            _refreshAttempts++;
            await _tokenStorage.clearTokens();
            handler.next(DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: DioExceptionType.badResponse,
              error:
                  'Token expirado y no se pudo refrescar. Por favor, inicia sesión nuevamente.',
            ));
            return;
          }
        }
        handler.next(error);
      },
    ));
  }
}
