import 'package:flutter/material.dart';

import '../juego/datos_historia.dart';
import '../juego/motor.dart';
import '../widgets/fondo_granja.dart';

/// Pestaña "Mapa": arriba el paisaje de la granja con los lugares de la noche y el
/// granjero; abajo, el panel del lugar donde está, con sus puntos de búsqueda.
/// No guarda estado propio: todo lo lee del motor, y PantallaJuego la redibuja
/// cada vez que el motor avisa un cambio.
class VistaMapa extends StatelessWidget {
  const VistaMapa({
    super.key,
    required this.motor,
    required this.alJugar,
    required this.alPasarDeNoche,
  });

  final MotorJuego motor;
  final ValueChanged<Resultado> alJugar;
  final VoidCallback alPasarDeNoche;

  @override
  Widget build(BuildContext context) {
    final paisaje = _Paisaje(motor: motor, alJugar: alJugar);
    final panel = _PanelLugar(motor: motor, alJugar: alJugar, alPasarDeNoche: alPasarDeNoche);
    return LayoutBuilder(
      // En horizontal, el panel se pone a la derecha del paisaje.
      builder: (context, restricciones) => restricciones.maxWidth > restricciones.maxHeight
          ? Row(children: [Expanded(flex: 5, child: paisaje), Expanded(flex: 4, child: panel)])
          : Column(children: [Expanded(flex: 4, child: paisaje), Expanded(flex: 5, child: panel)]),
    );
  }
}

// ------------------------------------------------------------------- Paisaje

class _Paisaje extends StatelessWidget {
  const _Paisaje({required this.motor, required this.alJugar});

  final MotorJuego motor;
  final ValueChanged<Resultado> alJugar;

  @override
  Widget build(BuildContext context) {
    final lugares = motor.lugaresDeLaNoche;
    final aqui = lugares.indexWhere((l) => l.id == motor.partida.lugarActual).clamp(0, 99);
    return FondoGranja(
      // A las 22:00 ya es de noche (0.7) y a las 03:00 está en lo más oscuro (1.0).
      oscuridad: 0.7 + 0.3 * motor.avanceNoche,
      child: LayoutBuilder(builder: (context, area) {
        // Centro de cada lugar: se reparten de izquierda a derecha, uno arriba y otro abajo.
        Offset centro(int i) => Offset(
              area.maxWidth * (lugares.length == 1 ? 0.5 : 0.22 + 0.56 * i / (lugares.length - 1)),
              area.maxHeight * (i.isEven ? 0.42 : 0.72),
            );
        return Stack(
          children: [
            for (var i = 0; i < lugares.length; i++)
              Positioned(
                left: centro(i).dx - 75,
                top: centro(i).dy - 29,
                width: 150,
                child: _MarcadorLugar(
                  lugar: lugares[i],
                  aqui: i == aqui,
                  alTocar: () => alJugar(motor.viajar(lugares[i].id)),
                ),
              ),
            // El granjero "camina" hasta el lugar elegido: AnimatedPositioned anima el
            // cambio de posición cada vez que cambia el lugar actual.
            AnimatedPositioned(
              left: centro(aqui).dx - 60,
              top: centro(aqui).dy - 98,
              width: 120,
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOutCubic,
              child: IgnorePointer(child: _Granjero(nombre: motor.granjero)),
            ),
          ],
        );
      }),
    );
  }
}

class _MarcadorLugar extends StatelessWidget {
  const _MarcadorLugar({required this.lugar, required this.aqui, required this.alTocar});

  final Lugar lugar;
  final bool aqui;
  final VoidCallback alTocar;

  static IconData _icono(String id) => switch (id) {
        'casa' => Icons.house,
        'maizal' => Icons.grass,
        'granero' => Icons.warehouse,
        'area_libre' => Icons.park,
        _ => Icons.place,
      };

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return AnimatedScale(
      scale: aqui ? 1.15 : 1,
      duration: const Duration(milliseconds: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            shape: CircleBorder(
              side: BorderSide(color: aqui ? esquema.tertiary : Colors.white70, width: 3),
            ),
            color: aqui ? esquema.primaryContainer : esquema.surface,
            elevation: 6,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: alTocar,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(_icono(lugar.id), size: 32, color: esquema.primary),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _Etiqueta(lugar.nombre, color: esquema.surface.withValues(alpha: 0.85)),
        ],
      ),
    );
  }
}

class _Granjero extends StatelessWidget {
  const _Granjero({required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Etiqueta(nombre, color: esquema.tertiaryContainer),
        Icon(Icons.person_pin_circle, size: 40, color: esquema.tertiary),
      ],
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto, {required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          texto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}

// ------------------------------------------------------- Panel del lugar actual

class _PanelLugar extends StatelessWidget {
  const _PanelLugar({required this.motor, required this.alJugar, required this.alPasarDeNoche});

  final MotorJuego motor;
  final ValueChanged<Resultado> alJugar;
  final VoidCallback alPasarDeNoche;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final lugar = motor.lugar;
    return Material(
      color: tema.colorScheme.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(lugar.nombre, style: tema.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            conGranjero(lugar.descripcion, motor.granjero),
            style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          ),
          if (motor.esDetective) ...[
            const SizedBox(height: 12),
            _TiempoRestante(minutos: Historia.minutosPorNocheDetective - motor.partida.minuto),
          ],
          if (motor.nocheCompleta) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: alPasarDeNoche,
              icon: const Icon(Icons.bedtime),
              label: const Text('Pasar a la noche 2'),
            ),
          ] else if (motor.sinTiempo) ...[
            const SizedBox(height: 12),
            Card(
              color: tema.colorScheme.errorContainer,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Ya son las 3:00. No puedes buscar más esta noche: '
                    'analiza en el tablero las pistas que tienes.'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('¿Dónde buscas? (30 min cada lugar)', style: tema.textTheme.titleSmall),
          const SizedBox(height: 4),
          for (final punto in lugar.puntos)
            _TarjetaPunto(
              punto: punto,
              revisado: motor.revisado(punto.id),
              // Modo Aprendiz: se resaltan los puntos donde hay una pista.
              resaltar: !motor.esDetective && punto.pistaId != null,
              alTocar: () => alJugar(motor.buscar(punto.id)),
            ),
        ],
      ),
    );
  }
}

class _TarjetaPunto extends StatelessWidget {
  const _TarjetaPunto({
    required this.punto,
    required this.revisado,
    required this.resaltar,
    required this.alTocar,
  });

  final PuntoBusqueda punto;
  final bool revisado;
  final bool resaltar;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final pistaId = punto.pistaId;
    return Card(
      child: ListTile(
        enabled: !revisado,
        leading: Icon(!revisado
            ? Icons.search
            : pistaId != null
                ? Icons.check_circle
                : Icons.remove_circle_outline),
        title: Text(punto.nombre),
        subtitle: !revisado
            ? null
            : Text(pistaId != null
                ? 'Pista: ${Historia.pista(pistaId).titulo}'
                : 'Nada fuera de lo normal'),
        trailing: !revisado && resaltar ? Icon(Icons.auto_awesome, color: esquema.tertiary) : null,
        onTap: alTocar,
      ),
    );
  }
}

class _TiempoRestante extends StatelessWidget {
  const _TiempoRestante({required this.minutos});

  final int minutos;

  @override
  Widget build(BuildContext context) {
    final texto = minutos >= 60 ? '${minutos ~/ 60} h ${minutos % 60} min' : '$minutos min';
    return Row(
      children: [
        const Icon(Icons.schedule, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: minutos / Historia.minutosPorNocheDetective,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text('Quedan $texto'),
      ],
    );
  }
}
