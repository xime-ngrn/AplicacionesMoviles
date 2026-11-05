import 'package:flutter/material.dart';

import '../juego/modelo.dart';

// Retrato de un sospechoso dibujado con código (CustomPainter)

/// Según el estado en el tablero:
///   - sinRevisar: a color.
///   - sospechoso: a color, con una lupa roja.
///   - descartado: en gris, semitransparente y con una ✗.
/// Con [silueta] se dibuja como sombra misteriosa (se usa al revelar al culpable).
class RetratoAnimal extends StatelessWidget {
  const RetratoAnimal({
    super.key,
    required this.id,
    this.tamano = 96,
    this.estado = EstadoSospechoso.sinRevisar,
    this.silueta = false,
  });

  final String id;
  final double tamano;
  final EstadoSospechoso estado;
  final bool silueta;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final rasgos = _rasgos[id] ?? _rasgos['perro']!;
    Widget dibujo = CustomPaint(size: Size.square(tamano), painter: _PintorAnimal(rasgos));

    if (silueta) {
      dibujo = ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFF1B1B2F), BlendMode.srcIn),
        child: dibujo,
      );
    } else if (estado == EstadoSospechoso.descartado) {
      dibujo = ColorFiltered(colorFilter: _grises, child: dibujo);
    }

    return SizedBox.square(
      dimension: tamano,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Stack(
          key: ValueKey((estado, silueta)),
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: esquema.secondaryContainer,
                  border: Border.all(
                    color: estado == EstadoSospechoso.sospechoso && !silueta
                        ? esquema.error
                        : esquema.outlineVariant,
                    width: tamano * 0.035,
                  ),
                ),
              ),
            ),
            ClipOval(child: dibujo),
            if (!silueta && estado == EstadoSospechoso.descartado)
              Center(
                child: Icon(Icons.close_rounded, size: tamano * 0.8, color: esquema.error),
              ),
            if (!silueta && estado == EstadoSospechoso.sospechoso)
              Align(
                alignment: Alignment.topRight,
                child: CircleAvatar(
                  radius: tamano * 0.15,
                  backgroundColor: esquema.error,
                  child: Icon(Icons.search, size: tamano * 0.18, color: esquema.onError),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Matriz que convierte los colores a escala de grises y baja la opacidad a la mitad
const _grises = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 0.55, 0,
]);

// -------------------------------------- Rasgos

enum _Oreja { puntiaguda, larga, redonda, caida }

class _Rasgos {
  const _Rasgos({
    required this.pelo,
    required this.cara,
    required this.oreja,
    this.interiorOreja = const Color(0xFFE8A0A8),
    this.nariz = const Color(0xFF2B2B2B),
    this.hocico = 0.5,
    this.antifaz = false,
    this.anillosOjos = false,
    this.dientes = false,
    this.lengua = false,
  });

  final Color pelo; // color principal de la cabeza
  final Color cara; // hocico y mejillas
  final _Oreja oreja;
  final Color interiorOreja;
  final Color nariz;
  final double hocico; // 0 = chato, 1 = muy largo
  final bool antifaz; // mapache
  final bool anillosOjos; // cacomixtle
  final bool dientes; // conejo
  final bool lengua; // perro
}

const _rasgos = <String, _Rasgos>{
  'perro': _Rasgos(
    pelo: Color(0xFFC8843E),
    cara: Color(0xFFF2D3A7),
    oreja: _Oreja.caida,
    interiorOreja: Color(0xFF8E5A26),
    hocico: 0.6,
    lengua: true,
  ),
  'conejo': _Rasgos(
    pelo: Color(0xFFF1EEE8),
    cara: Color(0xFFFFFFFF),
    oreja: _Oreja.larga,
    nariz: Color(0xFFE58FA0),
    hocico: 0.1,
    dientes: true,
  ),
  'zorro': _Rasgos(
    pelo: Color(0xFFD9622B),
    cara: Color(0xFFFFF4E6),
    oreja: _Oreja.puntiaguda,
    interiorOreja: Color(0xFF3A2A20),
    hocico: 0.9,
  ),
  'tlacuache': _Rasgos(
    pelo: Color(0xFFA9A49C),
    cara: Color(0xFFF7F4EE),
    oreja: _Oreja.redonda,
    interiorOreja: Color(0xFF2E2A28),
    nariz: Color(0xFFE79AA4),
    hocico: 1,
  ),
  'cacomixtle': _Rasgos(
    pelo: Color(0xFF9C8466),
    cara: Color(0xFFEDE1C8),
    oreja: _Oreja.redonda,
    interiorOreja: Color(0xFFF3E6CF),
    nariz: Color(0xFF5A4636),
    hocico: 0.45,
    anillosOjos: true,
  ),
  'mapache': _Rasgos(
    pelo: Color(0xFF8C8C8C),
    cara: Color(0xFFF5F5F5),
    oreja: _Oreja.redonda,
    interiorOreja: Color(0xFFF5F5F5),
    hocico: 0.4,
    antifaz: true,
  ),
};

// ------------------------------------ Pintor

class _PintorAnimal extends CustomPainter {
  _PintorAnimal(this.r);

  final _Rasgos r;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s * 0.58);
    final k = s * 0.3; // "radio" de la cabeza
    final pelo = Paint()..color = r.pelo;
    final cara = Paint()..color = r.cara;
    final oscuro = Paint()..color = const Color(0xFF1E1E1E);

    // Las orejas van detrás de la cabeza, excepto las caídas del perro, que cuelgan encima.
    if (r.oreja != _Oreja.caida) _orejas(canvas, c, k, pelo);

    // Cabeza: un óvalo un poco más ancho que alto.
    canvas.drawOval(Rect.fromCenter(center: c, width: k * 2.1, height: k * 1.9), pelo);
    if (r.oreja == _Oreja.caida) _orejas(canvas, c, k, pelo);

    // Hocico y mejillas claras; con hocico largo, el óvalo es más alto.
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, k * (0.38 + r.hocico * 0.08)),
        width: k * (1.25 + r.hocico * 0.25),
        height: k * (0.85 + r.hocico * 0.35),
      ),
      cara,
    );

    if (r.antifaz) {
      // Antifaz negro del mapache, con "cejas" blancas encima.
      canvas.drawOval(
        Rect.fromCenter(center: c.translate(0, -k * 0.42), width: k * 1.7, height: k * 0.32),
        cara,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(0, -k * 0.08), width: k * 1.85, height: k * 0.5),
          Radius.circular(k * 0.25),
        ),
        Paint()..color = const Color(0xFF262626),
      );
    }

    // Ojos
    for (final lado in [-1.0, 1.0]) {
      final ojo = c.translate(lado * k * 0.42, -k * 0.08);
      if (r.anillosOjos) canvas.drawCircle(ojo, k * 0.22, cara);
      canvas.drawCircle(ojo, k * 0.12, oscuro);
      canvas.drawCircle(ojo.translate(-k * 0.035, -k * 0.045), k * 0.04, Paint()..color = Colors.white);
    }

    // Nariz
    final nariz = c.translate(0, k * (0.3 + r.hocico * 0.15));
    canvas.drawOval(Rect.fromCenter(center: nariz, width: k * 0.32, height: k * 0.22),
        Paint()..color = r.nariz);

    // Boca: dos curvitas debajo de la nariz.
    final trazo = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = k * 0.045
      ..strokeCap = StrokeCap.round;
    final boca = nariz.translate(0, k * 0.11);
    canvas.drawLine(nariz, boca, trazo);
    for (final lado in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(boca.dx, boca.dy)
          ..quadraticBezierTo(boca.dx + lado * k * 0.08, boca.dy + k * 0.1,
              boca.dx + lado * k * 0.18, boca.dy + k * 0.02),
        trazo,
      );
    }

    if (r.dientes) {
      canvas.drawRect(
        Rect.fromLTWH(boca.dx - k * 0.08, boca.dy + k * 0.03, k * 0.16, k * 0.14),
        Paint()..color = Colors.white,
      );
      canvas.drawLine(boca.translate(0, k * 0.03), boca.translate(0, k * 0.17),
          trazo..strokeWidth = k * 0.02);
    }
    if (r.lengua) {
      canvas.drawOval(
        Rect.fromCenter(center: boca.translate(0, k * 0.14), width: k * 0.2, height: k * 0.22),
        Paint()..color = const Color(0xFFE5707E),
      );
    }

    // Bigotes
    final bigote = Paint()
      ..color = const Color(0x99303030)
      ..strokeWidth = k * 0.025;
    for (final lado in [-1.0, 1.0]) {
      for (final i in [-1, 0, 1]) {
        final inicio = nariz.translate(lado * k * 0.25, k * 0.08);
        canvas.drawLine(inicio, inicio.translate(lado * k * 0.6, i * k * 0.12), bigote);
      }
    }
  }

  void _orejas(Canvas canvas, Offset c, double k, Paint pelo) {
    final interior = Paint()..color = r.interiorOreja;
    for (final lado in [-1.0, 1.0]) {
      switch (r.oreja) {
        case _Oreja.puntiaguda:
          final base1 = c.translate(lado * k * 0.98, -k * 0.2);
          final base2 = c.translate(lado * k * 0.22, -k * 0.82);
          final punta = c.translate(lado * k * 0.92, -k * 1.5);
          canvas.drawPath(_triangulo(base1, base2, punta, 1), pelo);
          canvas.drawPath(_triangulo(base1, base2, punta, 0.55), interior);
        case _Oreja.larga:
          canvas.save();
          canvas.translate(c.dx + lado * k * 0.42, c.dy - k * 1.2);
          canvas.rotate(lado * 0.18);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: k * 0.55, height: k * 1.3), pelo);
          canvas.drawOval(
              Rect.fromCenter(center: Offset.zero, width: k * 0.28, height: k * 1.0), interior);
          canvas.restore();
        case _Oreja.redonda:
          final centro = c.translate(lado * k * 0.78, -k * 0.78);
          canvas.drawCircle(centro, k * 0.38, pelo);
          canvas.drawCircle(centro, k * 0.22, interior);
        case _Oreja.caida:
          canvas.save();
          canvas.translate(c.dx + lado * k * 0.98, c.dy - k * 0.05);
          canvas.rotate(lado * 0.35);
          canvas.drawOval(
              Rect.fromCenter(center: Offset.zero, width: k * 0.55, height: k * 1.25), interior);
          canvas.restore();
      }
    }
  }

  static Path _triangulo(Offset a, Offset b, Offset c, double escala) {
    final centro = (a + b + c) / 3;
    Offset e(Offset p) => centro + (p - centro) * escala;
    return Path()
      ..moveTo(e(a).dx, e(a).dy)
      ..lineTo(e(b).dx, e(b).dy)
      ..lineTo(e(c).dx, e(c).dy)
      ..close();
  }

  @override
  bool shouldRepaint(_PintorAnimal anterior) => anterior.r != r;
}