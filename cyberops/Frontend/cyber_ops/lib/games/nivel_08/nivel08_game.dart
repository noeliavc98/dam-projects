// Nivel08Game · Lógica d

//  Los 3 laboratorios (bypass de login, extracción UNION, bypass de filtro).

import 'components/elemento_nivel08.dart';

class Nivel08Game {
  int _vidas = 3;
  int _xp = 0;
  int _labActualIdx = 0;
  final List<PiezaSql> _payload = [];

  int get vidas => _vidas;
  int get xp => _xp;
  int get labActualIdx => _labActualIdx;
  // Devuelve siempre un Lab válido. Si el índice se ha pasado del último

  Lab get labActual => labs[_labActualIdx.clamp(0, labs.length - 1)];
  bool get nivelCompletado => _labActualIdx >= labs.length;
  List<PiezaSql> get payload => List.unmodifiable(_payload);

  //  DIÁLOGOS DE INTRO
  final List<MomentoFractura> dialogosIntro = const [
    MomentoFractura(
      texto:
          'Estás frente al servidor. Cada sistema tiene sus grietas. Vamos a encontrar las suyas.',
      estado: EstadoFractura.pensando,
    ),
    MomentoFractura(
      texto: 'Yo veo lo que tú no ves. Y lo que veo aquí... es una invitación.',
      estado: EstadoFractura.pensando,
    ),
    MomentoFractura(
      texto:
          'No vamos a romper nada. Vamos a hablarle al servidor en su idioma. Le diremos lo que quiere oír.',
      estado: EstadoFractura.atenta,
    ),
    MomentoFractura(
      texto:
          'Yo te paso las piezas. Tú las combinas. Cuidado con las rojas — esas no entran. Esas borran.',
      estado: EstadoFractura.atenta,
    ),
    MomentoFractura(
      texto: 'Empieza. Lee el código. Donde concatenan, sangra.',
      estado: EstadoFractura.neutral,
    ),
  ];

  //DIÁLOGOS
  final List<MomentoFractura> dialogosOutro = const [
    MomentoFractura(
      texto: 'Has entrado. La grieta cedió. Esto se llama Inyección SQL.',
      estado: EstadoFractura.triunfal,
    ),
    MomentoFractura(
      texto:
          'Cualquier campo que un dedo pueda tocar y llegue sin filtrar a una base de datos... es una invitación como esta.',
      estado: EstadoFractura.aprobando,
    ),
    MomentoFractura(
      texto:
          'Si algún día tú escribes código: parametriza. Habla el idioma seguro. O alguien como nosotros vendrá a recordártelo.',
      estado: EstadoFractura.atenta,
    ),
    MomentoFractura(
      texto: 'Has aprendido a leer una grieta. Sigue. La red está llena.',
      estado: EstadoFractura.triunfal,
    ),
  ];

  //  LABS
  late final List<Lab> labs = [
    // LAB 1 · Bypass de login
    Lab(
      numero: 1,
      titulo: 'BYPASS DE LOGIN',
      mision: 'Convence al login de que tienes una contraseña que no tienes.',
      victimaUrl: 'servidor / login',
      codigoLineas: [
        "\$user = \$_POST['user'];",
        "\$sql = \"SELECT * FROM users WHERE user='\".\$user.\"' AND pass='\$p'\";",
        "\$db->query(\$sql);",
      ],
      lineaVulnerable: 1,
      avisoCodigo:
          '⚠ La línea 02 concatena \$user sin escapar — la grieta vive aquí.',
      arsenal: const [
        PiezaSql(id: 'l1_q1', token: "'", categoria: CategoriaPieza.escape),
        PiezaSql(id: 'l1_q2', token: '"', categoria: CategoriaPieza.escape),
        PiezaSql(
          id: 'l1_or1',
          token: 'OR 1=1',
          categoria: CategoriaPieza.bypass,
        ),
        PiezaSql(
          id: 'l1_or2',
          token: "OR 'a'='a'",
          categoria: CategoriaPieza.bypass,
        ),
        PiezaSql(id: 'l1_c1', token: '--', categoria: CategoriaPieza.silencio),
        PiezaSql(id: 'l1_c2', token: '#', categoria: CategoriaPieza.silencio),
        PiezaSql(
          id: 'l1_admin',
          token: 'admin',
          categoria: CategoriaPieza.senuelo,
        ),
        PiezaSql(
          id: 'l1_drop',
          token: 'DROP',
          categoria: CategoriaPieza.trampa,
        ),
        PiezaSql(
          id: 'l1_del',
          token: 'DELETE',
          categoria: CategoriaPieza.trampa,
        ),
      ],
      categoriasNecesarias: const [
        CategoriaPieza.escape,
        CategoriaPieza.bypass,
        CategoriaPieza.silencio,
      ],
      queryPlantilla:
          "SELECT * FROM users WHERE user='{payload}' AND pass='****'",
      mensajeExito:
          '[200 OK] ✓ DENTRO\nEl login te dejó pasar como si fueras alguien.\nNadie pidió tu contraseña.',
    ),

    // LAB 2 · Extracción de datos con UNION
    Lab(
      numero: 2,
      titulo: 'EXTRACCIÓN UNION',
      mision: 'Pídele a la búsqueda que te enseñe lo que no debe.',
      victimaUrl: 'servidor / buscar',
      codigoLineas: [
        "\$q = \$_GET['buscar'];",
        "\$sql = \"SELECT nombre FROM productos WHERE nombre LIKE '\$q'\";",
        "\$db->query(\$sql);",
      ],
      lineaVulnerable: 1,
      avisoCodigo:
          '⚠ La búsqueda concatena directamente. Puedes UNIR otra consulta.',
      arsenal: const [
        PiezaSql(id: 'l2_q', token: "'", categoria: CategoriaPieza.escape),
        PiezaSql(
          id: 'l2_union',
          token: 'UNION SELECT email',
          categoria: CategoriaPieza.extraer,
        ),
        PiezaSql(
          id: 'l2_from',
          token: 'FROM users',
          categoria: CategoriaPieza.extraer,
        ),
        PiezaSql(id: 'l2_c', token: '--', categoria: CategoriaPieza.silencio),
        PiezaSql(
          id: 'l2_or',
          token: 'OR 1=1',
          categoria: CategoriaPieza.bypass,
        ),
        PiezaSql(
          id: 'l2_admin',
          token: 'admin',
          categoria: CategoriaPieza.senuelo,
        ),
        PiezaSql(
          id: 'l2_drop',
          token: 'DROP TABLE',
          categoria: CategoriaPieza.trampa,
        ),
      ],
      categoriasNecesarias: const [
        CategoriaPieza.escape,
        CategoriaPieza.extraer,
        CategoriaPieza.silencio,
      ],
      queryPlantilla:
          "SELECT nombre FROM productos WHERE nombre LIKE '{payload}'",
      mensajeExito:
          '[200 OK] ✓ TE LO HA DICHO\nLa búsqueda te ha enseñado lo que no debía.\nNadie le ha avisado de que mentías.',
    ),

    // LAB 3 · Bypass de filtro WAF
    Lab(
      numero: 3,
      titulo: 'BYPASS DE FILTRO',
      mision:
          'El filtro tapa la palabra "OR". Encuentra otra que diga lo mismo.',
      victimaUrl: 'servidor / login  [filtro WAF activo]',
      codigoLineas: [
        "\$user = filter('OR', \$_POST['user']);",
        "\$sql = \"SELECT * FROM users WHERE user='\$user' AND pass='\$p'\";",
        "\$db->query(\$sql);",
      ],
      lineaVulnerable: 0,
      avisoCodigo:
          '⚠ El filtro borra "OR" pero no protege contra otros operadores.',
      arsenal: const [
        PiezaSql(id: 'l3_q', token: "'", categoria: CategoriaPieza.escape),
        PiezaSql(
          id: 'l3_or',
          token: 'OR 1=1',
          categoria: CategoriaPieza.bypass,
        ),
        PiezaSql(
          id: 'l3_pipe',
          token: '|| 1=1',
          categoria: CategoriaPieza.bypass,
        ),
        PiezaSql(id: 'l3_c', token: '--', categoria: CategoriaPieza.silencio),
        PiezaSql(
          id: 'l3_admin',
          token: 'admin',
          categoria: CategoriaPieza.senuelo,
        ),
        PiezaSql(
          id: 'l3_drop',
          token: 'DROP',
          categoria: CategoriaPieza.trampa,
        ),
      ],
      categoriasNecesarias: const [
        CategoriaPieza.escape,
        CategoriaPieza.bypass,
        CategoriaPieza.silencio,
      ],
      queryPlantilla:
          "SELECT * FROM users WHERE user='{payload}' AND pass='****'",
      mensajeExito:
          '[200 OK] ✓ EL FILTRO NUNCA CUBRIÓ TODO\nLo que bloqueaba una palabra, lo decías con otra.\nDentro otra vez.',
    ),
  ];

  // ACCIONES DEL JUGADOR

  /// Añade una pieza al payload actual.
  void anadirPieza(PiezaSql pieza) {
    _payload.add(pieza);
  }

  /// Quita la última pieza del payload.
  void quitarUltima() {
    if (_payload.isNotEmpty) _payload.removeLast();
  }

  /// Vacía todo el payload.
  void limpiarPayload() {
    _payload.clear();
  }

  /// Texto del payload concatenado tal cual.
  String payloadTexto() => _payload.map((p) => p.token).join(' ');

  /// SQL final con el payload sustituido en la plantilla.
  String sqlGenerado() {
    final txt = payloadTexto();
    return labActual.queryPlantilla.replaceFirst('{payload}', txt);
  }

  /// Ejecuta el payload contra el servidor simulado.
  ResultadoEjecucion ejecutar() {
    if (_payload.isEmpty) {
      return ResultadoEjecucion(
        sqlGenerado: '(payload vacío)',
        respuestaServidor: '[!] El payload está vacío. Añade piezas.',
        tipo: TipoResultado.payloadVacio,
        perdioVida: false,
      );
    }

    final sql = sqlGenerado();
    final categorias = _payload.map((p) => p.categoria).toSet();

    // 1) Trampa siempre prevalece
    if (categorias.contains(CategoriaPieza.trampa)) {
      _vidas--;
      return ResultadoEjecucion(
        sqlGenerado: sql,
        respuestaServidor:
            '[!] HAS HECHO RUIDO.\n'
            '    Esa pieza no abre puertas — deja ruinas.\n'
            '    El servidor no se ríe. Tú tampoco.\n'
            '    Quítala y vuelve a probar.',
        tipo: TipoResultado.trampaEjecutada,
        perdioVida: true,
      );
    }

    // 2) Tiene todas las categorías necesarias
    final tieneTodas = labActual.categoriasNecesarias.every(
      (cat) => categorias.contains(cat),
    );

    if (tieneTodas) {
      //  guardamos el mensaje ANTES de incrementar el índice.
      //
      final mensajeDelLabGanado = labActual.mensajeExito;
      _xp += 100;
      _labActualIdx++;
      _payload.clear();
      return ResultadoEjecucion(
        sqlGenerado: sql,
        respuestaServidor: mensajeDelLabGanado,
        tipo: TipoResultado.exito,
        perdioVida: false,
      );
    }

    // 3) Payload incompleto
    _vidas--;
    final faltantes = labActual.categoriasNecesarias
        .where((cat) => !categorias.contains(cat))
        .map(_nombreCategoria)
        .join(', ');
    return ResultadoEjecucion(
      sqlGenerado: sql,
      respuestaServidor:
          '[401] Login failed: invalid credentials.\nFalta: $faltantes',
      tipo: TipoResultado.payloadIncompleto,
      perdioVida: true,
    );
  }

  String _nombreCategoria(CategoriaPieza c) {
    switch (c) {
      case CategoriaPieza.escape:
        return 'ESCAPE';
      case CategoriaPieza.bypass:
        return 'BYPASS';
      case CategoriaPieza.extraer:
        return 'EXTRAER';
      case CategoriaPieza.silencio:
        return 'SILENCIO';
      case CategoriaPieza.senuelo:
        return 'SEÑUELO';
      case CategoriaPieza.trampa:
        return 'TRAMPA';
    }
  }

  bool get gameOver => _vidas <= 0;

  /// Reinicia el estado para volver a empezar.
  void reset() {
    _vidas = 3;
    _xp = 0;
    _labActualIdx = 0;
    _payload.clear();
  }
}
