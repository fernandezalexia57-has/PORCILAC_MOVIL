
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ====== COLORES PORCILAC ======
const kRosa = Color(0xFFE8628C);
const kVerde = Color(0xFF4CAF7A);
const kAzul = Color(0xFF3B5B8C);

// ======================================================
// MODELO DE CERDA
// ======================================================

class CerdaDestete {
  final String id;
  final int numero;
  final String arete;

  CerdaDestete({
    required this.id,
    required this.numero,
    required this.arete,
  });

  factory CerdaDestete.fromMap(Map<String, dynamic> m) {
    final n = m['numero'];

    return CerdaDestete(
      id: (m['id'] ?? '').toString(),
      numero: n is num
          ? n.toInt()
          : int.tryParse(n?.toString() ?? '') ?? 0,
      arete: (m['numero_arete'] ?? '').toString(),
    );
  }
}

// ======================================================
// MODELO DE DESTETE
// ======================================================

class Destete {
  final String id;
  final String cerdaId;
  final int numero;
  final String arete;
  final DateTime fecha;
  final int numLechones;
  final double pesoPromedio;

  Destete({
    required this.id,
    required this.cerdaId,
    required this.numero,
    required this.arete,
    required this.fecha,
    required this.numLechones,
    required this.pesoPromedio,
  });

  factory Destete.fromMap(
    Map<String, dynamic> m,
    Map<String, CerdaDestete> cerdas,
  ) {
    final cerdaId = (m['cerda_id'] ?? '').toString();
    final cerda = cerdas[cerdaId];

    final lechones = m['num_lechones'];
    final peso = m['peso_promedio'];

    return Destete(
      id: (m['id'] ?? '').toString(),
      cerdaId: cerdaId,
      numero: cerda?.numero ?? 0,
      arete: (m['numero_arete'] ?? cerda?.arete ?? '').toString(),
      fecha: DateTime.tryParse(
            (m['fecha_destete'] ?? '').toString(),
          ) ??
          DateTime.now(),
      numLechones: lechones is num
          ? lechones.toInt()
          : int.tryParse(lechones?.toString() ?? '') ?? 0,
      pesoPromedio: peso is num
          ? peso.toDouble()
          : double.tryParse(peso?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'cerda_id': cerdaId,
        'numero_arete': arete,
        'fecha_destete': fecha.toIso8601String().split('T').first,
        'num_lechones': numLechones,
        'peso_promedio': pesoPromedio,
      };

  String get fechaTexto =>
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/'
      '${fecha.year}';
}

// ======================================================
// PANTALLA PRINCIPAL
// ======================================================

class ScreenDestete extends StatefulWidget {
  const ScreenDestete({super.key});

  @override
  State<ScreenDestete> createState() => _ScreenDesteteState();
}

class _ScreenDesteteState extends State<ScreenDestete> {
  final _db = Supabase.instance.client;

  List<CerdaDestete> _cerdas = [];
  List<Destete> _destetes = [];

  bool _cargando = true;
  String? _errorCarga;

  String _busqueda = '';
  String _tipoFiltro = 'Todos';

  DateTime? _fechaFiltro;
  String _areteFiltro = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // ====================================================
  // FILTRAR DESTETES
  // ====================================================

  List<Destete> get _filtrados {
    final q = _busqueda.toLowerCase().trim();

    return _destetes.where((d) {
      if (_tipoFiltro == 'Fecha') {
        if (_fechaFiltro == null) return false;

        if (d.fecha.year != _fechaFiltro!.year ||
            d.fecha.month != _fechaFiltro!.month ||
            d.fecha.day != _fechaFiltro!.day) {
          return false;
        }
      }

      if (_tipoFiltro == 'Arete') {
        if (!d.arete.toLowerCase().contains(
          _areteFiltro.toLowerCase(),
        )) {
          return false;
        }
      }

      return q.isEmpty ||
          d.numero.toString().contains(q) ||
          d.arete.toLowerCase().contains(q) ||
          d.numLechones.toString().contains(q);
    }).toList();
  }

  // ====================================================
  // CARGAR DATOS
  // ====================================================

  Future<void> _cargar() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _errorCarga = null;
    });

    try {
      final datosCerdas = await _db
          .from('cerdas')
          .select('id, numero, numero_arete')
          .order('numero');

      final cerdas = datosCerdas
          .map((e) => CerdaDestete.fromMap(e))
          .toList();

      final mapaCerdas = {
        for (final c in cerdas) c.id: c,
      };

      final datosDestetes = await _db
          .from('destetes')
          .select()
          .order('fecha_destete', ascending: false);

      final destetes = datosDestetes
          .map((e) => Destete.fromMap(e, mapaCerdas))
          .toList();

      if (!mounted) return;

      setState(() {
        _cerdas = cerdas;
        _destetes = destetes;
        _cargando = false;
      });
    } on PostgrestException catch (e) {
      debugPrint('ERROR SUPABASE: ${e.message}');
      debugPrint('DETALLES: ${e.details}');
      debugPrint('CÓDIGO: ${e.code}');

      if (!mounted) return;

      setState(() {
        _cargando = false;
        _errorCarga = e.message;
      });
    } catch (e) {
      debugPrint('ERROR AL CARGAR: $e');

      if (!mounted) return;

      setState(() {
        _cargando = false;
        _errorCarga = e.toString();
      });
    }
  }

  // ====================================================
  // ABRIR FORMULARIO
  // ====================================================

  Future<void> _abrirFormulario({Destete? destete}) async {
    final resultado = await showDialog<Destete>(
      context: context,
      builder: (_) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _FormularioDestete(
            cerdas: _cerdas,
            destete: destete,
          ),
        ),
      ),
    );

    if (resultado == null || !mounted) return;

    try {
      if (destete == null) {
        await _db.from('destetes').insert(resultado.toMap());
      } else {
        await _db
            .from('destetes')
            .update(resultado.toMap())
            .eq('id', destete.id);
      }

      await _cargar();

      if (!mounted) return;

      _mensaje(
        destete == null
            ? 'Destete registrado correctamente'
            : 'Destete actualizado correctamente',
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _mensaje('Error al guardar: ${e.message}', error: true);
    } catch (e) {
      if (!mounted) return;
      _mensaje('Error al guardar: $e', error: true);
    }
  }

  // ====================================================
  // ELIMINAR
  // ====================================================

  Future<void> _eliminar(Destete d) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar destete'),
        content: Text(
          '¿Deseas eliminar el registro de destete '
          'de la cerda con arete ${d.arete}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: kRosa),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _db.from('destetes').delete().eq('id', d.id);

      await _cargar();

      if (!mounted) return;

      _mensaje('Destete eliminado correctamente');
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _mensaje('Error al eliminar: ${e.message}', error: true);
    } catch (e) {
      if (!mounted) return;
      _mensaje('Error al eliminar: $e', error: true);
    }
  }

  // ====================================================
  // MENSAJES
  // ====================================================

  void _mensaje(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          texto,
          style: const TextStyle(color: Colors.black87),
        ),
        backgroundColor: error
            ? const Color(0xFFF4A9A9)
            : const Color(0xFF9FEFBF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ====================================================
  // BUILD
  // ====================================================

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
        label: const Text('Nuevo destete'),
      ),

      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Destete',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black87,
              ),
            ),
          ),

          // ==============================================
          // BUSCADOR Y FILTRO EN UNA MISMA FILA
          // ==============================================

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                // BUSCADOR
                Expanded(
                  flex: 2,
                  child: TextField(
                    onChanged: (v) {
                      setState(() => _busqueda = v);
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar destete',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // FILTRO
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _tipoFiltro,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Filtrar',
                    
                    
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: ['Todos', 'Fecha', 'Arete']
                        .map(
                          (tipo) => DropdownMenuItem(
                            value: tipo,
                            child: Text(
                              tipo,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      if (valor == null) return;

                      setState(() {
                        _tipoFiltro = valor;
                        _fechaFiltro = null;
                        _areteFiltro = '';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // ==============================================
          // FILTRO POR FECHA
          // ==============================================

          if (_tipoFiltro == 'Fecha')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(
                    Icons.calendar_month,
                    color: kRosa,
                  ),
                  label: Text(
                    _fechaFiltro == null
                        ? 'Seleccionar fecha de destete'
                        : '${_fechaFiltro!.day.toString().padLeft(2, '0')}/'
                            '${_fechaFiltro!.month.toString().padLeft(2, '0')}/'
                            '${_fechaFiltro!.year}',
                  ),
                  onPressed: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (fecha != null) {
                      setState(() {
                        _fechaFiltro = fecha;
                      });
                    }
                  },
                ),
              ),
            ),

          // ==============================================
          // FILTRO POR ARETE
          // ==============================================

          if (_tipoFiltro == 'Arete')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (valor) {
                  setState(() {
                    _areteFiltro = valor;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Número de arete',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),
          const Divider(),

          Expanded(
            child: _contenido(lista),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // CONTENIDO
  // ====================================================

  Widget _contenido(List<Destete> lista) {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: kRosa),
      );
    }

    if (_errorCarga != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorCarga!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _cargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (lista.isEmpty) {
      return const Center(
        child: Text('No hay destetes registrados'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: lista.length,
      itemBuilder: (_, i) {
        final d = lista[i];

        return _TarjetaDestete(
          destete: d,
          onEditar: () => _abrirFormulario(destete: d),
          onEliminar: () => _eliminar(d),
        );
      },
    );
  }
}

// ======================================================
// TARJETA DE DESTETE
// ======================================================

class _TarjetaDestete extends StatelessWidget {
  final Destete destete;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _TarjetaDestete({
    required this.destete,
    required this.onEditar,
    required this.onEliminar,
  });

  Widget _dato(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        '$etiqueta: $valor',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _boton(
    String texto,
    IconData icono,
    Color color,
    VoidCallback funcion,
  ) {
    return ElevatedButton.icon(
      onPressed: funcion,
      icon: Icon(icono, size: 16),
      label: Text(texto),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dato('Número de arete', destete.arete),
            _dato('Fecha de destete', destete.fechaTexto),
            _dato('Número de lechones', '${destete.numLechones}'),
            _dato(
              'Peso promedio',
              '${destete.pesoPromedio.toStringAsFixed(2)} kg',
            ),

            const SizedBox(height: 10),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
               Center(child: _boton(
                  'Editar',
                  Icons.edit,
                  kVerde,
                  onEditar,
                ),) 


              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// FORMULARIO DE DESTETE
// ======================================================

class _FormularioDestete extends StatefulWidget {
  final List<CerdaDestete> cerdas;
  final Destete? destete;

  const _FormularioDestete({
    required this.cerdas,
    this.destete,
  });

  @override
  State<_FormularioDestete> createState() =>
      _FormularioDesteteState();
}

class _FormularioDesteteState extends State<_FormularioDestete> {
  final _formKey = GlobalKey<FormState>();

  final _lechonesController = TextEditingController();
  final _pesoController = TextEditingController();

  String? _cerdaId;
  late DateTime _fecha;

  bool get _editando => widget.destete != null;

  @override
  void initState() {
    super.initState();

    final d = widget.destete;

    _cerdaId = d?.cerdaId;
    _fecha = d?.fecha ?? DateTime.now();

    _lechonesController.text = d?.numLechones.toString() ?? '';
    _pesoController.text = d?.pesoPromedio.toString() ?? '';
  }

  @override
  void dispose() {
    _lechonesController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  // ====================================================
  // SELECCIONAR CERDA
  // ====================================================

  Future<void> _seleccionarCerda() async {
    if (widget.cerdas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontraron cerdas en la tabla cerdas.'),
        ),
      );
      return;
    }

    final seleccionada = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.65,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Seleccionar cerda',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: widget.cerdas.length,
                    itemBuilder: (_, i) {
                      final c = widget.cerdas[i];

                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFCE4EC),

                        ),
                        title: Text('Cerda ${c.numero}'),
                        subtitle: Text('Arete: ${c.arete}'),
                        trailing: _cerdaId == c.id
                            ? const Icon(
                                Icons.check_circle,
                                color: kVerde,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(sheetContext, c.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    if (seleccionada != null) {
      setState(() => _cerdaId = seleccionada);
    }
  }

  // ====================================================
  // SELECCIONAR FECHA
  // ====================================================

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted) return;

    if (fecha != null) {
      setState(() => _fecha = fecha);
    }
  }

  // ====================================================
  // GUARDAR
  // ====================================================

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    if (_cerdaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una cerda'),
        ),
      );
      return;
    }

    final cerdas = widget.cerdas.where((c) => c.id == _cerdaId);

    CerdaDestete? cerda;

    if (cerdas.isNotEmpty) {
      cerda = cerdas.first;
    } else if (widget.destete != null &&
        widget.destete!.cerdaId == _cerdaId) {
      final d = widget.destete!;

      cerda = CerdaDestete(
        id: d.cerdaId,
        numero: d.numero,
        arete: d.arete,
      );
    }

    if (cerda == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró la cerda seleccionada'),
        ),
      );
      return;
    }

    final lechones = int.tryParse(_lechonesController.text.trim());

    final peso = double.tryParse(
      _pesoController.text.trim().replaceAll(',', '.'),
    );

    if (lechones == null || peso == null) return;

    final resultado = Destete(
      id: widget.destete?.id ?? '',
      cerdaId: cerda.id,
      numero: cerda.numero,
      arete: cerda.arete,
      fecha: _fecha,
      numLechones: lechones,
      pesoPromedio: peso,
    );

    Navigator.pop(context, resultado);
  }

  // ====================================================
  // BUILD FORMULARIO
  // ====================================================

  @override
  Widget build(BuildContext context) {
    final cerdasDisponibles = [...widget.cerdas];

    if (widget.destete != null &&
        !cerdasDisponibles.any(
          (c) => c.id == widget.destete!.cerdaId,
        )) {
      cerdasDisponibles.add(
        CerdaDestete(
          id: widget.destete!.cerdaId,
          numero: widget.destete!.numero,
          arete: widget.destete!.arete,
        ),
      );
    }

    CerdaDestete? seleccionada;

    for (final c in cerdasDisponibles) {
      if (c.id == _cerdaId) {
        seleccionada = c;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  _editando ? 'Editar destete' : 'Registro destete',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text('Capture los datos básicos del destete'),
              ),

              const SizedBox(height: 20),

              // CERDA

              InkWell(
                onTap: _seleccionarCerda,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Número de arete de la cerda',
                    border: OutlineInputBorder(),

                  ),
                  child: Text(
                    seleccionada == null
                        ? 'Seleccionar cerda'
                        : '${seleccionada.numero} - ${seleccionada.arete}',
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // FECHA

              InkWell(
                onTap: _seleccionarFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de destete',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  child: Text(
                    '${_fecha.year}-'
                    '${_fecha.month.toString().padLeft(2, '0')}-'
                    '${_fecha.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // NÚMERO DE LECHONES

              TextFormField(
                controller: _lechonesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de lechones',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa el número de lechones';
                  }

                  final numero = int.tryParse(valor.trim());

                  if (numero == null) {
                    return 'Ingresa un número entero válido';
                  }

                  if (numero < 0) {
                    return 'El número no puede ser negativo';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              // PESO PROMEDIO

              TextFormField(
                controller: _pesoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Peso promedio (kg)',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa el peso promedio';
                  }

                  final peso = double.tryParse(
                    valor.trim().replaceAll(',', '.'),
                  );

                  if (peso == null) {
                    return 'Ingresa un peso válido';
                  }

                  if (peso < 0) {
                    return 'El peso no puede ser negativo';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              // BOTONES

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kAzul,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _guardar,
                      icon: const Icon(Icons.save),
                      label: Text(
                        _editando ? 'Actualizar' : 'Registrar',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kRosa,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
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