import 'package:http/http.dart' as http;

import '../storage/secure_storage_service.dart';

typedef OnUnauthorizedCallback = void Function();

/// Interceptor desacoplado y reactivo para capturar respuestas HTTP 401 Unauthorized.
/// Actúa como un middleware/filtro para todas las peticiones que viajan con sesión activa.
class AuthInterceptor extends http.BaseClient {
  final http.Client _innerClient;
  final SecureStorageService _secureStorage;
  final OnUnauthorizedCallback? _onUnauthorized;

  AuthInterceptor({
    http.Client? innerClient,
    required SecureStorageService secureStorage,
    OnUnauthorizedCallback? onUnauthorized,
  })  : _innerClient = innerClient ?? http.Client(),
        _secureStorage = secureStorage,
        _onUnauthorized = onUnauthorized;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Procesa la petición exactamente una sola vez (un único envío sin reintentos automáticos)
    final response = await _innerClient.send(request);

    // Detección reactiva de error HTTP 401 Unauthorized en peticiones autenticadas
    if (response.statusCode == 401 &&
        request.headers.containsKey('Authorization')) {
      // 1. Purga inmediatamente el token de autenticación del almacenamiento local
      await _secureStorage.limpiarSesion();

      // 2. Notifica y fuerza reactivamente el estado de sesión cerrada en la aplicación
      _onUnauthorized?.call();

      // 3. Bloquea cualquier reintento automático retornando la respuesta original sin reintentar
    }

    return response;
  }
}
