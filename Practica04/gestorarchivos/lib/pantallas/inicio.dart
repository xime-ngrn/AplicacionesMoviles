import 'package:flutter/material.dart';

import '../almacenamiento/fuente_archivos.dart';
import '../almacenamiento/fuente_local.dart';
import '../app/ajustes.dart';
import '../app/tema.dart';
import 'explorador.dart';

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key, required this.ajustes, required this.local});

  final Ajustes ajustes;
  final FuenteLocal local;

  void _explorar(BuildContext context, FuenteArchivos fuente) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PantallaExplorador(fuente: fuente)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;
    final oscuro = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de Archivos')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Ubicaciones', style: texto.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(Icons.phone_android, color: colores.primary),
                  title: Text(local.nombre),
                  subtitle: const Text('Archivos privados de la app (no requiere permisos)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _explorar(context, local),
                ),
              ),
              const SizedBox(height: 24),
              Text('Tema', style: texto.titleMedium),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: ajustes,
                builder: (context, _) => SegmentedButton<TemaApp>(
                  segments: [
                    for (final t in TemaApp.values)
                      ButtonSegment(value: t, label: Text(t.etiqueta)),
                  ],
                  selected: {ajustes.tema},
                  onSelectionChanged: (s) => ajustes.cambiarTema(s.first),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                oscuro ? 'Modo oscuro (sigue al sistema)' : 'Modo claro (sigue al sistema)',
                style: texto.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}