// REPOSITORIO: dónde y cómo se guardan las partidas en el teléfono.
//
// Cada partida es UN archivo en el almacenamiento privado de la app:
//   Android: /data/data/<paquete>/app_flutter/partidas/   (solo la app puede verlo)
//   iOS:     Documents/partidas/   (visible en la app Archivos por UIFileSharingEnabled)
// El nombre es "<id>.<extensión>"; la extensión es el formato elegido en Opciones.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app/opciones.dart';
import '../modelo.dart';
import '../motor.dart';
import 'serializador.dart';

/// Un archivo de partida con sus metadatos. Si el archivo está dañado,
/// [partida] es null y [error] dice qué tiene mal.
class ResumenPartida {
  const ResumenPartida({
    required this.archivo,
    required this.formato,
    required this.tamano,
    required this.modificado,
    this.partida,
    this.error,
  });

  final File archivo;
  final FormatoGuardado formato;
  final int tamano;
  final DateTime modificado;
  final EstadoPartida? partida;
  final String? error;

  bool get danada => partida == null;
  String get nombreArchivo => p.basename(archivo.path);
  DateTime get fecha => partida?.actualizada ?? modificado;
}

class RepositorioPartidas {
  RepositorioPartidas(this._opciones, {Future<Directory> Function()? carpetaBase})
      : _carpetaBase = carpetaBase ?? getApplicationDocumentsDirectory;

  final Opciones _opciones;
  final Future<Directory> Function() _carpetaBase;

  /// Las escrituras se hacen una tras otra, nunca dos al mismo tiempo.
  Future<void> _cola = Future.value();

  Future<Directory> carpeta() async {
    final carpeta = Directory(p.join((await _carpetaBase()).path, 'partidas'));
    await carpeta.create(recursive: true);
    return carpeta;
  }

  /// El formato en que se guardan las partidas nuevas (se elige en Opciones).
  FormatoGuardado get formatoActual => _opciones.formato;

  File _archivo(Directory carpeta, String id, FormatoGuardado formato) =>
      File(p.join(carpeta.path, '$id.${formato.extension}'));

  /// Guarda la partida en el formato elegido en Opciones, o en [formato] si se indica
  /// (por ejemplo, al renombrar una partida se conserva el formato de su archivo).
  Future<void> guardar(EstadoPartida partida, {FormatoGuardado? formato}) {
    final elegido = formato ?? _opciones.formato;
    // El texto se genera YA: si la partida cambia mientras espera su turno, no importa.
    final texto = elegido.serializador.escribir(partida);
    final tarea = _cola.then((_) => _escribir(partida.id, elegido, texto));
    _cola = tarea.catchError((Object _) {}); // si una falla, la cola sigue
    return tarea;
  }

  Future<void> _escribir(String id, FormatoGuardado formato, String texto) async {
    final dir = await carpeta();
    final destino = _archivo(dir, id, formato);
    // Primero a un archivo temporal y luego se renombra: si la app se cierra a la
    // mitad, el archivo anterior queda completo (nunca uno escrito a medias).
    final temporal = File('${destino.path}.tmp');
    await temporal.writeAsString(texto, flush: true);
    await temporal.rename(destino.path);
    // Si el jugador cambió de formato, se borra la copia vieja para no tener dos.
    for (final otro in FormatoGuardado.values) {
      final viejo = _archivo(dir, id, otro);
      if (otro != formato && await viejo.exists()) await viejo.delete();
    }
  }

  /// Todas las partidas guardadas, de la más reciente a la más antigua.
  /// Los archivos dañados también aparecen (con su error) para poder borrarlos.
  Future<List<ResumenPartida>> listar() async {
    await _cola; // espera a que terminen las escrituras pendientes
    final resumenes = <ResumenPartida>[];
    await for (final entrada in (await carpeta()).list()) {
      if (entrada is! File) continue;
      final formato = formatoDeArchivo(entrada.path);
      if (formato == null) continue; // por ejemplo, un .tmp
      final info = await entrada.stat();
      EstadoPartida? partida;
      String? error;
      try {
        partida = leerPartida(await entrada.readAsBytes(), formato);
      } on ErrorPartida catch (e) {
        error = e.mensaje;
      }
      resumenes.add(ResumenPartida(
        archivo: entrada,
        formato: formato,
        tamano: info.size,
        modificado: info.modified,
        partida: partida,
        error: error,
      ));
    }
    resumenes.sort((a, b) => b.fecha.compareTo(a.fecha));
    return resumenes;
  }

  /// La partida sin terminar más reciente (para el botón "Continuar").
  Future<EstadoPartida?> ultimaSinTerminar() async {
    for (final r in await listar()) {
      final partida = r.partida;
      if (partida != null && !partida.terminada) return partida;
    }
    return null;
  }

  /// Importa un archivo elegido por el usuario: lo VALIDA y, si está bien, lo copia
  /// a la carpeta de partidas en su mismo formato. Si ya existe una partida con ese
  /// id, se guarda como copia con un id nuevo. Lanza ErrorPartida si está dañado.
  Future<EstadoPartida> importar(List<int> bytes, String nombreArchivo) async {
    final formato = formatoDeArchivo(nombreArchivo);
    if (formato == null) {
      throw const ErrorPartida('Solo se pueden importar archivos .json, .xml o .txt.');
    }
    var partida = leerPartida(bytes, formato);
    final existentes = {for (final r in await listar()) r.partida?.id};
    if (existentes.contains(partida.id)) {
      partida = EstadoPartida.fromMap({
        ...partida.toMap(),
        'id': 'partida_${DateTime.now().millisecondsSinceEpoch}',
        'nombre': '${partida.nombre} (copia)',
      });
    }
    await guardar(partida, formato: formato);
    return partida;
  }

  /// El contenido del archivo tal cual (para "Ver contenido"), aunque esté dañado.
  Future<String> leerTexto(ResumenPartida resumen) async =>
      utf8.decode(await resumen.archivo.readAsBytes(), allowMalformed: true);

  Future<void> eliminar(ResumenPartida resumen) async {
    await _cola;
    if (await resumen.archivo.exists()) await resumen.archivo.delete();
  }
}

/// Guardado automático: cada vez que el motor avisa un cambio, espera medio segundo
/// (por si vienen varias jugadas seguidas) y escribe el archivo.
class AutoGuardado {
  AutoGuardado(this._motor, this._repositorio) {
    _motor.addListener(_programar);
    guardarYa(); // la partida existe en disco desde el primer momento
  }

  final MotorJuego _motor;
  final RepositorioPartidas _repositorio;
  Timer? _espera;

  void _programar() {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 500), guardarYa);
  }

  Future<void> guardarYa() {
    _espera?.cancel();
    return _repositorio
        .guardar(_motor.partida)
        .catchError((Object e) => debugPrint('No se pudo guardar la partida: $e'));
  }

  /// Al salir de la pantalla de juego: deja de escuchar y guarda por última vez.
  void cerrar() {
    _motor.removeListener(_programar);
    guardarYa();
  }
}
