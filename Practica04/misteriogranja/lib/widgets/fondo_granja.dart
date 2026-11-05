import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fondo animado de la granja: cielo, cerros, pasto y una fila de milpa en la parte baja.
///
/// [oscuridad] va de 0 (día) a 1 (noche). Si no se indica, sigue el modo claro/oscuro
/// del sistema; en el juego (paso J3) se le pasará la hora de la noche y el cielo
/// cambiará suavemente. Las plantas se mecen con el viento y de noche hay luciérnagas.
/// Todo se dibuja con código (CustomPainter): se adapta a cualquier tamaño y orientación.
class FondoGranja extends StatefulWidget {
  const FondoGranja({super.key, this.oscuridad, this.child});

  final double? oscuridad;
  final Widget? child;

  @override
  State<FondoGranja> createState() => _FondoGranjaState();
}

class _FondoGranjaState extends State<FondoGranja> with SingleTickerProviderStateMixin {
  late final AnimationController _viento =
      AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respeta la opción de accesibilidad del sistema "quitar animaciones".
    if (MediaQuery.disableAnimationsOf(context)) {
      _viento.stop();
    } else if (!_viento.isAnimating) {
      _viento.repeat();
    }
  }

  @override
  void dispose() {
    _viento.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destino = widget.oscuridad ??
        (Theme.of(context).brightness == Brightness.dark ? 1.0 : 0.0);
    // Si cambia la oscuridad (modo del sistema u hora del juego), el cielo se transforma poco a poco.
    return TweenAnimationBuilder<double>(
      tween: Tween(end: destino.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      builder: (context, oscuridad, child) => RepaintBoundary(
        child: CustomPaint(
          painter: _PintorGranja(oscuridad: oscuridad, viento: _viento),
          child: child,
        ),
      ),
      child: widget.child ?? const SizedBox.expand(),
    );
  }
}

class _PintorGranja extends CustomPainter {
  _PintorGranja({required this.oscuridad, required this.viento}) : super(repaint: viento);

  final double oscuridad;
  final Animation<double> viento;

  /// Mezcla el color de día con el de noche según la oscuridad.
  Color _c(int dia, int noche) => Color.lerp(Color(dia), Color(noche), oscuridad)!;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final fase = viento.value * 2 * math.pi;
    final horizonte = size.height * 0.70;
    final suelo = size.height * 0.88; // donde nace la milpa

    _cielo(canvas, size, horizonte);
    _estrellas(canvas, size, fase);
    _astro(canvas, size);
    _nubes(canvas, size, fase);
    _cerros(canvas, size, horizonte);
    _milpa(canvas, size, suelo, fase);
    _pastoDelFrente(canvas, size, fase);
    if (oscuridad > 0.3) _luciernagas(canvas, size, suelo, fase);
  }

  void _cielo(Canvas canvas, Size size, double horizonte) {
    final rect = Rect.fromLTWH(0, 0, size.width, horizonte + 2);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_c(0xFF7EC8F2, 0xFF0B1630), _c(0xFFD8F0FF, 0xFF2B3F6B)],
        ).createShader(rect),
    );
  }

  void _estrellas(Canvas canvas, Size size, double fase) {
    if (oscuridad < 0.05) return;
    final azar = math.Random(7);
    final pintura = Paint();
    for (var i = 0; i < 45; i++) {
      final p = Offset(azar.nextDouble() * size.width, azar.nextDouble() * size.height * 0.55);
      final brillo = 0.55 + 0.45 * math.sin(fase * 2 + i * 1.3); // parpadeo
      pintura.color = Colors.white.withValues(alpha: oscuridad * brillo * 0.9);
      canvas.drawCircle(p, 0.8 + azar.nextDouble() * 1.2, pintura);
    }
  }

  void _astro(Canvas canvas, Size size) {
    final centro = Offset(size.width * 0.80, size.height * 0.12);
    final radio = math.min(size.width, size.height) * 0.07;
    // Sol (se desvanece al anochecer)
    if (oscuridad < 0.95) {
      final a = 1 - oscuridad;
      canvas.drawCircle(centro, radio * 1.7,
          Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35 * a));
      canvas.drawCircle(centro, radio, Paint()..color = const Color(0xFFFFCA28).withValues(alpha: a));
    }
    // Luna creciente (aparece al anochecer)
    if (oscuridad > 0.05) {
      final luna = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: centro, radius: radio)),
        Path()..addOval(Rect.fromCircle(center: centro + Offset(radio * 0.45, -radio * 0.2), radius: radio)),
      );
      canvas.drawCircle(centro, radio * 1.5,
          Paint()..color = const Color(0xFFFFF8E1).withValues(alpha: 0.08 * oscuridad));
      canvas.drawPath(luna, Paint()..color = const Color(0xFFFFF4C2).withValues(alpha: oscuridad));
    }
  }

  void _nubes(Canvas canvas, Size size, double fase) {
    final a = (1 - oscuridad) * 0.9; // de noche desaparecen
    if (a <= 0.01) return;
    final pintura = Paint()..color = Colors.white.withValues(alpha: a);
    final escala = math.min(size.width, size.height) / 400;
    for (final (x, y, s) in [(0.18, 0.10, 1.0), (0.55, 0.20, 0.8), (0.95, 0.30, 0.7)]) {
      final c = Offset(size.width * x + math.sin(fase + x * 5) * 10, size.height * y);
      final r = 22 * s * escala;
      for (final (dx, dy, k) in [(-1.2, 0.2, 0.8), (0.0, 0.0, 1.0), (1.1, 0.25, 0.75), (0.4, 0.45, 0.8)]) {
        canvas.drawCircle(c + Offset(dx * r, dy * r), r * k, pintura);
      }
    }
  }

  void _cerros(Canvas canvas, Size size, double horizonte) {
    final w = size.width, h = size.height;
    // Cerros lejanos
    final lejos = Path()
      ..moveTo(0, horizonte)
      ..quadraticBezierTo(w * 0.15, horizonte - h * 0.09, w * 0.35, horizonte - h * 0.03)
      ..quadraticBezierTo(w * 0.55, horizonte - h * 0.10, w * 0.78, horizonte - h * 0.04)
      ..quadraticBezierTo(w * 0.92, horizonte - h * 0.08, w, horizonte - h * 0.05)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(lejos, Paint()..color = _c(0xFF9CCB6B, 0xFF1E3828));
    // Pradera cercana
    final cerca = Path()
      ..moveTo(0, horizonte + h * 0.03)
      ..quadraticBezierTo(w * 0.3, horizonte - h * 0.02, w * 0.6, horizonte + h * 0.02)
      ..quadraticBezierTo(w * 0.85, horizonte + h * 0.05, w, horizonte + h * 0.01)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final rect = Rect.fromLTWH(0, horizonte - h * 0.02, w, h - horizonte);
    canvas.drawPath(
      cerca,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_c(0xFF86C04F, 0xFF1A3424), _c(0xFF5E9E35, 0xFF10251A)],
        ).createShader(rect),
    );
  }

  void _milpa(Canvas canvas, Size size, double suelo, double fase) {
    final separacion = (size.width / 8).clamp(46.0, 92.0);
    final alto = (size.height * 0.27).clamp(95.0, 290.0);
    final cantidad = (size.width / separacion).ceil() + 1;
    for (var i = 0; i < cantidad; i++) {
      final azar = math.Random(i * 31 + 5);
      final x = separacion * (i + 0.15) + (azar.nextDouble() - 0.5) * separacion * 0.35;
      final base = suelo + (azar.nextDouble() - 0.5) * 10;
      final inclinacion = math.sin(fase + i * 0.8) * 0.035; // el viento
      _planta(canvas, x, base, alto * (0.82 + azar.nextDouble() * 0.28), inclinacion, azar);
    }
  }

  /// Una planta de maíz: tallo, hojas, uno o dos elotes y la espiga en la punta.
  void _planta(Canvas canvas, double x, double base, double alto, double inclinacion, math.Random azar) {
    canvas.save();
    canvas.translate(x, base);
    canvas.rotate(inclinacion);

    // Tallo
    canvas.drawLine(
      Offset.zero,
      Offset(0, -alto),
      Paint()
        ..color = _c(0xFF4C8C2B, 0xFF223F1E)
        ..strokeWidth = math.max(3.0, alto * 0.035)
        ..strokeCap = StrokeCap.round,
    );

    // Hojas alternadas, largas y caídas en la punta
    final hojaA = Paint()..color = _c(0xFF6BAF3D, 0xFF2A4F25);
    final hojaB = Paint()..color = _c(0xFF58A032, 0xFF234520);
    for (var k = 0; k < 5; k++) {
      final y = -alto * (0.14 + k * 0.15);
      final lado = k.isEven ? 1.0 : -1.0;
      final largo = alto * (0.46 - k * 0.05);
      final hoja = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(lado * largo * 0.55, y - largo * 0.42, lado * largo, y + largo * 0.12)
        ..quadraticBezierTo(lado * largo * 0.50, y - largo * 0.16, 0, y + alto * 0.035)
        ..close();
      canvas.drawPath(hoja, k.isEven ? hojaA : hojaB);
    }

    // Elotes
    final dosElotes = azar.nextBool();
    _elote(canvas, alto, -alto * 0.50, azar.nextBool() ? 1.0 : -1.0);
    if (dosElotes) _elote(canvas, alto * 0.85, -alto * 0.36, azar.nextBool() ? 1.0 : -1.0);

    // Espiga (la flor del maíz)
    final espiga = Paint()
      ..color = _c(0xFFD9B44A, 0xFF6F6232)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var j = -2; j <= 2; j++) {
      canvas.drawLine(
        Offset(0, -alto),
        Offset(j * alto * 0.05, -alto * (1.11 - j.abs() * 0.03)),
        espiga,
      );
    }
    canvas.restore();
  }

  void _elote(Canvas canvas, double alto, double y, double lado) {
    final ancho = alto * 0.085, largo = alto * 0.21;
    canvas.save();
    canvas.translate(lado * ancho * 0.9, y);
    canvas.rotate(lado * 0.45);
    // Mazorca con granos
    final mazorca = Rect.fromCenter(center: Offset(0, -largo * 0.1), width: ancho, height: largo);
    canvas.drawOval(mazorca, Paint()..color = _c(0xFFF4C430, 0xFF8C7A3A));
    final grano = Paint()..color = _c(0xFFE0A800, 0xFF6E5E25);
    for (var fila = 0; fila < 4; fila++) {
      for (var col = -1; col <= 1; col++) {
        canvas.drawCircle(
          Offset(col * ancho * 0.25, -largo * 0.45 + fila * largo * 0.2),
          ancho * 0.08,
          grano,
        );
      }
    }
    // Hojas que envuelven el elote (totomoxtle)
    final hoja = Paint()..color = _c(0xFFA5D46A, 0xFF3C5E2C);
    for (final s in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(0, largo * 0.45)
          ..quadraticBezierTo(s * ancho * 0.95, largo * 0.05, s * ancho * 0.15, -largo * 0.35)
          ..quadraticBezierTo(s * ancho * 0.25, largo * 0.1, 0, largo * 0.45)
          ..close(),
        hoja,
      );
    }
    // Cabellos del elote
    final pelo = Paint()
      ..color = _c(0xFFA0643A, 0xFF4A3420)
      ..strokeWidth = 1.2;
    for (var j = -1; j <= 1; j++) {
      canvas.drawLine(Offset(0, -largo * 0.58), Offset(j * ancho * 0.35, -largo * 0.78), pelo);
    }
    canvas.restore();
  }

  void _pastoDelFrente(Canvas canvas, Size size, double fase) {
    final pintura = Paint()..color = _c(0xFF4F8F2A, 0xFF0F2416);
    final clara = Paint()..color = _c(0xFF6DB33F, 0xFF173220);
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.93, size.width, h * 0.07), pintura);
    for (var x = -6.0; x < size.width + 8; x += 9) {
      final azar = math.Random(x.toInt());
      final altura = 12 + azar.nextDouble() * 18;
      final mecer = math.sin(fase + x * 0.04) * 3;
      canvas.drawPath(
        Path()
          ..moveTo(x - 3, h * 0.94)
          ..quadraticBezierTo(x + mecer * 0.5, h * 0.94 - altura * 0.6, x + mecer, h * 0.94 - altura)
          ..quadraticBezierTo(x + 1, h * 0.94 - altura * 0.5, x + 3, h * 0.94)
          ..close(),
        azar.nextBool() ? pintura : clara,
      );
    }
  }

  void _luciernagas(Canvas canvas, Size size, double suelo, double fase) {
    final azar = math.Random(21);
    final brillo = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (var i = 0; i < 12; i++) {
      final base = Offset(azar.nextDouble() * size.width, suelo - azar.nextDouble() * size.height * 0.3);
      final p = base + Offset(math.sin(fase + i) * 12, math.cos(fase * 1.3 + i) * 8);
      final a = oscuridad * math.max(0.0, math.sin(fase * 3 + i * 1.7));
      brillo.color = const Color(0xFFFFF59D).withValues(alpha: a);
      canvas.drawCircle(p, 3, brillo);
    }
  }

  @override
  bool shouldRepaint(_PintorGranja anterior) => anterior.oscuridad != oscuridad;
}
