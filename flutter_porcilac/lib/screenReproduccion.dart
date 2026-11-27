import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ====== Colores del diseño Porcilac ======
const kRosa = Color(0xFFE8628C);
const kVerde = Color(0xFF4CAF7A);


// ====== Opciones de reproducción ======
const tiposServicio = ['Monta natural', 'Inseminación'];

// ====== Modelo de cerda ======
class CerdaOption {
  final String id;
  final int numero;
  final String arete;
  final bool activa;

  CerdaOption({
    required this.id,
    required this.numero,
    required this.arete,
    required this.activa,
  });

  factory CerdaOption.fromMap(Map<String, dynamic> m) {
    final numero = m['numero'];

    return CerdaOption(
      id: (m['id'] ?? '').toString(),
      numero: numero is num
          ? numero.toInt()
          : int.tryParse(numero.toString()) ?? 0,
      arete: (m['numero_arete'] ?? '').toString(),
      activa: m['activa'] == true,
    );
  }
}

// ====== Modelo de reproducción ======
class Reproduccion {
  String id;
  String cerdaId;
  int numero;
  String arete;
  String tipo;
  DateTime fechaRegistro;

  Reproduccion({
    required this.id,
    required this.cerdaId,
    required this.numero,
    required this.arete,
    required this.tipo,
    required this.fechaRegistro,
  });

  factory Reproduccion.fromMap(
    Map<String, dynamic> m,
    Map<String, CerdaOption> cerdas,
  ) {
    final cerdaId = (m['cerda_id'] ?? '').toString();
    final cerda = cerdas[cerdaId];

    final fecha = DateTime.tryParse(
      (m['fecha_prenio'] ?? '').toString(),
    );

    return Reproduccion(
      id: (m['id'] ?? '').toString(),
      cerdaId: cerdaId,
      numero: cerda?.numero ?? 0,
      arete: (m['numero_arete'] ?? cerda?.arete ?? '').toString(),
      tipo: (m['tipo_servicio'] ?? 'Monta natural').toString(),
      fechaRegistro: fecha ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'cerda_id': cerdaId,
        'numero_arete': arete,
        'fecha_prenio':
            fechaRegistro.toIso8601String().split('T').first,
        'tipo_servicio': tipo,
      };

  String get fechaTexto =>
      '${fechaRegistro.day.toString().padLeft(2, '0')}/'
      '${fechaRegistro.month.toString().padLeft(2, '0')}/'
      '${fechaRegistro.year}';
}

// ======================================================
// PANTALLA PRINCIPAL
// ======================================================

class ScreenReproduccion extends StatefulWidget {
  const ScreenReproduccion({super.key});

  @override
  State<ScreenReproduccion> createState() =>
      _ScreenReproduccionState();
}

class _ScreenReproduccionState extends State<ScreenReproduccion> {
  final _db = Supabase.instance.client;

  List<CerdaOption> _cerdas = [];
  List<Reproduccion> _reproducciones = [];

  bool _cargando = true;
  String? _errorCarga;

  String _busqueda = '';
  String _filtro = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // ====== Buscar y filtrar ======
  List<Reproduccion> get _filtradas {
    return _reproducciones.where((r) {
      final q = _busqueda.toLowerCase();

      final coincide = q.isEmpty ||
          r.numero.toString().contains(q) ||
          r.arete.toLowerCase().contains(q);

      final tipoOk =
          _filtro == 'Todos' || r.tipo == _filtro;

      return coincide && tipoOk;
    }).toList();
  }

  // ====== Cargar datos de Supabase ======
Future<void> _cargar() async {
  if (!mounted) return;

  setState(() {
    _cargando = true;
    _errorCarga = null;
  });

  try {
    // 1. Cargar las cerdas
    final dataCerdas = await _db
        .from('cerdas')
        .select();

    final cerdas = (dataCerdas as List)
        .map((e) => CerdaOption.fromMap(
              e as Map<String, dynamic>,
            ))
        .toList();

    // Crear mapa para relacionar reproducciones con cerdas
    final mapaCerdas = {
      for (final c in cerdas) c.id: c,
    };

    // 2. Cargar las reproducciones
    final dataReproducciones = await _db
        .from('reproducciones')
        .select()
        .order('fecha_prenio', ascending: false);

    final reproducciones = (dataReproducciones as List)
        .map((e) => Reproduccion.fromMap(
              e as Map<String, dynamic>,
              mapaCerdas,
            ))
        .toList();

    // 3. Actualizar las dos listas
    if (!mounted) return;

    setState(() {
      _cerdas = cerdas;
      _reproducciones = reproducciones;
      _cargando = false;
    });

    debugPrint('CERDAS: ${_cerdas.length}');
    debugPrint('REPRODUCCIONES: ${_reproducciones.length}');

  } catch (e, stack) {
    debugPrint('ERROR AL CARGAR: $e');
    debugPrint('$stack');

    if (!mounted) return;

    setState(() {
      _cargando = false;
      _errorCarga = 'Error al cargar los registros: $e';
    });
  }
}
  // ====== Abrir formulario ======
  Future<void> _abrirFormulario({
    Reproduccion? reproduccion,
  }) async {
    final resultado = await showDialog<Reproduccion>(
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
          child: _FormularioReproduccion(
            cerdas: _cerdas,
            reproduccion: reproduccion,
          ),
        ),
      ),
    );

    if (resultado == null || !mounted) return;

    try {
      if (reproduccion == null) {
        await _db
            .from('reproducciones')
            .insert(resultado.toMap());
      } else {
        await _db
            .from('reproducciones')
            .update(resultado.toMap())
            .eq('id', reproduccion.id);
      }

      await _cargar();

      if (!mounted) return;

      _mensaje(
        reproduccion == null
            ? 'Reproducción registrada correctamente'
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


  // ====== Mensajes ======
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

  // ====== Construcción de pantalla ======
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
        label: const Text('Nueva reproducción'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Reproducción',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black87,
              ),
            ),
          ),

          // Buscador y filtro
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) {
                      setState(() => _busqueda = v);
                    },
                    decoration: InputDecoration(
                      hintText:
                          'Buscar reproducción (ID, Núm. Arete)',
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black54),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _filtro,
                      items: ['Todos', ...tiposServicio]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _filtro = v);
                        }
                      },
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

  // ====== Contenido de la lista ======
  Widget _contenido(List<Reproduccion> lista) {
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
      return const Center(
        child: Text('No hay registros'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: lista.length,
      itemBuilder: (_, i) => _TarjetaReproduccion(
        reproduccion: lista[i],
        onEditar: () {
          _abrirFormulario(reproduccion: lista[i]);
        },
     
      ),
    );
  }
}

// ======================================================
// TARJETA DE REPRODUCCIÓN
// ======================================================

class _TarjetaReproduccion extends StatelessWidget {
  final Reproduccion reproduccion;
  final VoidCallback onEditar;
 

  const _TarjetaReproduccion({
    required this.reproduccion,
    required this.onEditar,
   
  });

  Color get _colorTipo {
    switch (reproduccion.tipo) {
      case 'Monta natural':
        return kVerde;
      case 'Inseminación':
      default:
        return Colors.grey;
    }
  }

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
    IconData? icono,
    Color color,
    VoidCallback funcion,
  ) {
    return ElevatedButton.icon(
      onPressed: funcion,
      icon: icono != null
          ? Icon(icono, size: 16)
          : const SizedBox.shrink(),
      label: Text(texto),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
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
            _dato('ID cerda', '${reproduccion.numero}'),
            _dato('Num. Arete', reproduccion.arete),
            _dato('Fecha de servicio', reproduccion.fechaTexto),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Text(
                    'Tipo de servicio: ',
                    style: TextStyle(fontSize: 14),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _colorTipo,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        reproduccion.tipo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
              Center( child: _boton('Editar', Icons.edit, kVerde, onEditar)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// FORMULARIO DE REGISTRO Y EDICIÓN
// ======================================================

class _FormularioReproduccion extends StatefulWidget {
  final List<CerdaOption> cerdas;
  final Reproduccion? reproduccion;

  const _FormularioReproduccion({
    required this.cerdas,
    this.reproduccion,
  });

  @override
  State<_FormularioReproduccion> createState() =>
      _FormularioReproduccionState();
}

class _FormularioReproduccionState
    extends State<_FormularioReproduccion> {
  final _formKey = GlobalKey<FormState>();

  String? _cerdaId;
  String? _tipo;
  late DateTime _fecha;

  bool get _editando => widget.reproduccion != null;

  @override
  void initState() {
    super.initState();

    final r = widget.reproduccion;

    _cerdaId = r?.cerdaId;

    _tipo = tiposServicio.contains(r?.tipo)
        ? r!.tipo
        : tiposServicio.first;

    _fecha = r?.fechaRegistro ?? DateTime.now();
  }

  // ====== Selector de cerdas ======
  Future<void> _seleccionarCerda(
    List<CerdaOption> cerdasDisponibles,
  ) async {
    if (cerdasDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay cerdas activas disponibles. '
            'Revisa la tabla Cerdas en Supabase.',
          ),
        ),
      );
      return;
    }

    final seleccionada = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
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
                    itemCount: cerdasDisponibles.length,
                    itemBuilder: (context, index) {
                      final cerda = cerdasDisponibles[index];

                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFCE4EC),
                         
                        ),
                        title: Text('Cerda ${cerda.numero}'),
                        subtitle: Text('Arete: ${cerda.arete}'),
                        trailing: _cerdaId == cerda.id
                            ? const Icon(
                                Icons.check_circle,
                                color: kVerde,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(sheetContext, cerda.id);
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
      setState(() {
        _cerdaId = seleccionada;
      });
    }
  }

  // ====== Selector de fecha ======
  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted) return;

    if (fecha != null) {
      setState(() {
        _fecha = fecha;
      });
    }
  }

  // ====== Guardar ======
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

    final coincidencias = widget.cerdas.where(
      (c) => c.id == _cerdaId,
    );

    CerdaOption? cerda;

    if (coincidencias.isNotEmpty) {
      cerda = coincidencias.first;
    } else if (widget.reproduccion != null &&
        widget.reproduccion!.cerdaId == _cerdaId) {
      final r = widget.reproduccion!;

      cerda = CerdaOption(
        id: r.cerdaId,
        numero: r.numero,
        arete: r.arete,
        activa: false,
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

    final resultado = Reproduccion(
      id: widget.reproduccion?.id ?? '',
      cerdaId: cerda.id,
      numero: cerda.numero,
      arete: cerda.arete,
      tipo: _tipo ?? tiposServicio.first,
      fechaRegistro: _fecha,
    );

    Navigator.pop(context, resultado);
  }

  // ====== Construcción del formulario ======
  @override
  Widget build(BuildContext context) {
    final cerdasDisponibles = [...widget.cerdas];

    // Conservar una cerda antigua al editar
    if (widget.reproduccion != null &&
        !cerdasDisponibles.any(
          (c) => c.id == widget.reproduccion!.cerdaId,
        )) {
      final anterior = widget.reproduccion!;

      cerdasDisponibles.add(
        CerdaOption(
          id: anterior.cerdaId,
          numero: anterior.numero,
          arete: anterior.arete,
          activa: false,
        ),
      );
    }

    CerdaOption? cerdaSeleccionada;

    for (final c in cerdasDisponibles) {
      if (c.id == _cerdaId) {
        cerdaSeleccionada = c;
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
              Text(
                _editando
                    ? 'Editar reproducción'
                    : 'Registro de nueva reproducción',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Capture los datos del servicio reproductivo',
              ),

              const SizedBox(height: 16),

              // Selector de cerda
              InkWell(
                onTap: () {
                  _seleccionarCerda(cerdasDisponibles);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar cerda',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    cerdaSeleccionada == null
                        ? 'Toca para seleccionar una cerda'
                        : 'N° ${cerdaSeleccionada.numero} '
                            '- Arete ${cerdaSeleccionada.arete}',
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Tipo de servicio
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de servicio',
                  border: OutlineInputBorder(),
                ),
                items: tiposServicio
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _tipo = v;
                  });
                },
                validator: (v) {
                  return v == null
                      ? 'Selecciona el tipo de servicio'
                      : null;
                },
              ),

              const SizedBox(height: 14),

              // Fecha del servicio
              InkWell(
                onTap: _seleccionarFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha del servicio',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  child: Text(
                    '${_fecha.day.toString().padLeft(2, '0')}/'
                    '${_fecha.month.toString().padLeft(2, '0')}/'
                    '${_fecha.year}',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
                    label: Text(
                      _editando ? 'Guardar' : 'Registrar',
                    ),
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