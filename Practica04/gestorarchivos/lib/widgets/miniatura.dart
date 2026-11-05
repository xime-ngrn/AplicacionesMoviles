import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../almacenamiento/cache_miniaturas.dart';
import '../almacenamiento/fuente_archivos.dart';
import '../modelos/entrada_archivo.dart';
import 'icono_archivo.dart';

/// Miniatura para imágenes (desde la caché) e icono para todo lo demás.
class Miniatura extends StatefulWidget {
  const Miniatura({super.key, required this.fuente, required this.entrada, this.tamano = 40});

  final FuenteArchivos fuente;
  final EntradaArchivo entrada;
  final double tamano;

  @override
  State<Miniatura> createState() => _MiniaturaState();
}

class _MiniaturaState extends State<Miniatura> {
  Future<Uint8List?>? _miniatura;

  @override
  void initState() {
    super.initState();
    _preparar();
  }

  @override
  void didUpdateWidget(Miniatura anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.entrada != widget.entrada ||
        anterior.entrada.modificado != widget.entrada.modificado) {
      _preparar();
    }
  }

  void _preparar() {
    _miniatura = widget.entrada.tipo == TipoArchivo.imagen
        ? CacheMiniaturas.instancia.obtener(widget.fuente, widget.entrada)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final icono = IconoArchivo(entrada: widget.entrada, tamano: widget.tamano);
    final miniatura = _miniatura;
    if (miniatura == null) return icono;
    return SizedBox.square(
      dimension: widget.tamano,
      child: FutureBuilder<Uint8List?>(
        future: miniatura,
        builder: (context, snap) {
          final datos = snap.data;
          if (datos == null) return Center(child: icono);
          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              datos,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => Center(child: icono),
            ),
          );
        },
      ),
    );
  }
}
