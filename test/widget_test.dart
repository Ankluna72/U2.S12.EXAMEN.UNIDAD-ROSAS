import 'dart:convert';

import 'package:aplicacion_seguridad/core/storage/secure_storage_service.dart';
import 'package:aplicacion_seguridad/features/auth/data/repositories/auth_repository.dart';
import 'package:aplicacion_seguridad/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aplicacion_seguridad/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
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
  testWidgets('LoginScreen muestra campos de formulario y valida campos vacíos',
      (WidgetTester tester) async {
    final fakeStorage = FakeSecureStorageService();
    final mockClient = MockClient((request) async => http.Response('{}', 400));
    final repo =
        AuthRepository(httpClient: mockClient, secureStorage: fakeStorage);
    final controller = AuthController(repository: repo);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(authController: controller),
      ),
    );

    // Verificar presencia de títulos y campos
    expect(find.text('Ingreso UPT'), findsOneWidget);
    expect(find.text('Puesto de Seguridad y Verificación'), findsOneWidget);
    expect(find.text('Identificador Institucional'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);

    // Intentar presionar "Iniciar Sesión" con campos vacíos
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pump();

    expect(find.text('Ingresa tu código o correo'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('Login exitoso transiciona a estado autenticado',
      (WidgetTester tester) async {
    final fakeStorage = FakeSecureStorageService();
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'datos': {
            'tipo_token': 'Bearer',
            'token_acceso': 'acceso_widget_test',
            'token_renovacion': 'renovacion_widget_test',
            'token_acceso_expira_en': '2026-09-18T16:00:00.000Z',
            'token_renovacion_expira_en': '2026-09-25T16:00:00.000Z',
            'usuario': {
              'id': 12,
              'codigo_institucional': 'PRUEBA-SEG-001',
              'correo_institucional': 'seg@upt.pe',
              'nombres': 'Carlos',
              'apellidos': 'Guardia',
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

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(authController: controller),
      ),
    );

    // Escribir credenciales
    await tester.enterText(find.byType(TextFormField).first, 'PRUEBA-SEG-001');
    await tester.enterText(find.byType(TextFormField).last, 'Password123');

    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    expect(controller.isAuthenticated, isTrue);
    expect(controller.usuario?.nombreCompleto, 'Carlos Guardia');
  });
}
