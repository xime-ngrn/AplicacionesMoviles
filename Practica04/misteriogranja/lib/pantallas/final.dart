import 'dart:async';

import 'package:flutter/material.dart';

import '../app/efectos.dart';
import '../juego/datos_historia.dart';
import '../juego/modelo.dart';
import '../juego/motor.dart';
import '../widgets/fondo_granja.dart';
import '../widgets/retrato_animal.dart';
import 'bitacora.dart';
import 'juego.dart';

/// Pantalla final: amanece en la granja, se revela al culpable (de silueta a color),
/// se cuenta el desenlace y se muestran la puntuación, el rango y las estadísticas.
class PantallaFinal extends StatefulWidget {
  const PantallaFinal({super.key, required this.motor, required this.efectos});

  final MotorJuego motor;
  final Efectos efectos;

  @override
  State<PantallaFinal> createState() => _PantallaFinalState();
}

class _PantallaFinalState extends State<PantallaFinal> {
  /// Empieza de noche (1) y, ya dibujada la pantalla, pasa a amanecer (0.25):
  /// FondoGranja anima el cambio de cielo.
  double _oscuridad = 1;
  bool _revelado = false;
  Timer? _espera;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _oscuridad = 0.25);
    });
    // Suspenso: el culpable aparece en silueta y se revela 1.2 segundos después.
    if (widget.motor.partida.resuelta) {
      _espera = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _revelado = true);
      });
    }
  }

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }

  void _jugarOtraVez() {
    widget.efectos.reproducir(Sonido.clic);
    final p = widget.motor.partida;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => PantallaJuego(
        motor: MotorJuego.nueva(dificultad: p.dificultad, granjero: p.nombreGranjero),
        efectos: widget.efectos,
      ),
    ));
  }

  void _verBitacora() {
    widget.efectos.reproducir(Sonido.clic);
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PantallaBitacora(partida: widget.motor.partida),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final motor = widget.motor;
    final p = motor.partida;
    final culpable = Historia.sospechoso(Historia.culpable);
    final confirmacion = Historia.pistas.firstWhere((x) => x.esConfirmacion);
    final pura = p.resuelta && !p.pistasEncontradas.contains(confirmacion.id);
    final descartados = Historia.sospechosos
        .where((s) => p.estadoDe(s.id) == EstadoSospechoso.descartado)
        .length;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: FondoGranja(oscuridad: _oscuridad)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Card(
                    color: tema.colorScheme.surface.withValues(alpha: 0.92),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            p.resuelta ? '¡Caso resuelto!' : 'Caso sin resolver',
                            textAlign: TextAlign.center,
                            style: tema.textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          // Revelación: crece con rebote al pasar de silueta a color.
                          Center(
                            child: AnimatedScale(
                              scale: _revelado ? 1.1 : 0.9,
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.elasticOut,
                              child: RetratoAnimal(
                                id: culpable.id,
                                tamano: 140,
                                silueta: !_revelado,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedOpacity(
                            opacity: _revelado || !p.resuelta ? 1 : 0,
                            duration: const Duration(milliseconds: 600),
                            child: Text(
                              p.resuelta
                                  ? 'Era ${culpable.nombre.toLowerCase()}'
                                  : 'El ladrón de elotes sigue libre…',
                              textAlign: TextAlign.center,
                              style: tema.textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            p.historial.last.texto,
                            textAlign: TextAlign.center,
                            style: tema.textTheme.bodyLarge,
                          ),
                          if (pura) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: Chip(
                                avatar: const Icon(Icons.psychology),
                                label: Text('Deducción pura (+${Puntaje.deduccionPura})'),
                              ),
                            ),
                          ],
                          const Divider(height: 32),
                          // La puntuación "cuenta" desde 0 hasta el total.
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: p.puntuacion),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutCubic,
                            builder: (context, valor, _) => Text(
                              '$valor puntos',
                              textAlign: TextAlign.center,
                              style: tema.textTheme.displaySmall
                                  ?.copyWith(color: tema.colorScheme.primary),
                            ),
                          ),
                          Text(
                            motor.rango,
                            textAlign: TextAlign.center,
                            style: tema.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Dato(
                                Icons.search,
                                'Pistas',
                                '${p.pistasEncontradas.length} de ${Historia.pistas.length}',
                              ),
                              _Dato(Icons.close, 'Descartados', '$descartados de 5'),
                              _Dato(Icons.timer, 'Tiempo jugado', _duracion(p.segundosJugados)),
                              _Dato(Icons.nightlight_round, 'Terminó', 'Noche ${p.nivel}, ${p.hora}'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _jugarOtraVez,
                            icon: const Icon(Icons.replay),
                            label: const Text('Jugar otra vez'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _verBitacora,
                            icon: const Icon(Icons.menu_book),
                            label: const Text('Leer la bitácora del caso'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Volver al inicio'),
                          ),
                        ],
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

  static String _duracion(int segundos) {
    final m = segundos ~/ 60;
    final s = segundos % 60;
    return m > 0 ? '$m min $s s' : '$s s';
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.icono, this.titulo, this.valor);

  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      width: 140,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tema.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icono, size: 20),
          Text(titulo, style: tema.textTheme.labelMedium),
          Text(valor, style: tema.textTheme.titleSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
