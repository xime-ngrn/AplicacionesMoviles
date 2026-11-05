// Pruebas del paso J1. Ejecuta en la terminal, dentro de misteriogranja:
//   flutter test
// Cuando TODAS pasen, tu historia está completa y bien conectada.

import 'package:flutter_test/flutter_test.dart';
import 'package:misteriogranja/app/opciones.dart';
import 'package:misteriogranja/juego/datos_historia.dart';
import 'package:misteriogranja/juego/modelo.dart';

void main() {
  group('Contenido de la historia (lo completas tú)', () {
    test('hay 4 lugares, 2 por noche', () {
      expect(Historia.lugares.map((l) => l.id),
          containsAll(['casa', 'maizal', 'granero', 'area_libre']));
      expect(Historia.lugaresDeNivel(1), hasLength(2));
      expect(Historia.lugaresDeNivel(2), hasLength(2));
    });

    test('hay 6 sospechosos e incluyen al culpable y a los finalistas', () {
      final ids = Historia.sospechosos.map((s) => s.id);
      expect(ids, containsAll(['perro', 'conejo', 'zorro', 'tlacuache', 'cacomixtle', 'mapache']));
      expect(ids, containsAll(Historia.finalistas));
      expect(ids, contains(Historia.culpable));
    });

    test('los ids no se repiten', () {
      void sinRepetir(Iterable<String> ids, String que) =>
          expect(ids.toSet().length, ids.length, reason: 'Hay $que con id repetido');
      sinRepetir(Historia.lugares.map((l) => l.id), 'lugares');
      sinRepetir(Historia.sospechosos.map((s) => s.id), 'sospechosos');
      sinRepetir(Historia.pistas.map((p) => p.id), 'pistas');
      sinRepetir(Historia.todosLosPuntos.map((p) => p.id), 'puntos de búsqueda');
    });

    test('cada lugar tiene al menos 2 puntos de búsqueda', () {
      for (final l in Historia.lugares) {
        expect(l.puntos.length, greaterThanOrEqualTo(2), reason: '"${l.id}" tiene pocos puntos');
      }
    });

    test('cada punto apunta a una pista que existe y es de la misma noche', () {
      for (final l in Historia.lugares) {
        for (final p in l.puntos.where((p) => p.pistaId != null)) {
          expect(Historia.existePista(p.pistaId!), isTrue,
              reason: 'El punto "${p.id}" usa la pista "${p.pistaId}", que no existe');
          expect(Historia.pista(p.pistaId!).nivel, l.nivel,
              reason: 'La pista "${p.pistaId}" no es de la misma noche que "${l.id}"');
        }
      }
    });

    test('cada pista está escondida en algún punto', () {
      final escondidas = Historia.todosLosPuntos.map((p) => p.pistaId).toSet();
      for (final p in Historia.pistas) {
        expect(escondidas, contains(p.id), reason: 'La pista "${p.id}" no está en ningún punto');
      }
    });

    test('las pistas solo mencionan sospechosos que existen', () {
      for (final p in Historia.pistas) {
        for (final s in [...p.descarta, ...p.apuntaA]) {
          expect(Historia.existeSospechoso(s), isTrue,
              reason: 'La pista "${p.id}" menciona a "$s", que no existe');
        }
      }
    });

    test('en la noche 1 se puede descartar a perro, conejo y zorro', () {
      for (final s in Historia.descartadosNoche1) {
        expect(Historia.pistas.any((p) => p.nivel == 1 && p.descarta.contains(s)), isTrue,
            reason: 'Ninguna pista de la noche 1 descarta a "$s"');
      }
    });

    test('ninguna pista descarta al culpable', () {
      for (final p in Historia.pistas) {
        expect(p.descarta, isNot(contains(Historia.culpable)), reason: '"${p.id}" lo descarta');
      }
    });

    test('hay una sola confirmación final, en la noche 2, y apunta al culpable', () {
      final confirmaciones = Historia.pistas.where((p) => p.esConfirmacion).toList();
      expect(confirmaciones, hasLength(1));
      expect(confirmaciones.first.nivel, 2);
      expect(confirmaciones.first.apuntaA, contains(Historia.culpable));
    });

    test('el desenlace está escrito', () {
      expect(Historia.desenlace.trim(), isNotEmpty);
    });
  });

  group('Modelo de partida', () {
    EstadoPartida partidaDePrueba() {
      final pista = Historia.pistas.first;
      return EstadoPartida.nueva(
        nombre: 'Prueba',
        dificultad: Dificultad.detective,
        nombreGranjero: 'Don Chema',
      )
        ..etiquetas.add('En progreso')
        ..puntuacion = 120
        ..minuto = 90
        ..pistasEncontradas.add(pista.id)
        ..puntosRevisados.add(Historia.lugares.first.puntos.first.id)
        ..estados['perro'] = EstadoSospechoso.descartado
        ..pistasAsignadas['perro'] = {pista.id}
        ..historial.add(Evento(
          nivel: 1,
          minuto: 30,
          tipo: TipoEvento.pista,
          lugarId: 'casa',
          referencia: pista.id,
          texto: 'Encontró una pista.',
        ));
    }

    test('toMap y fromMap conservan toda la partida', () {
      final original = partidaDePrueba();
      expect(EstadoPartida.fromMap(original.toMap()).toMap(), original.toMap());
    });

    test('acepta números y booleanos escritos como texto (así llegan de XML y TXT)', () {
      final mapa = partidaDePrueba().toMap()
        ..['puntuacion'] = '120'
        ..['terminada'] = 'false';
      final cargada = EstadoPartida.fromMap(mapa);
      expect(cargada.puntuacion, 120);
      expect(cargada.terminada, isFalse);
    });

    test('un campo faltante da un error legible', () {
      final mapa = partidaDePrueba().toMap()..remove('puntuacion');
      expect(
        () => EstadoPartida.fromMap(mapa),
        throwsA(isA<ErrorPartida>().having((e) => e.mensaje, 'mensaje', contains('puntuacion'))),
      );
    });

    test('una pista desconocida se rechaza', () {
      final mapa = partidaDePrueba().toMap()..['pistas'] = ['pista_inventada'];
      expect(() => EstadoPartida.fromMap(mapa), throwsA(isA<ErrorPartida>()));
    });

    test('un archivo vacío se rechaza', () {
      expect(() => EstadoPartida.fromMap({}), throwsA(isA<ErrorPartida>()));
    });

    test('la hora se cuenta desde las 22:00', () {
      expect(horaDeMinuto(0), '22:00');
      expect(horaDeMinuto(150), '00:30');
      expect(horaDeMinuto(300), '03:00');
    });
  });
}
