import 'package:flutter/material.dart';

import '../app/efectos.dart';
import '../app/opciones.dart';
import '../app/tema.dart';
import '../widgets/dialogos.dart';

/// Menú de opciones que pide la práctica: formato de guardado, jugabilidad y apariencia.
class PantallaOpciones extends StatelessWidget {
  const PantallaOpciones({super.key, required this.opciones, required this.efectos});

  final Opciones opciones;
  final Efectos efectos;

  Future<void> _cambiarNombre(BuildContext context) async {
    final nombre = await pedirNombre(
      context,
      titulo: 'Nombre del granjero',
      boton: 'Guardar',
      inicial: opciones.nombreGranjero,
    );
    if (nombre != null) await opciones.cambiarNombre(nombre);
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final variante = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget titulo(String t) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(t, style: texto.titleMedium),
    );
    Widget nota(String t) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(t, style: texto.bodySmall?.copyWith(color: variante)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Opciones')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListenableBuilder(
            listenable: opciones,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                titulo('Jugabilidad'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Nombre del granjero'),
                    subtitle: Text(opciones.nombreGranjero),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _cambiarNombre(context),
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<Dificultad>(
                  segments: [
                    for (final d in Dificultad.values)
                      ButtonSegment(value: d, label: Text(d.etiqueta)),
                  ],
                  selected: {opciones.dificultad},
                  onSelectionChanged: (s) => opciones.cambiarDificultad(s.first),
                ),
                nota(opciones.dificultad.descripcion),
                titulo('Formato de guardado'),
                SegmentedButton<FormatoGuardado>(
                  showSelectedIcon: false,
                  segments: [
                    for (final f in FormatoGuardado.values)
                      ButtonSegment(value: f, label: Text(f.etiqueta)),
                  ],
                  selected: {opciones.formato},
                  onSelectionChanged: (s) => opciones.cambiarFormato(s.first),
                ),
                nota('Las partidas nuevas se guardan en este formato. '
                    'Puedes cargar partidas de cualquiera de los tres.'),
                titulo('Sonido y vibración'),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.volume_up_outlined),
                        title: const Text('Efectos de sonido'),
                        value: opciones.sonido,
                        onChanged: opciones.cambiarSonido,
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.vibration),
                        title: const Text('Vibración'),
                        value: opciones.vibracion,
                        onChanged: opciones.cambiarVibracion,
                      ),
                      ListTile(
                        leading: const Icon(Icons.music_note_outlined),
                        title: const Text('Probar efectos'),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            for (final s in [Sonido.pista, Sonido.error, Sonido.victoria])
                              IconButton(
                                tooltip: s.name,
                                icon: Icon(switch (s) {
                                  Sonido.pista => Icons.lightbulb_outline,
                                  Sonido.error => Icons.close,
                                  _ => Icons.emoji_events_outlined,
                                }),
                                onPressed: () => efectos.reproducir(s),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                titulo('Apariencia'),
                SegmentedButton<TemaApp>(
                  showSelectedIcon: false,
                  segments: [
                    for (final t in TemaApp.values)
                      ButtonSegment(value: t, label: Text(t.etiqueta)),
                  ],
                  selected: {opciones.tema},
                  onSelectionChanged: (s) => opciones.cambiarTema(s.first),
                ),
                nota('El modo claro u oscuro sigue la configuración del sistema.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
