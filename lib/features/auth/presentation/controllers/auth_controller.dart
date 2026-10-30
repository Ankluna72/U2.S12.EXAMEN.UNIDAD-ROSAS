import 'package:flutter/foundation.dart';

import '../../../../core/error/api_exception.dart';
import '../../data/models/sesion_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthController extends ChangeNotifier {
  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.initial;
  SesionModel? _sesion;
  UsuarioModel? _usuario;
  String? _errorMessage;

  // Control de bloqueo de intentos de autenticación (Ítem 2 del Examen)
  int _intentosFallidos = 0;
  static const int maxIntentosFallidos = 3;

  AuthController({required AuthRepository repository})
      : _repository = repository;

  AuthStatus get status => _status;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  SesionModel? get sesion => _sesion;
  UsuarioModel? get usuario => _usuario ?? _sesion?.usuario;
  String? get errorMessage => _errorMessage;

  int get intentosFallidos => _intentosFallidos;
  bool get estaBloqueado => _intentosFallidos >= maxIntentosFallidos;

  /// Restablece manualmente el contador de intentos fallidos.
  void resetearIntentos() {
    _intentosFallidos = 0;
    _errorMessage = null;
    notifyListeners();
  }

  /// Cierre de sesión reactivo forzado ante error HTTP 401 Unauthorized (Ítem 3 del Examen).
  void forzarCierreSesionPor401() {
    _sesion = null;
    _usuario = null;
    _errorMessage =
        'Sesión cerrada automáticamente: Se recibió un error HTTP 401 Unauthorized.';
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Restaura la sesión guardada al iniciar la aplicación.
  Future<void> inicializarSesion() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final tokenAcceso = await _repository.storage.obtenerTokenAcceso();
      final tokenRenovacion =
          await _repository.storage.obtenerTokenRenovacion();
      final tokenAccesoExpiraEn =
          await _repository.storage.obtenerTokenAccesoExpiraEn();
      final tokenRenovacionExpiraEn =
          await _repository.storage.obtenerTokenRenovacionExpiraEn();

      // Si falta alguno de los tokens o el de renovación ya expiró, ir a login
      if (tokenAcceso == null ||
          tokenRenovacion == null ||
          tokenAccesoExpiraEn == null ||
          tokenRenovacionExpiraEn == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      final now = DateTime.now();
      if (now.isAfter(tokenRenovacionExpiraEn)) {
        await _repository.storage.limpiarSesion();
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // Si el token de acceso sigue vigente (más de 30 segundos restantes)
      if (now.add(const Duration(seconds: 30)).isBefore(tokenAccesoExpiraEn)) {
        try {
          final usuario = await _repository.consultarSesion(tokenAcceso);
          _usuario = usuario;
          _sesion = SesionModel(
            tipoToken: 'Bearer',
            tokenAcceso: tokenAcceso,
            tokenRenovacion: tokenRenovacion,
            tokenAccesoExpiraEn: tokenAccesoExpiraEn,
            tokenRenovacionExpiraEn: tokenRenovacionExpiraEn,
            usuario: usuario,
          );
          _status = AuthStatus.authenticated;
          notifyListeners();
          return;
        } catch (_) {
          // Si falla consultar sesión, intentamos renovar
        }
      }

      // Si el token de acceso venció o falló la consulta, renovamos sesión
      final nuevaSesion = await _repository.renovarSesion(tokenRenovacion);
      _sesion = nuevaSesion;
      _usuario = nuevaSesion.usuario;
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (_) {
      // Cualquier fallo en restauración limpia la sesión local y va a login
      await _repository.storage.limpiarSesion();
      _sesion = null;
      _usuario = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Inicia sesión con credenciales institucionales.
  /// Administra el bloqueo de tres intentos fallidos consecutivos (Ítem 2 del Examen).
  Future<bool> iniciarSesion({
    required String identificador,
    required String contrasena,
  }) async {
    // CONDICIÓN DE INTERRUPCIÓN PREVIA A LA LLAMADA DEL SERVICIO (Ítem 2):
    // Al registrarse el cuarto intento consecutivo (cuando ya acumuló 3 fallos previos),
    // la app debe bloquearse: no emite ninguna llamada al servicio de autenticación
    // y presenta un mensaje de bloqueo temporal explícito al usuario.
    if (estaBloqueado) {
      _errorMessage =
          'Acceso bloqueado: Has superado el límite de $maxIntentosFallidos intentos fallidos consecutivos. La app no procesará nuevas llamadas de autenticación.';
      _status = AuthStatus.error;
      notifyListeners();
      return false; // Retorna de inmediato (CERO llamadas de red)
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final sesion = await _repository.iniciarSesion(
        identificador: identificador,
        contrasena: contrasena,
      );
      // Login exitoso: se reinicia el acumulador de intentos fallidos
      _intentosFallidos = 0;
      _sesion = sesion;
      _usuario = sesion.usuario;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _intentosFallidos++;
      if (estaBloqueado) {
        _errorMessage =
            'Acceso bloqueado: Has acumulado $maxIntentosFallidos intentos fallidos consecutivos. Tu próximo intento no será emitido al servidor.';
      } else {
        _errorMessage =
            '${e.mensaje} (Intento fallido $_intentosFallidos de $maxIntentosFallidos)';
      }
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _intentosFallidos++;
      if (estaBloqueado) {
        _errorMessage =
            'Acceso bloqueado: Has acumulado $maxIntentosFallidos intentos fallidos consecutivos.';
      } else {
        _errorMessage =
            'Ocurrió un error inesperado al iniciar sesión. (Intento $_intentosFallidos de $maxIntentosFallidos)';
      }
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión activa.
  Future<void> cerrarSesion() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _repository.cerrarSesion(_sesion?.tokenAcceso);
    } finally {
      _sesion = null;
      _usuario = null;
      _errorMessage = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }
}
