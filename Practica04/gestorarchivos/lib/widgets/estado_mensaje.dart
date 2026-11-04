import 'package:flutter/material.dart';

class EstadoMensaje extends StatelessWidget {
  const EstadoMensaje({
    super.key,
    required this.icono,
    required this.titulo,
    this.mensaje,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String? mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return LayoutBuilder(
      builder: (context, restricciones) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: restricciones.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icono, size: 64, color: tema.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(titulo, style: tema.textTheme.titleMedium, textAlign: TextAlign.center),
                  if (mensaje != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      mensaje!,
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyMedium
                          ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                    ),
                  ],
                  if (accion != null) ...[const SizedBox(height: 16), accion!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}