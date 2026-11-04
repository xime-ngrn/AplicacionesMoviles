String formatoTamano(int? bytes){
  if(bytes == null || bytes < 0) return 'No disponible';
  const unidades = ['B', 'KB', 'MB', 'GB'];
  var valor = bytes.toDouble();
  var i = 0;
  while(valor >= 1024 && i < unidades.length - 1){
    valor /= 1024;
    i++;
  }
  return i == 0 ? '$bytes B' : '${valor.toStringAsFixed(1)} ${unidades[i]}';
}

String formatoFecha(DateTime? fecha){
  if(fecha == null) return 'No disponible';
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
      '${dos(fecha.hour)}:${dos(fecha.minute)}';
}