import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  final AuthController authController;

  const LoginScreen({super.key, required this.authController});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identificadorController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identificadorController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    // ÍTEM 1: Validación de formulario antes de procesar el envío
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await widget.authController.iniciarSesion(
      identificador: _identificadorController.text,
      contrasena: _contrasenaController.text,
    );

    if (!success && mounted) {
      final error =
          widget.authController.errorMessage ?? 'Error al iniciar sesión';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate dark
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Encabezado
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 44,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ingreso UPT',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Puesto de Seguridad y Verificación',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Tarjeta del formulario
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF334155),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Alerta inline de error o bloqueo (Ítem 1 y 2)
                          ListenableBuilder(
                            listenable: widget.authController,
                            builder: (context, _) {
                              final error = widget.authController.errorMessage;
                              if (error == null) return const SizedBox.shrink();

                              return Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade900
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.red.shade700),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_clock,
                                        color: Colors.redAccent, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        error,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Campo Identificador
                          Text(
                            'Identificador Institucional',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: const Color(0xFFCBD5E1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _identificadorController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Código o correo institucional',
                              hintStyle:
                                  const TextStyle(color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              prefixIcon: const Icon(Icons.person_outline,
                                  color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF334155)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF334155)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF38BDF8), width: 1.5),
                              ),
                            ),
                            // Validación inline (Ítem 1)
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Ingresa tu código o correo';
                              }
                              if (val.trim().length < 3) {
                                return 'Debe tener al menos 3 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Campo Contraseña
                          Text(
                            'Contraseña',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: const Color(0xFFCBD5E1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _contrasenaController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle:
                                  const TextStyle(color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Color(0xFF94A3B8)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF94A3B8),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF334155)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF334155)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF38BDF8), width: 1.5),
                              ),
                            ),
                            // Validación de longitud mínima de 6 caracteres (Ítem 1)
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Ingresa tu contraseña';
                              }
                              if (val.length < 6) {
                                return 'La contraseña debe tener al menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),

                          // Botón de Inicio de Sesión y estado de carga (Ítem 1 y 2)
                          ListenableBuilder(
                            listenable: widget.authController,
                            builder: (context, _) {
                              final isLoading = widget.authController.isLoading;
                              final estaBloqueado =
                                  widget.authController.estaBloqueado;

                              return ElevatedButton(
                                onPressed: (isLoading || estaBloqueado)
                                    ? null
                                    : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: estaBloqueado
                                      ? Colors.red.shade900
                                      : const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: estaBloqueado
                                      ? Colors.red.shade900
                                          .withValues(alpha: 0.6)
                                      : const Color(0xFF0369A1)
                                          .withValues(alpha: 0.6),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        estaBloqueado
                                            ? 'Acceso Bloqueado'
                                            : 'Iniciar Sesión',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Acceso restringido únicamente al personal autorizado de Seguridad y Administración de la UPT.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
