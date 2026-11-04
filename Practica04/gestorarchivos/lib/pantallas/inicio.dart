import 'package:flutter/material.dart';

import '../app/ajustes.dart';
import '../app/tema.dart';

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key, required this.ajustes});
  final Ajustes ajustes;

  @override
  Widget build(BuildContext context) {
    final oscuro = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestor de Archivos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tema', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: ajustes,
            builder: (context, _) => SegmentedButton<TemaApp>(
              segments: [
                for(final t in TemaApp.values)
                  ButtonSegment(value: t, label: Text(t.etiqueta)
                  )
              ],
              selected: {ajustes.tema},
              onSelectionChanged: (s) => ajustes.cambiarTema(s.first),
            ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
                title: const Text('Acerca de'),
                subtitle: Text(oscuro ? 'Modo oscuro (sistema)' : 'Modo claro (sistema)'),
              ),
            ),
            ElevatedButton(onPressed: () {}, child: const Text('Abrir archivo')),
        ],
      ),
    );
  }
}