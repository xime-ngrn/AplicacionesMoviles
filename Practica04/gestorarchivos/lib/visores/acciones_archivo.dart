import 'package:flutter/material.dart';

import '../almacenamiento/errores.dart';
import '../almacenamiento/fuente_archivos.dart';
import '../modelos/entrada_archivo.dart';
import 'acciones_sistema.dart';

enum AccionArchivo { abrirCon, compartir, exportar }

/// Diálogo para formatos que la app no sabe mostrar (PDF, ZIP, audio, etc.):
/// permite abrirlos con otra app, compartirlos o exportar una copia.
Future<void> mostrarOpcionesArchivo(
  BuildContext context, {
  required FuenteArchivos fuente,
  required EntradaArchivo entrada,
}) async {
  final accion = await showDialog<AccionArchivo>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(entrada.nombre),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            'La app no puede mostrar este tipo de archivo '
            '(${entrada.mime ?? 'tipo desconocido'}). Puedes usar estas opciones del sistema:',
          ),
        ),
        _opcion(context, AccionArchivo.abrirCon, Icons.open_in_new, 'Abrir con otra app'),
        _opcion(context, AccionArchivo.compartir, Icons.share_outlined, 'Compartir'),
        _opcion(context, AccionArchivo.exportar, Icons.save_alt, 'Exportar una copia…'),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ),
        ),
      ],
    ),
  );
  if (accion != null && context.mounted) {
    await ejecutarAccion(context, accion, fuente: fuente, entrada: entrada);
  }
}

Widget _opcion(BuildContext context, AccionArchivo accion, IconData icono, String texto) {
  return SimpleDialogOption(
    onPressed: () => Navigator.pop(context, accion),
    child: Row(children: [Icon(icono), const SizedBox(width: 16), Text(texto)]),
  );
}

/// Ejecuta una acción del sistema e informa el resultado con un SnackBar.
Future<void> ejecutarAccion(
  BuildContext context,
  AccionArchivo accion, {
  required FuenteArchivos fuente,
  required EntradaArchivo entrada,
}) async {
  final mensajero = ScaffoldMessenger.of(context);
  final origen = origenDe(context);
  void avisar(String texto) => mensajero.showSnackBar(SnackBar(content: Text(texto)));
  try {
    switch (accion) {
      case AccionArchivo.abrirCon:
        final error = await abrirConOtraApp(await fuente.rutaLocal(entrada), mime: entrada.mime);
        if (error != null) avisar(error);
      case AccionArchivo.compartir:
        await compartirArchivo(await fuente.rutaLocal(entrada),
            mime: entrada.mime, origen: origen);
      case AccionArchivo.exportar:
        final guardado =
            await exportarBytes(entrada.nombre, await fuente.leerBytes(entrada), mime: entrada.mime);
        avisar(guardado ? 'Copia exportada correctamente.' : 'Exportación cancelada.');
    }
  } catch (e) {
    avisar('${ErrorArchivo.desde(e)}');
  }
}
