import 'package:flutter/material.dart';

import 'almacenamiento/carpetas_autorizadas.dart';
import 'almacenamiento/fuente_local.dart';
import 'app/ajustes.dart';
import 'app/historial.dart';
import 'app/tema.dart';
import 'pantallas/inicio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ajustes = Ajustes();
  await ajustes.cargar();
  final local = await FuenteLocal.espacioPropio();
  await local.copiarEjemplosSiHaceFalta();
  final carpetas = CarpetasAutorizadas();
  await carpetas.cargar(); // carpetas autorizadas en sesiones anteriores
  final historial = Historial();
  await historial.cargar(); // recientes y favoritos
  runApp(GestorApp(ajustes: ajustes, local: local, carpetas: carpetas, historial: historial));
}

class GestorApp extends StatelessWidget {
  const GestorApp({
    super.key,
    required this.ajustes,
    required this.local,
    required this.carpetas,
    required this.historial,
  });

  final Ajustes ajustes;
  final FuenteLocal local;
  final CarpetasAutorizadas carpetas;
  final Historial historial;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ajustes,
      builder: (context, _) {
        return MaterialApp(
          title: 'Gestor de Archivos',
          debugShowCheckedModeBanner: false,
          theme: TemasApp.claro(ajustes.tema),
          darkTheme: TemasApp.oscuro(ajustes.tema),
          themeMode: ThemeMode.system,
          home: PantallaInicio(
            ajustes: ajustes,
            local: local,
            carpetas: carpetas,
            historial: historial,
          ),
        );
      },
    );
  }
}
