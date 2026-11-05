import 'package:flutter/material.dart';

import '../app/efectos.dart';
import '../juego/datos_historia.dart';
import '../juego/modelo.dart';
import '../juego/motor.dart';
import '../widgets/dialogos.dart';
import '../widgets/retrato_animal.dart';
import '../widgets/ventanas_juego.dart';

/// Pestaña "Sospechosos": las fichas de los 6 animales y, abajo, la libreta de pistas.
/// Al tocar una ficha se abre la hoja del sospechoso, donde se le asignan pistas,
/// se marca, se descarta o (en la noche 2) se le acusa.
class VistaTablero extends StatelessWidget {
  const VistaTablero({
    super.key,
    required this.motor,
    required this.efectos,
    required this.alJugar,
    required this.alPasarDeNoche,
  });

  final MotorJuego motor;
  final Efectos efectos;
  final ValueChanged<Resultado> alJugar;
  final VoidCallback alPasarDeNoche;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final pistas = motor.pistasEncontradas;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverList.list(
            children: [
              if (motor.nocheCompleta)
                Card(
                  color: tema.colorScheme.tertiaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.bedtime),
                    title: const Text('¡Descartaste a los tres de esta noche!'),
                    trailing: FilledButton(
                      onPressed: alPasarDeNoche,
                      child: const Text('Noche 2'),
                    ),
                  ),
                ),
              Text('Sospechosos', style: tema.textTheme.titleMedium),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              mainAxisExtent: 180,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: Historia.sospechosos.length,
            itemBuilder: (context, i) {
              final s = Historia.sospechosos[i];
              return _TarjetaSospechoso(
                sospechoso: s,
                estado: motor.partida.estadoDe(s.id),
                pistas: motor.pistasDe(s.id).length,
                alTocar: () {
                  efectos.reproducir(Sonido.clic);
                  _abrirHoja(context, s);
                },
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          sliver: SliverList.list(
            children: [
              Text('Libreta de pistas (${pistas.length})', style: tema.textTheme.titleMedium),
              const SizedBox(height: 6),
              if (pistas.isEmpty)
                Text(
                  'Todavía no encuentras pistas. Búscalas en el mapa.',
                  style: TextStyle(color: tema.colorScheme.onSurfaceVariant),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in pistas)
                      ActionChip(
                        avatar: const Icon(Icons.description_outlined, size: 18),
                        label: Text(p.titulo),
                        // Volver a leer la pista completa.
                        onPressed: () =>
                            mostrarPista(context, p, conGranjero(p.texto, motor.granjero)),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _abrirHoja(BuildContext context, Sospechoso s) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (context, scroll) => _HojaSospechoso(
          sospechoso: s,
          motor: motor,
          efectos: efectos,
          alJugar: alJugar,
          scroll: scroll,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ Tarjeta

class _TarjetaSospechoso extends StatelessWidget {
  const _TarjetaSospechoso({
    required this.sospechoso,
    required this.estado,
    required this.pistas,
    required this.alTocar,
  });

  final Sospechoso sospechoso;
  final EstadoSospechoso estado;
  final int pistas;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final descartado = estado == EstadoSospechoso.descartado;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              // El globito de abajo muestra cuántas pistas le has asignado.
              Badge.count(
                count: pistas,
                isLabelVisible: pistas > 0,
                alignment: AlignmentDirectional.bottomEnd,
                offset: const Offset(-6, -14),
                child: RetratoAnimal(id: sospechoso.id, estado: estado, tamano: 76),
              ),
              const SizedBox(height: 6),
              Text(
                sospechoso.nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tema.textTheme.titleSmall?.copyWith(
                  decoration: descartado ? TextDecoration.lineThrough : null,
                ),
              ),
              const Spacer(),
              Text(
                etiquetaEstado(estado),
                maxLines: 1,
                style: tema.textTheme.labelSmall
                    ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String etiquetaEstado(EstadoSospechoso estado) => switch (estado) {
      EstadoSospechoso.sinRevisar => 'Sin revisar',
      EstadoSospechoso.sospechoso => 'Sospechoso',
      EstadoSospechoso.descartado => 'Descartado',
    };

// --------------------------------------------------------- Hoja del sospechoso

class _HojaSospechoso extends StatelessWidget {
  const _HojaSospechoso({
    required this.sospechoso,
    required this.motor,
    required this.efectos,
    required this.alJugar,
    required this.scroll,
  });

  final Sospechoso sospechoso;
  final MotorJuego motor;
  final Efectos efectos;
  final ValueChanged<Resultado> alJugar;
  final ScrollController scroll;

  /// Cierra la hoja y entrega el resultado: así el mensaje se ve sobre el tablero.
  void _jugarYCerrar(BuildContext context, Resultado Function() jugada) {
    Navigator.pop(context);
    alJugar(jugada());
  }

  Future<void> _acusar(BuildContext context) async {
    final seguro = await confirmar(
      context,
      titulo: '¿Acusar a ${sospechoso.nombre}?',
      mensaje: 'Si las pruebas no alcanzan, pierdes ${-Puntaje.error} puntos.',
      boton: 'Acusar',
      destructivo: true,
    );
    if (seguro && context.mounted) _jugarYCerrar(context, () => motor.acusar(sospechoso.id));
  }

  @override
  Widget build(BuildContext context) {
    // La hoja es otra ruta: escucha al motor por su cuenta para actualizarse al asignar pistas.
    return ListenableBuilder(
      listenable: motor,
      builder: (context, _) {
        final tema = Theme.of(context);
        final id = sospechoso.id;
        final estado = motor.partida.estadoDe(id);
        final activo = !motor.partida.terminada && estado != EstadoSospechoso.descartado;
        final suyas = motor.pistasDe(id).map((p) => p.id).toSet();
        final ficha = sospechoso.ficha;

        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Row(
              children: [
                RetratoAnimal(id: id, estado: estado, tamano: 96),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sospechoso.nombre, style: tema.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Chip(label: Text(etiquetaEstado(estado))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(sospechoso.presentacion),
            const SizedBox(height: 12),
            _Dato(icono: Icons.schedule, titulo: 'Horario', texto: ficha.horario),
            _Dato(icono: Icons.restaurant, titulo: 'Dieta', texto: ficha.dieta),
            _Dato(icono: Icons.pets, titulo: 'Huellas', texto: ficha.huellas),
            _Dato(icono: Icons.gesture, titulo: 'Cola', texto: ficha.cola),
            _Dato(icono: Icons.lightbulb_outline, titulo: 'Dato curioso', texto: ficha.dato),
            const Divider(height: 32),
            Text('Pistas que le asignas', style: tema.textTheme.titleMedium),
            if (!motor.esDetective)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Para descartarlo, asígnale una pista que demuestre que no pudo ser él. '
                  'Para acusarlo, una pista que lo señale.',
                  style: tema.textTheme.bodySmall
                      ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 8),
            if (motor.pistasEncontradas.isEmpty)
              const Text('Aún no tienes pistas. Búscalas en el mapa.')
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final p in motor.pistasEncontradas)
                    FilterChip(
                      label: Text(p.titulo),
                      selected: suyas.contains(p.id),
                      onSelected: !activo
                          ? null
                          : (_) {
                              efectos.reproducir(Sonido.clic);
                              motor.alternarPista(id, p.id);
                            },
                    ),
                ],
              ),
            if (activo) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      efectos.reproducir(Sonido.clic);
                      motor.alternarSospecha(id);
                    },
                    icon: const Icon(Icons.search),
                    label: Text(estado == EstadoSospechoso.sospechoso
                        ? 'Quitar marca'
                        : 'Marcar sospechoso'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _jugarYCerrar(context, () => motor.descartar(id)),
                    icon: const Icon(Icons.close),
                    label: const Text('Descartar'),
                  ),
                  if (motor.partida.nivel == 2)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: tema.colorScheme.error,
                        foregroundColor: tema.colorScheme.onError,
                      ),
                      onPressed: () => _acusar(context),
                      icon: const Icon(Icons.gavel),
                      label: const Text('Acusar'),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.titulo, required this.texto});

  final IconData icono;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icono),
      title: Text(titulo),
      subtitle: Text(texto),
    );
  }
}
