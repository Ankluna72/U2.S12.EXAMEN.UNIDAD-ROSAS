import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/role_policy.dart';
import '../models/sesion_model.dart';
import '../models/usuario_model.dart';

class AuthRepository {
  final http.Client _httpClient;
  final SecureStorageService _secureStorage;
  final OnUnauthorizedCallback? _onUnauthorized;

  AuthRepository({
    http.Client? httpClient,
    SecureStorageService? secureStorage,
    OnUnauthorizedCallback? onUnauthorized,
  })  : _secureStorage = secureStorage ?? FlutterSecureStorageService(),
        _onUnauthorized = onUnauthorized,
        _httpClient = AuthInterceptor(
          innerClient: httpClient ?? http.Client(),
          secureStorage: secureStorage ?? FlutterSecureStorageService(),
          onUnauthorized: onUnauthorized,
        );

  SecureStorageService get storage => _secureStorage;
  OnUnauthorizedCallback? get onUnauthorized => _onUnauthorized;

  Map<String, String> _buildHeaders({String? tokenAcceso}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (tokenAcceso != null && tokenAcceso.isNotEmpty) {
      headers['Authorization'] = 'Bearer $tokenAcceso';
    }
    return headers;
  }

  ApiException _handleErrorResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body.containsKey('error')) {
        final err = body['error'] as Map<String, dynamic>;
        final codigo = err['codigo'] as String? ?? 'ERROR_DESCONOCIDO';
        final mensaje =
            err['mensaje'] as String? ?? 'Ocurrió un error inesperado.';

        switch (codigo) {
          case 'CREDENCIALES_INVALIDAS':
            return CredencialesInvalidasException(mensaje);
          case 'USUARIO_NO_HABILITADO':
            return UsuarioNoHabilitadoException(mensaje);
          case 'INICIO_SESION_BLOQUEADO':
            return InicioSesionBloqueadoException(mensaje);
          case 'DATOS_INVALIDOS':
          case 'JSON_INVALIDO':
            return DatosInvalidosException(mensaje);
          case 'TOKEN_RENOVACION_INVALIDO':
          case 'TOKEN_ACCESO_INVALIDO':
          case 'AUTENTICACION_REQUERIDA':
            return TokenInvalidoException(
              codigo: codigo,
              mensaje: mensaje,
              statusCode: response.statusCode,
            );
          default:
            return ApiException(
              codigo: codigo,
              mensaje: mensaje,
              statusCode: response.statusCode,
            );
        }
      }
    } catch (_) {
      // Si la respuesta no es un JSON estándar de error
    }

    if (response.statusCode == 401) {
      return const CredencialesInvalidasException();
    } else if (response.statusCode == 403) {
      return const UsuarioNoHabilitadoException();
    } else if (response.statusCode == 429) {
      return const InicioSesionBloqueadoException();
    }

    return ApiException(
      codigo: 'HTTP_${response.statusCode}',
      mensaje: 'Error en el servidor (${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  /// Inicia sesión con identificador (código o correo) y contraseña.
  Future<SesionModel> iniciarSesion({
    required String identificador,
    required String contrasena,
  }) async {
    final trimmedIdentificador = identificador.trim();
    if (trimmedIdentificador.isEmpty || contrasena.isEmpty) {
      throw const DatosInvalidosException(
          'Debes ingresar tu identificador y contraseña.');
    }

    final uri = ApiConfig.uriFor(ApiConfig.iniciarSesionPath);
    final body = jsonEncode({
      'identificador': trimmedIdentificador,
      'contrasena': contrasena,
    });

    http.Response response;
    try {
      response = await _httpClient
          .post(uri, headers: _buildHeaders(), body: body)
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException(
          'Tiempo de espera agotado al conectar con el servidor.');
    }

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final datos = decoded['datos'] as Map<String, dynamic>;
      final sesion = SesionModel.fromJson(datos);

      // Verificación de política de roles
      if (!RolePolicy.tieneRolPermitido(sesion.usuario.roles)) {
        // Intenta revocar sesión en servidor y limpia localmente
        try {
          await cerrarSesion(sesion.tokenAcceso);
        } catch (_) {
          await _secureStorage.limpiarSesion();
        }
        throw const RolNoAutorizadoException();
      }

      // Guardar en almacenamiento seguro
      await _secureStorage.guardarTokens(
        tokenAcceso: sesion.tokenAcceso,
        tokenRenovacion: sesion.tokenRenovacion,
        tokenAccesoExpiraEn: sesion.tokenAccesoExpiraEn,
        tokenRenovacionExpiraEn: sesion.tokenRenovacionExpiraEn,
      );

      return sesion;
    }

    throw _handleErrorResponse(response);
  }

  /// Renueva la sesión enviando el token de renovación en el cuerpo JSON.
  /// Rota atómicamente ambos tokens.
  Future<SesionModel> renovarSesion(String tokenRenovacion) async {
    final uri = ApiConfig.uriFor(ApiConfig.renovarSesionPath);
    final body = jsonEncode({
      'token_renovacion': tokenRenovacion.trim(),
    });

    http.Response response;
    try {
      response = await _httpClient
          .post(uri, headers: _buildHeaders(), body: body)
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException(
          'Tiempo de espera agotado al renovar la sesión.');
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final datos = decoded['datos'] as Map<String, dynamic>;
      final sesion = SesionModel.fromJson(datos);

      if (!RolePolicy.tieneRolPermitido(sesion.usuario.roles)) {
        await _secureStorage.limpiarSesion();
        throw const RolNoAutorizadoException();
      }

      await _secureStorage.guardarTokens(
        tokenAcceso: sesion.tokenAcceso,
        tokenRenovacion: sesion.tokenRenovacion,
        tokenAccesoExpiraEn: sesion.tokenAccesoExpiraEn,
        tokenRenovacionExpiraEn: sesion.tokenRenovacionExpiraEn,
      );

      return sesion;
    }

    // Ante fallo en renovación, limpiar sesión local
    await _secureStorage.limpiarSesion();
    throw _handleErrorResponse(response);
  }

  /// Consulta la sesión actual con token Bearer.
  Future<UsuarioModel> consultarSesion(String tokenAcceso) async {
    final uri = ApiConfig.uriFor(ApiConfig.consultarSesionPath);

    http.Response response;
    try {
      response = await _httpClient
          .get(uri, headers: _buildHeaders(tokenAcceso: tokenAcceso))
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException(
          'Tiempo de espera agotado al validar la sesión.');
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final datos = decoded['datos'] as Map<String, dynamic>;
      final usuario =
          UsuarioModel.fromJson(datos['usuario'] as Map<String, dynamic>);

      if (!RolePolicy.tieneRolPermitido(usuario.roles)) {
        await _secureStorage.limpiarSesion();
        throw const RolNoAutorizadoException();
      }

      return usuario;
    }

    throw _handleErrorResponse(response);
  }

  /// Cierra la sesión en el servidor y limpia siempre el almacenamiento local.
  Future<void> cerrarSesion([String? tokenAcceso]) async {
    final token = tokenAcceso ?? await _secureStorage.obtenerTokenAcceso();

    try {
      if (token != null && token.isNotEmpty) {
        final uri = ApiConfig.uriFor(ApiConfig.cerrarSesionPath);
        await _httpClient
            .post(uri, headers: _buildHeaders(tokenAcceso: token))
            .timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      // Ignora errores de red o servidor durante logout
    } finally {
      // Siempre borra la sesión local
      await _secureStorage.limpiarSesion();
    }
  }
}
