import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../app/efectos.dart';
import '../app/opciones.dart';
import '../juego/archivos/repositorio.dart';
import '../juego/archivos/serializador.dart';
import '../juego/modelo.dart';
import '../juego/motor.dart';
import '../utils/formato.dart';
import '../visores/acciones_sistema.dart';
import '../visores/visor_codigo.dart';
import '../widgets/dialogos.dart';
import '../widgets/estado_mensaje.dart';
import 'bitacora.dart';
import 'juego.dart';

/// "Partidas guardadas": lista los archivos de partida con sus metadatos y permite
/// continuar, ver el contenido, leer la bitácora, renombrar, poner etiquetas,
/// exportar (en cualquier formato), compartir, importar y eliminar.
class PantallaPartidas extends StatefulWidget {
  const PantallaPartidas({super.key, required this.efectos, required this.repositorio});

  final Efectos efectos;
  final RepositorioPartidas repositorio;

  @override
  State<PantallaPartidas> createState() => _PantallaPartidasState();
}

enum _Accion { continuar, contenido, bitacora, renombrar, etiquetas, exportar, compartir, eliminar }

class _PantallaPartidasState extends State<PantallaPartidas> {
  late Future<List<ResumenPartida>> _lista = widget.repositorio.listar();

  RepositorioPartidas get _repo => widget.repositorio;

  void _recargar() => setState(() => _lista = _repo.listar());

  void _avisar(String mensaje) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensaje)));

  // ------------------------------------------------------------------ Importar

  Future<void> _importar() async {
    widget.efectos.reproducir(Sonido.clic);
    final elegido = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json', 'xml', 'txt'],
    );
    if (elegido == null) return; // canceló
    final bytes = await elegido.readAsBytes();
    if (!mounted) return;
    try {
      final partida = await _repo.importar(bytes, elegido.name);
      widget.efectos.reproducir(Sonido.pista);
      _avisar('Se importó «${partida.nombre}».');
      _recargar();
    } on ErrorPartida catch (e) {
      // Archivo vacío, dañado o que no es una partida: se explica qué tiene mal.
      widget.efectos.reproducir(Sonido.error);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.error_outline),
          title: const Text('No se pudo importar'),
          content: Text('«${elegido.name}»\n\n${e.mensaje}'),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
          ],
        ),
      );
    }
  }

  // ------------------------------------------------------------------ Acciones

  Future<void> _acciones(ResumenPartida r, BuildContext contextoTarjeta) async {
    widget.efectos.reproducir(Sonido.clic);
    final p = r.partida;
    final origen = origenDe(contextoTarjeta); // para la hoja de compartir en iPad
    final accion = await showModalBottomSheet<_Accion>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        ListTile opcion(_Accion a, IconData icono, String texto, {Color? color}) => ListTile(
              leading: Icon(icono, color: color),
              title: Text(texto, style: TextStyle(color: color)),
              onTap: () => Navigator.pop(context, a),
            );
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(p?.nombre ?? r.nombreArchivo,
                    style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text(r.nombreArchivo),
              ),
              if (p != null && !p.terminada)
                opcion(_Accion.continuar, Icons.play_arrow, 'Continuar la partida'),
              opcion(_Accion.contenido, Icons.code, 'Ver el contenido del archivo'),
              if (p != null) ...[
                opcion(_Accion.bitacora, Icons.menu_book, 'Leer la bitácora'),
                opcion(_Accion.renombrar, Icons.edit, 'Renombrar'),
                opcion(_Accion.etiquetas, Icons.label_outline, 'Etiquetas'),
                opcion(_Accion.exportar, Icons.save_alt, 'Exportar una copia (JSON, XML o TXT)'),
              ],
              opcion(_Accion.compartir, Icons.share, 'Compartir'),
              opcion(_Accion.eliminar, Icons.delete_outline, 'Eliminar',
                  color: Theme.of(context).colorScheme.error),
            ],
          ),
        );
      },
    );
    if (accion == null || !mounted) return;

    switch (accion) {
      case _Accion.continuar:
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => PantallaJuego(
            motor: MotorJuego(p!),
            efectos: widget.efectos,
            repositorio: _repo,
          ),
        ));
        _recargar(); // al volver, la lista muestra el avance
      case _Accion.contenido:
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => _PantallaContenido(resumen: r, repositorio: _repo),
        ));
      case _Accion.bitacora:
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => PantallaBitacora(partida: p!),
        ));
      case _Accion.renombrar:
        final nombre = await pedirNombre(
          context,
          titulo: 'Renombrar partida',
          boton: 'Guardar',
          inicial: p!.nombre,
        );
        if (nombre == null) return;
        p.nombre = nombre.trim();
        await _repo.guardar(p, formato: r.formato); // conserva el formato de su archivo
        _recargar();
      case _Accion.etiquetas:
        final etiquetas = await showDialog<List<String>>(
          context: context,
          builder: (_) => _DialogoEtiquetas(actuales: p!.etiquetas),
        );
        if (etiquetas == null) return;
        p!.etiquetas = etiquetas;
        await _repo.guardar(p, formato: r.formato);
        _recargar();
      case _Accion.exportar:
        await _exportar(p!);
      case _Accion.compartir:
        await compartirArchivo(r.archivo.path, mime: _mime(r.formato), origen: origen);
      case _Accion.eliminar:
        final seguro = await confirmar(
          context,
          titulo: '¿Eliminar «${p?.nombre ?? r.nombreArchivo}»?',
          mensaje: 'Se borrará el archivo ${r.nombreArchivo}. No se puede deshacer.',
          boton: 'Eliminar',
          destructivo: true,
        );
        if (!seguro) return;
        await _repo.eliminar(r);
        _avisar('Partida eliminada.');
        _recargar();
    }
  }

  /// Exporta una copia en el formato que se elija: así una partida guardada en
  /// JSON se puede sacar también como XML o como bitácora TXT.
  Future<void> _exportar(EstadoPartida p) async {
    final formato = await showDialog<FormatoGuardado>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('¿En qué formato?'),
        children: [
          for (final f in FormatoGuardado.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, f),
              child: Text(f.etiqueta),
            ),
        ],
      ),
    );
    if (formato == null) return;
    final bytes = Uint8List.fromList(utf8.encode(formato.serializador.escribir(p)));
    final guardado =
        await exportarBytes('${p.nombre}.${formato.extension}', bytes, mime: _mime(formato));
    if (guardado && mounted) _avisar('Copia exportada en ${formato.etiqueta}.');
  }

  static String _mime(FormatoGuardado f) => switch (f) {
        FormatoGuardado.json => 'application/json',
        FormatoGuardado.xml => 'application/xml',
        FormatoGuardado.txt => 'text/plain',
      };

  // --------------------------------------------------------------------- Vista

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partidas guardadas'),
        actions: [
          IconButton(
            tooltip: 'Importar partida',
            onPressed: _importar,
            icon: const Icon(Icons.file_open),
          ),
        ],
      ),
      body: FutureBuilder<List<ResumenPartida>>(
        future: _lista,
        builder: (context, estado) {
          if (estado.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (estado.hasError) {
            return EstadoMensaje(
              icono: Icons.error_outline,
              titulo: 'No se pudo leer la carpeta de partidas',
              mensaje: '${estado.error}',
            );
          }
          final lista = estado.data!;
          if (lista.isEmpty) {
            return EstadoMensaje(
              icono: Icons.folder_off_outlined,
              titulo: 'Todavía no hay partidas guardadas',
              mensaje: 'Empieza una nueva partida o importa un archivo .json, .xml o .txt.',
              accion: FilledButton.icon(
                onPressed: _importar,
                icon: const Icon(Icons.file_open),
                label: const Text('Importar partida'),
              ),
            );
          }
          final danadas = lista.where((r) => r.danada).length;
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: lista.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                    child: Text(
                      '${lista.length} ${lista.length == 1 ? 'partida' : 'partidas'}'
                      '${danadas > 0 ? ' · $danadas dañada${danadas == 1 ? '' : 's'}' : ''}'
                      ' · las nuevas se guardan en ${_repo.formatoActual.etiqueta}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                final r = lista[i - 1];
                return Builder(
                  builder: (contextoTarjeta) => _TarjetaPartida(
                    resumen: r,
                    alTocar: () => _acciones(r, contextoTarjeta),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------ Tarjeta de partida

class _TarjetaPartida extends StatelessWidget {
  const _TarjetaPartida({required this.resumen, required this.alTocar});

  final ResumenPartida resumen;
  final VoidCallback alTocar;

  static IconData _icono(FormatoGuardado f) => switch (f) {
        FormatoGuardado.json => Icons.data_object,
        FormatoGuardado.xml => Icons.code,
        FormatoGuardado.txt => Icons.description_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final r = resumen;
    final p = r.partida;
    final estado = p == null
        ? null
        : !p.terminada
            ? 'En curso'
            : p.resuelta
                ? 'Resuelta'
                : 'Sin resolver';
    return Card(
      child: ListTile(
        onTap: alTocar,
        leading: Icon(
          r.danada ? Icons.broken_image_outlined : _icono(r.formato),
          color: r.danada ? tema.colorScheme.error : tema.colorScheme.primary,
        ),
        title: Text(p?.nombre ?? r.nombreArchivo),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadatos del archivo
            Text('${formatoFecha(r.fecha)} · ${r.formato.name.toUpperCase()} · '
                '${formatoTamano(r.tamano)}'),
            if (p != null)
              Text('$estado · Noche ${p.nivel}, ${p.hora} · ${p.puntuacion} puntos · '
                  '${p.dificultad.etiqueta}'),
            if (r.error != null)
              Text('Archivo dañado: ${r.error}', style: TextStyle(color: tema.colorScheme.error)),
            if (p != null && p.etiquetas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final e in p.etiquetas)
                      Chip(
                        label: Text(e),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.more_vert),
      ),
    );
  }
}

// ------------------------------------------------------- Contenido del archivo

/// Muestra el archivo tal cual está guardado, con colores para JSON y XML.
class _PantallaContenido extends StatelessWidget {
  const _PantallaContenido({required this.resumen, required this.repositorio});

  final ResumenPartida resumen;
  final RepositorioPartidas repositorio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(resumen.nombreArchivo)),
      body: FutureBuilder<String>(
        future: repositorio.leerTexto(resumen),
        builder: (context, estado) {
          if (!estado.hasData) return const Center(child: CircularProgressIndicator());
          return VisorCodigo(
            codigo: estado.data!,
            lenguaje: switch (resumen.formato) {
              FormatoGuardado.json => LenguajeCodigo.json,
              FormatoGuardado.xml => LenguajeCodigo.xml,
              FormatoGuardado.txt => LenguajeCodigo.texto,
            },
            ajustarLineas: resumen.formato == FormatoGuardado.txt,
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------------- Etiquetas

class _DialogoEtiquetas extends StatefulWidget {
  const _DialogoEtiquetas({required this.actuales});

  final List<String> actuales;

  @override
  State<_DialogoEtiquetas> createState() => _DialogoEtiquetasState();
}

class _DialogoEtiquetasState extends State<_DialogoEtiquetas> {
  static const _sugeridas = ['Favorita', 'Para el reporte', 'Difícil', 'Rápida'];

  late final Set<String> _elegidas = {...widget.actuales};
  final _nueva = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nueva.dispose();
    super.dispose();
  }

  void _agregar() {
    final texto = _nueva.text.trim();
    if (texto.isEmpty) return;
    setState(() {
      // Sin comas: en el archivo TXT las etiquetas se separan con comas.
      _error = texto.contains(',') ? 'No uses comas.' : null;
      if (_error == null) {
        _elegidas.add(texto);
        _nueva.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Etiquetas'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in {..._sugeridas, ..._elegidas})
                  FilterChip(
                    label: Text(e),
                    selected: _elegidas.contains(e),
                    onSelected: (si) => setState(() {
                      if (si) {
                        _elegidas.add(e);
                      } else {
                        _elegidas.remove(e);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nueva,
              maxLength: 20,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nueva etiqueta',
                errorText: _error,
                suffixIcon: IconButton(onPressed: _agregar, icon: const Icon(Icons.add)),
              ),
              onSubmitted: (_) => _agregar(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _elegidas.toList()),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
