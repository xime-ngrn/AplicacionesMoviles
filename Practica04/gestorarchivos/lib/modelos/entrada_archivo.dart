enum TipoArchivo { carpeta, texto, json, xml, imagen, otro }

class EntradaArchivo {
  const EntradaArchivo({
    required this.fuenteId,
    required this.id,
    required this.nombre,
    required this.esCarpeta,
    this.tamano,
    this.modificado,
    this.creado,
    this.mime,
  });

  final String fuenteId;
  final String id;
  final String nombre;
  final bool esCarpeta;
  final int? tamano;
  final DateTime? modificado;
  final DateTime? creado;
  final String? mime;

  String get extension {
    final punto = nombre.lastIndexOf('.');
    if(esCarpeta || punto <= 0) return '';
    return nombre.substring(punto + 1).toLowerCase();
  }

  TipoArchivo get tipo {
    if (esCarpeta) return TipoArchivo.carpeta;
    return switch (extension) {
      'txt' || 'md' || 'csv' || 'log' || 'yaml' || 'yml' => TipoArchivo.texto,
      'json' => TipoArchivo.json,
      'xml' => TipoArchivo.xml,
      'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' || 'bmp' => TipoArchivo.imagen,
      _ => TipoArchivo.otro,
    };
  }

  @override
  bool operator ==(Object other) => 
      other is EntradaArchivo && other.fuenteId == fuenteId && other.id == id;
  
  @override
  int get hashCode => Object.hash(fuenteId, id);
  
}