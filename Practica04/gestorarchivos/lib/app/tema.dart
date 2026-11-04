import 'package:flutter/material.dart';

enum TemaApp {
  guinda('Guinda IPN', Color(0xFF6C1D45)),
  azul('Azul IPN', Color(0xFF005A9C));

  const TemaApp(this.etiqueta, this.semilla);
  final String etiqueta;
  final Color semilla;
}

class TemasApp {
  static ThemeData claro(TemaApp tema) => _construir(tema, Brightness.light);
  static ThemeData oscuro(TemaApp tema) => _construir(tema, Brightness.dark);

  static ThemeData _construir(TemaApp tema, Brightness brillo) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: tema.semilla,
      brightness: brillo,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final esClaro = brillo == Brightness.light;
    return ThemeData(
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: esClaro ? colorScheme.primary : colorScheme.primaryContainer,
        foregroundColor: esClaro ? colorScheme.onPrimary : colorScheme.onPrimaryContainer,
      ),
    );
  }
}