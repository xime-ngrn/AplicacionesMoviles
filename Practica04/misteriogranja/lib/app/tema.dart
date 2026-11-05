import 'package:flutter/material.dart';

/// Temas del juego. Guinda y Azul son obligatorios según la práctica;
/// "Granja" es el tema propio del juego (cambia el color semilla a tu gusto).
enum TemaApp {
  granja('Granja', Color(0xFF5B8C2A)), // verde milpa
  guinda('Guinda IPN', Color(0xFF6C1D45)),
  azul('Azul ESCOM', Color(0xFF005A9C));

  const TemaApp(this.etiqueta, this.semilla);
  final String etiqueta;
  final Color semilla;
}

/// Construye el tema claro u oscuro a partir del color semilla.
/// La app usa ThemeMode.system, así que sigue el modo del sistema automáticamente.
class TemasApp {
  static ThemeData claro(TemaApp tema) => _construir(tema, Brightness.light);
  static ThemeData oscuro(TemaApp tema) => _construir(tema, Brightness.dark);

  static ThemeData _construir(TemaApp tema, Brightness brillo) {
    final colores = ColorScheme.fromSeed(
      seedColor: tema.semilla,
      brightness: brillo,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final esClaro = brillo == Brightness.light;
    return ThemeData(
      colorScheme: colores,
      appBarTheme: AppBarTheme(
        backgroundColor: esClaro ? colores.primary : colores.primaryContainer,
        foregroundColor: esClaro ? colores.onPrimary : colores.onPrimaryContainer,
      ),
    );
  }
}
