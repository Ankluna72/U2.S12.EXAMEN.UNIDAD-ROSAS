# GUÍA PARA LA ENTREGA DEL EXAMEN PRÁCTICO (TIPO 1)
## SI-988 · Soluciones Móviles II · Unidad I

* **Estudiante:** Jefferson Rosas Chambilla
* **Código:** 2021072618
* **Docente:** Dr. Oscar Juan Jimenez Flores
* **Archivo PDF a entregar en el Aula Virtual:** `SI988-EXPRAC-U1-RosasJefferson.pdf`
* **Repositorio GitHub:** `https://github.com/Ankluna72/SI988-EXPRAC-U1-RosasJefferson.git`

---

## 1. Comandos para Subir el Código a GitHub

Ejecuta estos 3 comandos en tu terminal PowerShell para subir todo a tu repositorio de entrega:

```powershell
cd c:\Users\rosas\Desktop\acadetempo\moviles2\py\app-seguridad-entrada-upt
git add .
git commit -m "feat(examen-u1): implementacion completa Tipo 1 - login, bloqueo 3 intentos, interceptor 401 y pruebas unitarias"
git push examen main
```

*(Si tu rama actual se llama `develop` o `master`, simplemente haz `git push examen HEAD:main`).*

---

## 2. Estructura del Documento PDF a Entregar (`SI988-EXPRAC-U1-RosasJefferson.pdf`)

Crea un documento en Word o Google Docs, pega las capturas indicadas a continuación, y guárdalo como **PDF** con el nombre obligatorio:
👉 **`SI988-EXPRAC-U1-RosasJefferson.pdf`**

---

### Página 1: Carátula Oficial
* **Universidad:** Universidad Privada de Tacna
* **Facultad:** Facultad de Ingeniería
* **Escuela:** Escuela Profesional de Ingeniería de Sistemas
* **Curso:** SI-988 Soluciones Móviles II
* **Autor:** 2021072618 - Rosas Chambilla, Jefferson
* **URL GitHub:** `https://github.com/Ankluna72/SI988-EXPRAC-U1-RosasJefferson.git`
* **Tipo de Examen:** **1** *(Márcalo claramente)*
* **Docente:** Dr. Oscar Juan Jimenez Flores
* **Lugar:** Tacna — Perú

---

### Página 2: Ítem 1. Validación de Formulario y Feedback en UI (4 puntos)
* **Breve explicación técnica:**  
  *Se implementó en `LoginScreen` la validación estricta de campos antes de emitir la llamada de red. La contraseña requiere un mínimo de 6 caracteres y el identificador al menos 3 caracteres. Si los datos no son conformes, se despliega un mensaje descriptivo de error inline sin contactar al servicio. Al cumplir la validación, el botón se bloquea y se despliega un CircularProgressIndicator.*
* **Capturas requeridas:**
  1. **Captura de código:** Archivo `lib/features/auth/presentation/screens/login_screen.dart` (bloque de los métodos `validator` y botón con `isLoading`).
  2. **Captura del emulador:** Pantalla con error en rojo (ej. escribiendo una clave menor a 6 caracteres).
  3. **Captura del emulador:** Botón mostrando el spinner de carga (`loading`) mientras autentica.

---

### Página 3: Ítem 2. Bloqueo de Intentos de Autenticación (4 puntos)
* **Breve explicación técnica:**  
  *Se programó en la capa de lógica de negocio / ViewModel (`AuthController`) el control de 3 logins fallidos consecutivos. Al registrarse el cuarto intento consecutivo, la condición de interrupción aborta inmediatamente el flujo, evitando emitir cualquier llamada de red al servicio de autenticación (cero peticiones) y notificando un mensaje explícito de bloqueo temporal.*
* **Capturas requeridas:**
  1. **Captura de código:** Archivo `lib/features/auth/presentation/controllers/auth_controller.dart` resaltando las líneas:
     - Contador `int _intentosFallidos = 0;` y constante `maxIntentosFallidos = 3;`
     - Condición de corte previo en `iniciarSesion()`: `if (estaBloqueado) { ... return false; }`
  2. **Captura del emulador:** Pantalla mostrando el banner rojo con el mensaje de bloqueo temporal y el botón en estado `Acceso Bloqueado`.

---

### Página 4: Ítem 3. Cierre de Sesión ante HTTP 401 Unauthorized (4 puntos)
* **Breve explicación técnica:**  
  *Se configuró el middleware desacoplado `AuthInterceptor` extendiendo de `http.BaseClient`. Al interceptar cualquier respuesta con código HTTP 401 en peticiones autenticadas, se ejecuta inmediatamente la purga del token en `SecureStorageService`, se fuerza de forma reactiva el estado de sesión cerrada en la app y se devuelve la respuesta sin reintentos automáticos.*
* **Capturas requeridas:**
  1. **Captura de código:** Archivo `lib/core/network/auth_interceptor.dart` (método `send()` donde se evalúa `response.statusCode == 401`, se llama a `limpiarSesion()` y se dispara `_onUnauthorized?.call()`).
  2. **Captura de código:** Archivo `lib/main.dart` mostrando la inyección del interceptor y el callback reactivo `forzarCierreSesionPor401()`.

---

### Página 5: Ítem 4. Tres Pruebas Unitarias del Login en Terminal (4 puntos)
* **Breve explicación técnica:**  
  *Se ejecutó la suite de pruebas unitarias por consola sin emulador ni red externa, validando: (a) estado inicial sin sesión, (b) autenticación exitosa con almacenamiento de token, y (c) autenticación rechazada con estado de error y cero reintentos.*
* **Comando a ejecutar para la captura:**
  ```powershell
  cd aplicacion_seguridad
  flutter test test/examen_tipo1_test.dart --name "Ítem 4"
  ```
* **Capturas requeridas:**
  1. **Captura completa de la terminal:** Mostrando el comando y la salida con los 3 tests en verde (`PASS / All tests passed!`).

---

### Página 6: Ítem 5. Dos Pruebas Unitarias del Bloqueo y de la Respuesta 401 (4 puntos)
* **Breve explicación técnica:**  
  *Se ejecutaron las dos pruebas focalizadas demostrando: (a) que tras 3 fallos consecutivos, el cuarto intento genera exactamente cero llamadas de red hacia el backend mediante un Mock/Spy, y (b) que la inyección de una respuesta HTTP 401 purga el token a nulo en el almacenamiento y registra un único envío sin reintentos.*
* **Comando a ejecutar para la captura:**
  ```powershell
  cd aplicacion_seguridad
  flutter test test/examen_tipo1_test.dart --name "Ítem 5"
  ```
* **Capturas requeridas:**
  1. **Captura de código:** Archivo `test/examen_tipo1_test.dart` (las dos funciones de test de `Ítem 5.a` y `Ítem 5.b`).
  2. **Captura completa de la terminal:** Mostrando la salida con ambos tests aprobados en verde (`PASS / All tests passed!`).
