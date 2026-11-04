import 'package:flutter/material.dart';

import 'app/ajustes.dart';
import 'app/tema.dart';
import 'pantallas/inicio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ajustes = Ajustes();
  await ajustes.cargar();
  runApp(GestorApp(ajustes: ajustes));
}

class GestorApp extends StatelessWidget {
  const GestorApp({super.key, required this.ajustes});
  final Ajustes ajustes;

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
          home: PantallaInicio(ajustes: ajustes),
        );
      },
    );
  }
}