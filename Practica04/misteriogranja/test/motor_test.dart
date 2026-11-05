import 'package:flutter_test/flutter_test.dart';
import 'package:misteriogranja/app/opciones.dart';
import 'package:misteriogranja/juego/datos_historia.dart';
import 'package:misteriogranja/juego/modelo.dart';
import 'package:misteriogranja/juego/motor.dart';

MotorJuego motorNuevo([Dificultad dificultad = Dificultad.detective]) =>
    MotorJuego.nueva(dificultad: dificultad, granjero: 'Don Chema');

// Visita los lugares de la noche actual y busca en todos sus puntos.
void buscarEnTodo(MotorJuego m) {
  for (final lugar in m.lugaresDeLaNoche) {
    m.viajar(lugar.id);
    for (final punto in lugar.puntos) {
      m.buscar(punto.id);
    }
  }
}

// A cada sospechoso le asigna la pista que lo descarta y lo descarta.
void descartarConPruebas(MotorJuego m, Iterable<String> ids) {
  for (final id in ids) {
    final prueba = m.pistasEncontradas.firstWhere((p) => p.descarta.contains(id));
    m.alternarPista(id, prueba.id);
    expect(m.descartar(id).tipo, TipoResultado.correcto, reason: 'No se pudo descartar a $id');
  }
}

void main() {
  test('se puede resolver el caso de principio a fin', () {
    final m = motorNuevo();
    expect(m.partida.historial.single.tipo, TipoEvento.inicio);

    buscarEnTodo(m);
    descartarConPruebas(m, Historia.descartadosNoche1);
    expect(m.nocheCompleta, isTrue);
    expect(m.pasarANoche2().tipo, TipoResultado.victoria);
    expect(m.partida.nivel, 2);
    expect(m.partida.hora, '22:00');

    buscarEnTodo(m);
    descartarConPruebas(m, Historia.finalistas.where((s) => s != Historia.culpable));
    final prueba = m.pistasEncontradas
        .firstWhere((p) => p.apuntaA.contains(Historia.culpable) && !p.esFalsa);
    m.alternarPista(Historia.culpable, prueba.id);
    expect(m.acusar(Historia.culpable).tipo, TipoResultado.victoria);

    expect(m.partida.resuelta, isTrue);
    expect(m.partida.historial.last.tipo, TipoEvento.fin);
    expect(m.partida.puntuacion, greaterThan(600));
  });

  test('descartar sin pruebas es un error y resta puntos', () {
    final m = motorNuevo();
    expect(m.descartar('perro').tipo, TipoResultado.error);
    expect(m.partida.puntuacion, Puntaje.error);
    expect(m.partida.estadoDe('perro'), EstadoSospechoso.sinRevisar);
  });

  test('una pista falsa no alcanza para acusar', () {
    final m = motorNuevo();
    buscarEnTodo(m);
    descartarConPruebas(m, Historia.descartadosNoche1);
    m.pasarANoche2();
    buscarEnTodo(m);
    final falsa = m.pistasEncontradas.firstWhere((p) => p.esFalsa && p.nivel == 2);
    final acusado = falsa.apuntaA.first;
    m.alternarPista(acusado, falsa.id);
    expect(m.acusar(acusado).tipo, TipoResultado.error);
    expect(m.partida.terminada, isFalse);
  });

  test('en modo Detective se acaba el tiempo; en Aprendiz no', () {
    for (final dificultad in Dificultad.values) {
      final m = motorNuevo(dificultad);
      final [primero, segundo] = m.lugaresDeLaNoche;
      for (var i = 0; i < 20; i++) {
        m.viajar(i.isEven ? segundo.id : primero.id);
      }
      expect(m.sinTiempo, dificultad == Dificultad.detective);
    }
  });

  test('una partida jugada se puede guardar y volver a cargar', () {
    final m = motorNuevo();
    buscarEnTodo(m);
    descartarConPruebas(m, ['perro']);
    final copia = EstadoPartida.fromMap(m.partida.toMap());
    expect(copia.toMap(), m.partida.toMap());
  });
}