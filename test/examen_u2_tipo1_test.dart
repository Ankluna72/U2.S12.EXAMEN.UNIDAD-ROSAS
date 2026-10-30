import 'dart:async';
import 'package:aplicacion_seguridad/features/ubicacion/domain/entities/ubicacion_usuario.dart';
import 'package:aplicacion_seguridad/features/ubicacion/domain/services/servicio_ubicacion.dart';
import 'package:aplicacion_seguridad/features/ubicacion/presentation/viewmodels/ubicacion_mapa_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Servicio simulado (Mock/Fake) que reemplaza al GPS para pruebas unitarias sin emulador ni hardware.
class FakeServicioUbicacion implements ServicioUbicacion {
  int llamadasObtenerUbicacion = 0;
  UbicacionUsuario? ubicacionRespuesta;
  Exception? errorSimulado;
  bool escuchaActiva = false;
  final StreamController<UbicacionUsuario> _controller =
      StreamController<UbicacionUsuario>.broadcast();

  @override
  bool get tieneEscuchaActiva => escuchaActiva;

  @override
  Future<UbicacionUsuario> obtenerUbicacionActual() async {
    llamadasObtenerUbicacion++;
    if (errorSimulado != null) {
      throw errorSimulado!;
    }
    return ubicacionRespuesta ??
        const UbicacionUsuario(
          latitud: -18.0066,
          longitud: -70.2463,
          precisionMetros: 35.0,
        );
  }

  @override
  Stream<UbicacionUsuario> escucharUbicacion() {
    escuchaActiva = true;
    return _controller.stream;
  }

  @override
  void detenerUbicacion() {
    escuchaActiva = false;
  }

  void emitirNuevaUbicacion(UbicacionUsuario u) {
    _controller.add(u);
  }
}

void main() {
  group('EXAMEN PRÁCTICO UNIDAD II - TIPO 1: Ubicación Desacoplada y Geocercas', () {
    late FakeServicioUbicacion fakeServicio;

    setUp(() {
      fakeServicio = FakeServicioUbicacion();
    });

    // =========================================================================
    // ÍTEM 4: TRES PRUEBAS UNITARIAS DEL VIEWMODEL DE UBICACIÓN (4 PUNTOS)
    // =========================================================================

    test('Ítem 4 - Prueba (a): Al crear el ViewModel no se pide ninguna ubicación',
        () {
      // 1. Instanciamos el ViewModel inyectando el servicio simulado
      final viewModel = UbicacionMapaViewModel(servicioUbicacion: fakeServicio);

      // 2. Verificaciones de aislamiento y carga perezosa
      expect(fakeServicio.llamadasObtenerUbicacion, equals(0));
      expect(viewModel.ubicacion, isNull);
      expect(viewModel.tieneUbicacion, isFalse);
      expect(viewModel.estado, equals(EstadoUbicacion.inicial));
      expect(fakeServicio.tieneEscuchaActiva, isFalse);

      print('  -> [OK] Llamadas a ubicación al crear ViewModel: 0 (Carga perezosa)');
      print('  -> [OK] Estado inicial: ubicacion = null, estado = inicial, escuchaActiva = false');
    });

    test(
        'Ítem 4 - Prueba (b): Con una lectura simulada en latitud -18.0066, longitud -70.2463 y precisión de 35 m, el estado expone esas coordenadas y esa precisión',
        () async {
      // 1. Inyectamos la lectura exacta solicitada en la rúbrica
      fakeServicio.ubicacionRespuesta = const UbicacionUsuario(
        latitud: -18.0066,
        longitud: -70.2463,
        precisionMetros: 35.0,
      );

      final viewModel = UbicacionMapaViewModel(servicioUbicacion: fakeServicio);

      // 2. Solicitamos ubicación
      await viewModel.solicitarUbicacion();

      // 3. Verificaciones de exposición de estado
      expect(viewModel.tieneUbicacion, isTrue);
      expect(viewModel.ubicacion?.latitud, equals(-18.0066));
      expect(viewModel.ubicacion?.longitud, equals(-70.2463));
      expect(viewModel.ubicacion?.precisionMetros, equals(35.0));
      expect(viewModel.estado, equals(EstadoUbicacion.obtenida));
      expect(fakeServicio.llamadasObtenerUbicacion, equals(1));

      print('  -> [OK] Coordenadas expuestas: Latitud = ${viewModel.ubicacion?.latitud}, Longitud = ${viewModel.ubicacion?.longitud}');
      print('  -> [OK] Precisión expuesta: ${viewModel.ubicacion?.precisionMetros} metros');
      print('  -> [OK] Estado de ViewModel: EstadoUbicacion.obtenida');
    });

    test(
        'Ítem 4 - Prueba (c): Con el GPS apagado simulado, el estado pasa a la elección en el mapa y la ubicación se pidió una sola vez',
        () async {
      // 1. Simulamos el fallo de GPS apagado
      fakeServicio.errorSimulado = const UbicacionGpsApagadoException('GPS apagado');

      final viewModel = UbicacionMapaViewModel(servicioUbicacion: fakeServicio);

      // 2. Intentamos solicitar ubicación
      await viewModel.solicitarUbicacion();

      // 3. Verificaciones de transición a modo manual y 1 sola llamada
      expect(viewModel.estado, equals(EstadoUbicacion.errorConEleccionManual));
      expect(viewModel.motivoError, contains('GPS apagado'));
      expect(fakeServicio.llamadasObtenerUbicacion, equals(1));
      expect(viewModel.ubicacion, isNull);

      print('  -> [OK] Fallo simulado: captura UbicacionGpsApagadoException ("GPS apagado")');
      print('  -> [OK] Llamadas totales al servicio: 1 (Se pidió una sola vez sin insistir)');
      print('  -> [OK] Estado transiciona a: errorConEleccionManual');

      // 4. Comprobamos la selección interactiva manual sobre el mapa
      viewModel.seleccionarUbicacionManual(-18.0070, -70.2460);
      expect(viewModel.estado, equals(EstadoUbicacion.obtenida));
      expect(viewModel.ubicacion?.esManual, isTrue);
      expect(viewModel.ubicacion?.latitud, equals(-18.0070));
      expect(viewModel.ubicacion?.longitud, equals(-70.2460));

      print('  -> [OK] Elección manual en mapa: Lat -18.0070, Lon -70.2460 (esManual = true)');
    });

    // =========================================================================
    // ÍTEM 5: DOS PRUEBAS UNITARIAS DE ZONA Y SIN ESCUCHAS ACTIVAS (4 PUNTOS)
    // =========================================================================

    test(
        'Ítem 5 - Prueba (a): Con centro en -18.0066, -70.2463 y zona de 150 m, el punto -18.0057, -70.2463 (a unos 100 m) queda dentro y el punto -18.0039, -70.2463 (a unos 300 m) queda fuera',
        () {
      const centroLat = -18.0066;
      const centroLon = -70.2463;
      const radioZona = 150.0;

      // 1. Validación punto A (a ~100 metros del centro)
      const puntoDentro = UbicacionUsuario(
        latitud: -18.0057,
        longitud: -70.2463,
        precisionMetros: 10.0,
      );
      final distanciaDentro = puntoDentro.distanciaHacia(centroLat, centroLon);
      expect(distanciaDentro, closeTo(100.0, 5.0));
      expect(puntoDentro.estaDentroDeZona(centroLat, centroLon, radioZona), isTrue);

      print('  -> [OK] Punto A (-18.0057, -70.2463): Distancia = ${distanciaDentro.toStringAsFixed(2)} m (<= 150m: DENTRO)');

      // 2. Validación punto B (a ~300 metros del centro)
      const puntoFuera = UbicacionUsuario(
        latitud: -18.0039,
        longitud: -70.2463,
        precisionMetros: 10.0,
      );
      final distanciaFuera = puntoFuera.distanciaHacia(centroLat, centroLon);
      expect(distanciaFuera, closeTo(300.0, 5.0));
      expect(puntoFuera.estaDentroDeZona(centroLat, centroLon, radioZona), isFalse);

      print('  -> [OK] Punto B (-18.0039, -70.2463): Distancia = ${distanciaFuera.toStringAsFixed(2)} m (> 150m: FUERA)');

      // 3. Verificación de mensajes contextuales en el ViewModel
      final viewModel = UbicacionMapaViewModel(servicioUbicacion: fakeServicio);

      viewModel.seleccionarUbicacionManual(-18.0057, -70.2463);
      expect(viewModel.estaDentroDeZona, isTrue);
      expect(viewModel.mensajeZona, equals('Estás dentro de la zona de Puerta Principal - Campus Capanique'));

      viewModel.seleccionarUbicacionManual(-18.0039, -70.2463);
      expect(viewModel.estaDentroDeZona, isFalse);
      expect(viewModel.mensajeZona, equals('Estás fuera de la zona de Puerta Principal - Campus Capanique'));

      print('  -> [OK] Mensaje textual Dentro: "${viewModel.mensajeZona}"');
    });

    test(
        'Ítem 5 - Prueba (b): Después de salir de la pantalla no queda ninguna escucha de ubicación activa',
        () async {
      final viewModel = UbicacionMapaViewModel(servicioUbicacion: fakeServicio);

      // 1. Iniciamos la escucha de ubicación
      await viewModel.solicitarUbicacion();
      expect(fakeServicio.tieneEscuchaActiva, isTrue);
      print('  -> [Paso 1] Pantalla activa: tieneEscuchaActiva = true');

      // 2. Simulamos la destrucción de la pantalla al salir (dispose)
      viewModel.dispose();

      // 3. Confirmamos que no queda ninguna escucha activa de ubicación
      expect(fakeServicio.tieneEscuchaActiva, isFalse);
      print('  -> [Paso 2] Pantalla destruida (dispose): tieneEscuchaActiva = false (GPS detenido)');
    });
  });
}
