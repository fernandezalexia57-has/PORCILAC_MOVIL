import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:porcilac/theme/themeFondo.dart';

import 'screenHome.dart';
import 'screenResetPassword.dart';

const porcilacPinkButton = Color(0xFFEA4C9A);

class ScreenLogin extends StatefulWidget {
  const ScreenLogin({super.key});

  @override
  State<ScreenLogin> createState() => _ScreenLoginState();
}

class _ScreenLoginState extends State<ScreenLogin> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _ocultarPassword = true;
  bool _cargando = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final correo = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (correo.isEmpty || password.isEmpty) {
      _mostrarMensaje('Ingresa tu correo electrónico y contraseña.');
      return;
    }

    setState(() => _cargando = true);

    try {
      final authResponse = await Supabase.instance.client.auth
          .signInWithPassword(email: correo, password: password);

      final emailAutenticado = authResponse.user?.email ?? correo;

      final empleado = await Supabase.instance.client
          .from('empleados')
          .select()
          .eq('correo', emailAutenticado)
          .maybeSingle();

      if (!mounted) return;

      if (empleado == null) {
        await Supabase.instance.client.auth.signOut();
        _mostrarMensaje(
          'Tu usuario existe en autenticación, pero no está registrado en empleados.',
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ScreenHome()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _mostrarMensaje(e.message);
    } catch (_) {
      if (!mounted) return;
      _mostrarMensaje('No se pudo conectar con Supabase. Revisa tu conexión.');
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return PorcilacAuthShell(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
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
              'Iniciar sesión',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 24),
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
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
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
            const SizedBox(height: 22),
            const Text(
              'Contraseña',
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
                controller: _passwordCtrl,
                obscureText: _ocultarPassword,
                style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: '••••••••••••••••',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 19,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() => _ocultarPassword = !_ocultarPassword);
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
            const SizedBox(height: 28),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _cargando ? null : _iniciarSesion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: porcilacPinkButton,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: _cargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScreenResetPassword(),
                    ),
                  );
                },
                child: const Text(
                  '¿Olvidaste la contraseña?',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: porcilacPinkButton,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: porcilacPinkButton,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
