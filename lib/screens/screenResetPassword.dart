import 'package:flutter/material.dart';
import 'package:porcilac/theme/themeFondo.dart';

const porcilacPinkButton = Color(0xFFEA4C9A);

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nuevaPassCtrl.dispose();
    _confirmarPassCtrl.dispose();
    super.dispose();
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
            const SizedBox(height: 20),
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
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide:
                        const BorderSide(color: porcilacPinkButton, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                controller: _nuevaPassCtrl,
                obscureText: _ocultarNuevaPass,
                style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: '••••••••••••••••',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                    borderSide:
                        const BorderSide(color: porcilacPinkButton, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                controller: _confirmarPassCtrl,
                obscureText: _ocultarConfirmarPass,
                style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: '••••••••••••••••',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                    borderSide:
                        const BorderSide(color: porcilacPinkButton, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: () {
                        // Aquí conectarás la lógica de restablecimiento en Supabase
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.save,
                        size: 17,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Guardar',
                        style: TextStyle(
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