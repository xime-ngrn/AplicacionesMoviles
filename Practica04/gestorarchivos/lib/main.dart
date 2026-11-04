import 'package:flutter/material.dart';

import 'app/ajustes.dart';
import 'app/tema.dart';
import 'pantallas/inicio.dart';
import 'almacenamiento/fuente_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ajustes = Ajustes();
  await ajustes.cargar();
  final local = await FuenteLocal.espacioPropio();
  await local.copiarEjemplosSiHaceFalta();
  runApp(GestorApp(ajustes: ajustes, local: local));
}

class GestorApp extends StatelessWidget {
  const GestorApp({super.key, required this.ajustes, required this.local});
  final Ajustes ajustes;
  final FuenteLocal local;

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
          home: PantallaInicio(ajustes: ajustes, local: local),
        );
      },
    );
  }
}