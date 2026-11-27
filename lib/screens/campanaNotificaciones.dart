import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screenNotificaciones.dart';

class CampanaNotificaciones extends StatefulWidget {
  const CampanaNotificaciones({super.key});

  @override
  State<CampanaNotificaciones> createState() => _CampanaNotificacionesState();
}

class _CampanaNotificacionesState extends State<CampanaNotificaciones> {
  final _db = Supabase.instance.client;
  final _sinLeer = ValueNotifier<int>(0);
  RealtimeChannel? _canal;
  Timer? _respaldo;

  @override
  void initState() {
    super.initState();
    _contar();
    _canal = _db
        .channel('campana-notificaciones')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notificaciones',
          callback: (payload) {
            if (!mounted) return;
            _contar();
            if (payload.eventType == PostgresChangeEvent.insert) {
              _aviso(payload.newRecord);
            }
          },
        )
        .subscribe();
    // Respaldo por si Realtime no está activo
    _respaldo = Timer.periodic(const Duration(seconds: 30), (_) => _contar());
  }

  @override
  void dispose() {
    _respaldo?.cancel();
    if (_canal != null) _db.removeChannel(_canal!);
    _sinLeer.dispose();
    super.dispose();
  }

  Future<void> _contar() async {
    try {
      final data = await _db
          .from('notificaciones')
          .select('id')
          .eq('leida', false);
      if (!mounted) return;
      _sinLeer.value = (data as List).length;
    } catch (e) {
      debugPrint('Error al contar notificaciones: $e');
    }
  }

  // Aviso emergente cuando llega una notificación nueva
  void _aviso(Map<String, dynamic> n) {
    final detalle = '${n['detalle'] ?? ''}';
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF3B5B8C),
        duration: const Duration(seconds: 5),
        content: Text(
          '${n['titulo']}${detalle.isNotEmpty ? '\n$detalle' : ''}',
          style: const TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () => verDetalleNotificacion(context, n),
        ),
      ),
    );
  }

  Future<void> _abrirPantalla() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScreenNotificaciones(conAppBar: true),
      ),
    );
    _contar();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _sinLeer,
      builder: (_, n, __) => IconButton(
        tooltip: 'Notificaciones',
        onPressed: _abrirPantalla,
        icon: Badge(
          isLabelVisible: n > 0,
          label: Text(n > 99 ? '99+' : '$n'),
          backgroundColor: const Color(0xFFE8628C),
          child: const Icon(Icons.notifications),
        ),
      ),
    );
  }
}
