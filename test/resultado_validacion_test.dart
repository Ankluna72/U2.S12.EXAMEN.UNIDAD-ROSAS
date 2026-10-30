import 'package:aplicacion_seguridad/features/validacion/data/models/resultado_validacion_model.dart';
import 'package:aplicacion_seguridad/features/validacion/presentation/screens/resultado_validacion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('US-09 · Mostrar resultado claro de validación', () {
    test('1. Parsea correctamente respuesta AUTORIZADO con identidad del estudiante', () {
      final json = {
        'resultado': 'AUTORIZADO',
        'motivo': 'ACCESO_AUTORIZADO',
        'mensaje': 'Ingreso autorizado.',
        'registrado_en': '2026-10-16T12:00:00.000Z',
        'punto_acceso': {
          'codigo': 'PUERTA-01',
          'nombre': 'Puerta Principal - Campus Capanique',
        },
        'identidad': {
          'nombre_completo': 'María Elena Pérez Quispe',
          'codigo_institucional': '2023071234',
          'escuela': 'Ingeniería de Sistemas',
          'estado_academico': 'REGULAR',
          'tipo_usuario': ['ESTUDIANTE'],
        },
      };

      final modelo = ResultadoValidacionModel.fromJson(json);

      expect(modelo.esAutorizado, isTrue);
      expect(modelo.resultado, equals('AUTORIZADO'));
      expect(modelo.identidad, isNotNull);
      expect(modelo.identidad!.nombreCompleto, equals('María Elena Pérez Quispe'));
      expect(modelo.identidad!.codigoInstitucional, equals('2023071234'));
      expect(modelo.identidad!.escuela, equals('Ingeniería de Sistemas'));
      expect(modelo.puntoAccesoCodigo, equals('PUERTA-01'));
    });

    test('2. Parsea respuesta DENEGADO y omite identidad por privacidad', () {
      final json = {
        'resultado': 'DENEGADO',
        'motivo': 'CREDENCIAL_YA_UTILIZADA',
        'mensaje': 'El código QR ya fue utilizado.',
        'registrado_en': '2026-10-16T12:05:00.000Z',
        'punto_acceso': {
          'codigo': 'PUERTA-01',
          'nombre': 'Puerta Principal',
        },
      };

      final modelo = ResultadoValidacionModel.fromJson(json);

      expect(modelo.esAutorizado, isFalse);
      expect(modelo.resultado, equals('DENEGADO'));
      expect(modelo.motivo, equals('CREDENCIAL_YA_UTILIZADA'));
      expect(modelo.identidad, isNull);
    });

    testWidgets('3. Pantalla muestra "INGRESO PERMITIDO" y datos de identidad',
        (tester) async {
      final modelo = ResultadoValidacionModel(
        resultado: 'AUTORIZADO',
        motivo: 'ACCESO_AUTORIZADO',
        mensaje: 'Ingreso autorizado.',
        registradoEn: DateTime.now(),
        puntoAccesoCodigo: 'PUERTA-01',
        puntoAccesoNombre: 'Puerta Principal',
        identidad: const IdentidadEstudianteModel(
          nombreCompleto: 'Juan Carlos Mamani',
          codigoInstitucional: '2022070001',
          escuela: 'Medicina Humana',
          estadoAcademico: 'REGULAR',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ResultadoValidacionScreen(resultado: modelo),
        ),
      );

      expect(find.text('INGRESO PERMITIDO'), findsOneWidget);
      expect(find.text('Juan Carlos Mamani'), findsOneWidget);
      expect(find.text('Cód: 2022070001'), findsOneWidget);
      expect(find.text('Medicina Humana'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('4. Pantalla muestra "INGRESO NO PERMITIDO" y causa de denegación',
        (tester) async {
      final modelo = ResultadoValidacionModel(
        resultado: 'DENEGADO',
        motivo: 'CREDENCIAL_YA_UTILIZADA',
        mensaje: 'El código QR ya fue utilizado anteriormente.',
        registradoEn: DateTime.now(),
        puntoAccesoCodigo: 'PUERTA-01',
        puntoAccesoNombre: 'Puerta Principal',
        identidad: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ResultadoValidacionScreen(resultado: modelo),
        ),
      );

      expect(find.text('INGRESO NO PERMITIDO'), findsOneWidget);
      expect(find.text('El código QR ya fue utilizado anteriormente.'),
          findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      // No debe existir tarjeta de identidad de alumno
      expect(find.text('Cód:'), findsNothing);
    });
  });
}
