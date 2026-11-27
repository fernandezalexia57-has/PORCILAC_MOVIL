import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ====== Colores del diseño Porcilac ======
const kRosa = Color(0xFFE8628C);
const kVerde = Color(0xFF4CAF7A);
const kAzul = Color(0xFF3B5B8C);

const int _kDiasMinimos = 111;

const filtrosParto = ['Todos', 'Con muertos', 'Sin muertos'];

// ====== Modelo ======
class Parto {
  String id;
  dynamic cerdaId;
  String arete;
  DateTime fechaParto;
  int vivos;
  int muertos;
  String observaciones;

  Parto({
    required this.id,
    required this.cerdaId,
    required this.arete,
    required this.fechaParto,
    required this.vivos,
    required this.muertos,
    required this.observaciones,
  });

  int get total => vivos + muertos;

  factory Parto.fromMap(Map<String, dynamic> m) => Parto(
    id: m['id'].toString(),
    cerdaId: m['cerda_id'],
    arete: (m['numero_arete'] ?? '').toString(),
    fechaParto: DateTime.parse(m['fecha_parto'].toString()),
    vivos: (m['lechones_vivos'] ?? 0) as int,
    muertos: (m['lechones_muertos'] ?? 0) as int,
    observaciones: (m['observaciones'] ?? '').toString(),
  );

  String get fechaTexto => fmtFecha(fechaParto);
}

String fmtFecha(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ====== Pantalla principal ======
class ScreenPartos extends StatefulWidget {
  const ScreenPartos({super.key});

  @override
  State<ScreenPartos> createState() => _ScreenPartosState();
}

class _ScreenPartosState extends State<ScreenPartos> {
  final _db = Supabase.instance.client;

  List<Parto> _partos = [];
  bool _cargando = true;
  String? _errorCarga;
  String _busqueda = '';
  String _filtro = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  List<Parto> get _filtrados {
    return _partos.where((p) {
      final q = _busqueda.toLowerCase();
      final coincide =
          q.isEmpty || p.id.contains(q) || p.arete.toLowerCase().contains(q);
      final filtroOk =
          _filtro == 'Todos' ||
          (_filtro == 'Con muertos' && p.muertos > 0) ||
          (_filtro == 'Sin muertos' && p.muertos == 0);
      return coincide && filtroOk;
    }).toList();
  }

  // ---------- Leer partos de Supabase ----------
  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    try {
      final data = await _db
          .from('partos')
          .select()
          .order('id', ascending: false);
      if (!mounted) return;
      setState(() {
        _partos = (data as List)
            .map((e) => Parto.fromMap(e as Map<String, dynamic>))
            .toList();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorCarga = 'No se pudieron cargar los partos.\n$e';
      });
    }
  }

  // ---------- Formulario (registrar / editar) ----------
  Future<void> _abrirFormulario({Parto? parto}) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _FormularioParto(parto: parto),
        ),
      ),
    );

    if (resultado == null) return;

    try {
      if (parto == null) {
        await _db.from('partos').insert(resultado);

        // La cerda ya parió: pasa de Gestante a Lactante
        await _db
            .from('cerdas')
            .update({'estado_reproductivo': 'Lactante'})
            .eq('id', resultado['cerda_id']);
      } else {
        await _db.from('partos').update(resultado).eq('id', parto.id);
      }
      await _cargar();
      if (!mounted) return;
      _mensaje(
        parto == null
            ? 'Parto registrado correctamente'
            : 'Información editada correctamente',
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _mensaje('Error al guardar: ${e.message}', error: true);
    } catch (e) {
      if (!mounted) return;
      _mensaje('Error al guardar: $e', error: true);
    }
  }

  void _mensaje(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto, style: const TextStyle(color: Colors.black87)),
        backgroundColor: error
            ? const Color(0xFFF4A9A9)
            : const Color(0xFF9FEFBF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final lista = _filtrados;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kRosa,
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo parto'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Partos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black87,
              ),
            ),
          ),
          // Buscador + filtro
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _busqueda = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar parto (ID, Núm. Arete)',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black54),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _filtro,
                      items: filtrosParto
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _filtro = v!),
                    ),
                  ),
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

  Widget _contenido(List<Parto> lista) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: kRosa));
    }
    if (_errorCarga != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorCarga!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _cargar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRosa,
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
      return const Center(child: Text('No hay partos registrados'));
    }
    return RefreshIndicator(
      color: kRosa,
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: lista.length,
        itemBuilder: (_, i) => _TarjetaParto(
          parto: lista[i],
          onEditar: () => _abrirFormulario(parto: lista[i]),
        ),
      ),
    );
  }
}

// ====== Tarjeta ======
class _TarjetaParto extends StatelessWidget {
  final Parto parto;
  final VoidCallback onEditar;

  const _TarjetaParto({required this.parto, required this.onEditar});

  Widget _dato(String etiqueta, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Text('$etiqueta: $valor', style: const TextStyle(fontSize: 14)),
  );

  Widget _boton(String texto, IconData? icono, Color color, VoidCallback f) {
    return ElevatedButton.icon(
      onPressed: f,
      icon: icono != null ? Icon(icono, size: 16) : const SizedBox.shrink(),
      label: Text(texto),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dato('ID parto', parto.id),
            _dato('Num. Arete', parto.arete),
            _dato('Fecha de parto', parto.fechaTexto),
            _dato('Num. de lechones', '${parto.total}'),
            _dato('Lechones vivos', '${parto.vivos}'),
            _dato('Lechones muertos', '${parto.muertos}'),
            if (parto.observaciones.isNotEmpty)
              _dato('Observaciones', parto.observaciones),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [_boton('Editar', Icons.edit, kVerde, onEditar)],
            ),
          ],
        ),
      ),
    );
  }
}

// ====== Formulario: Registro / Edición ======
class _FormularioParto extends StatefulWidget {
  final Parto? parto;

  const _FormularioParto({this.parto});

  @override
  State<_FormularioParto> createState() => _FormularioPartoState();
}

class _FormularioPartoState extends State<_FormularioParto> {
  final _db = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _cerdas = []; // solo cerdas gestantes
  bool _cargandoCerdas = true;
  dynamic _cerdaId;
  DateTime? _fecha;
  bool _errorFecha = false;
  int _vivos = 0;
  int _muertos = 0;
  final _obsCtrl = TextEditingController();

  bool _guardando = false;
  String? _error;

  bool get _editando => widget.parto != null;
  int get _total => _vivos + _muertos;

  @override
  void initState() {
    super.initState();
    final p = widget.parto;
    if (p != null) {
      _cerdaId = p.cerdaId;
      _fecha = p.fechaParto;
      _vivos = p.vivos;
      _muertos = p.muertos;
      _obsCtrl.text = p.observaciones;
    }
    _cargarCerdas();
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  /// Carga solo las cerdas activas que están en estado Gestante.
  /// Al editar, también se incluye la cerda del parto aunque ya no esté
  /// gestante, para que no desaparezca del formulario.
  Future<void> _cargarCerdas() async {
    try {
      final data = await _db
          .from('cerdas')
          .select()
          .eq('activa', true)
          .order('numero');

      final todas = List<Map<String, dynamic>>.from(data);
      final gestantes = todas.where((c) {
        final esGestante = c['estado_reproductivo'] == 'Gestante';
        final esLaDelParto = _editando && c['id'] == widget.parto!.cerdaId;
        return esGestante || esLaDelParto;
      }).toList();

      if (!mounted) return;
      setState(() {
        _cerdas = gestantes;
        _cargandoCerdas = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoCerdas = false;
        _error = 'Error al cargar cerdas: $e';
      });
    }
  }

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (f != null) {
      setState(() {
        _fecha = f;
        _errorFecha = false;
      });
    }
  }

  /// Valida que hayan pasado al menos 111 días desde la última monta/servicio.
  Future<String?> _validar111Dias() async {
    final rep = await _db
        .from('reproducciones')
        .select('fecha_prenio')
        .eq('cerda_id', _cerdaId)
        .order('fecha_prenio', ascending: false)
        .limit(1);

    if (rep.isEmpty) {
      return 'Esta cerda no tiene una reproducción registrada.';
    }
    final fechaPrenio = DateTime.parse(rep.first['fecha_prenio'].toString());
    final dias = _fecha!.difference(fechaPrenio).inDays;
    if (dias < _kDiasMinimos) {
      return 'El parto no puede registrarse antes de los $_kDiasMinimos días. '
          'Han transcurrido $dias días.';
    }
    return null;
  }

  Future<void> _guardar() async {
    setState(() => _error = null);

    final formOk = _formKey.currentState!.validate();
    if (_fecha == null) setState(() => _errorFecha = true);
    if (!formOk || _fecha == null) return;

    if (_total == 0) {
      setState(() => _error = 'Indica al menos un lechón.');
      return;
    }

    setState(() => _guardando = true);
    try {
      final err = await _validar111Dias();
      if (err != null) {
        if (mounted) setState(() => _error = err);
        return;
      }

      final cerda = _cerdas.firstWhere((c) => c['id'] == _cerdaId);

      if (!mounted) return;
      Navigator.pop(context, {
        'cerda_id': _cerdaId,
        'numero_arete': cerda['numero_arete'],
        'fecha_parto': fmtFecha(_fecha!),
        'num_lechones': _total,
        'lechones_vivos': _vivos,
        'lechones_muertos': _muertos,
        'observaciones': _obsCtrl.text.trim(),
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al validar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _contador(String label, int valor, ValueChanged<int> onChange) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        IconButton(
          onPressed: valor > 0 ? () => onChange(valor - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '$valor',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: () => onChange(valor + 1),
          icon: const Icon(Icons.add_circle, color: kVerde),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editando
                    ? 'Editar información del parto'
                    : 'Registro de nuevo parto',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Capture los datos básicos del parto'),
              const SizedBox(height: 16),
              DropdownButtonFormField<dynamic>(
                value: _cerdas.any((c) => c['id'] == _cerdaId)
                    ? _cerdaId
                    : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Número de arete de la cerda',
                  border: const OutlineInputBorder(),
                  helperText: (!_cargandoCerdas && _cerdas.isEmpty)
                      ? 'No hay cerdas gestantes registradas'
                      : null,
                ),
                items: _cerdas
                    .map(
                      (c) => DropdownMenuItem<dynamic>(
                        value: c['id'],
                        child: Text('${c['numero_arete']}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _cerdaId = v),
                validator: (v) => v == null ? 'Selecciona la cerda' : null,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _elegirFecha,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha del parto',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_month),
                    errorText: _errorFecha ? 'Selecciona la fecha' : null,
                  ),
                  child: Text(
                    _fecha == null ? 'Selecciona fecha' : fmtFecha(_fecha!),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _contador(
                'Lechones vivos:',
                _vivos,
                (v) => setState(() => _vivos = v),
              ),
              _contador(
                'Lechones muertos:',
                _muertos,
                (v) => setState(() => _muertos = v),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Número de lechones total: $_total',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _obsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: _guardando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(_editando ? 'Guardar' : 'Registrar parto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRosa,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
