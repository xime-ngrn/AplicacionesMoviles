import 'package:flutter/material.dart';

import '../modelos/entrada_archivo.dart';
import '../utils/formato.dart';
import 'icono_archivo.dart';

Future<void> mostrarDetalles(BuildContext context, EntradaArchivo e) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconoArchivo(entrada: e, tamano: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(e.nombre, style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Dato('Tipo', e.esCarpeta ? 'Carpeta' : (e.mime ?? 'No disponible')),
            _Dato('Tamaño', e.esCarpeta ? 'No aplica' : formatoTamano(e.tamano)),
            _Dato('Modificado', formatoFecha(e.modificado)),
            _Dato('Creado', formatoFecha(e.creado)),
            _Dato('Ubicación', e.id),
          ],
        ),
      ),
    ),
  );
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: tema.textTheme.labelMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          ),
          SelectableText(valor, style: tema.textTheme.bodyLarge),
        ],
      ),
    );
  }
}