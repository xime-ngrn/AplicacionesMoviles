import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../modelos/entrada_archivo.dart';
import 'fuente_archivos.dart';

/// Caché de miniaturas de imágenes en dos niveles:
/// 1. Memoria: inmediata, se pierde al cerrar la app (máximo [_maxMemoria] imágenes).
/// 2. Disco: carpeta de caché de la app (Android: getCacheDir, iOS: Library/Caches).
///    El sistema puede vaciarla si falta espacio; entonces simplemente se regeneran.
/// La clave incluye tamaño y fecha: si la imagen cambia, se genera una miniatura nueva.
class CacheMiniaturas {
  CacheMiniaturas._();

  static final instancia = CacheMiniaturas._();

  static const _lado = 160; // ancho de la miniatura en píxeles
  static const _maxMemoria = 150;
  static const _maxBytesOriginal = 30 * 1024 * 1024; // no se intentan imágenes enormes

  /// Mapa ordenado por uso: al leer se mueve al final, y se descarta el primero (LRU).
  final _memoria = <String, Uint8List>{};
  final _enCurso = <String, Future<Uint8List?>>{};
  Directory? _carpeta;

  /// Miniatura PNG de una imagen, o null si no se pudo generar (se muestra el icono).
  Future<Uint8List?> obtener(FuenteArchivos fuente, EntradaArchivo e) {
    final clave = _clave(e);
    final enMemoria = _memoria.remove(clave);
    if (enMemoria != null) {
      _memoria[clave] = enMemoria;
      return SynchronousFuture(enMemoria);
    }
    // Si la misma miniatura ya se está generando, se comparte ese trabajo.
    return _enCurso.putIfAbsent(
        clave, () => _generar(fuente, e, clave).whenComplete(() => _enCurso.remove(clave)));
  }

  /// Número de miniaturas y bytes ocupados en disco.
  Future<(int, int)> estadisticas() async {
    try {
      final carpeta = await _obtenerCarpeta();
      var cantidad = 0, bytes = 0;
      await for (final f in carpeta.list()) {
        if (f is File) {
          cantidad++;
          bytes += await f.length();
        }
      }
      return (cantidad, bytes);
    } catch (_) {
      return (0, 0);
    }
  }

  Future<void> limpiar() async {
    _memoria.clear();
    final carpeta = await _obtenerCarpeta();
    if (await carpeta.exists()) await carpeta.delete(recursive: true);
    _carpeta = null;
  }

  Future<Uint8List?> _generar(FuenteArchivos fuente, EntradaArchivo e, String clave) async {
    try {
      final archivo = File(p.join((await _obtenerCarpeta()).path, '$clave.png'));
      final Uint8List datos;
      if (await archivo.exists()) {
        datos = await archivo.readAsBytes(); // acierto en disco
      } else {
        if ((e.tamano ?? 0) > _maxBytesOriginal) return null;
        final original = await fuente.leerBytes(e);
        // Se decodifica ya reducida: no se carga la imagen completa en memoria.
        final codec = await ui.instantiateImageCodec(original, targetWidth: _lado);
        final cuadro = await codec.getNextFrame();
        final png = await cuadro.image.toByteData(format: ui.ImageByteFormat.png);
        cuadro.image.dispose();
        codec.dispose();
        if (png == null) return null;
        datos = png.buffer.asUint8List();
        await archivo.writeAsBytes(datos);
      }
      _memoria[clave] = datos;
      if (_memoria.length > _maxMemoria) _memoria.remove(_memoria.keys.first);
      return datos;
    } catch (err) {
      debugPrint('Sin miniatura para ${e.nombre}: $err');
      return null; // imagen dañada o sin acceso: se muestra el icono normal
    }
  }

  Future<Directory> _obtenerCarpeta() async {
    final existente = _carpeta;
    if (existente != null) return existente;
    final cache = await getTemporaryDirectory();
    return _carpeta = await Directory(p.join(cache.path, 'miniaturas')).create(recursive: true);
  }

  /// Nombre de archivo estable a partir de fuente, id, tamaño y fecha (dos hash FNV-1a de 32 bits).
  String _clave(EntradaArchivo e) {
    final texto = '${e.fuenteId}|${e.id}|${e.tamano}|${e.modificado?.millisecondsSinceEpoch}';
    int fnv(Iterable<int> unidades) {
      var h = 0x811c9dc5;
      for (final u in unidades) {
        h = ((h ^ u) * 0x01000193) & 0xFFFFFFFF;
      }
      return h;
    }

    final unidades = texto.codeUnits;
    return '${fnv(unidades).toRadixString(16)}${fnv(unidades.reversed).toRadixString(16)}';
  }
}
