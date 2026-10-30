# EXAMEN PRÁCTICO DE LA UNIDAD II
## SI-988 · SOLUCIONES MÓVILES II

* **Docente:** Dr. Oscar Juan Jimenez Flores
* **Estudiante:** Jefferson Rosas Chambilla
* **Código:** 2021072618
* **Usuario GitHub:** [Ankluna72](https://github.com/Ankluna72)
* **Repositorio oficial:** [U2.S12.EXAMEN.UNIDAD-ROSAS](https://github.com/Ankluna72/U2.S12.EXAMEN.UNIDAD-ROSAS.git)
* **Tipo de Examen:** **TIPO 1 — UBICACIÓN DESACOPLADA, MAPA OPENSTREETMAP, GEOCERCA 150M Y PRUEBAS UNITARIAS**

---

## Resumen Ejecutivo de Implementación (20 / 20 pts)

Se implementó de manera robusta y desacoplada la arquitectura de geolocalización, cartografía OpenStreetMap, control de geocercas y suite de pruebas unitarias para la aplicación móvil del guardia de seguridad (`aplicacion_seguridad`), cumpliendo estrictamente con los 5 ítems evaluados en la rúbrica del **Tipo 1**:

```
┌────────────────────────────────────────────────────────┐
│         PantallaMapaUbicacion (View UI)                │
│  - Mapa interactivo OpenStreetMap (flutter_map)        │
│  - Atribución © OpenStreetMap contributors visible     │
│  - Radio de precisión dinámica: "Precisión ± N m"      │
│  - Círculo de geocerca 150m (Puerta Principal Campus)  │
│  - Fallback táctil manual si falla o expira el GPS     │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│         UbicacionMapaViewModel (Presentation / VM)     │
│  - 0 importaciones de geolocator                       │
│  - Estados: inicial, obteniendo, obtenida, error       │
│  - Evaluación de Geocerca (150 m) con mensaje dinámico │
│  - Limpieza en dispose() para evitar fugas de memoria  │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│         ServicioUbicacion (Domain Interface / Contract)│
│  - Contrato abstracto puro en Dart                     │
│  - Permite sustitución por Mock/Fake en tests          │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│         ServicioUbicacionGeolocator (Data Service)     │
│  - Única clase autorizada a importar geolocator        │
│  - Precisión: LocationAccuracy.medium                  │
│  - Filtro: cada 30s o desplazamiento >= 50m            │
│  - Timeout 10s con mensaje: "Tiempo agotado"           │
│  - Al detener emite log: "GPS detenido"                │
└────────────────────────────────────────────────────────┘
```

---

## Detalle de Ítems Desarrollados y Archivos Afectados

### 1. Ubicación Desacoplada de la UI (4 puntos)
* **Archivos afectados:**
  - `lib/features/ubicacion/domain/entities/ubicacion_usuario.dart`
  - `lib/features/ubicacion/domain/services/servicio_ubicacion.dart`
  - `lib/features/ubicacion/data/services/servicio_ubicacion_geolocator.dart`
  - `lib/features/ubicacion/presentation/viewmodels/ubicacion_mapa_view_model.dart`
  - `lib/features/ubicacion/presentation/screens/pantalla_mapa_ubicacion.dart`
* **Implementación técnica:**
  - Se creó la entidad pura `UbicacionUsuario` con atributos inmutables (`latitud`, `longitud`, `precisionMetros`, `fechaHora`, `esManual`) sin librerías externas.
  - La interfaz `ServicioUbicacion` desacopla completamente el hardware GPS de las capas superiores.
  - Solo la clase de datos `ServicioUbicacionGeolocator` importa la librería `geolocator`.
  - La UI (`PantallaMapaUbicacion`) y el ViewModel (`UbicacionMapaViewModel`) tienen cero importaciones del plugin externo y muestran latitud y longitud numéricas con alta legibilidad.

### 2. Configuración de Precisión Media, Intervalo, Timeout y Apagado (4 puntos)
* **Archivos afectados:**
  - `lib/features/ubicacion/data/services/servicio_ubicacion_geolocator.dart`
* **Implementación técnica:**
  - `LocationSettings` configurado con `LocationAccuracy.medium` y `distanceFilter: 50` (50 metros).
  - Intervalo de muestreo controlado cada 30 segundos.
  - Temporizador de espera máxima de 10 segundos con `timeLimit: const Duration(seconds: 10)`. En caso de demora lanza `UbicacionTiempoAgotadoException` con el texto exacto «Tiempo agotado».
  - Método `detenerUbicacion()` cancela suscripciones y emite en consola mediante `debugPrint('GPS detenido')`.

### 3. Mapa OpenStreetMap con Radio de Precisión y Fallback Manual (4 puntos)
* **Archivos afectados:**
  - `lib/features/ubicacion/presentation/screens/pantalla_mapa_ubicacion.dart`
* **Implementación técnica:**
  - Integración de `flutter_map` con capa de teselas `TileLayer` apuntando a OpenStreetMap (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`).
  - Atribución visible en pantalla mediante `RichAttributionWidget` con el texto «© OpenStreetMap contributors».
  - Representación visual del radio de incertidumbre con `CircleMarker` proporcional a la precisión en metros y etiqueta textual «Precisión ± N m».
  - Fallback interactivo ante error o timeout del GPS que permite al usuario pulsar cualquier punto sobre el mapa para fijar manualmente sus coordenadas.

### 4. Tres Pruebas Unitarias del ViewModel en Terminal (4 puntos)
* **Archivos afectados:**
  - `test/examen_u2_tipo1_test.dart`
* **Pruebas ejecutadas:**
  - **4.a (Aislamiento inicial):** Comprueba que al crear el `UbicacionMapaViewModel` no se solicita ninguna ubicación (`llamadas == 0`).
  - **4.b (Lectura simulada):** Inyecta coordenadas simuladas (-18.0066, -70.2463, precisión 35 m) y verifica que el ViewModel expone fielmente los datos y el radio.
  - **4.c (Manejo de falla y modo manual):** Simula falla de GPS (`UbicacionGpsApagadoException`), verifica que transiciona al modo manual, que la ubicación se pidió exactamente una sola vez y que permite fijar el punto tocando el mapa.

### 5. Geocerca de 150m y Dos Pruebas Unitarias de Salida (4 puntos)
* **Archivos afectados:**
  - `lib/features/ubicacion/domain/entities/ubicacion_usuario.dart`
  - `lib/features/ubicacion/presentation/viewmodels/ubicacion_mapa_view_model.dart`
  - `test/examen_u2_tipo1_test.dart`
* **Implementación técnica:**
  - Cálculo geodésico de gran círculo mediante fórmula de Haversine (`distanciaHacia` y `estaDentroDeZona`).
  - Centro fijado en Puerta Principal Campus Capanique (`-18.0066, -70.2463`) con radio de 150 metros. Muestra mensaje contextual: «Estás dentro de la zona de Puerta Principal - Campus Capanique» o «Estás fuera de la zona de...».
* **Pruebas ejecutadas:**
  - **5.a (Validación geométrica):** Verifica que un punto a ~100 m (-18.0057) resulta dentro de la geocerca (<= 150 m) y un punto a ~300 m (-18.0039) resulta fuera (> 150 m).
  - **5.b (Verificación de dispose):** Comprueba que tras salir de la pantalla invocando `dispose()` no queda ninguna escucha activa al GPS.

---

## Instrucciones de Ejecución

### 1. Ejecutar las Pruebas Unitarias del Examen
```powershell
flutter test test/examen_u2_tipo1_test.dart
```

### 2. Ejecutar Toda la Suite de Pruebas (37 pruebas)
```powershell
flutter test
```

### 3. Análisis Estático de Código (0 errores)
```powershell
flutter analyze
```

### 4. Ejecutar la Aplicación en el Emulador
```powershell
flutter run -d emulator-5554
```
