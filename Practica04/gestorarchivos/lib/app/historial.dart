import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/entrada_archivo.dart';

/// Archivos recientes y favoritos, persistentes entre sesiones.
/// Se guardan como JSON en SharedPreferences, que usa SharedPreferences/DataStore en
/// Android y NSUserDefaults en iOS: una solución compatible con ambas plataformas.
class Historial extends ChangeNotifier {
  static const _claveRecientes = 'recientes';
  static const _claveFavoritos = 'favoritos';
  static const _maxRecientes = 15;

  final _prefs = SharedPreferencesAsync();
  List<EntradaArchivo> _recientes = [];
  List<EntradaArchivo> _favoritos = [];

  List<EntradaArchivo> get recientes => List.unmodifiable(_recientes);
  List<EntradaArchivo> get favoritos => List.unmodifiable(_favoritos);

  Future<void> cargar() async {
    _recientes = await _leer(_claveRecientes);
    _favoritos = await _leer(_claveFavoritos);
    notifyListeners();
  }

  bool esFavorito(EntradaArchivo e) => _favoritos.contains(e);

  /// Se llama al abrir un archivo: queda primero en recientes (sin duplicados).
  Future<void> registrarApertura(EntradaArchivo e) async {
    _recientes = [e, ..._recientes.where((r) => r != e)].take(_maxRecientes).toList();
    notifyListeners();
    await _escribir(_claveRecientes, _recientes);
  }

  Future<void> alternarFavorito(EntradaArchivo e) async {
    _favoritos =
        esFavorito(e) ? _favoritos.where((f) => f != e).toList() : [e, ..._favoritos];
    notifyListeners();
    await _escribir(_claveFavoritos, _favoritos);
  }

  /// Olvida un archivo que se eliminó, renombró o movió.
  Future<void> olvidar(EntradaArchivo e) => _filtrar((x) => x != e);

  /// Olvida todos los archivos de una fuente (p. ej. al quitar el acceso a una carpeta).
  Future<void> olvidarFuente(String fuenteId) => _filtrar((x) => x.fuenteId != fuenteId);

  Future<void> borrarRecientes() async {
    _recientes = [];
    notifyListeners();
    await _escribir(_claveRecientes, _recientes);
  }

  Future<void> _filtrar(bool Function(EntradaArchivo) conservar) async {
    _recientes = _recientes.where(conservar).toList();
    _favoritos = _favoritos.where(conservar).toList();
    notifyListeners();
    await _escribir(_claveRecientes, _recientes);
    await _escribir(_claveFavoritos, _favoritos);
  }

  Future<List<EntradaArchivo>> _leer(String clave) async {
    try {
      final guardados = await _prefs.getStringList(clave) ?? [];
      return [for (final s in guardados) _desdeJson(jsonDecode(s) as Map<String, dynamic>)];
    } catch (e) {
      debugPrint('No se pudo leer "$clave": $e'); // datos dañados: se empieza de cero
      return [];
    }
  }

  Future<void> _escribir(String clave, List<EntradaArchivo> lista) =>
      _prefs.setStringList(clave, [for (final e in lista) jsonEncode(_aJson(e))]);

  static Map<String, Object?> _aJson(EntradaArchivo e) => {
        'fuenteId': e.fuenteId,
        'id': e.id,
        'nombre': e.nombre,
        'tamano': e.tamano,
        'modificado': e.modificado?.millisecondsSinceEpoch,
        'mime': e.mime,
      };

  static EntradaArchivo _desdeJson(Map<String, dynamic> j) {
    final modificado = j['modificado'] as int?;
    return EntradaArchivo(
      fuenteId: j['fuenteId'] as String,
      id: j['id'] as String,
      nombre: j['nombre'] as String,
      esCarpeta: false,
      tamano: j['tamano'] as int?,
      modificado: modificado == null ? null : DateTime.fromMillisecondsSinceEpoch(modificado),
      mime: j['mime'] as String?,
    );
  }
}
