import 'package:flutter/material.dart';

import 'app/efectos.dart';
import 'app/opciones.dart';
import 'app/tema.dart';
import 'juego/archivos/repositorio.dart';
import 'pantallas/inicio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final opciones = Opciones();
  await opciones.cargar();
  final efectos = Efectos(opciones);
  final repositorio = RepositorioPartidas(opciones);
  runApp(JuegoApp(opciones: opciones, efectos: efectos, repositorio: repositorio));
}

class JuegoApp extends StatelessWidget {
  const JuegoApp({
    super.key,
    required this.opciones,
    required this.efectos,
    required this.repositorio,
  });

  final Opciones opciones;
  final Efectos efectos;
  final RepositorioPartidas repositorio;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: opciones,
      builder: (context, _) => MaterialApp(
        title: 'Misterio en la Granja',
        debugShowCheckedModeBanner: false,
        theme: TemasApp.claro(opciones.tema),
        darkTheme: TemasApp.oscuro(opciones.tema),
        themeMode: ThemeMode.system, // claro/oscuro según el sistema
        home: PantallaInicio(opciones: opciones, efectos: efectos, repositorio: repositorio),
      ),
    );
  }
}
