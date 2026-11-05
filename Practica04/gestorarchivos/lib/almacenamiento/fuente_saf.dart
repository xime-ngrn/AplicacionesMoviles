import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart';

import '../modelos/entrada_archivo.dart';
import 'errores.dart';
import 'fuente_archivos.dart';

/// Carpeta elegida por el usuario en Android con el Storage Access Framework (SAF).
/// No usa rutas ni permisos de almacenamiento: trabaja con URIs content:// que el
/// sistema autorizó solo para esa carpeta y su contenido (Scoped Storage).
class FuenteSaf implements FuenteArchivos {
  FuenteSaf({required this.uriRaiz, required this.nombre});

  /// URI del árbol autorizado (ACTION_OPEN_DOCUMENT_TREE).
  final String uriRaiz;

  @override
  final String nombre;

  final _saf = SafUtil();
  final _stream = SafStream();

  /// SAF necesita conocer la carpeta padre para mover; se recuerda al listar.
  final _padres = <String, String>{};

  @override
  String get id => 'saf:$uriRaiz';

  @override
  EntradaArchivo get raiz =>
      EntradaArchivo(fuenteId: id, id: uriRaiz, nombre: nombre, esCarpeta: true);

  /// false si el permiso se revocó o la carpeta ya no existe (se movió o se borró).
  Future<bool> tieneAcceso() async {
    try {
      final permiso = await _saf.hasPersistedPermission(uriRaiz, checkRead: true, checkWrite: true);
      return permiso && await _saf.exists(uriRaiz, true);
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------- Lectura

  @override
  Future<List<EntradaArchivo>> listar(EntradaArchivo carpeta) => _proteger(() async {
        final hijos = await _saf.list(carpeta.id);
        final entradas = <EntradaArchivo>[];
        for (final h in hijos) {
          if (h.name.startsWith('.')) continue; // archivos ocultos
          entradas.add(_registrar(_aEntrada(h), carpeta.id));
        }
        return entradas..sort(ordenarEntradas);
      });

  @override
  Future<Uint8List> leerBytes(EntradaArchivo archivo) =>
      _proteger(() => _stream.readFileBytes(archivo.id));

  /// "Abrir con…" y "Compartir" necesitan una ruta real, así que se copia a la caché.
  @override
  Future<String> rutaLocal(EntradaArchivo archivo) => _proteger(() async {
        final cache = await getTemporaryDirectory();
        final destino = p.join(cache.path, 'saf', archivo.nombre);
        await Directory(p.dirname(destino)).create(recursive: true);
        await _stream.copyToLocalFile(archivo.id, destino);
        return destino;
      });

  // ------------------------------------------------------------- Escritura

  @override
  Future<EntradaArchivo> crearCarpeta(EntradaArchivo padre, String nombre) =>
      _proteger(() async {
        final limpio = _validarNombre(nombre);
        if (await _saf.child(padre.id, [limpio]) != null) {
          throw const ErrorArchivo('Ya existe un elemento con ese nombre.');
        }
        return _registrar(_aEntrada(await _saf.mkdirp(padre.id, [limpio])), padre.id);
      });

  @override
  Future<EntradaArchivo> renombrar(EntradaArchivo entrada, String nuevoNombre) =>
      _proteger(() async {
        final limpio = _validarNombre(nuevoNombre);
        if (limpio == entrada.nombre) return entrada;
        final padre = _padres[entrada.id];
        if (padre != null && await _saf.child(padre, [limpio]) != null) {
          throw const ErrorArchivo('Ya existe un elemento con ese nombre.');
        }
        return _registrar(
            _aEntrada(await _saf.rename(entrada.id, entrada.esCarpeta, limpio)), padre);
      });

  @override
  Future<EntradaArchivo> copiar(EntradaArchivo entrada, EntradaArchivo carpetaDestino) =>
      _proteger(() async {
        _validarDestino(entrada, carpetaDestino);
        try {
          // Copia directa, si el proveedor de documentos la admite.
          final copia = await _saf.copyTo(entrada.id, entrada.esCarpeta, carpetaDestino.id);
          return _registrar(_aEntrada(copia), carpetaDestino.id);
        } on PlatformException {
          if (entrada.esCarpeta) {
            throw const ErrorArchivo('Esta ubicación no permite copiar carpetas.');
          }
          // Plan B para archivos: pasar por la caché (SAF renombra si el nombre ya existe).
          final temporal = await rutaLocal(entrada);
          final nuevo = await _stream.pasteLocalFile(temporal, carpetaDestino.id,
              entrada.nombre, entrada.mime ?? 'application/octet-stream');
          await File(temporal).delete();
          final doc = await _saf.stat(nuevo.uri.toString(), false);
          if (doc == null) throw const ErrorArchivo('No se pudo crear la copia.');
          return _registrar(_aEntrada(doc), carpetaDestino.id);
        }
      });

  @override
  Future<EntradaArchivo> mover(EntradaArchivo entrada, EntradaArchivo carpetaDestino) =>
      _proteger(() async {
        _validarDestino(entrada, carpetaDestino);
        final padre = _padres[entrada.id];
        if (padre == null) {
          throw const ErrorArchivo('Vuelve a abrir la carpeta e inténtalo de nuevo.');
        }
        if (padre == carpetaDestino.id) {
          throw const ErrorArchivo('El elemento ya está en esa carpeta.');
        }
        try {
          final movido =
              await _saf.moveTo(entrada.id, entrada.esCarpeta, padre, carpetaDestino.id);
          return _registrar(_aEntrada(movido), carpetaDestino.id);
        } on PlatformException {
          if (entrada.esCarpeta) {
            throw const ErrorArchivo('Esta ubicación no permite mover carpetas.');
          }
          // Plan B para archivos: copiar y luego borrar el original.
          final copia = await copiar(entrada, carpetaDestino);
          await _saf.delete(entrada.id, false);
          return copia;
        }
      });

  @override
  Future<void> eliminar(EntradaArchivo entrada) => _proteger(() async {
        if (entrada.id == uriRaiz) {
          throw const ErrorArchivo(
              'No se puede eliminar la carpeta autorizada. Si ya no la necesitas, quita el acceso desde el inicio.');
        }
        await _saf.delete(entrada.id, entrada.esCarpeta);
        _padres.remove(entrada.id);
      });

  // --------------------------------------------------------------- Auxiliares

  Future<T> _proteger<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } catch (e) {
      throw ErrorArchivo.desde(e);
    }
  }

  String _validarNombre(String nombre) {
    final error = validarNombre(nombre);
    if (error != null) throw ErrorArchivo(error);
    return nombre.trim();
  }

  void _validarDestino(EntradaArchivo entrada, EntradaArchivo carpetaDestino) {
    if (!carpetaDestino.esCarpeta) {
      throw const ErrorArchivo('El destino debe ser una carpeta.');
    }
    // En el almacenamiento del teléfono el id del documento es "primary:Carpeta/Sub",
    // así se puede saber si el destino está dentro de la carpeta que se copia o mueve.
    final origen = _idDocumento(entrada.id);
    final destino = _idDocumento(carpetaDestino.id);
    if (entrada.esCarpeta && (destino == origen || destino.startsWith('$origen/'))) {
      throw const ErrorArchivo('No se puede copiar ni mover una carpeta dentro de sí misma.');
    }
  }

  String _idDocumento(String uri) {
    final i = uri.lastIndexOf('/document/');
    final crudo = i >= 0 ? uri.substring(i + '/document/'.length) : uri.split('/').last;
    return Uri.decodeComponent(crudo);
  }

  EntradaArchivo _registrar(EntradaArchivo e, String? padre) {
    if (padre != null) _padres[e.id] = padre;
    return e;
  }

  EntradaArchivo _aEntrada(SafDocumentFile d) => EntradaArchivo(
        fuenteId: id,
        id: d.uri,
        nombre: d.name,
        esCarpeta: d.isDir,
        tamano: d.isDir || d.length < 0 ? null : d.length,
        modificado:
            d.lastModified > 0 ? DateTime.fromMillisecondsSinceEpoch(d.lastModified) : null,
        creado: null, // SAF no expone la fecha de creación
        mime: d.isDir ? null : lookupMimeType(d.name),
      );
}
