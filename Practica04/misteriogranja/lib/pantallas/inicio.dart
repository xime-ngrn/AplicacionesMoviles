import 'package:flutter/material.dart';

import '../app/efectos.dart';
import '../app/opciones.dart';
import '../juego/motor.dart';
import '../widgets/fondo_granja.dart';
import 'juego.dart';
import 'opciones.dart';

/// Portada del juego con el menú principal sobre el fondo animado de la granja.
/// Los botones "Nueva partida", "Continuar" y "Partidas" se conectan en los pasos J3 a J5.
class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key, required this.opciones, required this.efectos});

  final Opciones opciones;
  final Efectos efectos;

  void _pendiente(BuildContext context, String paso) {
    efectos.reproducir(Sonido.clic);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Esta parte se programa en el paso $paso.')));
  }

  void _nuevaPartida(BuildContext context) {
    efectos.reproducir(Sonido.clic);
    final motor = MotorJuego.nueva(
      dificultad: opciones.dificultad,
      granjero: opciones.nombreGranjero,
    );
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PantallaJuego(motor: motor, efectos: efectos),
    ));
  }

  void _abrirOpciones(BuildContext context) {
    efectos.reproducir(Sonido.clic);
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PantallaOpciones(opciones: opciones, efectos: efectos),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: FondoGranja()),
          SafeArea(
            child: LayoutBuilder(
              // Desplazable para que quepa en horizontal; el menú queda arriba de la milpa.
              builder: (context, restricciones) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: restricciones.maxHeight - 32),
                  child: Align(
                    alignment: const Alignment(0, -0.45),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Card(
                        // Semitransparente: se lee bien sin tapar el paisaje.
                        color: tema.colorScheme.surface.withValues(alpha: 0.88),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _menu(context, tema),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context, ThemeData tema) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.agriculture, size: 72, color: tema.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          'Misterio en la Granja',
          textAlign: TextAlign.center,
          style: tema.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: opciones,
          builder: (context, _) => Text(
            '¿Quién se está comiendo el maíz de ${opciones.nombreGranjero}?',
            textAlign: TextAlign.center,
            style: tema.textTheme.titleMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => _nuevaPartida(context),
          icon: const Icon(Icons.search),
          label: const Text('Nueva partida'),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => _pendiente(context, 'J4'),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Continuar partida'),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => _pendiente(context, 'J5'),
          icon: const Icon(Icons.folder_open),
          label: const Text('Partidas guardadas'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _abrirOpciones(context),
          icon: const Icon(Icons.settings),
          label: const Text('Opciones'),
        ),
      ],
    );
  }
}
