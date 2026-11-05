import 'package:flutter/material.dart';

import '../almacenamiento/fuente_archivos.dart';

/// Pide un nombre de archivo o carpeta y lo valida antes de aceptar.
/// Devuelve null si el usuario canceló.
Future<String?> pedirNombre(
  BuildContext context, {
  required String titulo,
  required String boton,
  String inicial = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _DialogoNombre(titulo: titulo, boton: boton, inicial: inicial),
  );
}

/// Confirmación para acciones destructivas o importantes. Devuelve true si se aceptó.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String boton,
  bool destructivo = false,
}) async {
  final colores = Theme.of(context).colorScheme;
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          style: destructivo
              ? FilledButton.styleFrom(
                  backgroundColor: colores.error, foregroundColor: colores.onError)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(boton),
        ),
      ],
    ),
  );
  return respuesta ?? false;
}

class _DialogoNombre extends StatefulWidget {
  const _DialogoNombre({required this.titulo, required this.boton, required this.inicial});

  final String titulo;
  final String boton;
  final String inicial;

  @override
  State<_DialogoNombre> createState() => _DialogoNombreState();
}

class _DialogoNombreState extends State<_DialogoNombre> {
  late final _control = TextEditingController(text: widget.inicial);
  final _formulario = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Selecciona el nombre sin la extensión, para escribir encima directamente.
    final punto = widget.inicial.lastIndexOf('.');
    _control.selection = TextSelection(
      baseOffset: 0,
      extentOffset: punto > 0 ? punto : widget.inicial.length,
    );
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  void _aceptar() {
    if (_formulario.currentState!.validate()) Navigator.pop(context, _control.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Form(
        key: _formulario,
        child: TextFormField(
          controller: _control,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
          validator: (valor) => validarNombre(valor ?? ''),
          onFieldSubmitted: (_) => _aceptar(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _aceptar, child: Text(widget.boton)),
      ],
    );
  }
}
