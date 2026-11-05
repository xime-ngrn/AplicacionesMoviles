import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'opciones.dart';

/// Sonidos del juego. Cada uno es un archivo `assets/sonidos/<nombre>.wav`
/// generado para este proyecto (sin derechos de terceros) e incluido en la app.
enum Sonido { clic, paso, pista, descarte, error, victoria }

/// Retroalimentación sonora y háptica (vibración), según las opciones del jugador.
/// Si el audio falla, el juego sigue funcionando en silencio.
class Efectos {
  Efectos(this._opciones);

  final Opciones _opciones;

  /// Un reproductor por sonido, para que varios puedan sonar a la vez.
  final _reproductores = <Sonido, AudioPlayer>{};

  Future<void> reproducir(Sonido sonido) async {
    if (_opciones.vibracion) {
      switch (sonido) {
        case Sonido.error:
          await HapticFeedback.heavyImpact();
        case Sonido.pista || Sonido.victoria:
          await HapticFeedback.mediumImpact();
        default:
          await HapticFeedback.selectionClick();
      }
    }
    if (!_opciones.sonido) return;
    try {
      var reproductor = _reproductores[sonido];
      if (reproductor == null) {
        reproductor = AudioPlayer();
        // En Android el modo de baja latencia es ideal para efectos cortos.
        if (Platform.isAndroid) await reproductor.setPlayerMode(PlayerMode.lowLatency);
        _reproductores[sonido] = reproductor;
      }
      await reproductor.stop();
      await reproductor.play(AssetSource('sonidos/${sonido.name}.wav'), volume: 0.8);
    } catch (e) {
      debugPrint('No se pudo reproducir "${sonido.name}": $e');
    }
  }
}
