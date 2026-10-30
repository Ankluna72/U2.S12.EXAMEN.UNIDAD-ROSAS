import 'dart:convert';

import 'package:aplicacion_seguridad/core/error/api_exception.dart';
import 'package:aplicacion_seguridad/core/storage/secure_storage_service.dart';
import 'package:aplicacion_seguridad/features/auth/data/repositories/auth_repository.dart';
import 'package:aplicacion_seguridad/features/auth/domain/role_policy.dart';
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
  group('AuthRepository Tests', () {
    late FakeSecureStorageService fakeStorage;

    setUp(() {
      fakeStorage = FakeSecureStorageService();
    });

    test(
        'iniciarSesion exitoso con rol SEGURIDAD guarda tokens y deserializa correctamente',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/autenticacion/iniciar-sesion'));
        expect(request.headers['Accept'], 'application/json');
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['identificador'], 'PRUEBA-SEG-001');
        expect(body['contrasena'], 'Pass123!');

        return http.Response(
          jsonEncode({
            'datos': {
              'tipo_token': 'Bearer',
              'token_acceso': 'acceso_abc123',
              'token_renovacion': 'renovacion_xyz789',
              'token_acceso_expira_en': '2026-09-18T16:00:00.000Z',
              'token_renovacion_expira_en': '2026-09-25T16:00:00.000Z',
              'usuario': {
                'id': 10,
                'codigo_institucional': 'PRUEBA-SEG-001',
                'correo_institucional': 'seguridad@upt.pe',
                'nombres': 'Juan',
                'apellidos': 'Perez',
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
      final sesion = await repo.iniciarSesion(
        identificador: '  PRUEBA-SEG-001  ', // Debe hacer trim
        contrasena: 'Pass123!',
      );

      expect(sesion.tokenAcceso, 'acceso_abc123');
      expect(sesion.tokenRenovacion, 'renovacion_xyz789');
      expect(sesion.usuario.nombres, 'Juan');
      expect(sesion.usuario.roles, contains('SEGURIDAD'));

      // Verificar persistencia en almacenamiento seguro
      expect(fakeStorage.tokenAcceso, 'acceso_abc123');
      expect(fakeStorage.tokenRenovacion, 'renovacion_xyz789');
    });

    test('iniciarSesion con rol ADMINISTRADOR es aceptado', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'datos': {
              'tipo_token': 'Bearer',
              'token_acceso': 'token_admin',
              'token_renovacion': 'token_renov_admin',
              'token_acceso_expira_en': '2026-09-18T16:00:00.000Z',
              'token_renovacion_expira_en': '2026-09-25T16:00:00.000Z',
              'usuario': {
                'id': 1,
                'codigo_institucional': 'ADMIN-001',
                'correo_institucional': 'admin@upt.pe',
                'nombres': 'Super',
                'apellidos': 'Admin',
                'roles': ['ADMINISTRADOR'],
              },
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo =
          AuthRepository(httpClient: mockClient, secureStorage: fakeStorage);
      final sesion = await repo.iniciarSesion(
        identificador: 'ADMIN-001',
        contrasena: 'AdminPass',
      );

      expect(sesion.usuario.roles, contains('ADMINISTRADOR'));
      expect(RolePolicy.tieneRolPermitido(sesion.usuario.roles), isTrue);
    });

    test('iniciarSesion rechaza cuenta sin roles autorizados (ej. ESTUDIANTE)',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/autenticacion/cerrar-sesion')) {
          return http.Response('', 204);
        }

        return http.Response(
          jsonEncode({
            'datos': {
              'tipo_token': 'Bearer',
              'token_acceso': 'token_estudiante',
              'token_renovacion': 'token_renov_estudiante',
              'token_acceso_expira_en': '2026-09-18T16:00:00.000Z',
              'token_renovacion_expira_en': '2026-09-25T16:00:00.000Z',
              'usuario': {
                'id': 50,
                'codigo_institucional': '2021072618',
                'correo_institucional': 'estudiante@upt.pe',
                'nombres': 'Alumno',
                'apellidos': 'Prueba',
                'roles': ['ESTUDIANTE'],
              },
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo =
          AuthRepository(httpClient: mockClient, secureStorage: fakeStorage);

      expect(
        () => repo.iniciarSesion(
            identificador: '2021072618', contrasena: 'Estudiante123'),
        throwsA(isA<RolNoAutorizadoException>()),
      );

      // Los tokens no deben quedar almacenados
      expect(fakeStorage.tokenAcceso, isNull);
    });

    test('iniciarSesion mapea CREDENCIALES_INVALIDAS (401)', () async {
      final mockClient = MockClient((request) async {
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

      expect(
        () => repo.iniciarSesion(
            identificador: 'PRUEBA-SEG-001', contrasena: 'WrongPass'),
        throwsA(isA<CredencialesInvalidasException>()),
      );
    });

    test('iniciarSesion mapea INICIO_SESION_BLOQUEADO (429)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'codigo': 'INICIO_SESION_BLOQUEADO',
              'mensaje': 'Demasiados intentos fallidos.',
            }
          }),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo =
          AuthRepository(httpClient: mockClient, secureStorage: fakeStorage);

      expect(
        () => repo.iniciarSesion(
            identificador: 'PRUEBA-SEG-001', contrasena: 'FailPass'),
        throwsA(isA<InicioSesionBloqueadoException>()),
      );
    });

    test('iniciarSesion mapea USUARIO_NO_HABILITADO (403)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'codigo': 'USUARIO_NO_HABILITADO',
              'mensaje': 'La cuenta no está activa.',
            }
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo =
          AuthRepository(httpClient: mockClient, secureStorage: fakeStorage);

      expect(
        () => repo.iniciarSesion(
            identificador: 'PRUEBA-SEG-001', contrasena: 'SomePass'),
        throwsA(isA<UsuarioNoHabilitadoException>()),
      );
    });

    test('renovarSesion rota ambos tokens atómicamente', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/autenticacion/renovar-sesion'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['token_renovacion'], 'token_antiguo_renovacion');

        return http.Response(
          jsonEncode({
            'datos': {
              'tipo_token': 'Bearer',
              'token_acceso': 'nuevo_acceso_111',
              'token_renovacion': 'nueva_renovacion_222',
              'token_acceso_expira_en': '2026-09-18T17:00:00.000Z',
              'token_renovacion_expira_en': '2026-09-25T17:00:00.000Z',
              'usuario': {
                'id': 10,
                'codigo_institucional': 'PRUEBA-SEG-001',
                'correo_institucional': 'seguridad@upt.pe',
                'nombres': 'Juan',
                'apellidos': 'Perez',
                'roles': ['SEGURIDAD'],
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo =
          AuthRepository(httpClient: mockClient, secureStorage: fakeStorage);
      final sesion = await repo.renovarSesion('token_antiguo_renovacion');

      expect(sesion.tokenAcceso, 'nuevo_acceso_111');
      expect(sesion.tokenRenovacion, 'nueva_renovacion_222');
      expect(fakeStorage.tokenAcceso, 'nuevo_acceso_111');
      expect(fakeStorage.tokenRenovacion, 'nueva_renovacion_222');
    });

    test('consultarSesion envía cabecera Bearer y deserializa usuario',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/autenticacion/sesion'));
        expect(request.headers['Authorization'], 'Bearer mi_token_valido');

        return http.Response(
          jsonEncode({
            'datos': {
              'usuario': {
                'id': 10,
                'codigo_institucional': 'PRUEBA-SEG-001',
                'correo_institucional': 'seguridad@upt.pe',
                'nombres': 'Juan',
                'apellidos': 'Perez',
                'roles': ['SEGURIDAD'],
              }
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo =
          AuthRepository(httpClient: mockClient, secureStorage: fakeStorage);
      final usuario = await repo.consultarSesion('mi_token_valido');

      expect(usuario.id, 10);
      expect(usuario.nombreCompleto, 'Juan Perez');
      expect(usuario.roles, contains('SEGURIDAD'));
    });

    test('cerrarSesion envía Bearer y siempre limpia almacenamiento local',
        () async {
      await fakeStorage.guardarTokens(
        tokenAcceso: 'token_a_borrar',
        tokenRenovacion: 'token_r_a_borrar',
        tokenAccesoExpiraEn: DateTime.now().add(const Duration(minutes: 10)),
        tokenRenovacionExpiraEn: DateTime.now().add(const Duration(days: 7)),
      );

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/autenticacion/cerrar-sesion'));
        expect(request.headers['Authorization'], 'Bearer token_a_borrar');
        return http.Response('', 204);
      });

      final repo =
          AuthRepository(httpClient: mockClient, secureStorage: fakeStorage);
      await repo.cerrarSesion('token_a_borrar');

      expect(fakeStorage.tokenAcceso, isNull);
      expect(fakeStorage.tokenRenovacion, isNull);
    });
  });
}
