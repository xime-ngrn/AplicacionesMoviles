import 'package:flutter/material.dart';

import '../app/efectos.dart';
import '../juego/archivos/repositorio.dart';
import '../juego/datos_historia.dart';
import '../juego/motor.dart';
import '../widgets/dialogos.dart';
import '../widgets/ventanas_juego.dart';
import 'bitacora.dart';
import 'final.dart';
import 'mapa.dart';
import 'tablero.dart';

/// Pantalla de una partida, con tres pestañas: Mapa, Sospechosos y Bitácora.
/// Es la dueña del motor: arranca el reloj, lo pausa si la app se va al fondo
/// y convierte cada Resultado del motor en un sonido y un mensaje.
class PantallaJuego extends StatefulWidget {
  const PantallaJuego({
    super.key,
    required this.motor,
    required this.efectos,
    required this.repositorio,
  });

  final MotorJuego motor;
  final Efectos efectos;
  final RepositorioPartidas repositorio;

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> {
  late final AppLifecycleListener _ciclo;
  late final AutoGuardado _guardado;
  int _pestana = 0;

  MotorJuego get motor => widget.motor;

  @override
  void initState() {
    super.initState();
    motor.iniciarReloj();
    // Guardado automático en el formato elegido en Opciones.
    _guardado = AutoGuardado(motor, widget.repositorio);
    // Si la app pasa a segundo plano, el reloj se pausa y la partida se guarda.
    _ciclo = AppLifecycleListener(
      onResume: motor.iniciarReloj,
      onPause: () {
        motor.detenerReloj();
        _guardado.guardarYa();
      },
    );
    // Partida recién creada (solo tiene la introducción): muestra el capítulo 1.
    if (motor.partida.historial.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _capitulo(1));
    }
  }

  @override
  void dispose() {
    _guardado.cerrar();
    _ciclo.dispose();
    motor.dispose();
    super.dispose();
  }

  void _capitulo(int noche) {
    if (!mounted) return;
    mostrarCapitulo(
        context, 'Noche $noche', conGranjero(Historia.introduccion[noche]!, motor.granjero));
  }

  /// Todas las jugadas terminan aquí: sonido, vibración y mensaje.
  void _alJugar(Resultado r) {
    widget.efectos.reproducir(switch (r.tipo) {
      TipoResultado.viaje => Sonido.paso,
      TipoResultado.pista => Sonido.pista,
      TipoResultado.correcto => Sonido.descarte,
      TipoResultado.error => Sonido.error,
      TipoResultado.victoria => Sonido.victoria,
      TipoResultado.nada || TipoResultado.aviso => Sonido.clic,
    });
    // Caso resuelto: se pasa a la pantalla final.
    if (motor.partida.terminada) {
      _irAlFinal();
      return;
    }
    final pista = r.pista;
    if (pista != null) {
      mostrarPista(context, pista, r.mensaje);
    } else if (r.tipo != TipoResultado.viaje) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(r.mensaje)));
    }
  }

  /// Cambia a la pantalla final con un fundido lento.
  void _irAlFinal() {
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 800),
      pageBuilder: (_, _, _) => PantallaFinal(
        motor: motor,
        efectos: widget.efectos,
        repositorio: widget.repositorio,
      ),
      transitionsBuilder: (_, animacion, _, child) =>
          FadeTransition(opacity: animacion, child: child),
    ));
  }

  /// Termina la partida sin resolver (por ejemplo, si en Detective se acabó el tiempo).
  Future<void> _abandonar() async {
    final seguro = await confirmar(
      context,
      titulo: '¿Abandonar el caso?',
      mensaje: 'La partida terminará sin resolver.',
      boton: 'Abandonar',
      destructivo: true,
    );
    if (!seguro || !mounted) return;
    motor.abandonar();
    _irAlFinal();
  }

  void _pasarDeNoche() {
    final r = motor.pasarANoche2();
    _alJugar(r);
    if (r.tipo == TipoResultado.victoria) _capitulo(2);
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder redibuja todo cada vez que el motor llama notifyListeners().
    return ListenableBuilder(
      listenable: motor,
      builder: (context, _) {
        final partida = motor.partida;
        return Scaffold(
          appBar: AppBar(
            title: Text('Noche ${partida.nivel} · ${partida.hora}'),
            actions: [
              _Puntos(partida.puntuacion),
              PopupMenuButton<void>(
                itemBuilder: (_) => [
                  PopupMenuItem<void>(onTap: _abandonar, child: const Text('Abandonar el caso')),
                ],
              ),
            ],
          ),
          // IndexedStack conserva cada pestaña (y su scroll) al cambiar entre ellas.
          body: IndexedStack(
            index: _pestana,
            children: [
              VistaMapa(motor: motor, alJugar: _alJugar, alPasarDeNoche: _pasarDeNoche),
              VistaTablero(
                motor: motor,
                efectos: widget.efectos,
                alJugar: _alJugar,
                alPasarDeNoche: _pasarDeNoche,
              ),
              VistaBitacora(partida: partida),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _pestana,
            onDestinationSelected: (i) {
              widget.efectos.reproducir(Sonido.clic);
              setState(() => _pestana = i);
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Mapa',
              ),
              NavigationDestination(
                // El globito muestra cuántas pistas llevas.
                icon: Badge.count(
                  count: motor.pistasEncontradas.length,
                  isLabelVisible: motor.pistasEncontradas.isNotEmpty,
                  child: const Icon(Icons.pets_outlined),
                ),
                selectedIcon: const Icon(Icons.pets),
                label: 'Sospechosos',
              ),
              const NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Bitácora',
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Marcador de puntos que "brinca" cada vez que cambia.
class _Puntos extends StatelessWidget {
  const _Puntos(this.puntos);

  final int puntos;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animacion) => ScaleTransition(scale: animacion, child: child),
      child: Chip(
        key: ValueKey(puntos),
        avatar: const Icon(Icons.star, size: 18),
        label: Text('$puntos'),
      ),
    );
  }
}
