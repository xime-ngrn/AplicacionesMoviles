import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Funciones del sistema operativo para compartir y exportar partidas.
/// (Reutilizado del gestor de archivos.)

/// Hoja de compartir del sistema (correo, mensajería, Drive, AirDrop, etc.).
/// [origen] es necesario en iPad para saber desde dónde se abre la hoja.
Future<void> compartirArchivo(String ruta, {String? mime, Rect? origen}) async {
  await SharePlus.instance.share(ShareParams(
    files: [XFile(ruta, mimeType: mime)],
    sharePositionOrigin: origen,
  ));
}

/// Guarda una copia donde el usuario elija: "Crear documento" de SAF en Android y
/// selector de Archivos en iOS. Devuelve false si el usuario canceló.
Future<bool> exportarBytes(String nombre, Uint8List bytes, {String? mime}) async {
  final destino = await FilePicker.saveFile(
    fileName: nombre,
    bytes: bytes,
    mimeType: mime ?? 'application/octet-stream',
  );
  return destino != null;
}

/// Rectángulo del widget en pantalla, para [compartirArchivo] en iPad.
Rect? origenDe(BuildContext context) {
  final caja = context.findRenderObject();
  if (caja is! RenderBox || !caja.hasSize) return null;
  return caja.localToGlobal(Offset.zero) & caja.size;
}
