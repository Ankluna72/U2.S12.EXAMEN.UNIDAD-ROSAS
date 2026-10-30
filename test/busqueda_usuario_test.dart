import 'package:aplicacion_seguridad/features/busqueda/data/models/usuario_busqueda_model.dart';
import 'package:aplicacion_seguridad/features/busqueda/presentation/screens/busqueda_usuario_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('US-16 · Buscar usuario por código o correo institucional', () {
    test('1. Parsea correctamente modelo de usuario habilitado', () {
      final json = {
        'codigo_institucional': '2021072618',
        'nombre_completo': 'Jefferson Rosas Chambilla',
        'correo_institucional': 'jr2021072618@virtual.upt.pe',
        'escuela': 'Ingeniería de Sistemas',
        'estado_acceso': 'HABILITADO',
        'roles': ['ESTUDIANTE'],
      };

      final modelo = UsuarioBusquedaModel.fromJson(json);

      expect(modelo.esHabilitado, isTrue);
      expect(modelo.codigoInstitucional, equals('2021072618'));
      expect(modelo.nombreCompleto, equals('Jefferson Rosas Chambilla'));
      expect(modelo.correoInstitucional, equals('jr2021072618@virtual.upt.pe'));
      expect(modelo.escuela, equals('Ingeniería de Sistemas'));
      expect(modelo.estadoAcceso, equals('HABILITADO'));
    });

    test('2. Parsea usuario bloqueado e indica esHabilitado como false', () {
      final json = {
        'codigo_institucional': '2020010101',
        'nombre_completo': 'Usuario Sancionado',
        'correo_institucional': 'sancionado@virtual.upt.pe',
        'escuela': 'Derecho',
        'estado_acceso': 'BLOQUEADO',
      };

      final modelo = UsuarioBusquedaModel.fromJson(json);

      expect(modelo.esHabilitado, isFalse);
      expect(modelo.estadoAcceso, equals('BLOQUEADO'));
    });

    testWidgets('3. Pantalla renderiza elementos de búsqueda iniciales',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BusquedaUsuarioScreen()),
      );

      expect(find.text('Búsqueda Manual de Usuario'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Buscar Usuario'), findsOneWidget);
      expect(find.text('Sin búsqueda activa'), findsOneWidget);
    });

    testWidgets('4. Buscar con campo vacío muestra mensaje de validación',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BusquedaUsuarioScreen()),
      );

      await tester.tap(find.text('Buscar Usuario'));
      await tester.pumpAndSettle();

      expect(
        find.text('Por favor ingresa un código institucional o correo.'),
        findsOneWidget,
      );
    });

    testWidgets('5. Búsqueda muestra resultado con datos del usuario',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BusquedaUsuarioScreen(
            onBuscar: (q) async => const UsuarioBusquedaModel(
              codigoInstitucional: '2021072618',
              nombreCompleto: 'Jefferson Rosas Chambilla',
              correoInstitucional: 'jr2021072618@virtual.upt.pe',
              escuela: 'Ingeniería de Sistemas',
              estadoAcceso: 'HABILITADO',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '2021072618');
      await tester.tap(find.text('Buscar Usuario'));
      await tester.pump(); // Inicia búsqueda
      await tester.pump(const Duration(milliseconds: 500)); // Espera el delay

      expect(find.text('Jefferson Rosas Chambilla'), findsOneWidget);
      expect(find.text('Código: 2021072618'), findsOneWidget);
      expect(find.text('HABILITADO'), findsOneWidget);
      expect(find.text('Registrar Entrada Manual'), findsOneWidget);
    });
  });
}
