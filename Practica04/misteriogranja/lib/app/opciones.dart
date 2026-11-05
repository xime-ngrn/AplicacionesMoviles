import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart';

/// Formatos en los que se puede guardar una partida.
enum FormatoGuardado {
  json('JSON', 'json'),
  xml('XML', 'xml'),
  txt('TXT (bitácora)', 'txt');

  const FormatoGuardado(this.etiqueta, this.extension);
  final String etiqueta;
  final String extension;
}

/// Modos de juego (configuración de jugabilidad).
enum Dificultad {
  aprendiz('Aprendiz', 'Las pistas importantes se resaltan y la noche no tiene límite.'),
  detective('Detective', 'La noche tiene horas limitadas y equivocarse resta puntos.');

  const Dificultad(this.etiqueta, this.descripcion);
  final String etiqueta;
  final String descripcion;
}

/// Opciones del jugador, persistentes entre sesiones (SharedPreferences:
/// SharedPreferences/DataStore en Android y NSUserDefaults en iOS).
/// También se copian dentro de cada partida como "configuraciones personalizadas".
class Opciones extends ChangeNotifier {
  final _prefs = SharedPreferencesAsync();

  TemaApp _tema = TemaApp.granja;
  FormatoGuardado _formato = FormatoGuardado.json;
  Dificultad _dificultad = Dificultad.aprendiz;
  bool _sonido = true;
  bool _vibracion = true;
  String _nombreGranjero = 'Don Chema';

  TemaApp get tema => _tema;
  FormatoGuardado get formato => _formato;
  Dificultad get dificultad => _dificultad;
  bool get sonido => _sonido;
  bool get vibracion => _vibracion;
  String get nombreGranjero => _nombreGranjero;

  Future<void> cargar() async {
    try {
      _tema = TemaApp.values.asNameMap()[await _prefs.getString('tema')] ?? _tema;
      _formato =
          FormatoGuardado.values.asNameMap()[await _prefs.getString('formato')] ?? _formato;
      _dificultad =
          Dificultad.values.asNameMap()[await _prefs.getString('dificultad')] ?? _dificultad;
      _sonido = await _prefs.getBool('sonido') ?? _sonido;
      _vibracion = await _prefs.getBool('vibracion') ?? _vibracion;
      _nombreGranjero = await _prefs.getString('nombre_granjero') ?? _nombreGranjero;
    } catch (e) {
      debugPrint('No se pudieron leer las opciones; se usan las predeterminadas: $e');
    }
    notifyListeners();
  }

  Future<void> cambiarTema(TemaApp valor) => _cambiar(() => _tema = valor, 'tema', valor.name);

  Future<void> cambiarFormato(FormatoGuardado valor) =>
      _cambiar(() => _formato = valor, 'formato', valor.name);

  Future<void> cambiarDificultad(Dificultad valor) =>
      _cambiar(() => _dificultad = valor, 'dificultad', valor.name);

  Future<void> cambiarSonido(bool valor) => _cambiar(() => _sonido = valor, 'sonido', valor);

  Future<void> cambiarVibracion(bool valor) =>
      _cambiar(() => _vibracion = valor, 'vibracion', valor);

  Future<void> cambiarNombre(String valor) =>
      _cambiar(() => _nombreGranjero = valor.trim(), 'nombre_granjero', valor.trim());

  /// Aplica el cambio en memoria (la UI se actualiza al instante) y luego lo guarda.
  Future<void> _cambiar(VoidCallback aplicar, String clave, Object valor) async {
    aplicar();
    notifyListeners();
    try {
      switch (valor) {
        case final bool b:
          await _prefs.setBool(clave, b);
        case final String s:
          await _prefs.setString(clave, s);
      }
    } catch (e) {
      debugPrint('No se pudo guardar la opción "$clave": $e');
    }
  }
}
