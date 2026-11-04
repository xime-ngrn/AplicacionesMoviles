import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart';

class Ajustes extends ChangeNotifier {
  static const _claveTema = 'tema';
  final _prefs = SharedPreferencesAsync();
  
  TemaApp _tema = TemaApp.guinda;
  TemaApp get tema => _tema;

  Future<void> cargar() async {
    try {
      final guardado = await _prefs.getString(_claveTema);
      _tema = TemaApp.values.firstWhere(
        (t) => t.name == guardado,
        orElse: () => TemaApp.guinda);
    } catch (e) {
      debugPrint('Error al cargar ajustes de tema: $e');
    }
  }

  Future<void> cambiarTema(TemaApp nuevo) async {
    if(nuevo == tema) return;
    _tema = nuevo;
    notifyListeners();
    try {
      await _prefs.setString(_claveTema, nuevo.name);
    } catch (e) {
      debugPrint('Error al guardar ajustes de tema: $e');
    }
  }
}
