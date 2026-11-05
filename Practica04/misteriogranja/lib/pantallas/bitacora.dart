import 'package:flutter/material.dart';

import '../juego/datos_historia.dart';
import '../juego/modelo.dart';

/// La bitácora: el historial de movimientos de la partida, contado como un cuento.
/// Cada jugada del motor agregó un Evento (hora, lugar, tipo y una frase); aquí solo
/// se muestran en orden, separados por noche. En J4 este mismo historial se guarda
/// en el archivo TXT.
class VistaBitacora extends StatelessWidget {
  const VistaBitacora({super.key, required this.partida});

  final EstadoPartida partida;

  static IconData _icono(TipoEvento tipo) => switch (tipo) {
        TipoEvento.inicio => Icons.auto_stories,
        TipoEvento.viaje => Icons.directions_walk,
        TipoEvento.busqueda => Icons.search_off,
        TipoEvento.pista => Icons.search,
        TipoEvento.asignacion => Icons.link,
        TipoEvento.marca => Icons.edit_note,
        TipoEvento.acusacion => Icons.gavel,
        TipoEvento.nivel => Icons.nightlight_round,
        TipoEvento.fin => Icons.emoji_events,
      };

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final filas = <Widget>[];
    int? noche;
    for (final e in partida.historial) {
      if (e.nivel != noche) {
        noche = e.nivel;
        filas.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text('Noche $noche', style: tema.textTheme.titleLarge),
        ));
      }
      final lugar = Historia.existeLugar(e.lugarId) ? Historia.lugar(e.lugarId).nombre : '';
      filas.add(ListTile(
        leading: CircleAvatar(
          backgroundColor: tema.colorScheme.secondaryContainer,
          child: Icon(_icono(e.tipo), size: 20),
        ),
        title: Text(e.texto),
        subtitle: Text('${e.hora} · $lugar'),
      ));
    }
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: filas);
  }
}

/// La bitácora como pantalla completa (se abre desde la pantalla final).
class PantallaBitacora extends StatelessWidget {
  const PantallaBitacora({super.key, required this.partida});

  final EstadoPartida partida;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bitácora: ${partida.nombre}')),
      body: VistaBitacora(partida: partida),
    );
  }
}
