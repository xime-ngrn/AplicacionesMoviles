/// Un lugar del mapa de la granja.
class Lugar {
  const Lugar({
    required this.id,
    required this.nombre,
    required this.nivel,
    required this.descripcion,
    required this.puntos,
  });

  final String id;
  final String nombre;

  final int nivel;

  final String descripcion;

  final List<PuntoBusqueda> puntos;

  String get imagen => 'assets/imagenes/lugares/$id.svg';
}

class PuntoBusqueda {
  const PuntoBusqueda({
    required this.id,
    required this.nombre,
    this.pistaId,
    this.textoVacio = 'Buscas con cuidado, pero aquí no hay nada fuera de lo normal.',
  });

  final String id;
  final String nombre;

  final String? pistaId;

  final String textoVacio;
}

class FichaAnimal {
  const FichaAnimal({
    required this.horario,
    required this.dieta,
    required this.huellas,
    required this.cola,
    required this.dato,
  });

  final String horario;
  final String dieta;
  final String huellas;
  final String cola;
  final String dato;
}

class Sospechoso {
  const Sospechoso({
    required this.id,
    required this.nombre,
    required this.presentacion,
    required this.ficha,
  });

  final String id;
  final String nombre;

  final String presentacion;
  final FichaAnimal ficha;

  String get imagen => 'assets/imagenes/animales/$id.svg';
}

class Pista {
  const Pista({
    required this.id,
    required this.titulo,
    required this.texto,
    required this.nivel,
    this.descarta = const [],
    this.apuntaA = const [],
    this.esFalsa = false,
    this.esConfirmacion = false,
  });

  final String id;
  final String titulo;

  final String texto;

  final int nivel;

  final List<String> descarta;

  final List<String> apuntaA;

  final bool esFalsa;

  final bool esConfirmacion;
}

String conGranjero(String texto, String nombre) => texto.replaceAll('{granjero}', nombre);

/// Todo el contenido de la historia en un solo lugar.
abstract final class Historia {
  static const culpable = 'mapache';
  /// Los 3 que siguen siendo sospechosos al empezar la noche 2.
  static const finalistas = ['mapache', 'tlacuache', 'cacomixtle'];

  /// Para pasar a la noche 2 hay que descartar a estos tres.
  static const descartadosNoche1 = ['perro', 'conejo', 'zorro'];

  static const minutosPorBusqueda = 30;
  static const minutosPorNocheDetective = 5 * 60;

  static const introduccion = {
    1: 'Son las diez de la noche. {granjero} escucha un crujido en el maizal y, por la mañana, '
        'faltan varias mazorcas. Alguien se está comiendo su cosecha. Esta noche investigará '
        'la casa y el maizal.',
    2: 'Tres animales ya quedaron libres de sospecha. Los que quedan saben trepar y tienen '
        'manitas hábiles. Esta noche {granjero} revisará el granero y el área libre.',
  };

  /// Se muestra cuando se acusa al mapache con las pruebas correctas.
  static const desenlace = 'Al ver las pistas encontradas no queda duda, alguien capaz de '
      'realizar tales hazañas debe ser un ladrón enmascarado. ¡El mapache es el único capaz!';

  // ------------------------------------------------------------------ Lugares

  static const lugares = <Lugar>[
    Lugar(
      id: 'casa',
      nombre: 'La casa',
      nivel: 1,
      descripcion: 'La casa de {granjero}: la cocina, la cama de Canelo y, atrás, el gallinero.',
      puntos: [
        PuntoBusqueda(id: 'cama_perro', nombre: 'Cama del perro', pistaId: 'coartada_perro'),
        PuntoBusqueda(id: 'gallinero', nombre: 'Gallinero', pistaId: 'huellas_gallinero'),
        PuntoBusqueda(
          id: 'cocina',
          nombre: 'Cocina',
          textoVacio: 'En la cocina solo está el café de la tarde, ya frío.',
        ),
      ],
    ),
    Lugar(
      id: 'maizal',
      nombre: 'El maizal',
      nivel: 1,
      descripcion: 'El maizal de {granjero}: los surcos bajos, las mazorcas altas y por debajo, el lodo.',
      puntos: [
        PuntoBusqueda(id: 'surcos_bajos', nombre: 'Los surcos bajos', pistaId: 'brotes_mordidos'),
        PuntoBusqueda(id: 'mazorcas_altas', nombre: 'Las mazorcas altas', pistaId: 'mazorcas'),
        PuntoBusqueda(
          id: 'lodo',
          nombre: 'El lodo debajo',
          pistaId: 'huellas_lodo',
        ),
      ],
    ),
    Lugar(
      id: 'granero',
      nombre: 'El granero',
      nivel: 2,
      descripcion: 'El granero de {granjero}: la viga alta, el piso y, al fondo, una ventana '
          'que da al área libre.',
      puntos: [
        PuntoBusqueda(id: 'viga_alta', nombre: 'La viga alta', pistaId: 'huella_viga'),
        PuntoBusqueda(id: 'piso', nombre: 'El piso del granero', pistaId: 'cascarones_huevo'),
        PuntoBusqueda(
          id: 'ventana',
          nombre: 'La ventana hacia el área libre',
          pistaId: 'pelos_encontrados',
        ),
      ],
    ),
    Lugar(
      id: 'area_libre',
      nombre: 'El área libre',
      nivel: 2,
      descripcion: 'El área libre detrás del granero: el árbol hueco, el abrevadero y un búho curioso.',
      puntos: [
        PuntoBusqueda(id: 'arbol_hueco', nombre: 'El árbol hueco', pistaId: 'madriguera'),
        PuntoBusqueda(id: 'abrevadero', nombre: 'El abrevadero', pistaId: 'restos_elote'),
        PuntoBusqueda(id: 'buho', nombre: 'El búho curioso', pistaId: 'don_tecolote'),
      ],
    ),
  ];

  // --------------------------------------------------------------- Sospechosos

  static const sospechosos = <Sospechoso>[
    Sospechoso(
      id: 'perro',
      nombre: 'Canelo, el perro',
      presentacion: 'El perro de la casa. Ladra mucho, pero jura que esa noche no salió.',
      ficha: FichaAnimal(
        horario: 'Diurno: de noche duerme en casa',
        dieta: 'Croquetas y sobras de la cocina',
        huellas: '4 dedos con uñas marcadas',
        cola: 'Corta y peluda',
        dato: 'Su olfato es miles de veces más sensible que el nuestro.',
      ),
    ),
    Sospechoso(
      id: 'conejo',
      nombre: 'Conejo blanco',
      presentacion: 'Uno de los conejos que se escapa de su madriguera.',
      ficha: FichaAnimal(
        horario: 'Diurno: de noche regresa a su madriguera con sus hermanos y hermanas.',
        dieta: 'Animal herbívoro, generalmente come pasto y hierbas',
        huellas: 'Sin distinguirse, su pelo cubre todas sus patas',
        cola: 'Corta y en forma de una bolita',
        dato: 'Los dientes de los conejos nunca dejan de crecer.',
      ),
    ),
    Sospechoso(
      id: 'zorro',
      nombre: 'Un zorro rojo muy audaz',
      presentacion: 'Un zorro rojo que no se deja ver. Un animal muy rápido y escurridizo.',
      ficha: FichaAnimal(
        horario: 'Nocturno: de noche es cuando sale sin preocupaciones',
        dieta: 'Omnívoro, generalmente come pequeños mamíferos, aves y frutas',
        huellas: '4 dedos con garras, alargada y estrecha',
        cola: 'Larga, espesa y peluda',
        dato: 'Se cree que usa el campo magnético de la Tierra para calcular su salto al cazar.',
      ),
    ),
    Sospechoso(
      id: 'tlacuache',
      nombre: 'Tlacu, el tlacuache',
      presentacion: 'El único marsupial nativo de México, el tlacuache.',
      ficha: FichaAnimal(
        horario: 'Nocturno: pasan el día durmiendo para buscar alimento en la noche',
        dieta: 'Omnívoro, comen de todo lo que puedan encontrar de forma fácil, incluso desperdicios',
        huellas: 'Patas cortas con 5 dedos',
        cola: 'Larga (muy larga), fuerte y lampiña, les ayuda a trepar',
        dato: 'Cuando se sienten en peligro extremo, fingen estar muertos.',
      ),
    ),
    Sospechoso(
      id: 'cacomixtle',
      nombre: 'Mini puma, el cacomixtle',
      presentacion: 'Le dicen "mini puma" por sus ojos de gato, pero en realidad es primo '
          'del mapache. Tímido y ágil, el cacomixtle.',
      ficha: FichaAnimal(
        horario: 'Nocturno principalmente: es un animal tímido y sigiloso que trabaja por la noche',
        dieta: 'Omnívoro, dieta muy variada (frutas, tunas, insectos, aves y roedores pequeños)',
        huellas: '5 dedos marcados, sus garras son semirretráctiles',
        cola: 'Esponjosa e incluso más larga que su cuerpo, patrón de anillos blancos con negro',
        dato: 'Sus patas traseras pueden girar más de 180 grados, lo que les permite trepar.',
      ),
    ),
    Sospechoso(
      id: 'mapache',
      nombre: 'Un mapache muy gordo',
      presentacion: 'El animal más gordo de la granja, el mapache.',
      ficha: FichaAnimal(
        horario: 'Nocturno y solitario',
        dieta: 'Omnívoro, comen todo lo que puedan encontrar (frutas, insectos, huevos, ranas)',
        huellas: '5 dedos largos, se asemejan a manos humanas pequeñas',
        cola: 'Mediana, gruesa, con un patrón de anillos grises, blancos y negros',
        dato: 'Tienen un sentido del tacto hiperdesarrollado, al mojarse se vuelven más sensibles.',
      ),
    ),
  ];

  // ------------------------------------------------------------------- Pistas

  static const pistas = <Pista>[
    Pista(
      id: 'coartada_perro',
      titulo: 'La coartada de Canelo',
      texto: 'La cama de Canelo sigue tibia y la puerta tiene el cerrojo puesto por dentro: '
          'el perro pasó toda la noche en casa.',
      nivel: 1,
      descarta: ['perro'],
    ),
    Pista(
      id: 'huellas_gallinero',
      titulo: 'Huellas hacia el gallinero',
      texto: 'Junto al gallinero hay huellas de cuatro dedos, una tras otra en línea recta. '
          'Van hacia las gallinas, no hacia el maizal.',
      nivel: 1,
      descarta: ['zorro'],
    ),
    Pista(
      id: 'brotes_mordidos',
      titulo: 'Brotes mordisqueados',
      texto: 'En los surcos bajos hay brotes de maíz cortados al ras del suelo, con mordidas '
          'limpias en diagonal, como de dientes que nunca dejan de crecer. Aunque... las orillas '
          'ya están secas y amarillas.',
      nivel: 1,
      apuntaA: ['conejo'],
      esFalsa: true,
    ),
    Pista(
      id: 'mazorcas',
      titulo: 'Mazorcas fuera de alcance',
      texto: 'Las mazorcas mordidas están en lo alto de las matas, a más de un metro del suelo, '
          'y alguien les quitó las hojas con mucho cuidado. Un conejo no llega hasta allá ni '
          'puede deshojar un elote: el ladrón sabe trepar y tiene manos hábiles.',
      nivel: 1,
      descarta: ['conejo'],
      apuntaA: ['mapache', 'tlacuache', 'cacomixtle'],
    ),
    Pista(
      id: 'huellas_lodo',
      titulo: 'Manitas en el lodo',
      texto: 'En el lodo entre los surcos se marcan huellas de cinco dedos, separados como '
          'manitas. No son las cuatro almohadillas de un perro, ni la huella estrecha de un '
          'zorro, ni las patas peludas de un conejo.',
      nivel: 1,
      descarta: ['perro', 'zorro', 'conejo'],
      apuntaA: ['mapache', 'tlacuache', 'cacomixtle'],
    ),
    Pista(
      id: 'cascarones_huevo',
      titulo: 'Cascarones en el piso',
      texto: 'En el piso del granero hay cascarones de huevo rotos. ¡Al tlacuache le encantan '
          'los huevos! Aunque estos cascarones están limpios, secos y llenos de polvo.',
      nivel: 2,
      apuntaA: ['tlacuache'],
      esFalsa: true,
    ),
    Pista(
      id: 'pelos_encontrados',
      titulo: 'Pelos en la ventana',
      texto: 'Atorados en el marco de la ventana que da al área libre hay pelos gruesos con '
          'anillos claros y oscuros, de una cola esponjosa. El tlacuache no pudo dejarlos: su '
          'cola es lampiña. Quien pasó por aquí escapó hacia el área libre.',
      nivel: 2,
      descarta: ['tlacuache'],
      apuntaA: ['mapache', 'cacomixtle'],
    ),
    Pista(
      id: 'huella_viga',
      titulo: 'Una huella muy clara',
      texto: 'En el polvo de la viga alta quedó una huella perfecta: cinco dedos largos y '
          'delgados, sin marcas de garras, igualita a la mano de una persona pequeña.',
      nivel: 2,
      apuntaA: ['mapache'],
    ),
    Pista(
      id: 'madriguera',
      titulo: 'La madriguera del árbol hueco',
      texto: 'En el hueco del árbol descansa el cacomixtle, rodeado de cáscaras de tuna y alas '
          'de grillo: acaba de cenar. No hay ni un grano de maíz, y sus patas no tienen lodo '
          'del maizal.',
      nivel: 2,
      descarta: ['cacomixtle'],
    ),
    Pista(
      id: 'restos_elote',
      titulo: 'Elotes lavados',
      texto: 'Dentro del abrevadero flotan olotes mordisqueados y granos remojados. Alguien '
          'trajo los elotes hasta el agua para mojarlos y tallarlos con las manos antes de '
          'comérselos.',
      nivel: 2,
      apuntaA: ['mapache'],
    ),
    Pista(
      id: 'don_tecolote',
      titulo: 'El testimonio de Don Tecolote',
      texto: '—¡Uh, uh! —ulula Don Tecolote desde su rama—. Yo lo he visto, {granjero}: cada '
          'noche alguien muy sigiloso cruza del maizal al abrevadero cargando elotes. No pude '
          'verle la cara... ¡porque la tapa un antifaz negro!',
      nivel: 2,
      apuntaA: ['mapache'],
      esConfirmacion: true,
    ),
  ];

  // ------------------------------------------------------------- Búsquedas

  static Lugar lugar(String id) => lugares.firstWhere((l) => l.id == id);
  static Sospechoso sospechoso(String id) => sospechosos.firstWhere((s) => s.id == id);
  static Pista pista(String id) => pistas.firstWhere((p) => p.id == id);

  static bool existeLugar(String id) => lugares.any((l) => l.id == id);
  static bool existeSospechoso(String id) => sospechosos.any((s) => s.id == id);
  static bool existePista(String id) => pistas.any((p) => p.id == id);
  static bool existePunto(String id) => todosLosPuntos.any((p) => p.id == id);

  static List<Lugar> lugaresDeNivel(int nivel) =>
      lugares.where((l) => l.nivel == nivel).toList();

  static Iterable<PuntoBusqueda> get todosLosPuntos => lugares.expand((l) => l.puntos);
}
