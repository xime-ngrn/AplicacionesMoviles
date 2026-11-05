import 'dart:io';

import 'package:flutter/material.dart';

import '../almacenamiento/cache_miniaturas.dart';
import '../almacenamiento/carpetas_autorizadas.dart';
import '../almacenamiento/errores.dart';
import '../almacenamiento/fuente_archivos.dart';
import '../almacenamiento/fuente_local.dart';
import '../app/ajustes.dart';
import '../app/historial.dart';
import '../app/tema.dart';
import '../modelos/entrada_archivo.dart';
import '../utils/formato.dart';
import '../widgets/dialogos.dart';
import '../widgets/icono_archivo.dart';
import 'explorador.dart';
import 'visor.dart';

/// Pantalla principal: ubicaciones, carpetas autorizadas, favoritos, recientes y ajustes.
class PantallaInicio extends StatelessWidget {
  const PantallaInicio({
    super.key,
    required this.ajustes,
    required this.local,
    required this.carpetas,
    required this.historial,
  });

  final Ajustes ajustes;
  final FuenteLocal local;
  final CarpetasAutorizadas carpetas;
  final Historial historial;

  void _explorar(BuildContext context, FuenteArchivos fuente) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PantallaExplorador(fuente: fuente, historial: historial),
    ));
  }

  // ------------------------------------------------------ Carpetas autorizadas

  /// Explica para qué se pide el acceso ANTES de abrir el selector del sistema,
  /// y respeta la decisión del usuario si cancela.
  Future<void> _agregarCarpeta(BuildContext context, {bool explicar = true}) async {
    if (explicar) {
      final aceptar = await confirmar(
        context,
        titulo: 'Dar acceso a una carpeta',
        mensaje: 'Para mostrarte archivos que están fuera de la app, se abrirá el selector '
            '${Platform.isIOS ? 'de Archivos' : 'de carpetas de Android'} para que elijas una.\n\n'
            '• La app solo podrá ver y modificar esa carpeta y lo que contiene.\n'
            '• No se pide acceso a todo el almacenamiento.\n'
            '• Puedes quitar el acceso cuando quieras desde esta pantalla.'
            '${Platform.isAndroid ? '\n\nAndroid no permite elegir la raíz del almacenamiento '
                'ni la carpeta Download completa; elige o crea una subcarpeta.' : ''}',
        boton: 'Elegir carpeta',
      );
      if (!aceptar) return;
    }
    if (!context.mounted) return;
    final mensajero = ScaffoldMessenger.of(context);
    try {
      final nueva = await carpetas.agregar();
      mensajero.showSnackBar(SnackBar(
        content: Text(nueva == null
            ? 'No se eligió ninguna carpeta.'
            : 'Acceso concedido a "${nueva.nombre}".'),
      ));
    } catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _abrirCarpeta(BuildContext context, CarpetaAutorizada c) async {
    try {
      final fuente = await carpetas.abrir(c);
      if (context.mounted) _explorar(context, fuente);
    } catch (e) {
      if (!context.mounted) return;
      // Permiso revocado o carpeta inexistente: se informa y se ofrece qué hacer.
      final accion = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.folder_off_outlined),
          title: Text('Sin acceso a "${c.nombre}"'),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'quitar'),
              child: const Text('Quitar de la lista'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'autorizar'),
              child: const Text('Volver a autorizar'),
            ),
          ],
        ),
      );
      if (accion == null) return;
      await _quitarSinPreguntar(c);
      if (accion == 'autorizar' && context.mounted) {
        await _agregarCarpeta(context, explicar: false);
      }
    }
  }

  Future<void> _quitarCarpeta(BuildContext context, CarpetaAutorizada c) async {
    final aceptar = await confirmar(
      context,
      titulo: '¿Quitar el acceso a "${c.nombre}"?',
      mensaje: 'No se borra ningún archivo; la app solo deja de tener permiso para ver la carpeta.',
      boton: 'Quitar acceso',
    );
    if (aceptar) await _quitarSinPreguntar(c);
  }

  Future<void> _quitarSinPreguntar(CarpetaAutorizada c) async {
    await carpetas.quitar(c);
    await historial.olvidarFuente(CarpetasAutorizadas.fuenteIdDe(c));
  }

  // ------------------------------------------------------ Recientes y favoritos

  Future<void> _abrirReferencia(BuildContext context, EntradaArchivo e) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      final fuente = e.fuenteId == local.id ? local : await carpetas.fuentePorId(e.fuenteId);
      if (fuente == null) {
        throw const ErrorArchivo('La carpeta de este archivo ya no está autorizada.');
      }
      if (!context.mounted) return;
      await abrirArchivo(context, fuente: fuente, entrada: e, historial: historial);
    } catch (err) {
      mensajero.showSnackBar(SnackBar(
        content: Text('${ErrorArchivo.desde(err)}'),
        action: SnackBarAction(label: 'Quitar', onPressed: () => historial.olvidar(e)),
      ));
    }
  }

  String _origen(EntradaArchivo e) {
    if (e.fuenteId == local.id) return local.nombre;
    for (final c in carpetas.carpetas) {
      if (CarpetasAutorizadas.fuenteIdDe(c) == e.fuenteId) return c.nombre;
    }
    return 'Ubicación no disponible';
  }

  List<Widget> _listaArchivos(
    BuildContext context,
    List<EntradaArchivo> archivos, {
    required String vacio,
    required bool favoritos,
  }) {
    final texto = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;
    if (archivos.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(vacio, style: texto.bodyMedium?.copyWith(color: colores.onSurfaceVariant)),
        ),
      ];
    }
    return [
      for (final e in archivos)
        Card(
          child: ListTile(
            leading: IconoArchivo(entrada: e, tamano: 32),
            title: Text(e.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${_origen(e)} · ${formatoTamano(e.tamano)}',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: favoritos
                ? IconButton(
                    tooltip: 'Quitar de favoritos',
                    icon: const Icon(Icons.star),
                    onPressed: () => historial.alternarFavorito(e),
                  )
                : null,
            onTap: () => _abrirReferencia(context, e),
          ),
        ),
    ];
  }

  // ------------------------------------------------------------------ Interfaz

  Widget _titulo(BuildContext context, String texto, {Widget? accion}) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.titleMedium)),
          ?accion, // solo se agrega si no es null
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;
    final oscuro = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de Archivos')),
      // En tablet u horizontal el contenido no se estira de orilla a orilla.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListenableBuilder(
            listenable: Listenable.merge([carpetas, historial]),
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                _titulo(context, 'Ubicaciones'),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.phone_android, color: colores.primary),
                    title: Text(local.nombre),
                    subtitle: const Text('Archivos privados de la app (no requiere permisos)'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _explorar(context, local),
                  ),
                ),
                for (final c in carpetas.carpetas)
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.folder_shared, color: colores.primary),
                      title: Text(c.nombre),
                      subtitle: Text(Platform.isAndroid
                          ? 'Carpeta autorizada con el selector de Android (SAF)'
                          : 'Carpeta autorizada con el selector de Archivos'),
                      trailing: IconButton(
                        tooltip: 'Quitar acceso',
                        icon: const Icon(Icons.link_off),
                        onPressed: () => _quitarCarpeta(context, c),
                      ),
                      onTap: () => _abrirCarpeta(context, c),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed:
                          CarpetasAutorizadas.disponible ? () => _agregarCarpeta(context) : null,
                      icon: const Icon(Icons.create_new_folder_outlined),
                      label: const Text('Agregar carpeta del dispositivo'),
                    ),
                  ),
                ),
                _titulo(context, 'Favoritos'),
                ..._listaArchivos(context, historial.favoritos,
                    vacio: 'Marca archivos con ☆ para tenerlos a la mano.', favoritos: true),
                _titulo(
                  context,
                  'Recientes',
                  accion: historial.recientes.isEmpty
                      ? null
                      : TextButton(
                          onPressed: historial.borrarRecientes,
                          child: const Text('Borrar historial'),
                        ),
                ),
                ..._listaArchivos(context, historial.recientes.take(5).toList(),
                    vacio: 'Los archivos que abras aparecerán aquí.', favoritos: false),
                _titulo(context, 'Tema'),
                ListenableBuilder(
                  listenable: ajustes,
                  builder: (context, _) => SegmentedButton<TemaApp>(
                    segments: [
                      for (final t in TemaApp.values)
                        ButtonSegment(value: t, label: Text(t.etiqueta)),
                    ],
                    selected: {ajustes.tema},
                    onSelectionChanged: (s) => ajustes.cambiarTema(s.first),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  oscuro ? 'Modo oscuro (sigue al sistema)' : 'Modo claro (sigue al sistema)',
                  style: texto.bodySmall,
                ),
                _titulo(context, 'Almacenamiento'),
                // Sin const: se recalcula cada vez que cambia el historial (se abrió algo).
                // ignore: prefer_const_constructors
                _TarjetaCache(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Muestra cuánto ocupa la caché de miniaturas y permite vaciarla.
class _TarjetaCache extends StatefulWidget {
  const _TarjetaCache();

  @override
  State<_TarjetaCache> createState() => _TarjetaCacheState();
}

class _TarjetaCacheState extends State<_TarjetaCache> {
  late Future<(int, int)> _datos = CacheMiniaturas.instancia.estadisticas();

  @override
  void didUpdateWidget(_TarjetaCache anterior) {
    super.didUpdateWidget(anterior);
    _datos = CacheMiniaturas.instancia.estadisticas();
  }

  Future<void> _limpiar() async {
    await CacheMiniaturas.instancia.limpiar();
    if (!mounted) return;
    setState(() => _datos = CacheMiniaturas.instancia.estadisticas());
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Caché de miniaturas vaciada.')));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: FutureBuilder<(int, int)>(
        future: _datos,
        builder: (context, snap) {
          final (cantidad, bytes) = snap.data ?? (0, 0);
          return ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Caché de miniaturas'),
            subtitle: Text('$cantidad miniaturas · ${formatoTamano(bytes)}'),
            trailing: TextButton(
              onPressed: cantidad == 0 ? null : _limpiar,
              child: const Text('Vaciar'),
            ),
          );
        },
      ),
    );
  }
}
