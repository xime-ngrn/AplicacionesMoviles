import 'package:flutter/material.dart';

/// Resaltado de sintaxis propio para JSON y XML (sin paquetes externos).
/// Reutilizable en el juego para mostrar el contenido de los archivos de guardado.

/// Colores del resaltado, tomados del tema activo (Guinda/Azul, claro/oscuro).
class PaletaCodigo {
  PaletaCodigo.desde(ColorScheme c)
      : clave = c.primary,
        cadena = c.tertiary,
        numero = c.secondary,
        puntuacion = c.onSurfaceVariant,
        comentario = c.outline,
        texto = c.onSurface;

  final Color clave; // claves JSON y nombres de etiquetas XML
  final Color cadena; // textos entre comillas y valores de atributos
  final Color numero; // números, true/false/null y nombres de atributos
  final Color puntuacion;
  final Color comentario;
  final Color texto;
}

final _tokensJson = RegExp(
  r'("(?:[^"\\]|\\.)*")(\s*:)?' // 1: cadena · 2: ":" si la cadena es una clave
  r'|(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)' // 3: número
  r'|\b(true|false|null)\b' // 4: literal
  r'|([{}\[\],:])', // 5: puntuación
);

/// Colorea un texto JSON. Funciona aunque el JSON sea inválido (colorea lo que reconoce).
TextSpan resaltarJson(String codigo, PaletaCodigo paleta) {
  final partes = <TextSpan>[];
  var ultimo = 0;
  for (final m in _tokensJson.allMatches(codigo)) {
    if (m.start > ultimo) partes.add(TextSpan(text: codigo.substring(ultimo, m.start)));
    if (m.group(1) != null) {
      final esClave = m.group(2) != null;
      partes.add(TextSpan(
        text: m.group(1),
        style: TextStyle(
          color: esClave ? paleta.clave : paleta.cadena,
          fontWeight: esClave ? FontWeight.w600 : null,
        ),
      ));
      if (esClave) {
        partes.add(TextSpan(text: m.group(2), style: TextStyle(color: paleta.puntuacion)));
      }
    } else if (m.group(3) != null || m.group(4) != null) {
      partes.add(TextSpan(text: m.group(0), style: TextStyle(color: paleta.numero)));
    } else {
      partes.add(TextSpan(text: m.group(0), style: TextStyle(color: paleta.puntuacion)));
    }
    ultimo = m.end;
  }
  if (ultimo < codigo.length) partes.add(TextSpan(text: codigo.substring(ultimo)));
  return TextSpan(style: TextStyle(color: paleta.texto), children: partes);
}

final _tokensXml = RegExp(
  r'(<!--[\s\S]*?-->)' // 1: comentario
  r'|(<!\[CDATA\[[\s\S]*?\]\]>)' // 2: CDATA
  r'|(<\?[\s\S]*?\?>|<!DOCTYPE[\s\S]*?>)' // 3: declaración <?xml ?> o DOCTYPE
  r'|(</?)([\w:.\-]+)([^<>]*?)(/?>)', // 4: "<" o "</" · 5: nombre · 6: atributos · 7: ">" o "/>"
);

final _atributosXml = RegExp(r'''([\w:.\-]+)(\s*=\s*)("[^"]*"|'[^']*')''');

/// Colorea un texto XML: etiquetas, atributos, valores y comentarios.
TextSpan resaltarXml(String codigo, PaletaCodigo paleta) {
  final partes = <TextSpan>[];
  final puntuacion = TextStyle(color: paleta.puntuacion);
  var ultimo = 0;
  for (final m in _tokensXml.allMatches(codigo)) {
    if (m.start > ultimo) partes.add(TextSpan(text: codigo.substring(ultimo, m.start)));
    if (m.group(1) != null || m.group(3) != null) {
      partes.add(TextSpan(
        text: m.group(0),
        style: TextStyle(color: paleta.comentario, fontStyle: FontStyle.italic),
      ));
    } else if (m.group(2) != null) {
      partes.add(TextSpan(text: m.group(0), style: TextStyle(color: paleta.cadena)));
    } else {
      partes.add(TextSpan(text: m.group(4), style: puntuacion));
      partes.add(TextSpan(
        text: m.group(5),
        style: TextStyle(color: paleta.clave, fontWeight: FontWeight.w600),
      ));
      partes.addAll(_resaltarAtributos(m.group(6)!, paleta));
      partes.add(TextSpan(text: m.group(7), style: puntuacion));
    }
    ultimo = m.end;
  }
  if (ultimo < codigo.length) partes.add(TextSpan(text: codigo.substring(ultimo)));
  return TextSpan(style: TextStyle(color: paleta.texto), children: partes);
}

List<TextSpan> _resaltarAtributos(String texto, PaletaCodigo paleta) {
  final partes = <TextSpan>[];
  var ultimo = 0;
  for (final m in _atributosXml.allMatches(texto)) {
    if (m.start > ultimo) partes.add(TextSpan(text: texto.substring(ultimo, m.start)));
    partes
      ..add(TextSpan(text: m.group(1), style: TextStyle(color: paleta.numero)))
      ..add(TextSpan(text: m.group(2), style: TextStyle(color: paleta.puntuacion)))
      ..add(TextSpan(text: m.group(3), style: TextStyle(color: paleta.cadena)));
    ultimo = m.end;
  }
  if (ultimo < texto.length) partes.add(TextSpan(text: texto.substring(ultimo)));
  return partes;
}
