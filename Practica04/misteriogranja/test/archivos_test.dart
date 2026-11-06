// Pruebas del paso J4: guardar y cargar partidas en JSON, XML y TXT.
//   flutter test test/archivos_test.dart

// El paquete de "preferencias en memoria" ya viene con shared_preferences; solo se usa aquí.
// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:misteriogranja/app/opciones.dart';
import 'package:misteriogranja/juego/archivos/repositorio.dart';
import 'package:misteriogranja/juego/archivos/serializador.dart';
import 'package:misteriogranja/juego/datos_historia.dart';
import 'package:misteriogranja/juego/modelo.dart';
import 'package:misteriogranja/juego/motor.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Una partida a medio jugar: noche 2, con pistas, descartes y eventos.
EstadoPartida partidaJugada() {
  final m = MotorJuego.nueva(dificultad: Dificultad.detective, granjero: 'Doña Lupe');
  for (final lugar in m.lugaresDeLaNoche) {
    m.viajar(lugar.id);
    for (final punto in lugar.puntos) {
      m.buscar(punto.id);
    }
  }
  for (final id in Historia.descartadosNoche1) {
    m.alternarPista(id, m.pistasEncontradas.firstWhere((p) => p.descarta.contains(id)).id);
    m.descartar(id);
  }
  m.pasarANoche2();
  m.buscar(m.lugar.puntos.first.id);
  m.alternarSospecha('mapache');
  m.partida.etiquetas.addAll(['Favorita', 'Noche 2']);
  return m.partida;
}

Matcher errorQueDice(String texto) =>
    throwsA(isA<ErrorPartida>().having((e) => e.mensaje, 'mensaje', contains(texto)));

void main() {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();

  group('Cada formato guarda y carga la partida completa', () {
    for (final formato in FormatoGuardado.values) {
      test(formato.etiqueta, () {
        final original = partidaJugada();
        final texto = formato.serializador.escribir(original);
        final cargada = leerPartida(utf8.encode(texto), formato);
        expect(cargada.toMap(), original.toMap());
      });
    }
  });

  group('Archivos dañados dan un error legible', () {
    test('vacío', () {
      expect(() => leerPartida([], FormatoGuardado.json), errorQueDice('vacío'));
    });
    test('JSON mal escrito', () {
      expect(() => leerPartida(utf8.encode('{"nombre": "Prueba",'), FormatoGuardado.json),
          errorQueDice('JSON está mal escrito'));
    });
    test('XML que no es una partida', () {
      expect(() => leerPartida(utf8.encode('<receta><nombre>Tamales</nombre></receta>'),
          FormatoGuardado.xml), errorQueDice('no es una partida'));
    });
    test('XML sin un dato obligatorio', () {
      final xml = FormatoGuardado.xml.serializador
          .escribir(partidaJugada())
          .replaceFirst(RegExp(r'<puntuacion>.*</puntuacion>'), '');
      expect(() => leerPartida(utf8.encode(xml), FormatoGuardado.xml), errorQueDice('puntuacion'));
    });
    test('TXT con una línea rota indica el número de línea', () {
      final txt = FormatoGuardado.txt.serializador
          .escribir(partidaJugada())
          .replaceFirst('== Noche 1 ==', '== Noche 1 ==\nesta línea no tiene formato');
      expect(() => leerPartida(utf8.encode(txt), FormatoGuardado.txt), errorQueDice('Línea'));
    });
    test('TXT con una pista inventada', () {
      final txt = FormatoGuardado.txt.serializador
          .escribir(partidaJugada())
          .replaceFirst('pistas: ', 'pistas: pista_inventada, ');
      expect(() => leerPartida(utf8.encode(txt), FormatoGuardado.txt),
          errorQueDice('pista_inventada'));
    });
  });

  group('Repositorio', () {
    late Directory carpeta;
    late Opciones opciones;
    late RepositorioPartidas repo;

    setUp(() async {
      carpeta = await Directory.systemTemp.createTemp('partidas_prueba');
      opciones = Opciones();
      repo = RepositorioPartidas(opciones, carpetaBase: () async => carpeta);
    });
    tearDown(() => carpeta.delete(recursive: true));

    test('guarda, lista y continúa la última partida sin terminar', () async {
      final partida = partidaJugada();
      await repo.guardar(partida);
      final lista = await repo.listar();
      expect(lista, hasLength(1));
      expect(lista.single.nombreArchivo, '${partida.id}.json');
      expect((await repo.ultimaSinTerminar())?.toMap(), partida.toMap());
    });

    test('al cambiar de formato se reemplaza el archivo (no quedan dos)', () async {
      final partida = partidaJugada();
      await repo.guardar(partida);
      await opciones.cambiarFormato(FormatoGuardado.txt);
      await repo.guardar(partida);
      final lista = await repo.listar();
      expect(lista.single.formato, FormatoGuardado.txt);
    });

    test('importar un archivo válido lo copia (y si ya existe, como copia nueva)', () async {
      final partida = partidaJugada();
      final xml = utf8.encode(FormatoGuardado.xml.serializador.escribir(partida));
      final primera = await repo.importar(xml, 'de_un_amigo.xml');
      expect(primera.id, partida.id);
      final segunda = await repo.importar(xml, 'de_un_amigo.xml');
      expect(segunda.id, isNot(partida.id));
      expect(segunda.nombre, endsWith('(copia)'));
      expect(await repo.listar(), hasLength(2));
    });

    test('importar un archivo dañado se rechaza y no se copia', () async {
      await expectLater(repo.importar(utf8.encode('<partida></partida>'), 'rota.xml'),
          throwsA(isA<ErrorPartida>()));
      await expectLater(repo.importar(utf8.encode('hola'), 'foto.png'), throwsA(isA<ErrorPartida>()));
      expect(await repo.listar(), isEmpty);
    });

    test('un archivo dañado aparece en la lista con su error', () async {
      final dir = await repo.carpeta();
      await File('${dir.path}/rota.json').writeAsString('esto no es json');
      final lista = await repo.listar();
      expect(lista.single.danada, isTrue);
      expect(lista.single.error, contains('JSON'));
      expect(await repo.ultimaSinTerminar(), isNull);
    });
  });
}
