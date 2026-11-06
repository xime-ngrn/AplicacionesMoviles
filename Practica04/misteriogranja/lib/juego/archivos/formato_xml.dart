import 'package:xml/xml.dart';

import '../modelo.dart';
import 'serializador.dart';

/// XML: los datos simples son etiquetas, las listas son etiquetas con hijos y
/// cada sospechoso y cada evento guarda sus datos como atributos.
///
/// ```xml
/// <partida version="1">
///   <nombre>Investigación de Don Chema</nombre>
///   <pistas><pista>coartada_perro</pista></pistas>
///   <sospechosos><sospechoso id="perro" estado="descartado">...</sospechoso></sospechosos>
///   <historial><evento nivel="1" minuto="30" tipo="pista" lugar="casa">...</evento></historial>
/// </partida>
/// ```
class SerializadorXml extends Serializador {
  const SerializadorXml();

  static const _simples = [
    'id', 'nombre', 'creada', 'actualizada', 'nivel', 'minuto', //
    'lugar', 'puntuacion', 'segundos', 'terminada', 'acusado',
  ];
  static const _atributosEvento = ['nivel', 'minuto', 'tipo', 'lugar', 'referencia'];

  @override
  String escribir(EstadoPartida partida) {
    final m = partida.toMap();
    final config = m['configuracion']! as Map<String, Object?>;
    final b = XmlBuilder()..processing('xml', 'version="1.0" encoding="UTF-8"');

    void lista(String contenedor, String hijo, Object? valores) => b.element(contenedor, nest: () {
          for (final v in valores! as List) {
            b.element(hijo, nest: '$v');
          }
        });

    b.element('partida', attributes: {'version': '${m['version']}'}, nest: () {
      for (final clave in _simples) {
        if (m[clave] != null) b.element(clave, nest: '${m[clave]}');
      }
      lista('etiquetas', 'etiqueta', m['etiquetas']);
      b.element('configuracion', nest: () {
        b.element('dificultad', nest: '${config['dificultad']}');
        b.element('granjero', nest: '${config['granjero']}');
      });
      lista('pistas', 'pista', m['pistas']);
      lista('puntos', 'punto', m['puntos']);
      b.element('sospechosos', nest: () {
        for (final s in (m['sospechosos']! as List).cast<Map<String, Object?>>()) {
          b.element('sospechoso',
              attributes: {'id': '${s['id']}', 'estado': '${s['estado']}'},
              nest: () {
            for (final pista in s['pistas']! as List) {
              b.element('pista', nest: '$pista');
            }
          });
        }
      });
      b.element('historial', nest: () {
        for (final e in (m['historial']! as List).cast<Map<String, Object?>>()) {
          b.element('evento',
              attributes: {
                for (final clave in _atributosEvento)
                  if (e[clave] != null) clave: '${e[clave]}',
              },
              nest: '${e['texto']}');
        }
      });
    });
    return b.buildDocument().toXmlString(pretty: true, indent: '  ');
  }

  @override
  EstadoPartida leer(String texto) {
    final XmlDocument documento;
    try {
      documento = XmlDocument.parse(texto);
    } on XmlException catch (e) {
      throw ErrorPartida('El archivo XML está mal escrito: ${e.message}.');
    }
    final raiz = documento.rootElement;
    if (raiz.name.local != 'partida') {
      throw ErrorPartida('El archivo XML no es una partida: empieza con <${raiz.name.local}>.');
    }

    String? valor(XmlElement? padre, String nombre) => padre?.getElement(nombre)?.innerText;
    Iterable<XmlElement> hijos(String contenedor, String hijo) =>
        raiz.getElement(contenedor)?.findElements(hijo) ?? const [];
    final config = raiz.getElement('configuracion');

    // Se arma el Map canónico; fromMap se encarga de validar cada dato.
    return EstadoPartida.fromMap({
      'version': raiz.getAttribute('version'),
      for (final clave in _simples) clave: valor(raiz, clave),
      'etiquetas': [for (final e in hijos('etiquetas', 'etiqueta')) e.innerText],
      'configuracion': {
        'dificultad': valor(config, 'dificultad'),
        'granjero': valor(config, 'granjero'),
      },
      'pistas': [for (final e in hijos('pistas', 'pista')) e.innerText],
      'puntos': [for (final e in hijos('puntos', 'punto')) e.innerText],
      'sospechosos': [
        for (final s in hijos('sospechosos', 'sospechoso'))
          {
            'id': s.getAttribute('id'),
            'estado': s.getAttribute('estado'),
            'pistas': [for (final pista in s.findElements('pista')) pista.innerText],
          },
      ],
      'historial': [
        for (final e in hijos('historial', 'evento'))
          {
            for (final clave in _atributosEvento) clave: e.getAttribute(clave),
            'texto': e.innerText,
          },
      ],
    });
  }
}
