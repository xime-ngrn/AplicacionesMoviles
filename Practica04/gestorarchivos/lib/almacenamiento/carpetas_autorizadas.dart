import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:saf_util/saf_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'errores.dart';
import 'fuente_archivos.dart';
import 'fuente_local.dart';
import 'fuente_saf.dart';

/// Carpeta que el usuario autorizó con el selector del sistema.
class CarpetaAutorizada {
  const CarpetaAutorizada({required this.id, required this.nombre, this.marcador});

  /// Android: URI content:// del árbol SAF. iOS: ruta de la carpeta.
  final String id;
  final String nombre;

  /// Solo iOS: "security-scoped bookmark" (en base64) que recupera el acceso al reabrir la app.
  final String? marcador;

  Map<String, Object?> toJson() => {'id': id, 'nombre': nombre, 'marcador': marcador};

  factory CarpetaAutorizada.fromJson(Map<String, dynamic> json) => CarpetaAutorizada(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        marcador: json['marcador'] as String?,
      );
}

/// Lista persistente de carpetas autorizadas, con el código específico de cada plataforma:
/// - Android: Storage Access Framework (saf_util) con permiso persistente.
/// - iOS: selector de Archivos nativo (canal "gestorarchivos/carpetas_ios" en AppDelegate.swift).
class CarpetasAutorizadas extends ChangeNotifier {
  static const _clave = 'carpetas_autorizadas';
  static const _canalIos = MethodChannel('gestorarchivos/carpetas_ios');
  static const _sinAcceso = 'Se perdió el acceso a esta carpeta: el permiso se revocó, '
      'o la carpeta se movió o se eliminó. Vuelve a autorizarla.';

  final _prefs = SharedPreferencesAsync();
  final _saf = SafUtil();

  List<CarpetaAutorizada> _carpetas = [];
  List<CarpetaAutorizada> get carpetas => List.unmodifiable(_carpetas);

  /// El selector de carpetas solo existe en Android e iOS.
  static bool get disponible => Platform.isAndroid || Platform.isIOS;

  /// Identificador de la fuente de una carpeta (se guarda en recientes y favoritos).
  static String fuenteIdDe(CarpetaAutorizada c) =>
      Platform.isAndroid ? 'saf:${c.id}' : 'ios:${c.id}';

  Future<void> cargar() async {
    try {
      final guardadas = await _prefs.getStringList(_clave) ?? [];
      _carpetas = [
        for (final s in guardadas)
          CarpetaAutorizada.fromJson(jsonDecode(s) as Map<String, dynamic>),
      ];
    } catch (e) {
      debugPrint('No se pudieron leer las carpetas autorizadas: $e');
      _carpetas = [];
    }
    notifyListeners();
  }

  /// Abre el selector del sistema. Devuelve null si el usuario canceló.
  Future<CarpetaAutorizada?> agregar() async {
    try {
      final nueva = Platform.isAndroid ? await _elegirAndroid() : await _elegirIos();
      if (nueva == null) return null;
      _carpetas = [..._carpetas.where((c) => c.id != nueva.id), nueva];
      await _guardar();
      notifyListeners();
      return nueva;
    } catch (e) {
      throw ErrorArchivo.desde(e);
    }
  }

  Future<CarpetaAutorizada?> _elegirAndroid() async {
    // ACTION_OPEN_DOCUMENT_TREE: el permiso queda guardado (sobrevive a reinicios)
    // y solo cubre la carpeta elegida y su contenido.
    final d = await _saf.pickDirectory(writePermission: true, persistablePermission: true);
    if (d == null) return null;
    return CarpetaAutorizada(id: d.uri, nombre: d.name);
  }

  Future<CarpetaAutorizada?> _elegirIos() async {
    final r = await _canalIos.invokeMapMethod<String, Object?>('elegirCarpeta');
    if (r == null) return null;
    final marcador = r['marcador'] as Uint8List?;
    return CarpetaAutorizada(
      id: r['ruta'] as String,
      nombre: r['nombre'] as String,
      marcador: marcador == null ? null : base64Encode(marcador),
    );
  }

  /// Quita la carpeta de la lista y devuelve el permiso al sistema.
  /// No borra ningún archivo.
  Future<void> quitar(CarpetaAutorizada c) async {
    try {
      if (Platform.isAndroid) {
        await _saf.releasePersistedPermission(c.id, read: true, write: true);
      } else if (Platform.isIOS) {
        await _canalIos.invokeMethod<void>('liberar', c.id);
      }
    } catch (e) {
      debugPrint('El permiso ya no existía: $e'); // si ya estaba revocado, igual se quita
    }
    _carpetas = _carpetas.where((x) => x.id != c.id).toList();
    await _guardar();
    notifyListeners();
  }

  /// Comprueba que el acceso siga vigente y devuelve la fuente para explorar la carpeta.
  /// Lanza ErrorArchivo si el permiso se revocó o la carpeta ya no existe.
  Future<FuenteArchivos> abrir(CarpetaAutorizada c) async {
    if (Platform.isAndroid) {
      final fuente = FuenteSaf(uriRaiz: c.id, nombre: c.nombre);
      if (!await fuente.tieneAcceso()) throw const ErrorArchivo(_sinAcceso);
      return fuente;
    }
    // iOS: el marcador recupera el acceso aunque la app se haya cerrado.
    var ruta = c.id;
    final marcador = c.marcador;
    if (marcador != null) {
      try {
        final r = await _canalIos.invokeMapMethod<String, Object?>(
            'abrirMarcador', base64Decode(marcador));
        ruta = r?['ruta'] as String? ?? ruta;
      } on PlatformException {
        throw const ErrorArchivo(_sinAcceso);
      }
    }
    if (!await Directory(ruta).exists()) throw const ErrorArchivo(_sinAcceso);
    return FuenteLocal.carpetaAutorizada(ruta, id: fuenteIdDe(c), nombre: c.nombre);
  }

  /// Busca la carpeta autorizada de un archivo de recientes o favoritos.
  /// Devuelve null si esa carpeta ya no está en la lista.
  Future<FuenteArchivos?> fuentePorId(String fuenteId) async {
    for (final c in _carpetas) {
      if (fuenteIdDe(c) == fuenteId) return abrir(c);
    }
    return null;
  }

  Future<void> _guardar() => _prefs.setStringList(
      _clave, [for (final c in _carpetas) jsonEncode(c.toJson())]);
}
