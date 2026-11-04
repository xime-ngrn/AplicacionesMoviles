import 'package:flutter/material.dart';
import '../modelos/entrada_archivo.dart';

class IconoArchivo extends StatelessWidget {
  const IconoArchivo({super.key, required this.entrada, this.tamano = 24});
  final EntradaArchivo entrada;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final (icono, color) = switch(entrada.tipo){
      TipoArchivo.carpeta => (Icons.folder, colores.primary),
      TipoArchivo.texto => (Icons.description_outlined, colores.secondary),
      TipoArchivo.json => (Icons.data_object, colores.tertiary),
      TipoArchivo.xml => (Icons.code, colores.tertiary),
      TipoArchivo.imagen => (Icons.image_outlined, colores.secondary),
      TipoArchivo.otro when entrada.extension == 'pdf' =>
      (Icons.picture_as_pdf_outlined, colores.error),
      TipoArchivo.otro => (Icons.insert_drive_file_outlined, colores.outline),
    };
    return Icon(icono, size: tamano, color: color);
  }

}