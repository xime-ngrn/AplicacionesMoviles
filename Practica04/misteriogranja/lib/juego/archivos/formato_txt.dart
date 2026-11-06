import 'dart:convert';

import '../modelo.dart';
import 'serializador.dart';

/// TXT "bitácora": se lee como un cuento y también se puede volver a cargar.
///
///   # Misterio en la Granja — bitácora de la partida
///   nombre: Investigación de Don Chema
///   puntuacion: 120
///   ...
///   --- SOSPECHOSOS ---
///   perro | descartado | coartada_perro
///   --- BITÁCORA ---
///   == Noche 1 ==
///   22:30 | casa | pista:coartada_perro | En «Cama del perro», Don Chema encontró...
///
/// Las líneas que empiezan con # son comentarios y se ignoran al leer.
class SerializadorTxt extends Serializador {
  const SerializadorTxt();

  static const _sospechosos = '--- SOSPECHOSOS ---';
  static const _bitacora = '--- BITÁCORA ---';
  static final _titulo = RegExp(r'^== Noche (\d+) ==$');
  static final _hora = RegExp(r'^(\d{1,2}):(\d{2})$');

  @override
  String escribir(EstadoPartida partida) {
    final m = partida.toMap();
    final config = m['configuracion']! as Map<String, Object?>;
    final b = StringBuffer()
      ..writeln('# Misterio en la Granja — bitácora de la partida')
      ..writeln('# Este archivo se puede leer como un cuento y volver a cargar en el juego.')
      ..writeln();

    void dato(String clave, Object? valor) => b.writeln('$clave: ${valor ?? ''}');
    String lista(Object? valores) => (valores! as List).join(', ');

    dato('version', m['version']);
    dato('id', m['id']);
    dato('nombre', m['nombre']);
    dato('etiquetas', lista(m['etiquetas']));
    for (final clave in ['creada', 'actualizada', 'nivel', 'minuto', 'lugar', 'puntuacion', 'segundos']) {
      dato(clave, m[clave]);
    }
    dato('terminada', partida.terminada ? 'sí' : 'no');
    dato('acusado', m['acusado']);
    dato('dificultad', config['dificultad']);
    dato('granjero', config['granjero']);
    dato('pistas', lista(m['pistas']));
    dato('puntos', lista(m['puntos']));

    b
      ..writeln()
      ..writeln(_sospechosos);
    for (final s in (m['sospechosos']! as List).cast<Map<String, Object?>>()) {
      b.writeln('${s['id']} | ${s['estado']} | ${lista(s['pistas'])}');
    }

    b
      ..writeln()
      ..writeln(_bitacora);
    int? noche;
    for (final e in partida.historial) {
      if (e.nivel != noche) {
        noche = e.nivel;
        b.writeln('== Noche $noche ==');
      }
      final tipo = e.referencia == null ? e.tipo.name : '${e.tipo.name}:${e.referencia}';
      b.writeln('${e.hora} | ${e.lugarId} | $tipo | ${e.texto}');
    }
    return b.toString();
  }

  @override
  EstadoPartida leer(String texto) {
    final datos = <String, dynamic>{};
    final sospechosos = <Map<String, dynamic>>[];
    final historial = <Map<String, dynamic>>[];
    var seccion = 'datos';
    var noche = 1;

    final lineas = const LineSplitter().convert(texto);
    for (var i = 0; i < lineas.length; i++) {
      final linea = lineas[i].trim();
      final n = i + 1; // número de línea para los mensajes de error
      if (linea.isEmpty || linea.startsWith('#')) continue;
      if (linea == _sospechosos || linea == _bitacora) {
        seccion = linea;
        continue;
      }

      switch (seccion) {
        case 'datos':
          final dosPuntos = linea.indexOf(':');
          if (dosPuntos <= 0) {
            throw ErrorPartida('Línea $n: se esperaba "dato: valor" y dice "$linea".');
          }
          datos[linea.substring(0, dosPuntos).trim()] = linea.substring(dosPuntos + 1).trim();

        case _sospechosos:
          final partes = _partir(linea, 3);
          if (partes.length != 3) {
            throw ErrorPartida('Línea $n: se esperaba "sospechoso | estado | pistas".');
          }
          sospechosos.add({'id': partes[0], 'estado': partes[1], 'pistas': _lista(partes[2])});

        case _bitacora:
          final titulo = _titulo.firstMatch(linea);
          if (titulo != null) {
            noche = int.parse(titulo.group(1)!);
            continue;
          }
          final partes = _partir(linea, 4);
          final hora = partes.length == 4 ? _hora.firstMatch(partes[0]) : null;
          if (hora == null) {
            throw ErrorPartida('Línea $n: se esperaba "HH:MM | lugar | tipo | texto".');
          }
          // De la hora del reloj se regresa a "minutos desde las 22:00".
          final reloj = int.parse(hora.group(1)!) * 60 + int.parse(hora.group(2)!);
          final tipo = partes[2].split(':');
          historial.add({
            'nivel': noche,
            'minuto': (reloj - 22 * 60 + 24 * 60) % (24 * 60),
            'tipo': tipo.first,
            'lugar': partes[1],
            if (tipo.length > 1) 'referencia': tipo[1],
            'texto': partes[3],
          });
      }
    }

    if (datos.isEmpty) throw const ErrorPartida('El archivo TXT no tiene los datos de la partida.');
    return EstadoPartida.fromMap({
      ...datos,
      'etiquetas': _lista(datos['etiquetas']),
      'pistas': _lista(datos['pistas']),
      'puntos': _lista(datos['puntos']),
      'configuracion': {'dificultad': datos['dificultad'], 'granjero': datos['granjero']},
      'sospechosos': sospechosos,
      'historial': historial,
    });
  }

  /// "a, b, c" → ['a', 'b', 'c'] (sin elementos vacíos).
  static List<String> _lista(Object? texto) => [
        for (final x in (texto ?? '').toString().split(','))
          if (x.trim().isNotEmpty) x.trim(),
      ];

  /// Parte la línea en [partes] trozos usando "|"; el último trozo se queda con el resto,
  /// por si el texto de la bitácora llegara a tener una "|".
  static List<String> _partir(String linea, int partes) {
    final trozos = <String>[];
    var resto = linea;
    while (trozos.length < partes - 1) {
      final barra = resto.indexOf('|');
      if (barra < 0) break;
      trozos.add(resto.substring(0, barra).trim());
      resto = resto.substring(barra + 1);
    }
    return trozos..add(resto.trim());
  }
}
