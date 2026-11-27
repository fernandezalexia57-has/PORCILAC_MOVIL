import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:porcilac/theme/themeFondo.dart';

const porcilacPinkButton = Color(0xFFEA4C9A);
const String _kResetRedirectUrl = 'porcilac://reset-password';

class ScreenResetPassword extends StatefulWidget {
  const ScreenResetPassword({super.key});

  @override
  State<ScreenResetPassword> createState() => _ScreenResetPasswordState();
}

class _ScreenResetPasswordState extends State<ScreenResetPassword> {
  final _emailCtrl = TextEditingController();
  final _nuevaPassCtrl = TextEditingController();
  final _confirmarPassCtrl = TextEditingController();

  bool _ocultarNuevaPass = true;
  bool _ocultarConfirmarPass = true;
  bool _enviando = false;

  // Se activa cuando Supabase detecta que la app se abrió desde el enlace de recuperación
  bool _modoNuevaPassword = false;

  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _escucharRecuperacion();
  }

  void _escucharRecuperacion() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery && mounted) {
        setState(() => _modoNuevaPassword = true);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailCtrl.dispose();
    _nuevaPassCtrl.dispose();
    _confirmarPassCtrl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> _enviarCorreoRecuperacion() async {
    final correo = _emailCtrl.text.trim();
    if (correo.isEmpty || !correo.contains('@')) {
      _mostrarMensaje('Ingresa un correo electrónico válido.', esError: true);
      return;
    }

    setState(() => _enviando = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        correo,
        redirectTo: _kResetRedirectUrl,
      );
      _mostrarMensaje(
        'Te enviamos un enlace a $correo para restablecer tu contraseña.',
      );
    } on AuthException catch (e) {
      _mostrarMensaje(e.message, esError: true);
    } catch (e) {
      _mostrarMensaje('No se pudo enviar el correo: $e', esError: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _guardarNuevaPassword() async {
    final pass1 = _nuevaPassCtrl.text;
    final pass2 = _confirmarPassCtrl.text;

    if (pass1.length < 6) {
      _mostrarMensaje(
        'La contraseña debe tener al menos 6 caracteres.',
        esError: true,
      );
      return;
    }
    if (pass1 != pass2) {
      _mostrarMensaje('Las contraseñas no coinciden.', esError: true);
      return;
    }

    setState(() => _enviando = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pass1),
      );
      _mostrarMensaje('Contraseña actualizada correctamente.');
      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) {
      _mostrarMensaje(e.message, esError: true);
    } catch (e) {
      _mostrarMensaje('Error al guardar contraseña: $e', esError: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _onGuardarPressed() async {
    if (_enviando) return;
    if (_modoNuevaPassword) {
      await _guardarNuevaPassword();
    } else {
      await _enviarCorreoRecuperacion();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PorcilacAuthShell(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Reestablecer contraseña',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _modoNuevaPassword
                  ? 'Escribe y confirma tu nueva contraseña.'
                  : 'Ingresa tu correo para recibir el enlace de recuperación.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 18),
            if (!_modoNuevaPassword) ...[
              const Text(
                'Correo electrónico',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3A3A3A),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'ejemplo@gmail.com',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: const BorderSide(
                        color: porcilacPinkButton,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'Nueva contraseña',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3A3A3A),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                child: TextField(
                  controller: _nuevaPassCtrl,
                  obscureText: _ocultarNuevaPass,
                  style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: '••••••••••••••••',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarNuevaPass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 19,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() => _ocultarNuevaPass = !_ocultarNuevaPass);
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: const BorderSide(
                        color: porcilacPinkButton,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Confirmar contraseña',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3A3A3A),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                child: TextField(
                  controller: _confirmarPassCtrl,
                  obscureText: _ocultarConfirmarPass,
                  style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: '••••••••••••••••',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarConfirmarPass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 19,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(
                          () => _ocultarConfirmarPass = !_ocultarConfirmarPass,
                        );
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: const BorderSide(
                        color: porcilacPinkButton,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: _enviando ? null : () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 17,
                        color: porcilacPinkButton,
                      ),
                      label: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: porcilacPinkButton,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFF3B6D3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: _enviando ? null : _onGuardarPressed,
                      icon: _enviando
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.save,
                              size: 17,
                              color: Colors.white,
                            ),
                      label: Text(
                        _modoNuevaPassword ? 'Guardar' : 'Enviar enlace',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: porcilacPinkButton,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}