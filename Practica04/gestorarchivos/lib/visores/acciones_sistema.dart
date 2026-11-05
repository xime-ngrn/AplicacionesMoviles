import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

/// Funciones del sistema operativo para un archivo local (ruta real del dispositivo).
/// No dependen del resto del gestor: se pueden copiar tal cual al juego para
/// compartir y exportar partidas.

/// Abre el archivo con otra app instalada (Intent ACTION_VIEW en Android,
/// UIDocumentInteractionController en iOS). Devuelve un mensaje de error o null si se abrió.
Future<String?> abrirConOtraApp(String ruta, {String? mime}) async {
  final r = await OpenFilex.open(ruta, type: mime);
  return switch (r.type) {
    ResultType.done => null,
    ResultType.noAppToOpen => 'No hay ninguna app instalada que pueda abrir este archivo.',
    ResultType.fileNotFound => 'El archivo ya no existe.',
    ResultType.permissionDenied => 'No hay permiso para abrir el archivo.',
    ResultType.error => 'No se pudo abrir el archivo: ${r.message}',
  };
}

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
