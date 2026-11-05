/// Valida un nombre de partida o de archivo. Devuelve el mensaje de error, o null si es válido.
/// (Copiado del gestor de archivos: los nombres de partida también son nombres de archivo.)
String? validarNombre(String nombre) {
  final limpio = nombre.trim();
  if (limpio.isEmpty) return 'El nombre no puede estar vacío.';
  if (limpio == '.' || limpio == '..') return 'Ese nombre no está permitido.';
  if (limpio.length > 60) return 'Usa como máximo 60 caracteres.';
  if (RegExp(r'[\\/:*?"<>|]').hasMatch(limpio)) {
    return r'No uses estos caracteres: \ / : * ? " < > |';
  }
  return null;
}
