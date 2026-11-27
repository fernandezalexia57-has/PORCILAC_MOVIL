import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ====== Colores del diseño Porcilac ======
const kRosa = Color(0xFFE8628C);
const kVerde = Color(0xFF4CAF7A);
const kAzul = Color(0xFF3B5B8C);

// ====== Opciones (las mismas de la web) ======
const razas = ['Yorkshire', 'Landrace', 'Duroc', 'Pietrain', 'Hampshire'];
const colores = ['Blanco', 'Negro', 'Rojo', 'Manchado'];
const estados = ['Celo', 'Gestante', 'Lactante', 'Vacía'];

// ====== Modelo ======
class Cerda {
  String id; // uuid real (se usa para editar / dar de baja)
  int numero; // número consecutivo que se muestra: 1, 2, 3...
  String arete;
  String raza;
  String color;
  int edad;
  String estado;
  DateTime fechaRegistro;

  Cerda({
    required this.id,
    required this.numero,
    required this.arete,
    required this.raza,
    required this.color,
    required this.edad,
    required this.estado,
    required this.fechaRegistro,
  });

  factory Cerda.fromMap(Map<String, dynamic> m) => Cerda(
    id: m['id'].toString(),
    numero: m['numero'] as int,
    arete: m['numero_arete'] as String,
    raza: m['raza'] as String,
    color: m['color'] as String,
    edad: m['edad_anios'] as int,
    estado: m['estado_reproductivo'] as String,
    fechaRegistro: DateTime.parse(m['fecha_registro'] as String),
  );

  // Datos que se envían a Supabase (el id, el número y la fecha los genera la base de datos)
  Map<String, dynamic> toMap() => {
    'numero_arete': arete,
    'raza': raza,
    'color': color,
    'edad_anios': edad,
    'estado_reproductivo': estado,
  };

  String get fechaTexto =>
      '${fechaRegistro.year}-${fechaRegistro.month.toString().padLeft(2, '0')}-${fechaRegistro.day.toString().padLeft(2, '0')}';
}

// ====== Pantalla principal ======
class ScreenCerdas extends StatefulWidget {
  const ScreenCerdas({super.key});

  @override
  State<ScreenCerdas> createState() => _ScreenCerdasState();
}

class _ScreenCerdasState extends State<ScreenCerdas> {
  final _db = Supabase.instance.client;

  List<Cerda> _cerdas = [];
  bool _cargando = true;
  String? _errorCarga;
  String _busqueda = '';
  String _filtro = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  List<Cerda> get _filtradas {
    return _cerdas.where((c) {
      final q = _busqueda.toLowerCase();
      final coincide =
          q.isEmpty ||
          c.numero.toString().contains(q) ||
          c.arete.toLowerCase().contains(q);
      final estadoOk = _filtro == 'Todos' || c.estado == _filtro;
      return coincide && estadoOk;
    }).toList();
  }

  // ---------- Leer cerdas de Supabase ----------
  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    try {
      final data = await _db
          .from('cerdas')
          .select()
          .eq('activa', true)
          .order('numero');
      if (!mounted) return;
      setState(() {
        _cerdas = (data as List)
            .map((e) => Cerda.fromMap(e as Map<String, dynamic>))
            .toList();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorCarga = 'No se pudieron cargar las cerdas.\n$e';
      });
    }
  }

  // ---------- Formulario (registrar / editar) ----------
  Future<void> _abrirFormulario({Cerda? cerda}) async {
    final resultado = await showDialog<Cerda>(
      context: context,
      builder: (_) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _FormularioCerda(
            cerda: cerda,
            aretesUsados: _cerdas
                .where((c) => c.id != cerda?.id)
                .map((c) => c.arete)
                .toList(),
          ),
        ),
      ),
    );

    if (resultado == null) return;

    try {
      if (cerda == null) {
        await _db.from('cerdas').insert(resultado.toMap());
      } else {
        await _db.from('cerdas').update(resultado.toMap()).eq('id', cerda.id);
      }
      await _cargar();
      if (!mounted) return;
      _mensaje(
        cerda == null
            ? 'Cerda registrada correctamente'
            : 'Información editada correctamente',
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      if (e.code == '23505') {
        _mensaje('Ese número de arete ya está registrado', error: true);
      } else {
        _mensaje('Error al guardar: ${e.message}', error: true);
      }
    } catch (e) {
      if (!mounted) return;
      _mensaje('Error al guardar: $e', error: true);
    }
  }

  // ---------- Dar de baja ----------
  Future<void> _darDeBaja(Cerda c) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dar de baja'),
        content: Text('¿Desea dar de baja a la cerda con arete ${c.arete}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí', style: TextStyle(color: kRosa)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _db.from('cerdas').update({'activa': false}).eq('id', c.id);
      await _cargar();
      if (!mounted) return;
      _mensaje('Cerda dada de baja correctamente');
    } catch (e) {
      if (!mounted) return;
      _mensaje('Error al dar de baja: $e', error: true);
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
    final lista = _filtradas;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kRosa,
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva cerda'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Cerdas',
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
                      hintText: 'Buscar cerda (ID, Núm. Arete)',
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
                      items: ['Todos', ...estados]
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

  Widget _contenido(List<Cerda> lista) {
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
      return const Center(child: Text('No hay cerdas registradas'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: lista.length,
      itemBuilder: (_, i) => _TarjetaCerda(
        cerda: lista[i],
        onEditar: () => _abrirFormulario(cerda: lista[i]),
        onBaja: () => _darDeBaja(lista[i]),
        onHistorial: () =>
            _mensaje('Historial de la cerda ${lista[i].arete} (pendiente)'),
      ),
    );
  }
}

// ====== Tarjeta ======
class _TarjetaCerda extends StatelessWidget {
  final Cerda cerda;
  final VoidCallback onEditar;
  final VoidCallback onBaja;
  final VoidCallback onHistorial;

  const _TarjetaCerda({
    required this.cerda,
    required this.onEditar,
    required this.onBaja,
    required this.onHistorial,
  });

  Color get _colorEstado {
    switch (cerda.estado) {
      case 'Gestante':
        return kVerde;
      case 'Celo':
        return const Color(0xFFB07A4A);
      default:
        return Colors.grey;
    }
  }

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
            _dato('ID cerda', '${cerda.numero}'),
            _dato('Num. Arete', cerda.arete),
            _dato('Raza', cerda.raza),
            _dato('Color', cerda.color),
            _dato('Edad', '${cerda.edad} años'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Text(
                    'Estado reproductivo: ',
                    style: TextStyle(fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _colorEstado,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cerda.estado,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _dato('Fecha de registro', cerda.fechaTexto),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _boton('Ver historial', Icons.visibility, kAzul, onHistorial),
                _boton('Editar', Icons.edit, kVerde, onEditar),
                _boton('Dar de baja', null, kRosa, onBaja),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ====== Formulario: Registro / Edición ======
class _FormularioCerda extends StatefulWidget {
  final Cerda? cerda;
  final List<String> aretesUsados;

  const _FormularioCerda({this.cerda, required this.aretesUsados});

  @override
  State<_FormularioCerda> createState() => _FormularioCerdaState();
}

class _FormularioCerdaState extends State<_FormularioCerda> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _arete;
  String? _raza;
  String? _color;
  late int _edad;
  late String _estado;

  bool get _editando => widget.cerda != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cerda;
    _arete = TextEditingController(text: c?.arete ?? '');
    _raza = c?.raza;
    _color = c?.color;
    _edad = c?.edad ?? 1;
    _estado = c?.estado ?? 'Celo';
  }

  @override
  void dispose() {
    _arete.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      Cerda(
        id: widget.cerda?.id ?? '', // el id real lo genera Supabase
        numero: widget.cerda?.numero ?? 0, // el número lo genera Supabase
        arete: _arete.text.trim(),
        raza: _raza!,
        color: _color!,
        edad: _edad,
        estado: _estado,
        fechaRegistro: widget.cerda?.fechaRegistro ?? DateTime.now(),
      ),
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
                    ? 'Editar información de cerda'
                    : 'Registro de nueva cerda',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Capture los datos básicos de la cerda'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _arete,
                decoration: const InputDecoration(
                  labelText: 'Número de Arete de la cerda',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Ingresa el número de arete';
                  if (widget.aretesUsados.contains(t)) {
                    return 'Ese arete ya está registrado';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _raza,
                decoration: const InputDecoration(
                  labelText: 'Raza',
                  border: OutlineInputBorder(),
                ),
                items: razas
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _raza = v),
                validator: (v) => v == null ? 'Selecciona la raza' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _color,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                ),
                items: colores
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _color = v),
                validator: (v) => v == null ? 'Selecciona el color' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _estado,
                decoration: const InputDecoration(
                  labelText: 'Estado reproductivo',
                  border: OutlineInputBorder(),
                ),
                items: estados
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _estado = v!),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Edad (años):', style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    onPressed: _edad > 0 ? () => setState(() => _edad--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_edad',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _edad++),
                    icon: const Icon(Icons.add_circle, color: kVerde),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: _guardar,
                    icon: const Icon(Icons.add),
                    label: Text(_editando ? 'Guardar' : 'Registrar cerda'),
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