import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/entrada_archivo.dart';
import 'errores.dart';
import 'fuente_archivos.dart';

class FuenteLocal implements FuenteArchivos {
  FuenteLocal._(this._carpetaRaiz);

  final Directory _carpetaRaiz;

  static Future<FuenteLocal> espacioPropio() async {
    final docs = await getApplicationDocumentsDirectory();
    return FuenteLocal._(docs);
  }

  @override
  String get id => 'local';

  @override
  String get nombre => 'Almacenamiento local';

  @override
  EntradaArchivo get raiz => EntradaArchivo(
    fuenteId: id,
    id: _carpetaRaiz.path,
    nombre: nombre,
    esCarpeta: true,
  );

  @override
  Future<List<EntradaArchivo>> listar(EntradaArchivo carpeta) => _proteger(() async {
    final dir = Directory(carpeta.id);
    if(!await dir.exists()) throw ErrorArchivo('La carpeta no existe');
    final entradas = <EntradaArchivo>[];
    await for(final elemento in dir.list(followLinks:  false)) {
      if(p.basename(elemento.path).startsWith('.')) continue;
      entradas.add(await _aEntrada(elemento));
    }
    return entradas..sort(ordenarEntradas);
  });

  @override
  Future<String> rutaLocal(EntradaArchivo archivo) async => archivo.id;

  @override
  Future<EntradaArchivo> crearCarpeta(EntradaArchivo padre, String nombre) => _proteger(() async {
    _validarNombre(nombre);
    final dir = Directory(p.join(padre.id, nombre.trim()));
    if(await dir.exists()) throw ErrorArchivo("Ya existe una carpeta con ese nombre");
    return _aEntrada(await dir.create());
  });

  @override
  Future<EntradaArchivo> renombrar(EntradaArchivo entrada, String nuevoNombre) => _proteger(() async {
    _validarNombre(nuevoNombre);
    final destino = p.join(p.dirname(entrada.id), nuevoNombre.trim());
    if(destino == entrada.id) return entrada;
    if(await FileSystemEntity.type(destino) != FileSystemEntityType.notFound) {
      throw const ErrorArchivo("Ya existe un archivo o carpeta con ese nombre");
    }
    return _aEntrada(await _entidad(entrada).rename(destino));
  });

  @override
  Future<EntradaArchivo> copiar(EntradaArchivo entrada, EntradaArchivo carpetaDestino) =>
      _proteger(() async {
        _validarDestino(entrada, carpetaDestino);
        final destino = await _rutaLibre(carpetaDestino.id, entrada.nombre);
        if (entrada.esCarpeta) {
          await _copiarCarpeta(Directory(entrada.id), Directory(destino));
          return _aEntrada(Directory(destino));
        }
        return _aEntrada(await File(entrada.id).copy(destino));
  });

  @override
  Future<EntradaArchivo> mover(EntradaArchivo entrada, EntradaArchivo carpetaDestino) =>
      _proteger(() async {
        _validarDestino(entrada, carpetaDestino);
        if (p.equals(p.dirname(entrada.id), carpetaDestino.id)) {
          throw const ErrorArchivo('El elemento ya está en esa carpeta.');
        }
        final destino = await _rutaLibre(carpetaDestino.id, entrada.nombre);
        return _aEntrada(await _entidad(entrada).rename(destino));
      });

  @override
  Future<void> eliminar(EntradaArchivo entrada) => _proteger(() async {
        if (p.equals(entrada.id, _carpetaRaiz.path)) {
          throw const ErrorArchivo('No se puede eliminar la carpeta raíz.');
        }
        await _entidad(entrada).delete(recursive: true);
  });

  Future<void> copiarEjemplosSiHaceFalta() async {
    const clave = 'ejemplos_copiados';
    final prefs = SharedPreferencesAsync();
    try {
      if(await prefs.getBool(clave) ?? false) return;
      final manifiesto = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifiesto.listAssets().where((a) => a.startsWith('assets/ejemplos/'));
      for(final asset in assets) {
        final nombre = p.basename(asset);
        final destino = File(p.join(_carpetaRaiz.path, _subcarpetaPara(nombre), nombre));
        await destino.parent.create(recursive: true);
        final datos = await rootBundle.load(asset);
        await destino.writeAsBytes(datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes));
      }
      await prefs.setBool(clave, true);
    } catch (e) {
      debugPrint('Error al copiar ejemplos: $e');
    }
  }

  String _subcarpetaPara(String nombre) {
     if (nombre.startsWith('roto') || nombre.startsWith('vacio')) {
      return p.join('Datos', 'Pruebas');
    }
    return switch (p.extension(nombre).toLowerCase()) {
      '.txt' || '.md' => 'Documentos',
      '.json' || '.xml' => 'Datos',
      '.png' || '.jpg' || '.jpeg' => 'Imágenes',
      _ => '',
    };
  }

  Future<T> _proteger<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } catch (e) {
      throw ErrorArchivo.desde(e);
    }
  }

  void _validarNombre(String nombre) {
    final error = validarNombre(nombre);
    if (error != null) throw ErrorArchivo(error);
  }

  void _validarDestino(EntradaArchivo entrada, EntradaArchivo carpetaDestino) {
    if (!carpetaDestino.esCarpeta) {
      throw const ErrorArchivo('El destino debe ser una carpeta.');
    }
    if (entrada.esCarpeta &&
        (p.equals(entrada.id, carpetaDestino.id) || p.isWithin(entrada.id, carpetaDestino.id))) {
      throw const ErrorArchivo('No se puede copiar ni mover una carpeta dentro de sí misma.');
    }
  }

  FileSystemEntity _entidad(EntradaArchivo e) => e.esCarpeta ? Directory(e.id) : File(e.id);

  Future<String> _rutaLibre(String carpeta, String nombre) async {
    final base = p.basenameWithoutExtension(nombre);
    final ext = p.extension(nombre);
    var candidato = p.join(carpeta, nombre);
    var n = 1;
    while (await FileSystemEntity.type(candidato) != FileSystemEntityType.notFound) {
      candidato = p.join(carpeta, '$base ($n)$ext');
      n++;
    }
    return candidato;
  }

  Future<void> _copiarCarpeta(Directory origen, Directory destino) async {
    await destino.create(recursive: true);
    await for (final elemento in origen.list(followLinks: false)) {
      final nuevo = p.join(destino.path, p.basename(elemento.path));
      if (elemento is Directory) {
        await _copiarCarpeta(elemento, Directory(nuevo));
      } else if (elemento is File) {
        await elemento.copy(nuevo);
      }
    }
  }

  Future<EntradaArchivo> _aEntrada(FileSystemEntity elemento) async {
    final stat = await elemento.stat();
    final esCarpeta = stat.type == FileSystemEntityType.directory;
    final nombre = p.basename(elemento.path);
    return EntradaArchivo(
      fuenteId: id,
      id: elemento.path,
      nombre: nombre,
      esCarpeta: esCarpeta,
      tamano: esCarpeta ? null : stat.size,
      modificado: stat.modified,
      creado: null,
      mime: esCarpeta ? null : lookupMimeType(nombre),
    );
  }

  @override
  Future<Uint8List> leerBytes(EntradaArchivo archivo) {
    return _proteger(() => File(archivo.id).readAsBytes());
  }

}