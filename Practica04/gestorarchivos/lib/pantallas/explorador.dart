import 'package:flutter/material.dart';

import '../almacenamiento/fuente_archivos.dart';
import '../modelos/entrada_archivo.dart';
import '../utils/formato.dart';
import '../widgets/breadcrumbs.dart';
import '../widgets/estado_mensaje.dart';
import '../widgets/hoja_detalles.dart';
import '../widgets/icono_archivo.dart';

class PantallaExplorador extends StatefulWidget{
  const PantallaExplorador({super.key, required this.fuente});

  final FuenteArchivos fuente;

  @override
  State<PantallaExplorador> createState() => _PantallaExploradorState();
}

class _PantallaExploradorState extends State<PantallaExplorador>{
  late final List<EntradaArchivo> _ruta = [widget.fuente.raiz];

  List<EntradaArchivo>? _entradas;
  Object? _error;

  bool? _cuadriculaElegida;

  EntradaArchivo get _actual => _ruta.last;

  @override
  void initState(){
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async{
    final carpeta = _actual;
    try{
      final entradas = await widget.fuente.listar(carpeta);

      if(!mounted || carpeta != _actual) return;
      setState(() {
        _entradas = entradas;
        _error = null;
      });
    } catch (e) {
      if(!mounted || carpeta != _actual) return;
      setState(() {
        _entradas = null;
        _error = e;
      });
    }
  }

  void _navegar(VoidCallback cambio){
    setState(() {
      cambio();
      _entradas = null;
      _error = null;
    });
    _cargar();
  }

  void _abrirCarpeta(EntradaArchivo carpeta) => _navegar(() => _ruta.add(carpeta));

  void _irANivel(int indice){
    if(indice < 0 || indice >= _ruta.length - 1) return;
    _navegar(() => _ruta.removeRange(indice + 1, _ruta.length));
  }

  void _tocar(EntradaArchivo e){
    if(e.esCarpeta){
      _abrirCarpeta(e);
    }else{
      mostrarDetalles(context, e);
    }
  }

  @override
  Widget build(BuildContext context){
    final enRaiz = _ruta.length == 1;
    final cuadricula = _cuadriculaElegida ?? MediaQuery.sizeOf(context).width >= 600;

    return PopScope(
      canPop: enRaiz,
      onPopInvokedWithResult: (didPop, _){
        if(!didPop) _irANivel(_ruta.length - 2);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(enRaiz ? widget.fuente.nombre : _actual.nombre),
          actions: [
            IconButton(
              tooltip: cuadricula ? 'Ver como lista' : 'Ver como cuadricula',
              icon: Icon(cuadricula ? Icons.view_list : Icons.grid_view),
              onPressed: () => setState(() => _cuadriculaElegida = !cuadricula),
            ),
          ],
        ),
        body: Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: Breadcrumbs(ruta: _ruta, alTocar: _irANivel),
              ),
            ),
            const Divider(height: 1,),
            Expanded(child: _contenido(cuadricula)),
          ],
        ),
      ),
    );
  }

  Widget _contenido(bool cuadricula){
    final error = _error;
    if(error != null){
      return EstadoMensaje(
          icono: Icons.error_outline,
          titulo: 'No se pudo abrir la carpeta',
          mensaje: '$error',
          accion: FilledButton.tonal(
            onPressed: () => _navegar(() {}),
            child: const Text('Reintentar')
          )
      );
    }

    final entradas = _entradas;
    if(entradas == null) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
        onRefresh: _cargar,
        child: entradas.isEmpty ? const EstadoMensaje(icono: Icons.folder_open, titulo: 'Esta carpeta está vacía', mensaje: 'Desliza hacia abajo para actualizar')
            : cuadricula ? _cuadricula(entradas) : _lista(entradas),
    );
  }

  String _resumen(EntradaArchivo e) => e.esCarpeta
      ? 'Carpeta - ${formatoFecha(e.modificado)}'
      : '${formatoTamano(e.tamano)} - ${formatoFecha(e.modificado)}';

  Widget _lista(List<EntradaArchivo> entradas){
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: entradas.length,
      itemBuilder: (context, i) {
        final e = entradas[i];
        return ListTile(
          leading: IconoArchivo(entrada: e, tamano: 32),
          title: Text(e.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(_resumen(e)),
          trailing: IconButton(
            tooltip: 'Detalles',
            icon: const Icon(Icons.info_outline),
            onPressed: () => mostrarDetalles(context, e),
          ),
          onTap: () => _tocar(e),
        );
      },
    );
  }

  Widget _cuadricula(List<EntradaArchivo> entradas) {
    final tema = Theme.of(context);
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: entradas.length,
      itemBuilder: (context, i){
        final e = entradas[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _tocar(e),
            onLongPress: () => mostrarDetalles(context, e),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(child: Center(child: IconoArchivo(entrada: e, tamano: 48))),
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
                    style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
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