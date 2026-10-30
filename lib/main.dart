import 'package:flutter/material.dart';

import 'core/storage/secure_storage_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/home_guardia_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final secureStorage = FlutterSecureStorageService();
  late final AuthController authController;

  final authRepository = AuthRepository(
    secureStorage: secureStorage,
    onUnauthorized: () {
      authController.forzarCierreSesionPor401();
    },
  );

  authController = AuthController(repository: authRepository);

  // Inicializa la sesión guardada en segundo plano
  authController.inicializarSesion();

  runApp(AppSeguridad(authController: authController));
}

class AppSeguridad extends StatelessWidget {
  final AuthController authController;

  const AppSeguridad({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seguridad UPT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: ListenableBuilder(
        listenable: authController,
        builder: (context, _) {
          switch (authController.status) {
            case AuthStatus.initial:
              return const Scaffold(
                backgroundColor: Color(0xFF0F172A),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                ),
              );
            case AuthStatus.loading:
              // Si ya teníamos pantalla de login, mantenemos la vista mientras carga
              if (!authController.isAuthenticated &&
                  authController.sesion == null) {
                return LoginScreen(authController: authController);
              }
              return const Scaffold(
                backgroundColor: Color(0xFF0F172A),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                ),
              );
            case AuthStatus.authenticated:
              return HomeGuardiaScreen(authController: authController);
            case AuthStatus.unauthenticated:
            case AuthStatus.error:
              return LoginScreen(authController: authController);
          }
        },
      ),
    );
  }
}
