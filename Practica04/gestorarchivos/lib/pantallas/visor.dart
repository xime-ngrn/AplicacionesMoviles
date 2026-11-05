import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../almacenamiento/fuente_archivos.dart';
import '../app/historial.dart';
import '../modelos/entrada_archivo.dart';
import '../utils/formato.dart';
import '../visores/acciones_archivo.dart';
import '../visores/visor_codigo.dart';
import '../widgets/estado_mensaje.dart';
import '../widgets/hoja_detalles.dart';

/// Abre un archivo: en el visor si el formato es compatible,
/// o con el diálogo de opciones del sistema si no lo es. Lo registra en recientes.
Future<void> abrirArchivo(
  BuildContext context, {
  required FuenteArchivos fuente,
  required EntradaArchivo entrada,
  required Historial historial,
}) async {
  unawaited(historial.registrarApertura(entrada));
  if (entrada.tipo == TipoArchivo.otro) {
    return mostrarOpcionesArchivo(context, fuente: fuente, entrada: entrada);
  }
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => PantallaVisor(fuente: fuente, entrada: entrada, historial: historial),
  ));
}

/// Visor de texto, JSON/XML con resaltado e imágenes con zoom y rotación.
class PantallaVisor extends StatefulWidget {
  const PantallaVisor({
    super.key,
    required this.fuente,
    required this.entrada,
    required this.historial,
  });

  final FuenteArchivos fuente;
  final EntradaArchivo entrada;
  final Historial historial;

  @override
  State<PantallaVisor> createState() => _PantallaVisorState();
}

enum _Opcion { detalles, abrirCon, compartir, exportar }

class _PantallaVisorState extends State<PantallaVisor> {
  /// Archivos de texto más grandes que esto se ofrecen para abrir con otra app.
  static const _maxTexto = 3 * 1024 * 1024;

  late Future<Uint8List> _datos;
  final _zoom = TransformationController();
  int _giros = 0; // cuartos de vuelta (0-3) de la imagen

  EntradaArchivo get _e => widget.entrada;

  @override
  void initState() {
    super.initState();
    _datos = widget.fuente.leerBytes(_e);
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _girar(int cuartos) {
    setState(() => _giros = (_giros + cuartos) % 4);
    _zoom.value = Matrix4.identity(); // al girar se quita el zoom
  }

  void _elegir(_Opcion opcion) {
    final accion = switch (opcion) {
      _Opcion.detalles => null,
      _Opcion.abrirCon => AccionArchivo.abrirCon,
      _Opcion.compartir => AccionArchivo.compartir,
      _Opcion.exportar => AccionArchivo.exportar,
    };
    if (accion == null) {
      mostrarDetalles(context, _e);
    } else {
      ejecutarAccion(context, accion, fuente: widget.fuente, entrada: _e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esImagen = _e.tipo == TipoArchivo.imagen;
    return Scaffold(
      appBar: AppBar(
        title: Text(_e.nombre, overflow: TextOverflow.ellipsis),
        actions: [
          if (esImagen) ...[
            IconButton(
              tooltip: 'Girar a la izquierda',
              icon: const Icon(Icons.rotate_left),
              onPressed: () => _girar(3),
            ),
            IconButton(
              tooltip: 'Girar a la derecha',
              icon: const Icon(Icons.rotate_right),
              onPressed: () => _girar(1),
            ),
          ],
          ListenableBuilder(
            listenable: widget.historial,
            builder: (context, _) {
              final favorito = widget.historial.esFavorito(_e);
              return IconButton(
                tooltip: favorito ? 'Quitar de favoritos' : 'Agregar a favoritos',
                icon: Icon(favorito ? Icons.star : Icons.star_border),
                onPressed: () => widget.historial.alternarFavorito(_e),
              );
            },
          ),
          PopupMenuButton<_Opcion>(
            onSelected: _elegir,
            itemBuilder: (context) => const [
              PopupMenuItem(value: _Opcion.detalles, child: Text('Detalles')),
              PopupMenuItem(value: _Opcion.abrirCon, child: Text('Abrir con otra app')),
              PopupMenuItem(value: _Opcion.compartir, child: Text('Compartir')),
              PopupMenuItem(value: _Opcion.exportar, child: Text('Exportar una copia…')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: _datos,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EstadoMensaje(
              icono: Icons.error_outline,
              titulo: 'No se pudo leer el archivo',
              mensaje: '${snap.error}',
              accion: FilledButton.tonal(
                onPressed: () => setState(() => _datos = widget.fuente.leerBytes(_e)),
                child: const Text('Reintentar'),
              ),
            );
          }
          return esImagen ? _imagen(snap.data!) : _texto(snap.data!);
        },
      ),
    );
  }

  // ------------------------------------------------------------------ Imagen

  Widget _imagen(Uint8List bytes) {
    final tema = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onDoubleTap: () => _zoom.value = Matrix4.identity(),
            child: InteractiveViewer(
              transformationController: _zoom,
              minScale: 0.5,
              maxScale: 8,
              child: Center(
                child: RotatedBox(
                  quarterTurns: _giros,
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined, size: 64, color: tema.colorScheme.outline),
                        const SizedBox(height: 8),
                        const Text('No se pudo mostrar la imagen: puede estar dañada.'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Pellizca para acercar · Doble toque para restablecer · ${formatoTamano(_e.tamano)}',
            style: tema.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------- Texto

  Widget _texto(Uint8List bytes) {
    if (bytes.length > _maxTexto) {
      return EstadoMensaje(
        icono: Icons.description_outlined,
        titulo: 'El archivo es demasiado grande para mostrarlo',
        mensaje: '${formatoTamano(bytes.length)}. Puedes abrirlo con otra app.',
        accion: FilledButton.tonal(
          onPressed: () => _elegir(_Opcion.abrirCon),
          child: const Text('Abrir con otra app'),
        ),
      );
    }
    var texto = utf8.decode(bytes, allowMalformed: true);
    if (texto.startsWith('﻿')) texto = texto.substring(1); // marca BOM
    if (texto.trim().isEmpty) {
      return const EstadoMensaje(icono: Icons.notes, titulo: 'El archivo está vacío');
    }

    // JSON y XML se formatean con sangría; si están dañados se avisa y se muestra el original.
    final (contenido, aviso) = switch (_e.tipo) {
      TipoArchivo.json => _formatearJson(texto),
      TipoArchivo.xml => _formatearXml(texto),
      _ => (texto, null),
    };
    final lenguaje = switch (_e.tipo) {
      TipoArchivo.json => LenguajeCodigo.json,
      TipoArchivo.xml => LenguajeCodigo.xml,
      _ => LenguajeCodigo.texto,
    };
    final colores = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (aviso != null)
          Material(
            color: colores.errorContainer,
            child: ListTile(
              leading: Icon(Icons.warning_amber, color: colores.onErrorContainer),
              title: Text(aviso, style: TextStyle(color: colores.onErrorContainer)),
            ),
          ),
        Expanded(
          child: VisorCodigo(
            codigo: contenido,
            lenguaje: lenguaje,
            ajustarLineas: lenguaje == LenguajeCodigo.texto,
          ),
        ),
      ],
    );
  }

  /// JSON con sangría; si es inválido, el texto original y la explicación del error.
  (String, String?) _formatearJson(String texto) {
    try {
      return (const JsonEncoder.withIndent('  ').convert(jsonDecode(texto)), null);
    } on FormatException catch (e) {
      return (texto, 'JSON inválido: ${e.message}. Se muestra el contenido original.');
    }
  }

  (String, String?) _formatearXml(String texto) {
    try {
      return (XmlDocument.parse(texto).toXmlString(pretty: true, indent: '  '), null);
    } on XmlException catch (e) {
      return (texto, 'XML inválido: ${e.message}. Se muestra el contenido original.');
    }
  }
}
