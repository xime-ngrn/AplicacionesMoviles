import 'dart:async';
import 'package:flutter/foundation.dart';
import '../app/opciones.dart';
import 'datos_historia.dart';
import 'modelo.dart';

abstract final class Puntaje{
  static const pista = 50;
  static const descarte = 30;
  static const error = -40;
  static const noche = 100;
  static const mediaHoraLibre = 10;
  static const deduccionPura = 80;
}

enum TipoResultado {viaje, nada, pista, correcto, error, aviso, victoria}

class Resultado{
  const Resultado(this.tipo, this.mensaje, {this.pista});

  final TipoResultado tipo;
  final String mensaje;

  final Pista? pista;
}

class MotorJuego extends ChangeNotifier{
  MotorJuego(this.partida);

  factory MotorJuego.nueva({required Dificultad dificultad, required String granjero}) {
    final motor = MotorJuego(EstadoPartida.nueva(
      nombre: 'Investigación de $granjero',
      dificultad: dificultad,
      nombreGranjero: granjero,
    ));
    motor._anotar(TipoEvento.inicio, conGranjero(Historia.introduccion[1]!, granjero));
    return motor;
  }

  final EstadoPartida partida;

  static const minutosPorViaje = 15;

  Timer? _reloj;

  String get granjero => partida.nombreGranjero;
  bool get esDetective => partida.dificultad == Dificultad.detective;
  Lugar get lugar => Historia.lugar(partida.lugarActual);
  List<Lugar> get lugaresDeLaNoche => Historia.lugaresDeNivel(partida.nivel);

  double get avanceNoche => (partida.minuto / Historia.minutosPorNocheDetective).clamp(0.0, 1.0);

  bool get sinTiempo => !_alcanza(Historia.minutosPorBusqueda);

  bool revisado(String puntoId) => partida.puntosRevisados.contains(puntoId);

  // Pistas encontradas
  List<Pista> get pistasEncontradas => [for (final p in Historia.pistas) if (partida.pistasEncontradas.contains(p.id)) p];

  // Pistas asignadas a cada sospechoso
  List<Pista> pistasDe(String sospechosoId){
    final suyas = partida.pistasAsignadas[sospechosoId] ?? const <String>{};
    return [for (final p in pistasEncontradas) if (suyas.contains(p.id)) p];
  }

  bool get nocheCompleta =>
      partida.nivel == 1 &&
      Historia.descartadosNoche1.every((s) => partida.estadoDe(s) == EstadoSospechoso.descartado);

  String get rango => switch (partida.puntuacion){
    >= 850 => 'Detective maestro',
    >= 600 => 'Detective',
    _ => 'Ayudante de detective',
  };

  // -------- Jugadas
  Resultado viajar(String lugarId){
    if(partida.terminada) return _yaTermino;
    if(lugarId == partida.lugarActual){
      return const Resultado(TipoResultado.aviso, 'Ya estas aquí.');
    }
    final destino = Historia.lugar(lugarId);
    if(destino.nivel != partida.nivel){
      return const Resultado(TipoResultado.aviso, 'Ese lugar se investiga en otra noche.');
    }
    if(!_alcanza(minutosPorViaje)) return _seAcaboElTiempo;

    partida.minuto += minutosPorViaje;
    partida.lugarActual = lugarId;
    _anotar(TipoEvento.viaje, '$granjero caminó hasta ${_minuscula(destino.nombre)}.');
    _cambio();
    return Resultado(TipoResultado.viaje, destino.nombre);
  }

  Resultado buscar(String puntoId){
    if(partida.terminada) return _yaTermino;
    final punto = lugar.puntos.firstWhere((p) => p.id == puntoId);
    if(revisado(puntoId)) return const Resultado(TipoResultado.aviso, 'Ya buscaste aquí.');
    if(sinTiempo) return _seAcaboElTiempo;

    partida.minuto += Historia.minutosPorBusqueda;
    partida.puntosRevisados.add(puntoId);

    final pistaId = punto.pistaId;
    if(pistaId == null){
      final texto = conGranjero(punto.textoVacio, granjero);
      _anotar(TipoEvento.busqueda, '$granjero buscó en <${punto.nombre}>. $texto', referencia: punto.id);
      _cambio();
      return Resultado(TipoResultado.nada, texto);
    }

    final pista = Historia.pista(pistaId);
    final texto = conGranjero(pista.texto, granjero);
    partida.pistasEncontradas.add(pista.id);

    partida.puntuacion += Puntaje.pista;
    _anotar(TipoEvento.pista, 'En <${punto.nombre}>, $granjero encontró una pista: <${pista.titulo}>. $texto', referencia: pista.id);
    _cambio();
    return Resultado(TipoResultado.pista, texto, pista: pista);
  }

  Resultado alternarPista(String sospechosoId, String pistaId){
    if(partida.terminada) return _yaTermino;
    if(!partida.pistasEncontradas.contains(pistaId)){
      return const Resultado(TipoResultado.aviso, 'Primero tienes que encontrar esta pista.');
    }

    final pista = Historia.pista(pistaId);
    final suyas = partida.pistasAsignadas.putIfAbsent(sospechosoId, () => {});
    if(suyas.remove(pistaId)){
      _cambio();
      return Resultado(TipoResultado.nada, 'Quitaste <${pista.titulo}>.');
    }
    suyas.add(pistaId);
    _anotar(TipoEvento.asignacion, '$granjero relacionó <${pista.titulo}> con ${_el(sospechosoId)}.', referencia: sospechosoId);
    _cambio();
    return Resultado(TipoResultado.nada, 'Asignaste <${pista.titulo}> a ${_el(sospechosoId)}.');
  }

  void alternarSospecha(String sospechosoId){
    final actual = partida.estadoDe(sospechosoId);
    if(partida.terminada || actual == EstadoSospechoso.descartado) return;
    if(actual == EstadoSospechoso.sospechoso){
      partida.estados[sospechosoId] = EstadoSospechoso.sinRevisar;
    }else{
      partida.estados[sospechosoId] = EstadoSospechoso.sospechoso;
      _anotar(TipoEvento.marca, '$granjero anotó a ${_el(sospechosoId)} como sospechoso.', referencia: sospechosoId);
    }
    _cambio();
  }

  Resultado descartar(String sospechosoId){
    if(partida.terminada) return _yaTermino;
    if(partida.estadoDe(sospechosoId) == EstadoSospechoso.descartado){
      return const Resultado(TipoResultado.aviso, 'Ya estaba descartado.');
    }
    final prueba = pistasDe(sospechosoId).where((p) => p.descarta.contains(sospechosoId)).firstOrNull;

    if(prueba == null){
      partida.puntuacion += Puntaje.error;
      _anotar(TipoEvento.marca, '$granjero quiso descartar a ${_el(sospechosoId)}, pero no tenía pruebas.', referencia: sospechosoId);
      _cambio();
      return Resultado(TipoResultado.error, esDetective ? 'No tienes pruebas para descartarlo.' : 'No tienes pruebas para descartarlo. Asígnale una pista que demuestre que no pudo ser él.');
    }

    partida.estados[sospechosoId] = EstadoSospechoso.descartado;
    partida.puntuacion += Puntaje.descarte;
    _anotar(TipoEvento.marca, 'Gracias a <${prueba.titulo}>, ${_el(sospechosoId)} quedó libre de sospecha.', referencia: sospechosoId);
    _cambio();
    return Resultado(TipoResultado.correcto, '${Historia.sospechoso(sospechosoId).nombre}: descartado.');
  }

  Resultado pasarANoche2(){
    if(!nocheCompleta){
      return const Resultado(TipoResultado.aviso, 'Todavía no descartas a todos los sospechosos de esta noche.');
    }

    final bono = Puntaje.noche + _bonoTiempo();

    partida.puntuacion += bono;
    _anotar(TipoEvento.nivel, 'Así terminó la primera noche: solo quedaban 3 sospechosos.');

    partida.nivel = 2;
    partida.minuto = 0;
    partida.lugarActual = Historia.lugaresDeNivel(2).first.id;
    _anotar(TipoEvento.nivel, conGranjero(Historia.introduccion[2]!, granjero));
    _cambio();
    return Resultado(TipoResultado.victoria, '¡Primera noche resuelta! +$bono puntos.');
  }

  Resultado acusar(String sospechosoId){
    if(partida.terminada) return _yaTermino;
    if(partida.nivel != 2){
      return const Resultado(TipoResultado.aviso, 'La acusación se hace en la segunda noche.');
    }

    if(partida.estadoDe(sospechosoId) == EstadoSospechoso.descartado){
      return const Resultado(TipoResultado.aviso, 'No puedes acusar a alguien que ya descartaste.');
    }

    final pruebas = pistasDe(sospechosoId).where((p) => p.apuntaA.contains(sospechosoId));
    if(pruebas.isEmpty){
      return const Resultado(TipoResultado.aviso, 'Para acusar necesitas asignarle al menos una pista que lo señale.');
    }

    _anotar(TipoEvento.acusacion, '$granjero reunió sus pruebas y acusó a ${_el(sospechosoId)}.', referencia: sospechosoId);

    if(sospechosoId != Historia.culpable){
      partida.puntuacion += Puntaje.error;
      _anotar(TipoEvento.acusacion, 'Pero las pruebas no alcanzaban: ${_el(sospechosoId)} no era el culpable.', referencia: sospechosoId);
      _cambio();
      return Resultado(TipoResultado.error, esDetective ? 'Las pruebas no alcanzan.' : 'Las pruebas no alcanzan. ¿Alguna de tus pistas era engañosa?');
    }

    final confirmacion = Historia.pistas.firstWhere((p) => p.esConfirmacion);
    final pura = !partida.pistasEncontradas.contains(confirmacion.id);
    final bono = Puntaje.noche + _bonoTiempo() + (pura ? Puntaje.deduccionPura : 0);
    partida.puntuacion += bono;
    partida.terminada = true;
    partida.acusado = sospechosoId;
    _anotar(TipoEvento.fin, conGranjero(Historia.desenlace, granjero), referencia: sospechosoId);
    detenerReloj();
    _cambio();
    return Resultado(TipoResultado.victoria, pura ? '¡Deducción pura! Lo descubriste sin el testimonio de Don Tecolote.' : '¡Caso resuelto!');
  }

  void abandonar(){
    if(partida.terminada) return;
    partida.terminada = true;
    _anotar(TipoEvento.fin, 'Sin pruebas suficientes, $granjero dejó el caso sin resolver.');
    detenerReloj();
    _cambio();
  }

  void iniciarReloj() {
    if (partida.terminada || _reloj != null) return;
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) => partida.segundosJugados++);
  }

  void detenerReloj() {
    _reloj?.cancel();
    _reloj = null;
  }

  @override
  void dispose() {
    detenerReloj();
    super.dispose();
  }

  bool _alcanza(int minutos) => !esDetective || partida.minuto + minutos <= Historia.minutosPorNocheDetective;

  int _bonoTiempo() {
    final libres = Historia.minutosPorNocheDetective - partida.minuto;
    return libres <= 0 ? 0 : libres ~/ 30 * Puntaje.mediaHoraLibre;
  }

  void _anotar(TipoEvento tipo, String texto, {String? referencia}) {
    partida.historial.add(Evento(
      nivel: partida.nivel,
      minuto: partida.minuto,
      tipo: tipo,
      lugarId: partida.lugarActual,
      referencia: referencia,
      texto: texto,
    ));
  }

  void _cambio() {
    partida.actualizada = DateTime.now();
    notifyListeners();
  }

  static String _el(String sospechosoId) => 'el $sospechosoId';

  static String _minuscula(String texto) =>
      texto.isEmpty ? texto : texto[0].toLowerCase() + texto.substring(1);

  static const _yaTermino = Resultado(TipoResultado.aviso, 'La partida ya terminó.');

  static const _seAcaboElTiempo = Resultado(TipoResultado.aviso,
      'Ya son las 3:00: se acabó el tiempo para buscar esta noche. Analiza las pistas que tienes.');
}