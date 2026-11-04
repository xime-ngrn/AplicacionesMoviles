import 'dart:typed_data';

import '../modelos/entrada_archivo.dart';

abstract class FuenteArchivos {
  String get id;
  String get nombre;

  EntradaArchivo get raiz;

  Future<List<EntradaArchivo>> listar(EntradaArchivo carpeta);
  Future<Uint8List> leerBytes(EntradaArchivo archivo);

  Future<String> rutaLocal(EntradaArchivo archivo);

  Future<EntradaArchivo> crearCarpeta(EntradaArchivo padre, String nombre);
  Future<EntradaArchivo> renombrar(EntradaArchivo entrada, String nuevoNombre);
  Future<EntradaArchivo> copiar(EntradaArchivo entrada, EntradaArchivo carpetaDestino);
  Future<EntradaArchivo> mover(EntradaArchivo entrada, EntradaArchivo carpetaDestino);
  Future<void> eliminar(EntradaArchivo entrada);
}

int ordenarEntradas(EntradaArchivo a, EntradaArchivo b) {
  if(a.esCarpeta != b.esCarpeta) return a.esCarpeta ? -1 : 1;
  return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
}

String? validarNombre(String nombre) {
  final limpio = nombre.trim();
  if (limpio.isEmpty) return 'El nombre no puede estar vacío.';
  if (limpio == '.' || limpio == '..') return 'Ese nombre no está permitido.';
  if (RegExp(r'[\\/:*?"<>|]').hasMatch(limpio)) {
    return r'No uses estos caracteres: \ / : * ? " < > |';
  }
  return null;
}