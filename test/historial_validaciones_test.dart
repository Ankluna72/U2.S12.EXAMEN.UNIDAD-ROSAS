import 'package:aplicacion_seguridad/features/historial/data/models/registro_historial_model.dart';
import 'package:aplicacion_seguridad/features/historial/presentation/screens/historial_validaciones_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Historial de Validaciones Recientes (Trazabilidad en Punto de Acceso)', () {
    test('1. Modelo de datos deserializa y mapea motivos legibles correctamente', () {
      final json = {
        'id': 'VAL-100',
        'resultado': 'AUTORIZADO',
        'motivo': 'ACCESO_AUTORIZADO',
        'nombre_completo': 'Carlos Mario Delgado',
        'codigo_institucional': '2019012345',
        'escuela': 'Ingeniería Civil',
        'punto_acceso_nombre': 'Puerta 2 - Av. Pinto',
        'punto_acceso_codigo': 'PUERTA-PINTO',
        'registrado_en': '2026-10-23T10:30:00.000Z',
        'observacion': 'Paso normal con credencial',
      };

      final modelo = RegistroHistorialModel.fromJson(json);

      expect(modelo.id, 'VAL-100');
      expect(modelo.esAutorizado, isTrue);
      expect(modelo.motivoLegible, 'Acceso permitido');
      expect(modelo.nombreCompleto, 'Carlos Mario Delgado');
      expect(modelo.codigoInstitucional, '2019012345');
      expect(modelo.puntoAccesoCodigo, 'PUERTA-PINTO');

      final denegado = RegistroHistorialModel.fromJson({
        'id': 'VAL-101',
        'resultado': 'DENEGADO',
        'motivo': 'CREDENCIAL_YA_UTILIZADA',
        'punto_acceso_nombre': 'Puerta Principal',
      });
      expect(denegado.esAutorizado, isFalse);
      expect(denegado.motivoLegible, 'Credencial QR ya utilizada');
    });

    testWidgets('2. Pantalla renderiza cabecera, métricas y lista de accesos',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HistorialValidacionesScreen()),
      );

      expect(find.text('Historial de Accesos Recientes'), findsOneWidget);
      expect(find.text('Punto: Puerta Principal - Campus Capanique'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Permitidos'), findsOneWidget);
      expect(find.text('Denegados'), findsOneWidget);
      expect(find.text('María Elena Pérez Quispe'), findsOneWidget);
      expect(find.text('PERMITIDO'), findsWidgets);
      expect(find.text('DENEGADO'), findsWidgets);
    });

    testWidgets('3. Filtro por "Denegados" filtra y oculta autorizados',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HistorialValidacionesScreen()),
      );

      // Verificamos que inicialmente está el autorizado
      expect(find.text('María Elena Pérez Quispe'), findsOneWidget);

      // Tocamos el chip Denegados
      final chipDenegados = find.widgetWithText(ChoiceChip, 'Denegados (3)');
      expect(chipDenegados, findsOneWidget);
      await tester.tap(chipDenegados);
      await tester.pumpAndSettle();

      // Ya no debe mostrar el nombre del estudiante autorizado
      expect(find.text('María Elena Pérez Quispe'), findsNothing);
      // Debe mostrar motivos de denegados
      expect(find.text('Credencial QR ya utilizada'), findsOneWidget);
    });

    testWidgets('4. Tocar un registro abre modal con detalle del evento',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HistorialValidacionesScreen()),
      );

      // Tocamos la tarjeta de María Elena
      await tester.tap(find.text('María Elena Pérez Quispe'));
      await tester.pumpAndSettle();

      // Debe abrir modal con ID de evento y botón de cierre
      expect(find.text('ID Evento: VAL-001'), findsOneWidget);
      expect(find.text('INGRESO PERMITIDO'), findsWidgets);
      expect(find.text('Cerrar Detalle'), findsOneWidget);

      await tester.tap(find.text('Cerrar Detalle'));
      await tester.pumpAndSettle();

      expect(find.text('Cerrar Detalle'), findsNothing);
    });
  });
}
