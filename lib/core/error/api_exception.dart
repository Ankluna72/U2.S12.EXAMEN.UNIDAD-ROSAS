/// Excepción para errores devueltos por la API o problemas de comunicación.
class ApiException implements Exception {
  final String codigo;
  final String mensaje;
  final int? statusCode;

  const ApiException({
    required this.codigo,
    required this.mensaje,
    this.statusCode,
  });

  @override
  String toString() =>
      'ApiException(codigo: $codigo, mensaje: $mensaje, statusCode: $statusCode)';
}

class CredencialesInvalidasException extends ApiException {
  const CredencialesInvalidasException([String? mensaje])
      : super(
          codigo: 'CREDENCIALES_INVALIDAS',
          mensaje: mensaje ?? 'Identificador o contraseña incorrectos.',
          statusCode: 401,
        );
}

class UsuarioNoHabilitadoException extends ApiException {
  const UsuarioNoHabilitadoException([String? mensaje])
      : super(
          codigo: 'USUARIO_NO_HABILITADO',
          mensaje: mensaje ??
              'Tu cuenta está inactiva o no se encuentra autorizada.',
          statusCode: 403,
        );
}

class InicioSesionBloqueadoException extends ApiException {
  const InicioSesionBloqueadoException([String? mensaje])
      : super(
          codigo: 'INICIO_SESION_BLOQUEADO',
          mensaje: mensaje ??
              'Has superado el límite de intentos fallidos. Espera unos minutos antes de reintentar.',
          statusCode: 429,
        );
}

class DatosInvalidosException extends ApiException {
  const DatosInvalidosException([String? mensaje])
      : super(
          codigo: 'DATOS_INVALIDOS',
          mensaje: mensaje ??
              'Los datos ingresados no cumplen con el formato requerido.',
          statusCode: 400,
        );
}

class TokenInvalidoException extends ApiException {
  const TokenInvalidoException(
      {required super.codigo, required super.mensaje, super.statusCode = 401});
}

class RolNoAutorizadoException extends ApiException {
  const RolNoAutorizadoException([String? mensaje])
      : super(
          codigo: 'ROL_NO_AUTORIZADO',
          mensaje: mensaje ??
              'Acceso denegado: Esta aplicación es exclusiva para el personal de Seguridad o Administradores.',
          statusCode: 403,
        );
}

class NetworkException extends ApiException {
  const NetworkException([String? mensaje])
      : super(
          codigo: 'ERROR_CONEXION',
          mensaje: mensaje ??
              'No se pudo conectar con el servidor. Verifica tu conexión a internet.',
        );
}
