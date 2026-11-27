import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _rosa = Color(0xFFE8628C);
const _azul = Color(0xFF3B9AE8);
const _verde = Color(0xFF22C55E);
const _indigo = Color(0xFF6568E8);
const _turquesa = Color(0xFF22CDB0);

// Días de gestación de la cerda (3 meses, 3 semanas y 3 días)
const _diasGestacion = 114;

const _meses = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];
const _mesesCortos = [
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Sep',
  'Oct',
  'Nov',
  'Dic',
];

String _fecha(DateTime d) => '${d.day} ${_mesesCortos[d.month - 1]} ${d.year}';
String _cerdasTexto(int n) => '$n ${n == 1 ? 'cerda' : 'cerdas'}';

class ScreenInicio extends StatefulWidget {
  const ScreenInicio({super.key});

  @override
  State<ScreenInicio> createState() => _ScreenInicioState();
}

class _ScreenInicioState extends State<ScreenInicio> {
  final _db = Supabase.instance.client;

  bool _cargando = true;
  String? _error;

  int _totalCerdas = 0;
  int _preniadas = 0;
  int _lechones = 0;
  int _nacidosVivos = 0;
  int _destetados = 0;
  int _muertos = 0;
  Map<DateTime, List<String>> _partosPorDia = {};

  late DateTime _mesVisible;
  DateTime? _diaSeleccionado;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _mesVisible = DateTime(hoy.year, hoy.month, 1);
    _cargar();
  }

  // ---------- Leer todo de Supabase y calcular ----------
  Future<void> _cargar() async {
    try {
      final r = await Future.wait([
        _db.from('cerdas').select('id, estado_reproductivo').eq('activa', true),
        _db
            .from('partos')
            .select('cerda_id, fecha_parto, lechones_vivos, lechones_muertos'),
        _db.from('destetes').select('fecha_destete, num_lechones'),
        _db
            .from('reproducciones')
            .select('cerda_id, numero_arete, fecha_prenio'),
      ]);

      final cerdas = List<Map<String, dynamic>>.from(r[0] as List);
      final partos = List<Map<String, dynamic>>.from(r[1] as List);
      final destetes = List<Map<String, dynamic>>.from(r[2] as List);
      final repros = List<Map<String, dynamic>>.from(r[3] as List);

      final hoy = DateTime.now();
      bool esMesActual(DateTime d) =>
          d.year == hoy.year && d.month == hoy.month;

      final activas = cerdas.map((c) => c['id'].toString()).toSet();
      final preniadas = cerdas
          .where((c) => c['estado_reproductivo'] == 'Gestante')
          .length;

      // Partos
      int vivosTotal = 0, vivosMes = 0, muertosMes = 0;
      final partosDeCerda = <String, List<DateTime>>{};
      for (final p in partos) {
        final f = DateTime.parse(p['fecha_parto'] as String);
        final vivos = (p['lechones_vivos'] as num).toInt();
        final muertos = (p['lechones_muertos'] as num).toInt();
        vivosTotal += vivos;
        if (esMesActual(f)) {
          vivosMes += vivos;
          muertosMes += muertos;
        }
        (partosDeCerda[p['cerda_id'].toString()] ??= []).add(f);
      }

      // Destetes
      int destetadosTotal = 0, destetadosMes = 0;
      for (final d in destetes) {
        final f = DateTime.parse(d['fecha_destete'] as String);
        final n = (d['num_lechones'] as num).toInt();
        destetadosTotal += n;
        if (esMesActual(f)) destetadosMes += n;
      }

      // Próximos partos = fecha de preño + 114 días (si aún no ha parido)
      final hoyDia = DateTime(hoy.year, hoy.month, hoy.day);
      final mapa = <DateTime, List<String>>{};
      for (final rp in repros) {
        final cerdaId = rp['cerda_id'].toString();
        if (!activas.contains(cerdaId)) continue;
        final prenio = DateTime.parse(rp['fecha_prenio'] as String);
        final yaPario = (partosDeCerda[cerdaId] ?? []).any(
          (f) => !f.isBefore(prenio),
        );
        if (yaPario) continue;
        final estimado = DateTime(
          prenio.year,
          prenio.month,
          prenio.day + _diasGestacion,
        );
        if (estimado.isBefore(hoyDia)) continue;
        (mapa[estimado] ??= []).add(rp['numero_arete'].toString());
      }

      if (!mounted) return;
      setState(() {
        _totalCerdas = cerdas.length;
        _preniadas = preniadas;
        _lechones = math.max(0, vivosTotal - destetadosTotal);
        _nacidosVivos = vivosMes;
        _muertos = muertosMes;
        _destetados = destetadosMes;
        _partosPorDia = mapa;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo cargar el inicio.\n$e';
      });
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _rosa));
    }

    return ColoredBox(
      color: Colors.white,
      child: RefreshIndicator(
        color: _rosa,
        onRefresh: _cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Bienvenido, Administrador',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton(
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
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _TarjetaContador(
                      titulo: 'Cerdas totales',
                      valor: _totalCerdas,
                      color: _rosa,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TarjetaContador(
                      titulo: 'Lechones',
                      valor: _lechones,
                      color: _azul,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TarjetaContador(
                      titulo: 'Cerdas preñadas',
                      valor: _preniadas,
                      color: _verde,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  if (c.maxWidth >= 700) {
                    // Pantalla ancha: lado a lado y con la misma altura
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _seccion(
                              'Próximos partos',
                              _proximosPartos(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _seccion(
                              'Resumen de producción (este mes)',
                              _resumen(),
                              expandir: true,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  // Celular: uno debajo del otro
                  return Column(
                    children: [
                      _seccion('Próximos partos', _proximosPartos()),
                      const SizedBox(height: 12),
                      _seccion('Resumen de producción (este mes)', _resumen()),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo, Widget contenido, {bool expandir = false}) {
    return Card(
      elevation: 3,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (expandir)
              Expanded(child: Center(child: contenido))
            else
              contenido,
          ],
        ),
      ),
    );
  }

  // ---------- Próximos partos: calendario + lista ----------
  Widget _proximosPartos() {
    final fechas = _partosPorDia.keys.toList()..sort();
    final proximas = fechas.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _calendario(),
        const SizedBox(height: 8),
        if (_diaSeleccionado != null) _detalleDia(_diaSeleccionado!),
        const Divider(height: 24),
        if (proximas.isEmpty)
          const Text(
            'No hay partos programados',
            style: TextStyle(color: Colors.black54),
          )
        else
          for (final f in proximas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fecha(f)),
                  Text(
                    _cerdasTexto(_partosPorDia[f]!.length),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _detalleDia(DateTime dia) {
    final aretes = _partosPorDia[dia];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEBF1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        aretes == null
            ? 'Sin partos programados el ${_fecha(dia)}'
            : '${_fecha(dia)}: ${_cerdasTexto(aretes.length)} (arete ${aretes.join(', ')})',
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _calendario() {
    final diasMes = DateTime(_mesVisible.year, _mesVisible.month + 1, 0).day;
    final vacios = _mesVisible.weekday - 1; // lunes = 0
    final hoy = DateTime.now();

    final celdas = <Widget>[for (var i = 0; i < vacios; i++) const SizedBox()];

    for (var d = 1; d <= diasMes; d++) {
      final fecha = DateTime(_mesVisible.year, _mesVisible.month, d);
      final hayParto = _partosPorDia.containsKey(fecha);
      final seleccionado = _diaSeleccionado == fecha;
      final esHoy =
          fecha.year == hoy.year &&
          fecha.month == hoy.month &&
          fecha.day == hoy.day;

      celdas.add(
        GestureDetector(
          onTap: () =>
              setState(() => _diaSeleccionado = seleccionado ? null : fecha),
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: seleccionado
                    ? _rosa
                    : hayParto
                    ? const Color(0xFFFBD3E3)
                    : null,
                border: esHoy ? Border.all(color: _rosa, width: 1.5) : null,
              ),
              child: Text(
                '$d',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hayParto ? FontWeight.bold : FontWeight.normal,
                  color: seleccionado ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(
                () => _mesVisible = DateTime(
                  _mesVisible.year,
                  _mesVisible.month - 1,
                  1,
                ),
              ),
            ),
            Text(
              '${_meses[_mesVisible.month - 1]} ${_mesVisible.year}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(
                () => _mesVisible = DateTime(
                  _mesVisible.year,
                  _mesVisible.month + 1,
                  1,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            for (final l in ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
              Expanded(
                child: Center(
                  child: Text(
                    l,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _indigo,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < celdas.length; i += 7)
          SizedBox(
            height: 36,
            child: Row(
              children: [
                for (var j = i; j < i + 7; j++)
                  Expanded(
                    child: j < celdas.length ? celdas[j] : const SizedBox(),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // ---------- Resumen de producción ----------
  Widget _resumen() {
    final total = _nacidosVivos + _destetados + _muertos;

    Widget fila(Color c, String texto, int n) {
      final pct = total == 0 ? 0 : (n * 100 / total).round();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(texto, style: const TextStyle(fontSize: 14))),
            Text(
              '$n',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              width: 46,
              child: Text(
                '$pct%',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 170,
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(170, 170),
                painter: _DonutPainter(
                  [
                    _nacidosVivos.toDouble(),
                    _destetados.toDouble(),
                    _muertos.toDouble(),
                  ],
                  const [_indigo, _rosa, _turquesa],
                ),
              ),
              if (total == 0)
                const Padding(
                  padding: EdgeInsets.all(38),
                  child: Text(
                    'Sin datos este mes',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'en total',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        fila(_indigo, 'Nacidos vivos', _nacidosVivos),
        fila(_rosa, 'Destetados', _destetados),
        fila(_turquesa, 'Muertos', _muertos),
      ],
    );
  }
}

// ====== Tarjeta de contador ======
class _TarjetaContador extends StatelessWidget {
  final String titulo;
  final int valor;
  final Color color;

  const _TarjetaContador({
    required this.titulo,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Column(
          children: [
            SizedBox(
              height: 32,
              child: Center(
                child: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(FontAwesomeIcons.piggyBank, size: 22, color: color),
                  const SizedBox(width: 6),
                  Text(
                    '$valor',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== Gráfica de dona ======
class _DonutPainter extends CustomPainter {
  final List<double> valores;
  final List<Color> colores;

  _DonutPainter(this.valores, this.colores);

  @override
  void paint(Canvas canvas, Size size) {
    final total = valores.fold<double>(0, (a, b) => a + b);
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - 14,
    );

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..color = const Color(0xFFEEEEEE);

    if (total == 0) {
      canvas.drawArc(rect, 0, 2 * math.pi, false, base);
      return;
    }

    var inicio = -math.pi / 2;
    for (var i = 0; i < valores.length; i++) {
      if (valores[i] <= 0) continue;
      final barrido = valores[i] / total * 2 * math.pi;
      final pintura = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..color = colores[i];
      canvas.drawArc(rect, inicio, barrido, false, pintura);
      inicio += barrido;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}
