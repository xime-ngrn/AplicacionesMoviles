// ESTADO DE UNA PARTIDA: todo lo que cambia mientras se juega y lo que se guarda en archivo.
//
// FORMATO CANÓNICO: toMap() convierte la partida en un Map sencillo (textos, números,
// booleanos, listas y mapas). Los tres formatos de archivo parten de ese mismo Map:
//   - JSON: el Map tal cual.
//   - XML y TXT: el Map escrito como etiquetas o como líneas de texto.
// Al cargar, cada formato vuelve a armar el Map y fromMap() lo VALIDA una sola vez.
// Si algo falta o está dañado, lanza ErrorPartida con un mensaje legible.

import '../app/opciones.dart';
import 'datos_historia.dart';

/// Error legible al leer una partida vacía, incompleta o dañada.
class ErrorPartida implements Exception {
  const ErrorPartida(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

enum EstadoSospechoso { sinRevisar, sospechoso, descartado }

/// Tipos de movimiento que se registran en el historial (y que forman la bitácora).
enum TipoEvento { inicio, viaje, busqueda, pista, asignacion, marca, acusacion, nivel, fin }

/// Convierte minutos desde las 22:00 en una hora "HH:MM" (pasa de la medianoche).
String horaDeMinuto(int minuto) {
  final total = (22 * 60 + minuto) % (24 * 60);
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(total ~/ 60)}:${dos(total % 60)}';
}

/// Un movimiento del jugador: el "historial de movimientos" que pide la práctica.
class Evento {
  const Evento({
    required this.nivel,
    required this.minuto,
    required this.tipo,
    required this.lugarId,
    this.referencia,
    required this.texto,
  });

  final int nivel;

  /// Minutos desde las 22:00 de esa noche.
  final int minuto;
  final TipoEvento tipo;
  final String lugarId;

  /// Id de la pista o del sospechoso involucrado, si aplica.
  final String? referencia;

  /// Frase en tono de cuento para la bitácora.
  final String texto;

  String get hora => horaDeMinuto(minuto);

  Map<String, Object?> toMap() => {
        'nivel': nivel,
        'minuto': minuto,
        'tipo': tipo.name,
        'lugar': lugarId,
        if (referencia != null) 'referencia': referencia,
        'texto': texto,
      };

  factory Evento.fromMap(Map<String, dynamic> m) => Evento(
        nivel: _entero(m, 'nivel', min: 1, max: 2),
        minuto: _entero(m, 'minuto'),
        tipo: _enum(m, 'tipo', TipoEvento.values),
        lugarId: _texto(m, 'lugar'),
        referencia: _textoOpcional(m, 'referencia'),
        texto: _texto(m, 'texto'),
      );
}

/// La partida completa.
class EstadoPartida {
  EstadoPartida({
    required this.id,
    required this.nombre,
    List<String>? etiquetas,
    required this.creada,
    required this.actualizada,
    this.nivel = 1,
    this.minuto = 0,
    required this.lugarActual,
    this.puntuacion = 0,
    this.segundosJugados = 0,
    this.terminada = false,
    this.acusado,
    required this.dificultad,
    required this.nombreGranjero,
    Set<String>? pistasEncontradas,
    Set<String>? puntosRevisados,
    Map<String, EstadoSospechoso>? estados,
    Map<String, Set<String>>? pistasAsignadas,
    List<Evento>? historial,
  })  : etiquetas = etiquetas ?? [],
        pistasEncontradas = pistasEncontradas ?? {},
        puntosRevisados = puntosRevisados ?? {},
        estados = estados ?? {},
        pistasAsignadas = pistasAsignadas ?? {},
        historial = historial ?? [];

  /// Partida nueva con la configuración actual del jugador.
  factory EstadoPartida.nueva({
    required String nombre,
    required Dificultad dificultad,
    required String nombreGranjero,
  }) {
    final ahora = DateTime.now();
    return EstadoPartida(
      id: 'partida_${ahora.millisecondsSinceEpoch}',
      nombre: nombre,
      creada: ahora,
      actualizada: ahora,
      lugarActual: Historia.lugaresDeNivel(1).first.id,
      dificultad: dificultad,
      nombreGranjero: nombreGranjero,
    );
  }

  /// Sube este número si cambias la estructura del archivo.
  static const versionFormato = 1;

  // --- Identidad y metadatos
  final String id;
  String nombre;
  List<String> etiquetas;
  final DateTime creada;
  DateTime actualizada;

  // --- Progreso
  int nivel;
  int minuto; // minutos desde las 22:00 de la noche actual
  String lugarActual;
  int puntuacion;
  int segundosJugados; // tiempo real jugado
  bool terminada;
  String? acusado; // a quién acusó al final (null si todavía no)

  // --- Configuración personalizada (copiada de Opciones al crear la partida)
  Dificultad dificultad;
  String nombreGranjero;

  // --- Investigación
  final Set<String> pistasEncontradas;
  final Set<String> puntosRevisados;
  final Map<String, EstadoSospechoso> estados;
  final Map<String, Set<String>> pistasAsignadas; // sospechoso -> pistas que le asignó
  final List<Evento> historial;

  String get hora => horaDeMinuto(minuto);
  bool get resuelta => terminada && acusado == Historia.culpable;
  EstadoSospechoso estadoDe(String sospechosoId) =>
      estados[sospechosoId] ?? EstadoSospechoso.sinRevisar;

  // ------------------------------------------------------------ A Map (guardar)

  Map<String, Object?> toMap() {
    final idsSospechosos = {
      for (final s in Historia.sospechosos) s.id,
      ...estados.keys,
      ...pistasAsignadas.keys,
    };
    return {
      'version': versionFormato,
      'id': id,
      'nombre': nombre,
      'etiquetas': etiquetas,
      'creada': creada.toIso8601String(),
      'actualizada': actualizada.toIso8601String(),
      'nivel': nivel,
      'minuto': minuto,
      'lugar': lugarActual,
      'puntuacion': puntuacion,
      'segundos': segundosJugados,
      'terminada': terminada,
      if (acusado != null) 'acusado': acusado,
      'configuracion': {'dificultad': dificultad.name, 'granjero': nombreGranjero},
      'pistas': pistasEncontradas.toList(),
      'puntos': puntosRevisados.toList(),
      'sospechosos': [
        for (final s in idsSospechosos)
          {
            'id': s,
            'estado': estadoDe(s).name,
            'pistas': (pistasAsignadas[s] ?? const <String>{}).toList(),
          },
      ],
      'historial': [for (final e in historial) e.toMap()],
    };
  }

  // ----------------------------------------------- Desde Map (cargar y validar)

  factory EstadoPartida.fromMap(Map<String, dynamic> m) {
    if (m.isEmpty) throw const ErrorPartida('El archivo está vacío.');
    final version = _entero(m, 'version', min: 1);
    if (version > versionFormato) {
      throw ErrorPartida('La partida es de una versión más nueva del juego (versión $version).');
    }

    final config = _mapa(m['configuracion'], 'configuracion');
    final lugar = _texto(m, 'lugar');
    if (!Historia.existeLugar(lugar)) throw ErrorPartida('Lugar desconocido: "$lugar".');

    final pistas = _listaTextos(m, 'pistas');
    for (final p in pistas) {
      if (!Historia.existePista(p)) throw ErrorPartida('Pista desconocida: "$p".');
    }
    final puntos = _listaTextos(m, 'puntos');
    for (final p in puntos) {
      if (!Historia.existePunto(p)) throw ErrorPartida('Punto de búsqueda desconocido: "$p".');
    }

    final estados = <String, EstadoSospechoso>{};
    final asignadas = <String, Set<String>>{};
    for (final item in _lista(m, 'sospechosos')) {
      final s = _mapa(item, 'sospechosos');
      final id = _texto(s, 'id');
      if (!Historia.existeSospechoso(id)) throw ErrorPartida('Sospechoso desconocido: "$id".');
      estados[id] = _enum(s, 'estado', EstadoSospechoso.values);
      final suyas = _listaTextos(s, 'pistas');
      for (final p in suyas) {
        if (!pistas.contains(p)) {
          throw ErrorPartida('Al sospechoso "$id" se le asignó una pista no encontrada: "$p".');
        }
      }
      asignadas[id] = suyas.toSet();
    }

    final historial = <Evento>[];
    final eventos = _lista(m, 'historial');
    for (var i = 0; i < eventos.length; i++) {
      try {
        historial.add(Evento.fromMap(_mapa(eventos[i], 'historial')));
      } on ErrorPartida catch (e) {
        throw ErrorPartida('Movimiento ${i + 1} del historial: ${e.mensaje}');
      }
    }

    final acusado = _textoOpcional(m, 'acusado');
    if (acusado != null && !Historia.existeSospechoso(acusado)) {
      throw ErrorPartida('Sospechoso acusado desconocido: "$acusado".');
    }

    return EstadoPartida(
      id: _texto(m, 'id'),
      nombre: _texto(m, 'nombre'),
      etiquetas: _listaTextos(m, 'etiquetas'),
      creada: _fecha(m, 'creada'),
      actualizada: _fecha(m, 'actualizada'),
      nivel: _entero(m, 'nivel', min: 1, max: 2),
      minuto: _entero(m, 'minuto'),
      lugarActual: lugar,
      puntuacion: _entero(m, 'puntuacion', min: -100000),
      segundosJugados: _entero(m, 'segundos'),
      terminada: _booleano(m, 'terminada'),
      acusado: acusado,
      dificultad: _enum(config, 'dificultad', Dificultad.values),
      nombreGranjero: _texto(config, 'granjero'),
      pistasEncontradas: pistas.toSet(),
      puntosRevisados: puntos.toSet(),
      estados: estados,
      pistasAsignadas: asignadas,
      historial: historial,
    );
  }
}

// ----------------------------------------------------------------------------
// Lectura tolerante y validada de campos. Aceptan números y booleanos escritos
// como texto ("120", "true"), porque así llegan desde XML y TXT.

Object _requerido(Map<String, dynamic> m, String clave) {
  final v = m[clave];
  if (v == null || (v is String && v.trim().isEmpty)) {
    throw ErrorPartida('Falta el campo "$clave".');
  }
  return v;
}

String _texto(Map<String, dynamic> m, String clave) => _requerido(m, clave).toString().trim();

String? _textoOpcional(Map<String, dynamic> m, String clave) {
  final v = m[clave]?.toString().trim();
  return v == null || v.isEmpty ? null : v;
}

int _entero(Map<String, dynamic> m, String clave, {int min = 0, int? max}) {
  final v = _requerido(m, clave);
  final n = v is int ? v : int.tryParse(v.toString().trim());
  if (n == null) throw ErrorPartida('El campo "$clave" debe ser un número entero.');
  if (n < min || (max != null && n > max)) {
    throw ErrorPartida('El campo "$clave" tiene un valor fuera de rango ($n).');
  }
  return n;
}

bool _booleano(Map<String, dynamic> m, String clave) {
  final v = _requerido(m, clave);
  if (v is bool) return v;
  return switch (v.toString().trim().toLowerCase()) {
    'true' || 'sí' || 'si' => true,
    'false' || 'no' => false,
    _ => throw ErrorPartida('El campo "$clave" debe ser verdadero o falso.'),
  };
}

DateTime _fecha(Map<String, dynamic> m, String clave) =>
    DateTime.tryParse(_texto(m, clave)) ??
    (throw ErrorPartida('El campo "$clave" no es una fecha válida.'));

T _enum<T extends Enum>(Map<String, dynamic> m, String clave, List<T> valores) {
  final t = _texto(m, clave);
  return valores.asNameMap()[t] ?? (throw ErrorPartida('Valor inválido en "$clave": "$t".'));
}

List<Object?> _lista(Map<String, dynamic> m, String clave) {
  final v = m[clave];
  if (v == null) return const [];
  if (v is List) return v;
  throw ErrorPartida('El campo "$clave" debe ser una lista.');
}

List<String> _listaTextos(Map<String, dynamic> m, String clave) => [
      for (final x in _lista(m, clave))
        if (x != null && x.toString().trim().isNotEmpty) x.toString().trim(),
    ];

Map<String, dynamic> _mapa(Object? v, String nombre) {
  if (v is Map) return v.map((k, valor) => MapEntry(k.toString(), valor));
  throw ErrorPartida('El campo "$nombre" está dañado.');
}
