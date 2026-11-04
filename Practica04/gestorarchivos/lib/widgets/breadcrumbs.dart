import 'package:flutter/material.dart';
import '../modelos/entrada_archivo.dart';

class Breadcrumbs extends StatefulWidget{
  const Breadcrumbs({super.key, required this.ruta, required this.alTocar});

  final List<EntradaArchivo> ruta;

  final ValueChanged<int> alTocar;

  @override
  State<Breadcrumbs> createState() => _BreadcrumbsState();
}

class _BreadcrumbsState extends State<Breadcrumbs>{
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(Breadcrumbs oldWidget){
    super.didUpdateWidget(oldWidget);
    // Al cambiar la ruta, desplaza la barra al final para que la carpeta actual siempre se vea.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(!_scroll.hasClients) return;
      _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut
      );
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    final colores = Theme.of(context).colorScheme;
    final ultimo = widget.ruta.length - 1;
    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child:
        Row(
          children: [
            for(var i = 0; i <= ultimo; i++) ...[
              if(i > 0) Icon(Icons.chevron_right, size:18, color: colores.onSurfaceVariant),
              TextButton.icon(
                onPressed: i == ultimo ? null : () => widget.alTocar(i),
                style: TextButton.styleFrom(disabledForegroundColor:  colores.onSurface),
                icon: i == 0 ? const Icon(Icons.home_outlined, size: 18) : null,
                label: Text(
                  widget.ruta[i].nombre,
                  style: i == ultimo ? const TextStyle(fontWeight: FontWeight.bold) : null
                ),
              ),
            ],
          ],
        ),
    );
  }

}