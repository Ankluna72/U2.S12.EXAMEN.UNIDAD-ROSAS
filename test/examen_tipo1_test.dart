import 'dart:convert';

import 'package:aplicacion_seguridad/core/network/auth_interceptor.dart';
import 'package:aplicacion_seguridad/core/storage/secure_storage_service.dart';
import 'package:aplicacion_seguridad/features/auth/data/repositories/auth_repository.dart';
import 'package:aplicacion_seguridad/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeSecureStorageService implements SecureStorageService {
  String? tokenAcceso;
  String? tokenRenovacion;
  DateTime? tokenAccesoExpiraEn;
  DateTime? tokenRenovacionExpiraEn;

  @override
  Future<void> guardarTokens({
    required String tokenAcceso,
    required String tokenRenovacion,
    required DateTime tokenAccesoExpiraEn,
    required DateTime tokenRenovacionExpiraEn,
  }) async {
    this.tokenAcceso = tokenAcceso;
    this.tokenRenovacion = tokenRenovacion;
    this.tokenAccesoExpiraEn = tokenAccesoExpiraEn;
    this.tokenRenovacionExpiraEn = tokenRenovacionExpiraEn;
  }

  @override
  Future<String?> obtenerTokenAcceso() async => tokenAcceso;

  @override
  Future<String?> obtenerTokenRenovacion() async => tokenRenovacion;

  @override
  Future<DateTime?> obtenerTokenAccesoExpiraEn() async => tokenAccesoExpiraEn;

  @override
  Future<DateTime?> obtenerTokenRenovacionExpiraEn() async =>
      tokenRenovacionExpiraEn;

  @override
  Future<void> limpiarSesion() async {
    tokenAcceso = null;
    tokenRenovacion = null;
    tokenAccesoExpiraEn = null;
    tokenRenovacionExpiraEn = null;
  }
}

void main() {
  group(
      'EXAMEN PRÁCTICO UNIDAD 1 - TIPO 1: Login, Bloqueo por Intentos y Cierre ante HTTP 401',
      () {
    late FakeSecureStorageService fakeStorage;

    setUp(() {
      fakeStorage = FakeSecureStorageService();
    });

    // =========================================================================
    // ÍTEM 4: TRES PRUEBAS UNITARIAS DEL LOGIN EN TERMINAL (4 PUNTOS)
    // =========================================================================

    test(
        'Ítem 4.a (Estado inicial): verificar que al instanciar el servicio no existe sesión previa activa',
        () async {
      final mockClient =
          MockClient((request) async => http.Response('{}', 200));
      final repo =
          AuthRepository(httpClient: mockClient, secureStorage: fakeStorage);
      final controller = AuthController(repository: repo);

      // Verificación de estado inicial sin sesión
      expect(controller.isAuthenticated, isFalse);
      expect(controller.status, equals(AuthStatus.initial));
      expect(controller.sesion, isNull);
      expect(controller.usuario, isNull);
      expect(await fakeStorage.obtenerTokenAcceso(), isNull);
      expect(await fakeStorage.obtenerTokenRenovacion(), isNull);
    });

    test(
        'Ítem 4.b (Autenticación exitosa): credenciales válidas transicionan a autenticado y almacenan el token',
        () async {
      int callsCount = 0;
      final mockClient = MockClient((request) async {
        callsCount++;
        return http.Response(
          jsonEncode({
            'datos': {
              'tipo_token': 'Bearer',
              'token_acceso': 'upt_acceso_valido_123',
              'token_renovacion': 'upt_renovacion_valido_456',
              'token_acceso_expira_en': '2026-09-18T18:00:00.000Z',
              'token_renovacion_expira_en': '2026-09-25T18:00:00.000Z',
              'usuario': {
                'id': 10,
                'codigo_institucional': 'PRUEBA-SEG-001',
                'correo_institucional': 'seguridad@upt.pe',
                'nombres': 'Guardia',
                'apellidos': 'Seguridad',
                'roles': ['SEGURIDAD'],
              },
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo =
          AuthRepository(httpClient: mockClient, secureStorage: fakeStorage);
      final controller = AuthController(repository: repo);

      final result = await controller.iniciarSesion(
        identificador: 'PRUEBA-SEG-001',
        contrasena: 'PassValida123',
      );

      // Verificaciones
      expect(result, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.status, equals(AuthStatus.authenticated));
      expect(controller.sesion?.tokenAcceso, equals('upt_acceso_valido_123'));
      expect(await fakeStorage.obtenerTokenAcceso(),
          equals('upt_acceso_valido_123'));
      expect(callsCount, equals(1));
    });

    test(
        'Ítem 4.c (Autenticación rechazada): respuesta errónea del backend refleja error y asegura no reintentar',
        () async {
      int callsCount = 0;
      final mockClient = MockClient((request) async {
        callsCount++;
        return http.Response(
          jsonEncode({
            'error': {
              'codigo': 'CREDENCIALES_INVALIDAS',
              'mensaje': 'Identificador o contraseña no válidos.',
            }
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo =
          AuthRepository(httpClient: mockClient, secureStorage: fakeStorage);
      final controller = AuthController(repository: repo);

      final result = await controller.iniciarSesion(
        identificador: 'PRUEBA-SEG-001',
        contrasena: 'ClaveIncorrecta',
      );

      // Verificaciones
      expect(result, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.status, equals(AuthStatus.error));
      expect(controller.errorMessage,
          contains('Identificador o contraseña no válidos'));
      // Se asegura que se procesó un único intento y NO se generó reintento automático
      expect(callsCount, equals(1));
      expect(await fakeStorage.obtenerTokenAcceso(), isNull);
    });

    // =========================================================================
    // ÍTEM 5: DOS PRUEBAS UNITARIAS DEL BLOQUEO Y DE LA RESPUESTA 401 (4 PUNTOS)
    // =========================================================================

    test(
        'Ítem 5.a (Verificación de bloqueo): tras 3 fallos consecutivos, el 4to intento emite CERO llamadas al servicio (zero calls)',
        () async {
      int totalInvocacionesServicio = 0;

      // Mock/Spy que cuenta cada vez que la llamada de red llega al servidor
      final mockClient = MockClient((request) async {
        totalInvocacionesServicio++;
        return http.Response(
          jsonEncode({
            'error': {
              'codigo': 'CREDENCIALES_INVALIDAS',
              'mensaje': 'Credenciales inválidas.',
            }
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo =
          AuthRepository(httpClient: mockClient, secureStorage: fakeStorage);
      final controller = AuthController(repository: repo);

      // Intento 1 fallido
      await controller.iniciarSesion(
          identificador: 'USER', contrasena: 'FAIL1');
      expect(totalInvocacionesServicio, equals(1));
      expect(controller.estaBloqueado, isFalse);

      // Intento 2 fallido
      await controller.iniciarSesion(
          identificador: 'USER', contrasena: 'FAIL2');
      expect(totalInvocacionesServicio, equals(2));
      expect(controller.estaBloqueado, isFalse);

      // Intento 3 fallido (alcanza el límite de 3 fallos)
      await controller.iniciarSesion(
          identificador: 'USER', contrasena: 'FAIL3');
      expect(totalInvocacionesServicio, equals(3));
      expect(controller.estaBloqueado, isTrue);

      // CUARTO INTENTO CONSECUTIVO:
      // La app debe bloquearse y no emitir NINGUNA llamada al servicio (cero llamadas adicionales)
      final resultadoCuartoIntento = await controller.iniciarSesion(
        identificador: 'USER',
        contrasena: 'FAIL4',
      );

      // Demostración de ZERO CALLS en el 4to intento:
      expect(resultadoCuartoIntento, isFalse);
      expect(totalInvocacionesServicio, equals(3),
          reason:
              'El cuarto intento no debe incrementar las llamadas al servicio (zero calls)');
      expect(controller.errorMessage, contains('Acceso bloqueado'));
    });

    test(
        'Ítem 5.b (Verificación de HTTP 401): inyectar código 401 simulado purga el token a nulo y registra un único envío sin reintentos',
        () async {
      int requestCount = 0;
      bool callbackEjecutado = false;

      // Pre-cargar sesión activa con token existente en almacenamiento
      await fakeStorage.guardarTokens(
        tokenAcceso: 'token_activo_anterior',
        tokenRenovacion: 'token_renovacion_anterior',
        tokenAccesoExpiraEn: DateTime.now().add(const Duration(hours: 1)),
        tokenRenovacionExpiraEn: DateTime.now().add(const Duration(days: 7)),
      );

      expect(await fakeStorage.obtenerTokenAcceso(),
          equals('token_activo_anterior'));

      // Mock que simula el servidor respondiendo con 401 Unauthorized
      final mockServer = MockClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode({
            'error': {
              'codigo': 'TOKEN_ACCESO_INVALIDO',
              'mensaje': 'El token ha sido revocado o es inválido.',
            }
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      // Interceptor desacoplado que captura el 401
      final interceptor = AuthInterceptor(
        innerClient: mockServer,
        secureStorage: fakeStorage,
        onUnauthorized: () {
          callbackEjecutado = true;
        },
      );

      // Ejecutar una petición autenticada usando el interceptor
      final response = await interceptor.get(
        Uri.parse('https://api-moviles.fottuto.men/api/autenticacion/sesion'),
        headers: {
          'Authorization': 'Bearer token_activo_anterior',
          'Accept': 'application/json',
        },
      );

      // Aserciones de verificación
      expect(response.statusCode, equals(401));
      // 1. Demostrar que el token queda totalmente limpio/nulo en el almacenamiento
      expect(await fakeStorage.obtenerTokenAcceso(), isNull);
      expect(await fakeStorage.obtenerTokenRenovacion(), isNull);
      // 2. Demostrar que se notificó la sesión cerrada de forma reactiva
      expect(callbackEjecutado, isTrue);
      // 3. Demostrar que se registró exactamente un único envío sin reintentos
      expect(requestCount, equals(1));
    });
  });
}
