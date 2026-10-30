import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _envUrl = String.fromEnvironment('URL_API_UPT');

  static String get baseUrl {
    if (_envUrl.isNotEmpty) {
      return _envUrl;
    }
    if (kReleaseMode) {
      return 'https://api-moviles.fottuto.men/api';
    }
    // En desarrollo local por defecto se apunta a la API remota o local
    return 'https://api-moviles.fottuto.men/api';
  }

  static const String iniciarSesionPath = '/autenticacion/iniciar-sesion';
  static const String renovarSesionPath = '/autenticacion/renovar-sesion';
  static const String consultarSesionPath = '/autenticacion/sesion';
  static const String cerrarSesionPath = '/autenticacion/cerrar-sesion';
  static const String validarIngresoPath = '/ingresos/validar';
  static const String ingresosRecientesPath = '/ingresos/recientes';

  static Uri uriFor(String path) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$cleanPath');
  }
}
