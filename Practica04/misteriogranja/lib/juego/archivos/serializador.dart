// SERIALIZADORES: convierten una partida en texto (para guardarla en un archivo)
// y un texto de vuelta en partida.
//
// Los tres formatos parten del mismo Map canónico de EstadoPartida.toMap():
//   escribir: EstadoPartida → toMap() → texto JSON / XML / TXT
//   leer:     texto → Map → EstadoPartida.fromMap()  (aquí se valida todo una sola vez)
// Si el archivo está vacío, dañado o incompleto, se lanza ErrorPartida con un
// mensaje que se puede mostrar al jugador.

import 'dart:convert';

import 'package:path/path.dart' as p;

import '../../app/opciones.dart';
import '../modelo.dart';
import 'formato_json.dart';
import 'formato_txt.dart';
import 'formato_xml.dart';

abstract class Serializador {
  const Serializador();

  String escribir(EstadoPartida partida);

  EstadoPartida leer(String texto);
}

/// Cada formato sabe cuál es su serializador: `FormatoGuardado.xml.serializador`.
extension SerializadorDeFormato on FormatoGuardado {
  Serializador get serializador => switch (this) {
        FormatoGuardado.json => const SerializadorJson(),
        FormatoGuardado.xml => const SerializadorXml(),
        FormatoGuardado.txt => const SerializadorTxt(),
      };
}

/// El formato según la extensión del archivo (null si no es .json, .xml ni .txt).
FormatoGuardado? formatoDeArchivo(String ruta) {
  final extension = p.extension(ruta).replaceFirst('.', '').toLowerCase();
  for (final f in FormatoGuardado.values) {
    if (f.extension == extension) return f;
  }
  return null;
}

/// Lee los bytes de un archivo y los convierte en partida, validándolos.
EstadoPartida leerPartida(List<int> bytes, FormatoGuardado formato) {
  if (bytes.isEmpty) throw const ErrorPartida('El archivo está vacío.');
  String texto;
  try {
    texto = utf8.decode(bytes);
  } on FormatException {
    throw const ErrorPartida('El archivo no es texto UTF-8: puede estar dañado o no ser una partida.');
  }
  // El Bloc de notas de Windows a veces agrega una marca invisible (BOM) al inicio.
  if (texto.startsWith('﻿')) texto = texto.substring(1);
  if (texto.trim().isEmpty) throw const ErrorPartida('El archivo está vacío.');
  return formato.serializador.leer(texto);
}
