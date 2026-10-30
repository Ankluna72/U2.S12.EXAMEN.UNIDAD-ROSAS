import 'package:aplicacion_seguridad/features/administracion/presentation/screens/gestion_usuarios_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Gestión Exclusiva de Guardias de Seguridad', () {
    testWidgets('1. Renderiza la lista inicial de guardias de seguridad',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GestionUsuariosScreen()),
      );

      expect(find.text('Gestión de Guardias de Seguridad'), findsOneWidget);
      expect(find.text('Nuevo Guardia'), findsOneWidget);
      expect(find.text('Jefferson Rosas Chambilla'), findsOneWidget);
      expect(find.text('Marcos Vargas Flores'), findsOneWidget);
      expect(find.text('ACTIVO'), findsWidgets);
    });

    testWidgets('2. Presionar Nuevo Guardia abre formulario modal de registro',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GestionUsuariosScreen()),
      );

      await tester.tap(find.text('Nuevo Guardia'));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Nuevo Guardia'), findsOneWidget);
      expect(find.text('Rol Asignado: Guardia de Seguridad'), findsOneWidget);
      expect(find.text('Crear y Habilitar Guardia'), findsOneWidget);
    });

    testWidgets('3. Guardar con campos vacíos activa validaciones en formulario',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GestionUsuariosScreen()),
      );

      await tester.tap(find.text('Nuevo Guardia'));
      await tester.pumpAndSettle();

      final btnFinder = find.text('Crear y Habilitar Guardia');
      await tester.ensureVisible(btnFinder);
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      expect(find.text('Obligatorio'), findsWidgets);
      expect(find.text('Ingresa un usuario'), findsOneWidget);
    });
  });
}
