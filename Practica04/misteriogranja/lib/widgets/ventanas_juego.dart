import 'package:flutter/material.dart';

import '../juego/datos_historia.dart';

/// Ventana que aparece con un rebote cuando se encuentra una pista.
Future<void> mostrarPista(BuildContext context, Pista pista, String texto) {
  return showDialog<void>(
    context: context,
    builder: (context) => _Rebote(
      child: AlertDialog(
        icon: const Icon(Icons.search, size: 40),
        title: Text(pista.titulo),
        content: SingleChildScrollView(child: Text(texto)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anotar en la libreta'),
          ),
        ],
      ),
    ),
  );
}

/// Inicio de cada noche, como el capítulo de un cuento.
Future<void> mostrarCapitulo(BuildContext context, String titulo, String texto) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _Rebote(
      child: AlertDialog(
        icon: const Icon(Icons.nightlight_round, size: 40),
        title: Text(titulo),
        content: SingleChildScrollView(child: Text(texto)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Comenzar'),
          ),
        ],
      ),
    ),
  );
}

/// Hace que su contenido crezca con efecto de resorte (Curves.elasticOut).
class _Rebote extends StatelessWidget {
  const _Rebote({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, escala, child) => Transform.scale(scale: escala, child: child),
      child: child,
    );
  }
}
