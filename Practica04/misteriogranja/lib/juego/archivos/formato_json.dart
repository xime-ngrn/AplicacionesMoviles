import 'dart:convert';

import '../modelo.dart';
import 'serializador.dart';

/// JSON: el Map canónico tal cual, con sangría para que se pueda leer.
class SerializadorJson extends Serializador {
  const SerializadorJson();

  @override
  String escribir(EstadoPartida partida) =>
      const JsonEncoder.withIndent('  ').convert(partida.toMap());

  @override
  EstadoPartida leer(String texto) {
    final Object? datos;
    try {
      datos = jsonDecode(texto);
    } on FormatException catch (e) {
      throw ErrorPartida('El archivo JSON está mal escrito: ${e.message}.');
    }
    if (datos is! Map<String, dynamic>) {
      throw const ErrorPartida('El archivo JSON no contiene una partida.');
    }
    return EstadoPartida.fromMap(datos);
  }
}
