import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _rosa = Color(0xFFE8628C);
const _verde = Color(0xFF4CAF7A);
const _azulOscuro = Color(0xFF3B5B8C);
const _azul = Color(0xFF3B9AE8);
const _indigo = Color(0xFF6568E8);
const _naranja = Color(0xFFF59E0B);
const _rojo = Color(0xFFEF4444);

const _tiposFiltro = {
  'Todos': null,
  'Cerdas': 'cerda',
  'Reproducciones': 'reproduccion',
  'Partos': 'parto',
  'Destetes': 'destete',
};

// =====================================================================
// PANTALLA
// =====================================================================
class ScreenNotificaciones extends StatefulWidget {
  /// true cuando se abre desde la campana (con flecha para volver)
  final bool conAppBar;
  const ScreenNotificaciones({super.key, this.conAppBar = false});

  @override
  State<ScreenNotificaciones> createState() => _ScreenNotificacionesState();
}

class _ScreenNotificacionesState extends State<ScreenNotificaciones> {
  final _db = Supabase.instance.client;

  List<Map<String, dynamic>> _lista = [];
  bool _cargando = true;
  String? _error;
  String _busqueda = '';
  String _filtro = 'Todas';
  String _tipo = 'Todos';

  RealtimeChannel? _canal;
  Timer? _debounce;
  Timer? _respaldo;

  @override
  void initState() {
    super.initState();
    _cargar();
    _canal = _db
        .channel('pantalla-notificaciones')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notificaciones',
          callback: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), _cargar);
          },
        )
        .subscribe();
    _respaldo = Timer.periodic(const Duration(seconds: 30), (_) => _cargar());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _respaldo?.cancel();
    if (_canal != null) _db.removeChannel(_canal!);
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtradas {
    final q = _busqueda.toLowerCase();
    return _lista.where((n) {
      final texto = '${n['titulo']} ${n['detalle'] ?? ''}'.toLowerCase();
      final okBusqueda = q.isEmpty || texto.contains(q);
      final okLeida = _filtro == 'Todas' || n['leida'] != true;
      final clave = _tiposFiltro[_tipo];
      final okTipo = clave == null || tipoDeNotif(n) == clave;
      return okBusqueda && okLeida && okTipo;
    }).toList();
  }

  Future<void> _cargar() async {
    try {
      final data = await _db
          .from('notificaciones')
          .select()
          .order('creada_en', ascending: false)
          .limit(200);
      if (!mounted) return;
      setState(() {
        _lista = List<Map<String, dynamic>>.from(data);
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_lista.isNotEmpty) return; // no borrar lo que ya se ve
      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar las notificaciones.\n$e';
      });
    }
  }

  Future<void> _marcarLeida(Map<String, dynamic> n) async {
    if (n['leida'] == true) return;
    setState(() {
      _lista = _lista
          .map((x) => x['id'] == n['id'] ? {...x, 'leida': true} : x)
          .toList();
    });
    try {
      await _db
          .from('notificaciones')
          .update({'leida': true})
          .eq('id', n['id']);
    } catch (e) {
      debugPrint('Error al marcar como leída: $e');
    }
  }

  Future<void> _marcarTodas() async {
    setState(() {
      _lista = _lista.map((n) => {...n, 'leida': true}).toList();
    });
    try {
      await _db
          .from('notificaciones')
          .update({'leida': true})
          .eq('leida', false);
    } catch (e) {
      debugPrint('Error al marcar como leídas: $e');
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final lista = _filtradas;
    final sinLeer = _lista.where((n) => n['leida'] != true).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.conAppBar
          ? AppBar(
              backgroundColor: _rosa,
              foregroundColor: Colors.white,
              title: const Text('Notificaciones'),
            )
          : null,
      body: Column(
        children: [
          if (!widget.conAppBar)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Notificaciones',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.black87,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _busqueda = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar notificación',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _desplegable(
                      ['Todas', 'Sin leer'],
                      _filtro,
                      (v) => setState(() => _filtro = v),
                    ),
                    _desplegable(
                      _tiposFiltro.keys.toList(),
                      _tipo,
                      (v) => setState(() => _tipo = v),
                    ),
                    if (sinLeer > 0)
                      TextButton.icon(
                        onPressed: _marcarTodas,
                        icon: const Icon(Icons.done_all, size: 18),
                        label: Text('Marcar $sinLeer como leídas'),
                        style: TextButton.styleFrom(
                          foregroundColor: _azulOscuro,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(child: _contenido(lista)),
        ],
      ),
    );
  }

  Widget _desplegable(
    List<String> opciones,
    String valor,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black54),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          value: valor,
          items: opciones
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }

  Widget _contenido(List<Map<String, dynamic>> lista) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _rosa));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => _cargando = true);
                  _cargar();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _rosa,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (lista.isEmpty) {
      return const Center(child: Text('No hay notificaciones'));
    }
    return RefreshIndicator(
      color: _rosa,
      onRefresh: _cargar,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: lista.length,
        itemBuilder: (_, i) => _tarjeta(lista[i]),
      ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> n) {
    final leida = n['leida'] == true;
    final estilo = estiloNotif(tipoDeNotif(n), accionDeNotif(n));
    final detalle = '${n['detalle'] ?? ''}';

    return Card(
      elevation: 3,
      color: leida ? Colors.white : const Color(0xFFFDEBF1),
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: estilo.color.withOpacity(0.15),
                  child: estilo.icono,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${n['titulo']}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: leida ? FontWeight.w500 : FontWeight.bold,
                        ),
                      ),
                      if (detalle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            detalle,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          haceNotif(n['creada_en']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!leida)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: CircleAvatar(radius: 5, backgroundColor: _rosa),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _boton('Ver detalle', Icons.visibility, _azulOscuro, () {
                    _marcarLeida(n);
                    verDetalleNotificacion(context, n);
                  }),
                  if (!leida)
                    _boton(
                      'Marcar como leída',
                      Icons.check,
                      _verde,
                      () => _marcarLeida(n),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boton(String texto, IconData icono, Color color, VoidCallback f) {
    return ElevatedButton.icon(
      onPressed: f,
      icon: Icon(icono, size: 16),
      label: Text(texto),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
    );
  }
}

// =====================================================================
// FUNCIONES COMPARTIDAS (las usa también la campana)
// =====================================================================

// Notificaciones antiguas (sin columna accion) siguen funcionando
String tipoDeNotif(Map<String, dynamic> n) =>
    n['tipo'] == 'baja' ? 'cerda' : '${n['tipo']}';

String accionDeNotif(Map<String, dynamic> n) =>
    (n['accion'] ?? (n['tipo'] == 'baja' ? 'baja' : 'registro')) as String;

class EstiloNotif {
  final Widget icono;
  final Color color;
  EstiloNotif(this.icono, this.color);
}

EstiloNotif estiloNotif(String tipo, String accion) {
  if (accion == 'eliminacion') {
    return EstiloNotif(
      const Icon(Icons.delete_outline, size: 20, color: _rojo),
      _rojo,
    );
  }
  if (accion == 'baja') {
    return EstiloNotif(
      const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
      Colors.grey,
    );
  }
  if (accion == 'edicion') {
    return EstiloNotif(
      const Icon(Icons.edit, size: 19, color: _naranja),
      _naranja,
    );
  }
  switch (tipo) {
    case 'cerda':
      return EstiloNotif(
        const FaIcon(FontAwesomeIcons.piggyBank, size: 17, color: _rosa),
        _rosa,
      );
    case 'reproduccion':
      return EstiloNotif(
        const Icon(Icons.favorite, size: 19, color: _verde),
        _verde,
      );
    case 'parto':
      return EstiloNotif(
        const Icon(Icons.child_care, size: 21, color: _azul),
        _azul,
      );
    default: // destete
      return EstiloNotif(
        const Icon(Icons.restaurant, size: 19, color: _indigo),
        _indigo,
      );
  }
}

String haceNotif(dynamic valor) {
  final f = DateTime.tryParse('$valor')?.toLocal();
  if (f == null) return '';
  final d = DateTime.now().difference(f);
  if (d.inMinutes < 1) return 'Hace un momento';
  if (d.inMinutes < 60) return 'Hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'Hace ${d.inHours} h';
  return 'Hace ${d.inDays} ${d.inDays == 1 ? 'día' : 'días'}';
}

// ---------- Detalle tipo formulario ----------
const _orden = {
  'cerda': [
    'numero',
    'numero_arete',
    'raza',
    'color',
    'edad_anios',
    'estado_reproductivo',
    'fecha_registro',
  ],
  'parto': [
    'id',
    'numero_arete',
    'fecha_parto',
    'lechones_vivos',
    'lechones_muertos',
    'num_lechones',
    'observaciones',
  ],
  'reproduccion': ['numero_arete', 'fecha_prenio'],
  'destete': ['numero_arete', 'fecha_destete', 'num_lechones'],
};

const _etiquetas = {
  'numero': 'ID cerda',
  'id': 'ID parto',
  'numero_arete': 'Num. Arete',
  'raza': 'Raza',
  'color': 'Color',
  'edad_anios': 'Edad (años)',
  'estado_reproductivo': 'Estado reproductivo',
  'fecha_registro': 'Fecha de registro',
  'fecha_parto': 'Fecha de parto',
  'lechones_vivos': 'Lechones vivos',
  'lechones_muertos': 'Lechones muertos',
  'num_lechones': 'Número de lechones',
  'observaciones': 'Observaciones',
  'fecha_prenio': 'Fecha de preño',
  'fecha_destete': 'Fecha de destete',
};

const _ocultos = {'id', 'cerda_id', 'activa', 'created_at', 'creada_en'};

Map<String, dynamic> _mapa(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  if (v is String && v.isNotEmpty) {
    try {
      final d = jsonDecode(v);
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
  }
  return {};
}

String _valor(dynamic v) {
  if (v == null || '$v'.isEmpty) return '—';
  if (v is bool) return v ? 'Sí' : 'No';
  return '$v';
}

String _etiqueta(String k) {
  final e = _etiquetas[k];
  if (e != null) return e;
  final t = k.replaceAll('_', ' ');
  return t.isEmpty ? k : t[0].toUpperCase() + t.substring(1);
}

Widget _campo(String etiqueta, String valor, {String? antes}) {
  final cambiado = antes != null;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: etiqueta,
        filled: cambiado,
        fillColor: cambiado ? const Color(0xFFFFF4DC) : null,
        helperText: cambiado ? 'Antes: $antes' : null,
        helperStyle: const TextStyle(color: _naranja),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: cambiado
              ? const BorderSide(color: _naranja, width: 1.5)
              : const BorderSide(),
        ),
      ),
      child: Text(valor),
    ),
  );
}

void verDetalleNotificacion(BuildContext context, Map<String, dynamic> n) {
  final tipo = tipoDeNotif(n);
  final accion = accionDeNotif(n);
  final nuevo = _mapa(n['datos']);
  final viejo = _mapa(n['datos_anteriores']);
  final base = accion == 'eliminacion' ? viejo : nuevo;

  final orden = _orden[tipo] ?? const <String>[];
  final claves = <String>[
    ...orden.where(base.containsKey),
    ...base.keys.where(
      (k) => !orden.contains(k) && !_ocultos.contains(k) && !k.endsWith('_id'),
    ),
  ];

  final campos = <Widget>[];
  for (final k in claves) {
    final cambio =
        accion == 'edicion' &&
        viejo.containsKey(k) &&
        '${viejo[k]}' != '${nuevo[k]}';
    campos.add(
      _campo(
        _etiqueta(k),
        _valor(base[k]),
        antes: cambio ? _valor(viejo[k]) : null,
      ),
    );
  }

  String aviso;
  Color colorAviso;
  switch (accion) {
    case 'baja':
      aviso = 'Esta cerda fue dada de baja.';
      colorAviso = Colors.grey;
      break;
    case 'eliminacion':
      aviso = 'Este registro fue eliminado.';
      colorAviso = _rojo;
      break;
    case 'edicion':
      aviso = 'Los campos modificados aparecen resaltados.';
      colorAviso = _naranja;
      break;
    default:
      aviso = 'Registro nuevo.';
      colorAviso = _verde;
  }

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${n['titulo']}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                haceNotif(n['creada_en']),
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorAviso.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  aviso,
                  style: TextStyle(fontSize: 13, color: colorAviso),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: campos.isEmpty
                      ? Text('${n['detalle'] ?? 'Sin información adicional'}')
                      : Column(children: campos),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cerrar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}