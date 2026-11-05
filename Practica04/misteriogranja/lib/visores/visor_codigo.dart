import 'package:flutter/material.dart';

import 'resaltado.dart';

enum LenguajeCodigo { texto, json, xml }

/// Muestra texto con letra monoespaciada y resaltado de sintaxis opcional.
/// Se puede seleccionar y copiar. Reutilizable en el juego para ver partidas guardadas.
class VisorCodigo extends StatelessWidget {
  const VisorCodigo({
    super.key,
    required this.codigo,
    this.lenguaje = LenguajeCodigo.texto,
    this.ajustarLineas = false,
  });

  final String codigo;
  final LenguajeCodigo lenguaje;

  /// true: las líneas largas bajan de renglón (texto normal).
  /// false: se desplaza en horizontal (código, para no romper la indentación).
  final bool ajustarLineas;

  /// Por encima de este tamaño se muestra sin colores para que la app no se trabe.
  static const _limiteResaltado = 300 * 1024;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final paleta = PaletaCodigo.desde(tema.colorScheme);
    final estilo = tema.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Courier'],
      height: 1.4,
    );
    final resaltar = codigo.length <= _limiteResaltado;
    final span = switch (lenguaje) {
      LenguajeCodigo.json when resaltar => resaltarJson(codigo, paleta),
      LenguajeCodigo.xml when resaltar => resaltarXml(codigo, paleta),
      _ => TextSpan(text: codigo),
    };
    final texto = SelectableText.rich(span, style: estilo);

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ajustarLineas
            ? texto
            : SingleChildScrollView(scrollDirection: Axis.horizontal, child: texto),
      ),
    );
  }
}
