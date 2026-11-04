import 'dart:io';

import 'package:flutter/services.dart';

class ErrorArchivo implements Exception {
  const ErrorArchivo(this.mensaje);
  final String mensaje;

  factory ErrorArchivo.desde(Object error) {
    if(error is ErrorArchivo) return error;
    if(error is FileSystemException) {
      return switch(error.osError?.errorCode){
        2 => const ErrorArchivo('Archivo o carpeta no encontrado'),
        1 || 13 => const ErrorArchivo('Permiso denegado para acceder al archivo o carpeta'),
        17 => const ErrorArchivo('El archivo o carpeta ya existe'),
        28 => const ErrorArchivo('No hay espacio suficiente para guardar el archivo'),
        30 => const ErrorArchivo('La ubicación del archivo o carpeta es de solo lectura'),
        _ => ErrorArchivo('Error de sistema: ${error.message}'),
      };
    }
    if(error is PlatformException) {
      return ErrorArchivo(error.message ?? 'El sistema rechazó la operación: ${error.code}');
    }
    return ErrorArchivo('Error inesperado: $error');
  }

  @override
  String toString() => mensaje;
}