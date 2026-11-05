import 'package:flutter/material.dart';

import '../almacenamiento/errores.dart';
import '../almacenamiento/fuente_archivos.dart';
import '../app/historial.dart';
import '../modelos/entrada_archivo.dart';
import '../utils/formato.dart';
import '../widgets/breadcrumbs.dart';
import '../widgets/dialogos.dart';
import '../widgets/estado_mensaje.dart';
import '../widgets/hoja_detalles.dart';
import '../widgets/miniatura.dart';
import 'visor.dart';

/// Explorador de carpetas. Funciona con cualquier FuenteArchivos:
/// el espacio propio de la app y las carpetas autorizadas (SAF en Android, Archivos en iOS).
class PantallaExplorador extends StatefulWidget {
  const PantallaExplorador({super.key, required this.fuente, required this.historial});

  final FuenteArchivos fuente;
  final Historial historial;

  @override
  State<PantallaExplorador> createState() => _PantallaExploradorState();
}

enum _Accion { detalles, favorito, renombrar, copiar, mover, eliminar }

class _PantallaExploradorState extends State<PantallaExplorador> {
  /// Pila de carpetas visitadas, p. ej. [raíz, Datos, Pruebas]. Alimenta los breadcrumbs.
  late final List<EntradaArchivo> _ruta = [widget.fuente.raiz];

  /// Contenido de la carpeta actual; null mientras se carga.
  List<EntradaArchivo>? _entradas;
  Object? _error;

  /// null = automático según el ancho de pantalla; true/false = elegido por el usuario.
  bool? _cuadriculaElegida;

  /// Elemento marcado para copiar o mover; se pega al abrir la carpeta destino.
  ({EntradaArchivo entrada, bool mover})? _portapapeles;

  /// true mientras se ejecuta una operación (muestra una barra de progreso).
  bool _ocupado = false;

  FuenteArchivos get _fuente => widget.fuente;
  EntradaArchivo get _actual => _ruta.last;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Lee la carpeta actual. Los errores se muestran en pantalla, nunca cierran la app.
  Future<void> _cargar() async {
    final carpeta = _actual;
    try {
      final entradas = await _fuente.listar(carpeta);
      // Si el usuario cambió de carpeta mientras se leía, este resultado ya no sirve.
      if (!mounted || carpeta != _actual) return;
      setState(() {
        _entradas = entradas;
        _error = null;
      });
    } catch (e) {
      if (!mounted || carpeta != _actual) return;
      setState(() {
        _entradas = null;
        _error = e;
      });
    }
  }

  /// Aplica un cambio a la ruta, limpia el contenido (muestra el indicador) y recarga.
  void _navegar(VoidCallback cambio) {
    setState(() {
      cambio();
      _entradas = null;
      _error = null;
    });
    _cargar();
  }

  void _abrirCarpeta(EntradaArchivo carpeta) => _navegar(() => _ruta.add(carpeta));

  void _irANivel(int indice) {
    if (indice < 0 || indice >= _ruta.length - 1) return;
    _navegar(() => _ruta.removeRange(indice + 1, _ruta.length));
  }

  void _tocar(EntradaArchivo e) {
    if (e.esCarpeta) {
      _abrirCarpeta(e);
    } else {
      abrirArchivo(context, fuente: _fuente, entrada: e, historial: widget.historial);
    }
  }

  // -------------------------------------------------------------- Operaciones

  void _avisar(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  /// Ejecuta una operación de archivos: muestra progreso, informa el resultado y recarga.
  /// Si el sistema o el proveedor de documentos la rechaza, se explica el motivo.
  Future<void> _operacion(Future<void> Function() accion, {required String exito}) async {
    setState(() => _ocupado = true);
    String mensaje;
    try {
      await accion();
      mensaje = exito;
    } catch (e) {
      mensaje = '${ErrorArchivo.desde(e)}';
    }
    if (!mounted) return;
    setState(() => _ocupado = false);
    _avisar(mensaje);
    await _cargar();
  }

  Future<void> _nuevaCarpeta() async {
    final nombre = await pedirNombre(context, titulo: 'Nueva carpeta', boton: 'Crear');
    if (nombre == null) return;
    await _operacion(() => _fuente.crearCarpeta(_actual, nombre),
        exito: 'Se creó la carpeta "$nombre".');
  }

  Future<void> _mostrarAcciones(EntradaArchivo e) async {
    final favorito = widget.historial.esFavorito(e);
    final accion = await showModalBottomSheet<_Accion>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: Miniatura(fuente: _fuente, entrada: e),
              title: Text(e.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(_resumen(e)),
            ),
            const Divider(),
            _itemAccion(context, _Accion.detalles, Icons.info_outline, 'Detalles'),
            if (!e.esCarpeta)
              _itemAccion(context, _Accion.favorito, favorito ? Icons.star : Icons.star_border,
                  favorito ? 'Quitar de favoritos' : 'Agregar a favoritos'),
            _itemAccion(context, _Accion.renombrar, Icons.edit_outlined, 'Renombrar'),
            _itemAccion(context, _Accion.copiar, Icons.copy_outlined, 'Copiar'),
            _itemAccion(context, _Accion.mover, Icons.drive_file_move_outlined, 'Mover'),
            _itemAccion(context, _Accion.eliminar, Icons.delete_outline, 'Eliminar'),
          ],
        ),
      ),
    );
    if (accion == null || !mounted) return;
    switch (accion) {
      case _Accion.detalles:
        await mostrarDetalles(context, e);
      case _Accion.favorito:
        await widget.historial.alternarFavorito(e);
        _avisar(favorito ? 'Se quitó de favoritos.' : 'Se agregó a favoritos.');
      case _Accion.renombrar:
        await _renombrar(e);
      case _Accion.copiar || _Accion.mover:
        final mover = accion == _Accion.mover;
        setState(() => _portapapeles = (entrada: e, mover: mover));
        _avisar('Abre la carpeta destino y pulsa "Pegar aquí".');
      case _Accion.eliminar:
        await _eliminar(e);
    }
  }

  Widget _itemAccion(BuildContext context, _Accion accion, IconData icono, String texto) {
    final color = accion == _Accion.eliminar ? Theme.of(context).colorScheme.error : null;
    return ListTile(
      leading: Icon(icono, color: color),
      title: Text(texto, style: TextStyle(color: color)),
      onTap: () => Navigator.pop(context, accion),
    );
  }

  Future<void> _renombrar(EntradaArchivo e) async {
    final nuevo =
        await pedirNombre(context, titulo: 'Renombrar', boton: 'Renombrar', inicial: e.nombre);
    if (nuevo == null || nuevo == e.nombre) return;
    await _operacion(() async {
      await _fuente.renombrar(e, nuevo);
      await widget.historial.olvidar(e); // la referencia vieja ya no es válida
    }, exito: 'Se renombró a "$nuevo".');
  }

  Future<void> _eliminar(EntradaArchivo e) async {
    final aceptar = await confirmar(
      context,
      titulo: '¿Eliminar "${e.nombre}"?',
      mensaje: e.esCarpeta
          ? 'Se eliminará la carpeta y todo su contenido. Esta acción no se puede deshacer.'
          : 'Esta acción no se puede deshacer.',
      boton: 'Eliminar',
      destructivo: true,
    );
    if (!aceptar) return;
    await _operacion(() async {
      await _fuente.eliminar(e);
      await widget.historial.olvidar(e);
    }, exito: 'Se eliminó "${e.nombre}".');
  }

  Future<void> _pegar() async {
    final pendiente = _portapapeles;
    if (pendiente == null) return;
    setState(() => _portapapeles = null);
    final (e, mover) = (pendiente.entrada, pendiente.mover);
    await _operacion(() async {
      if (mover) {
        await _fuente.mover(e, _actual);
        await widget.historial.olvidar(e);
      } else {
        await _fuente.copiar(e, _actual);
      }
    }, exito: mover ? 'Se movió "${e.nombre}".' : 'Se copió "${e.nombre}".');
  }

  // ---------------------------------------------------------------- Interfaz

  @override
  Widget build(BuildContext context) {
    final enRaiz = _ruta.length == 1;
    // Diseño responsivo: cuadrícula en pantallas anchas (tablet u horizontal), lista en teléfono.
    final cuadricula = _cuadriculaElegida ?? MediaQuery.sizeOf(context).width >= 600;
    final colores = Theme.of(context).colorScheme;

    return PopScope(
      // En una subcarpeta, "atrás" (botón del sistema o flecha) sube un nivel
      // en vez de cerrar el explorador.
      canPop: enRaiz,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _irANivel(_ruta.length - 2);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(enRaiz ? _fuente.nombre : _actual.nombre),
          actions: [
            IconButton(
              tooltip: cuadricula ? 'Ver como lista' : 'Ver como cuadrícula',
              icon: Icon(cuadricula ? Icons.view_list : Icons.grid_view),
              onPressed: () => setState(() => _cuadriculaElegida = !cuadricula),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Nueva carpeta',
          onPressed: _ocupado ? null : _nuevaCarpeta,
          child: const Icon(Icons.create_new_folder_outlined),
        ),
        bottomNavigationBar: _barraPegar(),
        body: Column(
          children: [
            Material(
              color: colores.surfaceContainer,
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: Breadcrumbs(ruta: _ruta, alTocar: _irANivel),
              ),
            ),
            if (_ocupado) const LinearProgressIndicator() else const Divider(height: 1),
            Expanded(child: _contenido(cuadricula)),
          ],
        ),
      ),
    );
  }

  /// Barra inferior que aparece mientras hay algo por copiar o mover.
  Widget? _barraPegar() {
    final pendiente = _portapapeles;
    if (pendiente == null) return null;
    final colores = Theme.of(context).colorScheme;
    return Material(
      color: colores.secondaryContainer,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Icon(pendiente.mover ? Icons.drive_file_move_outlined : Icons.copy_outlined,
                  color: colores.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${pendiente.mover ? 'Mover' : 'Copiar'} "${pendiente.entrada.nombre}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colores.onSecondaryContainer),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _portapapeles = null),
                child: const Text('Cancelar'),
              ),
              FilledButton(onPressed: _ocupado ? null : _pegar, child: const Text('Pegar aquí')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenido(bool cuadricula) {
    final error = _error;
    if (error != null) {
      return EstadoMensaje(
        icono: Icons.error_outline,
        titulo: 'No se pudo abrir la carpeta',
        mensaje: '$error',
        accion: FilledButton.tonal(
          onPressed: () => _navegar(() {}),
          child: const Text('Reintentar'),
        ),
      );
    }
    final entradas = _entradas;
    if (entradas == null) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _cargar,
      child: entradas.isEmpty
          ? const EstadoMensaje(
              icono: Icons.folder_open,
              titulo: 'Esta carpeta está vacía',
              mensaje: 'Desliza hacia abajo para actualizar.',
            )
          : cuadricula
              ? _cuadricula(entradas)
              : _lista(entradas),
    );
  }

  String _resumen(EntradaArchivo e) => e.esCarpeta
      ? 'Carpeta · ${formatoFecha(e.modificado)}'
      : '${formatoTamano(e.tamano)} · ${formatoFecha(e.modificado)}';

  Widget _lista(List<EntradaArchivo> entradas) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 88), // espacio para el botón flotante
      itemCount: entradas.length,
      itemBuilder: (context, i) {
        final e = entradas[i];
        return ListTile(
          leading: Miniatura(fuente: _fuente, entrada: e),
          title: Text(e.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(_resumen(e)),
          trailing: IconButton(
            tooltip: 'Más opciones',
            icon: const Icon(Icons.more_vert),
            onPressed: () => _mostrarAcciones(e),
          ),
          onTap: () => _tocar(e),
          onLongPress: () => _mostrarAcciones(e),
        );
      },
    );
  }

  Widget _cuadricula(List<EntradaArchivo> entradas) {
    final tema = Theme.of(context);
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      // Las columnas se calculan solas: más ancho de pantalla = más columnas.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: entradas.length,
      itemBuilder: (context, i) {
        final e = entradas[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _tocar(e),
            onLongPress: () => _mostrarAcciones(e),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(
                    child: Center(child: Miniatura(fuente: _fuente, entrada: e, tamano: 72)),
                  ),
                  Text(
                    e.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.esCarpeta ? 'Carpeta' : formatoTamano(e.tamano),
                    maxLines: 1,
                    style: tema.textTheme.bodySmall
                        ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
