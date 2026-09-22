import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;
import 'package:cyber_ops/widgets/fractura/fractura_dialogo.dart';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';

// ── ENUMS & MODELS ────────────────────────────────────────────────────────────

enum RolNivel13 { sinElegir, defensor, atacante }

enum EstadoNodo { limpio, infectado, cuarentena, apagado, honeypot }

enum HerramientaActiva {
  ninguna,
  // Defensor
  firewall,
  antivirus,
  cuarentena,
  parche,
  honeypot,
  // Atacante
  phishing,
  gusano,
  rootkit,
  ddos,
  botmaster,
}

class Nodo {
  final int id;
  final String nombre;
  EstadoNodo estado;
  bool firewall;
  bool escaneando;
  double tiempoEscaneo;
  bool esBotmaster;
  // Campos adicionales para modo atacante
  bool oculto;
  bool escaneado;
  bool protegido;

  Nodo({
    required this.id,
    required this.nombre,
    this.estado = EstadoNodo.limpio,
    this.firewall = false,
    this.escaneando = false,
    this.tiempoEscaneo = 0,
    this.esBotmaster = false,
    this.oculto = false,
    this.escaneado = false,
    this.protegido = false,
  });
}

class Conexion {
  final int desde;
  final int hasta;
  bool bloqueada;

  Conexion({required this.desde, required this.hasta, this.bloqueada = false});
}

// ── SCREEN ────────────────────────────────────────────────────────────────────

class Nivel13Screen extends StatefulWidget {
  final bool soloEntrenamiento;

  const Nivel13Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel13Screen> createState() => _Nivel13ScreenState();
}

class _Nivel13ScreenState extends State<Nivel13Screen>
    with TickerProviderStateMixin {
  static const int _puntosNivel = 1000;
  static const int _maxInfectados = 7;
  static const int _nodosParaDdos = 7;
  static const double _intervaloAtaque = 8.0;
  static const double _tiempoScaneo = 3.0;

  // ── Estado del juego ────────────────────────────────────────────────────────

  RolNivel13 _rol = RolNivel13.sinElegir;
  bool _mostrarIntro = false;
  bool _gameOver = false;
  bool _nivelYaCompletado = false;
  bool _nivelActivo = true;
  bool _mostrandoFinal = false;

  int _dialogoActual = 0;
  int _dialogoFinalActual = 0;
  int _turno = 0;
  int _accionesTurno = 2;

  HerramientaActiva _herramienta = HerramientaActiva.ninguna;
  Map<HerramientaActiva, int> _usosHerramienta = {};
  double _timerAtaque = _intervaloAtaque;
  Timer? _tickTimer;

  static const int _usosIniciales = 3;

  late AnimationController _pulseController;
  late AnimationController _glowController;

  // ── FRACTURA ──────────────────────────────────────────────────────────────
  bool _mostrarFractura = true;
  final List<String> _dialogosFractura = [
    'Una botnet es un ejército de dispositivos infectados controlados desde la sombra.',
    'El atacante los expande en silencio, nodo a nodo, hasta tener suficiente potencia para lanzar el DDoS.',
    'El defensor analiza el tráfico, aísla dispositivos y neutraliza la amenaza antes de que sea tarde.',
    'Hoy eliges un bando. Los dos tienen el mismo objetivo: ganar antes de que el otro lo haga.',
  ];

  // ── Red de dispositivos ──────────────────────────────────────────────────────

  late List<Nodo> _nodos;
  late List<Conexion> _conexiones;
  final _rng = math.Random();

  // ── Diálogos ────────────────────────────────────────────────────────────────

  final List<String> _dialogosIntroDefensor = [
    'Alerta de seguridad. Hemos detectado actividad anómala en la red corporativa.',
    'Un actor malicioso ha desplegado una botnet. Dispositivos infectados obedecen al botmaster.',
    'Si la botnet controla demasiados nodos lanzará un ataque DDoS masivo.',
    'Tu misión: detectar los infectados, aislarlos y limpiar la red antes de que sea demasiado tarde.',
    'Tienes herramientas: Firewall, Antivirus, Cuarentena, Parche y Honeypot. Úsalas con cabeza.',
    'Tienes 2 acciones por turno. La botnet se propaga automáticamente. ¡No desperdicies tiempo!',
  ];

  final List<String> _dialogosIntroAtacante = [
    'Has infiltrado la red corporativa. Es hora de demostrar tu control.',
    'Comenzarás con un único nodo comprometido. Desde ahí debes expandir tu botnet.',
    'La defensa automática del sistema intentará neutralizarte cada turno.',
    'Si controlas 7 o más nodos, podrás lanzar el ataque DDoS y ganar.',
    'Herramientas: Phishing, Gusano, Rootkit, DDoS y Botmaster. Cada una tiene su momento.',
    'Tienes 2 acciones por turno. La defensa es implacable. ¡Actúa rápido y con estrategia!',
  ];

  final List<String> _dialogosFinalesDefensor = [
    'Red corporativa estabilizada. La botnet ha sido neutralizada.',
    'Una botnet es una red de dispositivos comprometidos controlados por un C2 (Command & Control).',
    'El botmaster envía órdenes a todos los bots simultáneamente para lanzar ataques coordinados.',
    'El DDoS (Distributed Denial of Service) satura un objetivo con tráfico desde miles de IPs.',
    'Defensa clave: segmentar la red, monitorizar tráfico anómalo y aplicar parches rápidamente.',
    'Los honeypots son señuelos que atraen a los atacantes y revelan sus técnicas sin riesgo real.',
    'Misión completada. La red está limpia.',
  ];

  final List<String> _dialogosFinalesAtacante = [
    'DDoS lanzado con éxito. La red corporativa está saturada.',
    'Has experimentado cómo opera una botnet real desde la perspectiva del atacante.',
    'El phishing es el vector de entrada más común para comprometer nodos iniciales.',
    'Los gusanos se propagan de forma autónoma aprovechando vulnerabilidades conocidas.',
    'Un rootkit oculta la presencia del malware al sistema operativo y herramientas de defensa.',
    'El Botmaster coordina todos los nodos comprometidos desde un servidor C2 centralizado.',
    'Comprender el ataque es el primer paso para construir defensas efectivas.',
  ];

  List<String> get _dialogosIntro => _rol == RolNivel13.atacante
      ? _dialogosIntroAtacante
      : _dialogosIntroDefensor;

  List<String> get _dialogosFinales => _rol == RolNivel13.atacante
      ? _dialogosFinalesAtacante
      : _dialogosFinalesDefensor;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _inicializarRed();
    _setupNivel();
  }

  @override
  void dispose() {
    _nivelActivo = false;
    _tickTimer?.cancel();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // ── Setup ────────────────────────────────────────────────────────────────────

  void _inicializarRed() {
    _nodos = [
      Nodo(id: 0, nombre: 'SRV-01'),
      Nodo(id: 1, nombre: 'PC-02'),
      Nodo(id: 2, nombre: 'PC-03'),
      Nodo(id: 3, nombre: 'DB-04'),
      Nodo(id: 4, nombre: 'WEB-05'),
      Nodo(id: 5, nombre: 'IOT-06'),
      Nodo(id: 6, nombre: 'PC-07'),
      Nodo(id: 7, nombre: 'SRV-08'),
      Nodo(id: 8, nombre: 'CCTV-09'),
      Nodo(id: 9, nombre: 'ROUTER'),
    ];

    _conexiones = [
      Conexion(desde: 9, hasta: 0),
      Conexion(desde: 9, hasta: 4),
      Conexion(desde: 9, hasta: 7),
      Conexion(desde: 0, hasta: 1),
      Conexion(desde: 0, hasta: 2),
      Conexion(desde: 0, hasta: 3),
      Conexion(desde: 4, hasta: 5),
      Conexion(desde: 4, hasta: 6),
      Conexion(desde: 7, hasta: 8),
      Conexion(desde: 1, hasta: 6),
    ];
  }

  void _inicializarDefensor() {
    _inicializarRed();
    _nodos[5].estado = EstadoNodo.infectado;
    _nodos[8].estado = EstadoNodo.infectado;
  }

  void _inicializarAtacante() {
    _inicializarRed();
    // Solo un nodo infectado inicial (el botmaster)
    _nodos[9].estado = EstadoNodo.infectado;
    _nodos[9].esBotmaster = true;
  }

  Future<void> _setupNivel() async {
    _nivelYaCompletado = widget.soloEntrenamiento;
    if (!widget.soloEntrenamiento) {
      try {
        final datos = await FirestoreService.obtenerUsuario();
        final nivelUsuario = datos['nivel'] ?? 1;
        _nivelYaCompletado = nivelUsuario > 13;
      } catch (e) {
        debugPrint('No se pudo comprobar progreso del nivel 13: $e');
      }
    }
    try {
      await MusicService().playNiveles11to15Music();
    } catch (e) {
      debugPrint('Error iniciando música del nivel 13: $e');
    }
    if (mounted) setState(() {});
  }

  Map<HerramientaActiva, int> _buildUsosIniciales(RolNivel13 rol) {
    final herramientas = rol == RolNivel13.defensor
        ? [
            HerramientaActiva.firewall,
            HerramientaActiva.antivirus,
            HerramientaActiva.cuarentena,
            HerramientaActiva.parche,
            HerramientaActiva.honeypot,
          ]
        : [
            HerramientaActiva.phishing,
            HerramientaActiva.gusano,
            HerramientaActiva.rootkit,
            HerramientaActiva.ddos,
            HerramientaActiva.botmaster,
          ];
    return {for (final h in herramientas) h: _usosIniciales};
  }

  void _elegirRol(RolNivel13 rol) {
    setState(() {
      _rol = rol;
      _mostrarIntro = true;
      _dialogoActual = 0;
      _gameOver = false;
      _mostrandoFinal = false;
      _turno = 0;
      _accionesTurno = 2;
      _timerAtaque = _intervaloAtaque;
      _herramienta = HerramientaActiva.ninguna;
      _usosHerramienta = _buildUsosIniciales(rol);
      if (rol == RolNivel13.defensor) {
        _inicializarDefensor();
      } else {
        _inicializarAtacante();
      }
    });
  }

  void _iniciarLoop() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        for (final n in _nodos) {
          if (n.escaneando) {
            n.tiempoEscaneo -= 0.1;
            if (n.tiempoEscaneo <= 0) {
              n.escaneando = false;
              n.tiempoEscaneo = 0;
            }
          }
        }

        _timerAtaque -= 0.1;
        if (_timerAtaque <= 0) {
          _timerAtaque = _intervaloAtaque;
          _turno++;
          _accionesTurno = 2;
          if (_rol == RolNivel13.defensor) {
            _propagarBotnet();
            _verificarCondicionesDefensor();
          } else {
            _tickDefensaAutomatica();
            _verificarCondicionesAtacante();
          }
        }
      });
    });
  }

  // ── Lógica defensor ──────────────────────────────────────────────────────────

  void _propagarBotnet() {
    final infectados = _nodos
        .where((n) => n.estado == EstadoNodo.infectado)
        .toList();
    if (infectados.isEmpty) return;

    final origen = infectados[_rng.nextInt(infectados.length)];
    final vecinos = _vecinos(origen.id)
        .where(
          (n) =>
              (n.estado == EstadoNodo.limpio ||
                  n.estado == EstadoNodo.honeypot) &&
              !_conexionBloqueada(origen.id, n.id),
        )
        .toList();
    if (vecinos.isEmpty) return;

    final objetivo = vecinos[_rng.nextInt(vecinos.length)];
    if (objetivo.estado == EstadoNodo.honeypot) {
      objetivo.estado = EstadoNodo.limpio;
      _mostrarSnack('${objetivo.nombre} atrapó y neutralizó la propagación.');
      return;
    }
    objetivo.estado = EstadoNodo.infectado;
  }

  void _verificarCondicionesDefensor() {
    final infectados = _nodos
        .where((n) => n.estado == EstadoNodo.infectado)
        .length;
    if (infectados >= _maxInfectados) {
      _tickTimer?.cancel();
      setState(() => _gameOver = true);
      return;
    }
    if (infectados == 0) {
      _tickTimer?.cancel();
      _completarNivel();
    }
  }

  // ── Lógica atacante ──────────────────────────────────────────────────────────

  void _tickDefensaAutomatica() {
    final infectados = _nodos
        .where((n) => n.estado == EstadoNodo.infectado && !n.oculto)
        .toList();
    if (infectados.isEmpty) return;

    // Con 40% de prob, parchea un nodo visible infectado
    if (_rng.nextDouble() < 0.4) {
      final objetivo = infectados[_rng.nextInt(infectados.length)];
      objetivo.estado = EstadoNodo.limpio;
      objetivo.oculto = false;
      objetivo.escaneado = false;
      if (objetivo.esBotmaster) objetivo.esBotmaster = false;
      _mostrarSnack(
        'Defensa: ${objetivo.nombre} fue limpiado automáticamente.',
      );
      return;
    }

    // Con 30% de prob, bloquea una conexión hacia un infectado visible
    if (_rng.nextDouble() < 0.3) {
      final candidatas = _conexiones.where((c) {
        final desde = _nodos[c.desde];
        final hasta = _nodos[c.hasta];
        return !c.bloqueada &&
            (desde.estado == EstadoNodo.infectado ||
                hasta.estado == EstadoNodo.infectado);
      }).toList();
      if (candidatas.isNotEmpty) {
        candidatas[_rng.nextInt(candidatas.length)].bloqueada = true;
        _mostrarSnack('Defensa: conexión sospechosa bloqueada.');
      }
    }
  }

  void _verificarCondicionesAtacante() {
    final infectados = _nodos
        .where((n) => n.estado == EstadoNodo.infectado)
        .length;

    // Derrota: sin infectados
    if (infectados == 0) {
      _tickTimer?.cancel();
      setState(() => _gameOver = true);
      return;
    }

    // Derrota: botnet aislada (ningún infectado tiene vecino limpio alcanzable)
    final puedeExpandir = _nodos
        .where((n) => n.estado == EstadoNodo.infectado)
        .any(
          (n) => _vecinos(n.id).any(
            (v) =>
                v.estado == EstadoNodo.limpio &&
                !_conexionBloqueada(n.id, v.id),
          ),
        );

    if (!puedeExpandir && infectados < _nodosParaDdos) {
      _tickTimer?.cancel();
      setState(() => _gameOver = true);
    }
  }

  // ── Acciones del jugador ─────────────────────────────────────────────────────

  void _usarHerramienta(Nodo nodo) {
    if (_accionesTurno <= 0) {
      _mostrarSnack('Sin acciones este turno. Espera al siguiente.');
      return;
    }
    final usos = _usosHerramienta[_herramienta] ?? 0;
    if (usos <= 0) {
      _mostrarSnack('Sin usos restantes para esta herramienta.');
      return;
    }

    switch (_herramienta) {
      // Defensor
      case HerramientaActiva.firewall:
        _aplicarFirewall(nodo);
      case HerramientaActiva.antivirus:
        _aplicarAntivirus(nodo);
      case HerramientaActiva.cuarentena:
        _aplicarCuarentena(nodo);
      case HerramientaActiva.parche:
        _aplicarParche(nodo);
      case HerramientaActiva.honeypot:
        _aplicarHoneypot(nodo);
      // Atacante
      case HerramientaActiva.phishing:
        _aplicarPhishing(nodo);
      case HerramientaActiva.gusano:
        _aplicarGusano(nodo);
      case HerramientaActiva.rootkit:
        _aplicarRootkit(nodo);
      case HerramientaActiva.ddos:
        _ejecutarDdos();
      case HerramientaActiva.botmaster:
        _moverBotmaster(nodo);
      case HerramientaActiva.ninguna:
        _mostrarSnack('Selecciona una herramienta primero.');
        return;
    }
  }

  // Herramientas defensor
  void _aplicarFirewall(Nodo nodo) {
    if (nodo.firewall) {
      _mostrarSnack('${nodo.nombre} ya tiene firewall activo.');
      return;
    }
    setState(() {
      nodo.firewall = true;
      for (final c in _conexiones) {
        if (c.desde == nodo.id || c.hasta == nodo.id) c.bloqueada = true;
      }
      _accionesTurno--;
      _usosHerramienta[_herramienta] = (_usosHerramienta[_herramienta]! - 1);
    });
    _mostrarSnack(
      'Firewall activado en ${nodo.nombre}. Conexiones bloqueadas.',
    );
  }

  void _aplicarAntivirus(Nodo nodo) {
    if (nodo.escaneando) {
      _mostrarSnack('${nodo.nombre} ya está siendo escaneado.');
      return;
    }
    setState(() {
      nodo.escaneando = true;
      nodo.tiempoEscaneo = _tiempoScaneo;
      _accionesTurno--;
      _usosHerramienta[_herramienta] = (_usosHerramienta[_herramienta]! - 1);
    });
    _mostrarSnack(
      nodo.estado == EstadoNodo.infectado
          ? '¡${nodo.nombre} está INFECTADO! Aplica cuarentena o parche.'
          : '${nodo.nombre} parece limpio.',
    );
  }

  void _aplicarCuarentena(Nodo nodo) {
    if (nodo.estado == EstadoNodo.cuarentena ||
        nodo.estado == EstadoNodo.apagado) {
      _mostrarSnack('${nodo.nombre} ya está aislado.');
      return;
    }
    setState(() {
      nodo.estado = EstadoNodo.cuarentena;
      _accionesTurno--;
      _usosHerramienta[_herramienta] = (_usosHerramienta[_herramienta]! - 1);
    });
    _mostrarSnack('${nodo.nombre} en cuarentena. No propagará más.');
    _verificarCondicionesDefensor();
  }

  void _aplicarParche(Nodo nodo) {
    if (nodo.estado == EstadoNodo.limpio) {
      _mostrarSnack('${nodo.nombre} ya está limpio.');
      return;
    }
    if (nodo.estado == EstadoNodo.cuarentena ||
        nodo.estado == EstadoNodo.infectado) {
      setState(() {
        nodo.estado = EstadoNodo.limpio;
        nodo.firewall = true;
        _accionesTurno--;
        _usosHerramienta[_herramienta] = (_usosHerramienta[_herramienta]! - 1);
      });
      _mostrarSnack('${nodo.nombre} limpiado y protegido con parche.');
      _verificarCondicionesDefensor();
    }
  }

  void _aplicarHoneypot(Nodo nodo) {
    if (nodo.estado != EstadoNodo.limpio) {
      _mostrarSnack('Solo puedes colocar honeypot en nodos limpios.');
      return;
    }
    setState(() {
      nodo.estado = EstadoNodo.honeypot;
      _accionesTurno--;
      _usosHerramienta[_herramienta] = (_usosHerramienta[_herramienta]! - 1);
    });
    _mostrarSnack(
      'Honeypot desplegado en ${nodo.nombre}. Atrae y neutraliza la infección.',
    );
  }

  // Herramientas atacante
  void _aplicarPhishing(Nodo nodo) {
    // Infecta un nodo limpio que sea vecino de al menos un infectado
    if (nodo.estado != EstadoNodo.limpio) {
      _mostrarSnack('Phishing solo afecta a nodos limpios.');
      return;
    }
    final tieneVecinoInfectado = _vecinos(nodo.id).any(
      (v) =>
          v.estado == EstadoNodo.infectado &&
          !_conexionBloqueada(v.id, nodo.id),
    );
    if (!tieneVecinoInfectado) {
      _mostrarSnack('${nodo.nombre} no es alcanzable desde un nodo infectado.');
      return;
    }
    if (nodo.protegido) {
      _mostrarSnack(
        '${nodo.nombre} tiene protección activa. Phishing bloqueado.',
      );
      return;
    }
    setState(() {
      nodo.estado = EstadoNodo.infectado;
      _accionesTurno--;
      _usosHerramienta[_herramienta] = (_usosHerramienta[_herramienta]! - 1);
    });
    _mostrarSnack('Phishing exitoso. ${nodo.nombre} comprometido.');
    _verificarCondicionesAtacante();
  }

  void _aplicarGusano(Nodo nodo) {
    // Propaga desde un nodo infectado a hasta dos vecinos limpios
    if (nodo.estado != EstadoNodo.infectado) {
      _mostrarSnack('Gusano solo puede propagarse desde nodos infectados.');
      return;
    }
    final vecinos = _vecinos(nodo.id)
        .where(
          (v) =>
              v.estado == EstadoNodo.limpio &&
              !v.protegido &&
              !_conexionBloqueada(nodo.id, v.id),
        )
        .toList();
    if (vecinos.isEmpty) {
      _mostrarSnack('No hay vecinos alcanzables desde ${nodo.nombre}.');
      return;
    }
    vecinos.shuffle(_rng);
    final infectar = vecinos.take(2).toList();
    setState(() {
      for (final v in infectar) {
        v.estado = EstadoNodo.infectado;
      }
      _accionesTurno--;
      _usosHerramienta[_herramienta] = (_usosHerramienta[_herramienta]! - 1);
    });
    _mostrarSnack(
      'Gusano propagado a ${infectar.map((v) => v.nombre).join(', ')}.',
    );
    _verificarCondicionesAtacante();
  }

  void _aplicarRootkit(Nodo nodo) {
    if (nodo.estado != EstadoNodo.infectado) {
      _mostrarSnack('Rootkit solo se instala en nodos infectados.');
      return;
    }
    if (nodo.oculto) {
      _mostrarSnack('${nodo.nombre} ya tiene rootkit activo.');
      return;
    }
    setState(() {
      nodo.oculto = true;
      _accionesTurno--;
      _usosHerramienta[_herramienta] = (_usosHerramienta[_herramienta]! - 1);
    });
    _mostrarSnack('Rootkit instalado en ${nodo.nombre}. Oculto a la defensa.');
  }

  void _ejecutarDdos() {
    final infectados = _nodos
        .where((n) => n.estado == EstadoNodo.infectado)
        .length;
    if (infectados < _nodosParaDdos) {
      _mostrarSnack(
        'Necesitas $_nodosParaDdos nodos infectados para lanzar DDoS. Tienes $infectados.',
      );
      return;
    }
    _tickTimer?.cancel();
    _completarNivel();
  }

  void _moverBotmaster(Nodo nodo) {
    if (nodo.estado != EstadoNodo.infectado) {
      _mostrarSnack('El Botmaster solo puede moverse a nodos infectados.');
      return;
    }
    if (nodo.esBotmaster) {
      _mostrarSnack('${nodo.nombre} ya es el Botmaster.');
      return;
    }
    setState(() {
      for (final n in _nodos) {
        n.esBotmaster = false;
      }
      nodo.esBotmaster = true;
      _accionesTurno--;
      _usosHerramienta[_herramienta] = (_usosHerramienta[_herramienta]! - 1);
    });
    _mostrarSnack(
      'Botmaster movido a ${nodo.nombre}. Nuevas rutas disponibles.',
    );
  }

  // ── Helpers de red ───────────────────────────────────────────────────────────

  List<Nodo> _vecinos(int id) {
    final ids = <int>{};
    for (final c in _conexiones) {
      if (c.desde == id) ids.add(c.hasta);
      if (c.hasta == id) ids.add(c.desde);
    }
    return _nodos.where((n) => ids.contains(n.id)).toList();
  }

  bool _conexionBloqueada(int a, int b) {
    return _conexiones.any(
      (c) =>
          ((c.desde == a && c.hasta == b) || (c.desde == b && c.hasta == a)) &&
          c.bloqueada,
    );
  }

  void _mostrarSnack(String msg) {
    if (!mounted || !_nivelActivo) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'monospace')),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Completar / Game Over ────────────────────────────────────────────────────

  Future<void> _completarNivel() async {
    if (_mostrandoFinal) return;
    _tickTimer?.cancel();

    if (!_nivelYaCompletado) {
      try {
        await FirestoreService.guardarPuntuacion(
          puntos: _puntosNivel,
          nivelCompletado: 13,
          soloEntrenamiento: widget.soloEntrenamiento,
        );
        await FirestoreService.guardarMision(
          nivel: 13,
          mision: 1,
          puntos: _puntosNivel,
        );
      } catch (e) {
        debugPrint('No se pudo guardar progreso del nivel 13: $e');
      }
    }
    if (!mounted) return;
    setState(() {
      _mostrandoFinal = true;
      _dialogoFinalActual = 0;
    });
  }

  Future<void> _salirDelNivel() async {
    _nivelActivo = false;
    _tickTimer?.cancel();
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _reiniciarNivel() {
    _tickTimer?.cancel();
    setState(() {
      _gameOver = false;
      _mostrandoFinal = false;
      _mostrarIntro = true;
      _dialogoActual = 0;
      _turno = 0;
      _accionesTurno = 2;
      _timerAtaque = _intervaloAtaque;
      _herramienta = HerramientaActiva.ninguna;
      _usosHerramienta = _buildUsosIniciales(_rol);
      if (_rol == RolNivel13.defensor) {
        _inicializarDefensor();
      } else {
        _inicializarAtacante();
      }
    });
  }

  // ── Diálogos ─────────────────────────────────────────────────────────────────

  void _siguienteDialogoIntro() {
    if (_dialogoActual < _dialogosIntro.length - 1) {
      setState(() => _dialogoActual++);
    } else {
      setState(() => _mostrarIntro = false);
      _iniciarLoop();
    }
  }

  Future<void> _siguienteDialogoFinal() async {
    if (_dialogoFinalActual < _dialogosFinales.length - 1) {
      setState(() => _dialogoFinalActual++);
    } else {
      await _salirDelNivel();
    }
  }

  // ── Helpers de UI ────────────────────────────────────────────────────────────

  int get _infectadosCount =>
      _nodos.where((n) => n.estado == EstadoNodo.infectado).length;

  int get _limpiosCount => _nodos
      .where(
        (n) => n.estado == EstadoNodo.limpio || n.estado == EstadoNodo.honeypot,
      )
      .length;

  Color get _rolColor => _rol == RolNivel13.atacante
      ? const Color(0xFFEF4444)
      : const Color(0xFFD4537E);

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_mostrarFractura) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        body: Container(
          color: Colors.black.withValues(alpha: 0.80),
          child: FracturaDialogo(
            dialogos: _dialogosFractura,
            subtitulo: 'NIVEL 13 // BOTNET',
            textoBotonFinal: 'JUGAR',
            usarVoz: true,
            permitirSaltarIntro: true,
            permitirCambiarVoz: true,
            velocidadVoz: 0.66,
            milisegundosPorCaracter: 18,
            onFinalizado: () async {
              setState(() {
                _mostrarFractura = false;
              });

              await _setupNivel();
            },
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _rol == RolNivel13.sinElegir
              ? _buildSelectorRol(key: const ValueKey('selector'))
              : _mostrarIntro
              ? _buildDialogoView(
                  key: const ValueKey('intro'),
                  lineas: _dialogosIntro,
                  index: _dialogoActual,
                  subtitulo: _rol == RolNivel13.atacante
                      ? 'MODO ATACANTE // BOTNET'
                      : 'MODO DEFENSOR // BOTNET',
                  onNext: _siguienteDialogoIntro,
                  esUltimo: _dialogoActual == _dialogosIntro.length - 1,
                )
              : _gameOver
              ? _buildGameOverView()
              : _mostrandoFinal
              ? _buildDialogoView(
                  key: const ValueKey('final'),
                  lineas: _dialogosFinales,
                  index: _dialogoFinalActual,
                  subtitulo: _rol == RolNivel13.atacante
                      ? 'DDoS EJECUTADO // DEBRIEFING'
                      : 'RED LIMPIA // DEBRIEFING',
                  onNext: _siguienteDialogoFinal,
                  esUltimo: _dialogoFinalActual == _dialogosFinales.length - 1,
                )
              : _buildJuegoView(),
        ),
      ),
    );
  }

  // ── Selector de rol ──────────────────────────────────────────────────────────

  Widget _buildSelectorRol({required Key key}) {
    return Center(
      key: key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Tooltip(
                  message: 'Volver al mapa',
                  child: _BotonIcono(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: _salirDelNivel,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(
                Icons.coronavirus_outlined,
                color: Color(0xFFD4537E),
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'NIVEL 13 — BOTNET',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ELIGE TU ROL PARA ESTA MISIÓN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 10,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  final useRow = constraints.maxWidth >= 480;
                  final cards = [
                    _RolCard(
                      titulo: 'DEFENSOR',
                      subtitulo: 'Analista de Seguridad',
                      descripcion:
                          'Detecta y neutraliza la botnet antes de que lance el ataque DDoS. Usa firewall, antivirus, cuarentena, parche y honeypot.',
                      icon: Icons.shield_outlined,
                      color: const Color(0xFFD4537E),
                      onTap: () => _elegirRol(RolNivel13.defensor),
                    ),
                    _RolCard(
                      titulo: 'ATACANTE',
                      subtitulo: 'Control de Botnet',
                      descripcion:
                          'Expande tu botnet desde un único nodo comprometido. Infecta 7 nodos y lanza el DDoS antes de que la defensa te aísle.',
                      icon: Icons.bug_report_outlined,
                      color: const Color(0xFFEF4444),
                      onTap: () => _elegirRol(RolNivel13.atacante),
                    ),
                  ];
                  if (useRow) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[1]),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      cards[0],
                      const SizedBox(height: 16),
                      cards[1],
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Completar cualquier modo cuenta como superar el Nivel 13',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Vistas ───────────────────────────────────────────────────────────────────

  Widget _buildDialogoView({
    required Key key,
    required List<String> lineas,
    required int index,
    required String subtitulo,
    required VoidCallback onNext,
    required bool esUltimo,
  }) {
    return Center(
      key: key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _rolColor.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: _rolColor.withValues(alpha: 0.10),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _BotonIcono(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: _salirDelNivel,
                  ),
                ),
                const SizedBox(height: 20),
                Icon(
                  _rol == RolNivel13.atacante
                      ? Icons.bug_report_outlined
                      : Icons.coronavirus_outlined,
                  color: _rolColor,
                  size: 64,
                ),
                const SizedBox(height: 20),
                Text(
                  'NIVEL 13 — BOTNET',
                  style: TextStyle(
                    color: _rolColor.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitulo,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.bgMain.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.25),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      lineas[index],
                      key: ValueKey(index),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${index + 1} / ${lineas.length}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rolColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      esUltimo ? 'CONTINUAR' : 'SIGUIENTE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverView() {
    final esAtacante = _rol == RolNivel13.atacante;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.14),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  esAtacante ? Icons.security_rounded : Icons.wifi_off_rounded,
                  color: const Color(0xFFEF4444),
                  size: 72,
                ),
                const SizedBox(height: 20),
                Text(
                  esAtacante ? 'BOTNET NEUTRALIZADA' : 'ATAQUE DDoS LANZADO',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  esAtacante
                      ? 'La defensa automática ha limpiado o aislado completamente tu botnet. Inténtalo de nuevo.'
                      : 'La botnet ha comprometido demasiados dispositivos\ny ha lanzado el ataque. La red está caída.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _reiniciarNivel,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('REINTENTAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _rol = RolNivel13.sinElegir;
                        _gameOver = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'CAMBIAR ROL',
                      style: TextStyle(letterSpacing: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _salirDelNivel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'SALIR',
                      style: TextStyle(letterSpacing: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJuegoView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final isWide = w >= 900;
        final isTablet = w >= 600 && w < 900;
        final header = _buildHeader();
        final red = _buildMapaRed();
        final panel = _buildPanelHerramientas();

        if (isWide) {
          return Column(
            children: [
              header,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 6, child: red),
                      const SizedBox(width: 16),
                      SizedBox(width: 300, child: panel),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // Tablet: mapa más alto, panel al lado en orientación landscape
        if (isTablet) {
          final mapHeight = (h * 0.50).clamp(300.0, 450.0);
          return Column(
            children: [
              header,
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: Column(
                    children: [
                      SizedBox(height: mapHeight, child: red),
                      const SizedBox(height: 12),
                      panel,
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // Móvil: mapa compacto adaptado al alto disponible
        final mapHeight = (h * 0.42).clamp(260.0, 380.0);
        return Column(
          children: [
            header,
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
                child: Column(
                  children: [
                    SizedBox(height: mapHeight, child: red),
                    const SizedBox(height: 10),
                    panel,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final progress = _timerAtaque / _intervaloAtaque;
    final esAtacante = _rol == RolNivel13.atacante;

    final timerBox = _StatBox(
      label: esAtacante ? 'PRÓX. DEFENSA' : 'PRÓXIMO ATAQUE',
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            Text(
              '${_timerAtaque.toStringAsFixed(1)}s',
              style: TextStyle(
                color: esAtacante
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress < 0.35 ? const Color(0xFFEF4444) : _rolColor,
                ),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );

    final infectadosBox = _StatBox(
      label: esAtacante ? 'CONTROLADOS' : 'INFECTADOS',
      child: Text(
        esAtacante
            ? '$_infectadosCount/$_nodosParaDdos'
            : '$_infectadosCount/$_maxInfectados',
        style: TextStyle(
          color: esAtacante
              ? (_infectadosCount >= _nodosParaDdos
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444))
              : (_infectadosCount >= _maxInfectados - 2
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFD4537E)),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final accionesBox = _StatBox(
      label: 'ACCIONES',
      child: Text(
        '$_accionesTurno',
        style: TextStyle(
          color: _accionesTurno > 0
              ? AppColors.cyan
              : Colors.white.withValues(alpha: 0.3),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final turnoBox = _StatBox(
      label: 'TURNO',
      child: Text(
        '$_turno',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 560;

        final titleSection = Row(
          children: [
            _BotonIcono(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: _salirDelNivel,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    narrow ? 'N13 — BOTNET' : 'NIVEL 13 — BOTNET',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    widget.soloEntrenamiento
                        ? 'ENTRENAMIENTO // ${esAtacante ? "ATACANTE" : "DEFENSOR"}'
                        : esAtacante
                        ? 'CONTROL DE BOTNET'
                        : 'DEFENSA DE RED',
                    style: TextStyle(
                      color: _rolColor.withValues(alpha: 0.75),
                      fontSize: 9,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (!narrow) ...[
              timerBox,
              const SizedBox(width: 8),
              infectadosBox,
              const SizedBox(width: 8),
              accionesBox,
              const SizedBox(width: 8),
              turnoBox,
              if (_nivelYaCompletado) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'ENTREN.',
                    style: TextStyle(
                      color: AppColors.purple.withValues(alpha: 0.85),
                      fontSize: 8,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ],
        );

        if (narrow) {
          return Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Column(
              children: [
                titleSection,
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: timerBox),
                    const SizedBox(width: 6),
                    Expanded(child: infectadosBox),
                    const SizedBox(width: 6),
                    Expanded(child: accionesBox),
                    const SizedBox(width: 6),
                    Expanded(child: turnoBox),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: titleSection,
        );
      },
    );
  }

  // ── Mapa de red ──────────────────────────────────────────────────────────────

  static const List<Offset> _posicionesNodos = [
    Offset(0.50, 0.12), // 0 SRV-01
    Offset(0.25, 0.30), // 1 PC-02
    Offset(0.50, 0.30), // 2 PC-03
    Offset(0.75, 0.30), // 3 DB-04
    Offset(0.50, 0.55), // 4 WEB-05
    Offset(0.20, 0.72), // 5 IOT-06
    Offset(0.38, 0.75), // 6 PC-07
    Offset(0.75, 0.55), // 7 SRV-08
    Offset(0.90, 0.75), // 8 CCTV-09
    Offset(0.50, 0.90), // 9 ROUTER
  ];

  Widget _buildMapaRed() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _rolColor.withValues(alpha: 0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              children: [
                CustomPaint(size: Size(w, h), painter: _GridPainter()),
                CustomPaint(
                  size: Size(w, h),
                  painter: _ConexionesPainter(
                    conexiones: _conexiones,
                    nodos: _nodos,
                    posiciones: _posicionesNodos,
                    w: w,
                    h: h,
                  ),
                ),
                for (int i = 0; i < _nodos.length; i++)
                  _buildNodoWidget(_nodos[i], w, h),
                Positioned(bottom: 12, left: 12, child: _buildLeyenda()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNodoWidget(Nodo nodo, double w, double h) {
    final pos = _posicionesNodos[nodo.id];
    final cx = pos.dx * w;
    final cy = pos.dy * h;
    final r = (math.min(w, h) * 0.075).clamp(22.0, 34.0);

    final color = _colorNodo(nodo);
    final isSeleccionable =
        _herramienta != HerramientaActiva.ninguna &&
        _herramienta != HerramientaActiva.ddos;

    return Positioned(
      left: cx - r,
      top: cy - r,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseScale = nodo.estado == EstadoNodo.infectado
              ? 1.0 + _pulseController.value * 0.08
              : 1.0;
          return Transform.scale(scale: pulseScale, child: child);
        },
        child: GestureDetector(
          onTap: isSeleccionable ? () => _usarHerramienta(nodo) : null,
          child: Container(
            width: r * 2,
            height: r * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: nodo.oculto ? 0.08 : 0.18),
              border: Border.all(
                color: nodo.oculto ? color.withValues(alpha: 0.4) : color,
                width: isSeleccionable ? 2.5 : 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: nodo.estado == EstadoNodo.infectado ? 16 : 8,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_iconNodo(nodo), color: color, size: r * 0.44),
                SizedBox(height: r * 0.03),
                Text(
                  nodo.nombre,
                  style: TextStyle(
                    color: color,
                    fontSize: r * 0.22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                if (nodo.escaneando)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SizedBox(
                      width: r * 0.85,
                      child: LinearProgressIndicator(
                        value: 1 - (nodo.tiempoEscaneo / _tiempoScaneo),
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.cyan,
                        ),
                        minHeight: 3,
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (nodo.firewall)
                      Icon(
                        Icons.shield_rounded,
                        color: AppColors.cyan,
                        size: r * 0.28,
                      ),
                    if (nodo.oculto)
                      Icon(
                        Icons.visibility_off_rounded,
                        color: const Color(0xFFF59E0B),
                        size: r * 0.28,
                      ),
                    if (nodo.esBotmaster)
                      Icon(
                        Icons.hub_rounded,
                        color: const Color(0xFFEF4444),
                        size: r * 0.28,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _colorNodo(Nodo nodo) {
    switch (nodo.estado) {
      case EstadoNodo.limpio:
        return const Color(0xFF22C55E);
      case EstadoNodo.infectado:
        return const Color(0xFFEF4444);
      case EstadoNodo.cuarentena:
        return const Color(0xFFF59E0B);
      case EstadoNodo.apagado:
        return Colors.white.withValues(alpha: 0.3);
      case EstadoNodo.honeypot:
        return AppColors.purple;
    }
  }

  IconData _iconNodo(Nodo nodo) {
    switch (nodo.estado) {
      case EstadoNodo.limpio:
        return Icons.computer_rounded;
      case EstadoNodo.infectado:
        return Icons.bug_report_rounded;
      case EstadoNodo.cuarentena:
        return Icons.lock_rounded;
      case EstadoNodo.apagado:
        return Icons.power_off_rounded;
      case EstadoNodo.honeypot:
        return Icons.emoji_nature_rounded;
    }
  }

  Widget _buildLeyenda() {
    final esAtacante = _rol == RolNivel13.atacante;
    final items = esAtacante
        ? [
            (const Color(0xFF22C55E), 'Limpio'),
            (const Color(0xFFEF4444), 'Controlado'),
            (AppColors.cyan, 'Con Firewall'),
          ]
        : [
            (const Color(0xFF22C55E), 'Limpio'),
            (const Color(0xFFEF4444), 'Infectado'),
            (const Color(0xFFF59E0B), 'Cuarentena'),
            (AppColors.purple, 'Honeypot'),
          ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgMain.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        children: [
          for (final item in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.$1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item.$2,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Panel de herramientas ────────────────────────────────────────────────────

  Widget _buildPanelHerramientas() {
    return _rol == RolNivel13.atacante
        ? _buildPanelAtacante()
        : _buildPanelDefensor();
  }

  Widget _buildPanelDefensor() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelCard(
            titulo: 'HERRAMIENTAS — DEFENSOR',
            color: const Color(0xFFD4537E),
            child: Column(
              children: [
                _ToolButton(
                  icon: Icons.shield_outlined,
                  label: 'Firewall',
                  descripcion: 'Bloquea conexiones del nodo',
                  activa: _herramienta == HerramientaActiva.firewall,
                  color: AppColors.cyan,
                  usos: _usosHerramienta[HerramientaActiva.firewall] ?? 0,
                  onTap: () => setState(() {
                    _herramienta = _herramienta == HerramientaActiva.firewall
                        ? HerramientaActiva.ninguna
                        : HerramientaActiva.firewall;
                  }),
                ),
                _ToolButton(
                  icon: Icons.search_rounded,
                  label: 'Antivirus Scan',
                  descripcion: 'Detecta si el nodo está infectado',
                  activa: _herramienta == HerramientaActiva.antivirus,
                  color: const Color(0xFF22C55E),
                  usos: _usosHerramienta[HerramientaActiva.antivirus] ?? 0,
                  onTap: () => setState(() {
                    _herramienta = _herramienta == HerramientaActiva.antivirus
                        ? HerramientaActiva.ninguna
                        : HerramientaActiva.antivirus;
                  }),
                ),
                _ToolButton(
                  icon: Icons.lock_rounded,
                  label: 'Cuarentena',
                  descripcion: 'Aísla el nodo para detener propagación',
                  activa: _herramienta == HerramientaActiva.cuarentena,
                  color: const Color(0xFFF59E0B),
                  usos: _usosHerramienta[HerramientaActiva.cuarentena] ?? 0,
                  onTap: () => setState(() {
                    _herramienta = _herramienta == HerramientaActiva.cuarentena
                        ? HerramientaActiva.ninguna
                        : HerramientaActiva.cuarentena;
                  }),
                ),
                _ToolButton(
                  icon: Icons.healing_rounded,
                  label: 'Parche',
                  descripcion: 'Limpia y protege el nodo',
                  activa: _herramienta == HerramientaActiva.parche,
                  color: AppColors.purple,
                  usos: _usosHerramienta[HerramientaActiva.parche] ?? 0,
                  onTap: () => setState(() {
                    _herramienta = _herramienta == HerramientaActiva.parche
                        ? HerramientaActiva.ninguna
                        : HerramientaActiva.parche;
                  }),
                ),
                _ToolButton(
                  icon: Icons.emoji_nature_rounded,
                  label: 'Honeypot',
                  descripcion: 'Trampa que neutraliza infección',
                  activa: _herramienta == HerramientaActiva.honeypot,
                  color: const Color(0xFFD4537E),
                  usos: _usosHerramienta[HerramientaActiva.honeypot] ?? 0,
                  onTap: () => setState(() {
                    _herramienta = _herramienta == HerramientaActiva.honeypot
                        ? HerramientaActiva.ninguna
                        : HerramientaActiva.honeypot;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PanelCard(
            titulo: 'ESTADO RED',
            color: AppColors.cyan,
            child: Column(
              children: [
                _EstadoRow(
                  label: 'Limpios',
                  value: '$_limpiosCount',
                  color: const Color(0xFF22C55E),
                ),
                _EstadoRow(
                  label: 'Infectados',
                  value: '$_infectadosCount',
                  color: const Color(0xFFEF4444),
                ),
                _EstadoRow(
                  label: 'Cuarentena',
                  value:
                      '${_nodos.where((n) => n.estado == EstadoNodo.cuarentena).length}',
                  color: const Color(0xFFF59E0B),
                ),
                _EstadoRow(
                  label: 'Honeypots',
                  value:
                      '${_nodos.where((n) => n.estado == EstadoNodo.honeypot).length}',
                  color: AppColors.purple,
                ),
                _EstadoRow(
                  label: 'Con Firewall',
                  value: '${_nodos.where((n) => n.firewall).length}',
                  color: AppColors.cyan,
                ),
                const Divider(color: Colors.white12, height: 20),
                _EstadoRow(
                  label: 'Límite DDoS',
                  value: '$_maxInfectados nodos',
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PanelCard(
            titulo: 'INSTRUCCIONES',
            color: AppColors.purple,
            child: Text(
              '1. Selecciona una herramienta\n'
              '2. Toca un nodo para aplicarla\n'
              '3. Tienes $_accionesTurno acciones por turno\n'
              '4. La botnet ataca cada ${_intervaloAtaque.toInt()}s\n'
              '5. Limpia todos los infectados para ganar',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelAtacante() {
    final nodosControlados = _infectadosCount;
    final ddosListo = nodosControlados >= _nodosParaDdos;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelCard(
            titulo: 'HERRAMIENTAS — ATACANTE',
            color: const Color(0xFFEF4444),
            child: Column(
              children: [
                _ToolButton(
                  icon: Icons.mail_outline_rounded,
                  label: 'Phishing',
                  descripcion: 'Infecta nodo limpio vecino de infectado',
                  activa: _herramienta == HerramientaActiva.phishing,
                  color: const Color(0xFFEF4444),
                  usos: _usosHerramienta[HerramientaActiva.phishing] ?? 0,
                  onTap: () => setState(() {
                    _herramienta = _herramienta == HerramientaActiva.phishing
                        ? HerramientaActiva.ninguna
                        : HerramientaActiva.phishing;
                  }),
                ),
                _ToolButton(
                  icon: Icons.alt_route_rounded,
                  label: 'Gusano',
                  descripcion: 'Propaga a hasta 2 vecinos desde infectado',
                  activa: _herramienta == HerramientaActiva.gusano,
                  color: const Color(0xFFD4537E),
                  usos: _usosHerramienta[HerramientaActiva.gusano] ?? 0,
                  onTap: () => setState(() {
                    _herramienta = _herramienta == HerramientaActiva.gusano
                        ? HerramientaActiva.ninguna
                        : HerramientaActiva.gusano;
                  }),
                ),
                _ToolButton(
                  icon: Icons.visibility_off_rounded,
                  label: 'Rootkit',
                  descripcion: 'Oculta infectado a la defensa automática',
                  activa: _herramienta == HerramientaActiva.rootkit,
                  color: const Color(0xFFF59E0B),
                  usos: _usosHerramienta[HerramientaActiva.rootkit] ?? 0,
                  onTap: () => setState(() {
                    _herramienta = _herramienta == HerramientaActiva.rootkit
                        ? HerramientaActiva.ninguna
                        : HerramientaActiva.rootkit;
                  }),
                ),
                _ToolButton(
                  icon: Icons.hub_rounded,
                  label: 'Botmaster',
                  descripcion: 'Mueve el C2 a otro nodo infectado',
                  activa: _herramienta == HerramientaActiva.botmaster,
                  color: AppColors.purple,
                  usos: _usosHerramienta[HerramientaActiva.botmaster] ?? 0,
                  onTap: () => setState(() {
                    _herramienta = _herramienta == HerramientaActiva.botmaster
                        ? HerramientaActiva.ninguna
                        : HerramientaActiva.botmaster;
                  }),
                ),
                _ToolButton(
                  icon: Icons.wifi_off_rounded,
                  label: 'Lanzar DDoS',
                  descripcion: ddosListo
                      ? '¡Listo! Ejecuta el ataque masivo'
                      : 'Necesitas $_nodosParaDdos nodos ($nodosControlados/$_nodosParaDdos)',
                  activa: _herramienta == HerramientaActiva.ddos,
                  color: ddosListo
                      ? const Color(0xFF22C55E)
                      : Colors.white.withValues(alpha: 0.3),
                  usos: _usosHerramienta[HerramientaActiva.ddos] ?? 0,
                  onTap: () {
                    if (ddosListo) {
                      _ejecutarDdos();
                    } else {
                      _mostrarSnack(
                        'Necesitas $_nodosParaDdos nodos controlados para lanzar el DDoS.',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PanelCard(
            titulo: 'ESTADO BOTNET',
            color: const Color(0xFFEF4444),
            child: Column(
              children: [
                _EstadoRow(
                  label: 'Controlados',
                  value: '$nodosControlados',
                  color: const Color(0xFFEF4444),
                ),
                _EstadoRow(
                  label: 'Ocultos (Rootkit)',
                  value: '${_nodos.where((n) => n.oculto).length}',
                  color: const Color(0xFFF59E0B),
                ),
                _EstadoRow(
                  label: 'Limpios (Defensa)',
                  value: '$_limpiosCount',
                  color: const Color(0xFF22C55E),
                ),
                _EstadoRow(
                  label: 'Conexiones bloqueadas',
                  value: '${_conexiones.where((c) => c.bloqueada).length}',
                  color: AppColors.cyan,
                ),
                const Divider(color: Colors.white12, height: 20),
                _EstadoRow(
                  label: 'Objetivo DDoS',
                  value: '$_nodosParaDdos nodos',
                  color: ddosListo
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PanelCard(
            titulo: 'INSTRUCCIONES',
            color: AppColors.purple,
            child: Text(
              '1. Selecciona una herramienta\n'
              '2. Toca un nodo para aplicarla\n'
              '3. Tienes $_accionesTurno acciones por turno\n'
              '4. La defensa actúa cada ${_intervaloAtaque.toInt()}s\n'
              '5. Controla $_nodosParaDdos nodos y lanza DDoS',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── PAINTERS ──────────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

class _ConexionesPainter extends CustomPainter {
  final List<Conexion> conexiones;
  final List<Nodo> nodos;
  final List<Offset> posiciones;
  final double w;
  final double h;

  const _ConexionesPainter({
    required this.conexiones,
    required this.nodos,
    required this.posiciones,
    required this.w,
    required this.h,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in conexiones) {
      final p1 = Offset(posiciones[c.desde].dx * w, posiciones[c.desde].dy * h);
      final p2 = Offset(posiciones[c.hasta].dx * w, posiciones[c.hasta].dy * h);

      final color = c.bloqueada
          ? AppColors.cyan.withValues(alpha: 0.6)
          : _colorConexion(nodos[c.desde], nodos[c.hasta]);

      final paint = Paint()
        ..color = color
        ..strokeWidth = c.bloqueada ? 2.5 : 1.5
        ..style = PaintingStyle.stroke;

      if (c.bloqueada) {
        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy);
        canvas.drawPath(_dashPath(path, dashLength: 8, gapLength: 5), paint);
      } else {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  Color _colorConexion(Nodo a, Nodo b) {
    if (a.estado == EstadoNodo.infectado || b.estado == EstadoNodo.infectado) {
      return const Color(0xFFEF4444).withValues(alpha: 0.5);
    }
    return Colors.white.withValues(alpha: 0.15);
  }

  Path _dashPath(
    Path source, {
    required double dashLength,
    required double gapLength,
  }) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashLength : gapLength;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(_ConexionesPainter old) => true;
}

// ── WIDGETS AUXILIARES ────────────────────────────────────────────────────────

class _RolCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String descripcion;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RolCard({
    required this.titulo,
    required this.subtitulo,
    required this.descripcion,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 20),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              descripcion,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'JUGAR COMO $titulo',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonIcono extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BotonIcono({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.bgMain,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: AppColors.cyan, size: 16),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final Widget child;

  const _StatBox({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String titulo;
  final Color color;
  final Widget child;

  const _PanelCard({
    required this.titulo,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String descripcion;
  final bool activa;
  final Color color;
  final VoidCallback onTap;
  final int usos;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.descripcion,
    required this.activa,
    required this.color,
    required this.onTap,
    required this.usos,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: activa
              ? color.withValues(alpha: 0.18)
              : AppColors.bgMain.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: activa ? color : Colors.white.withValues(alpha: 0.1),
            width: activa ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: activa ? color : Colors.white.withValues(alpha: 0.5),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: activa
                          ? color
                          : Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    descripcion,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (usos > 0
                                ? color
                                : Colors.white.withValues(alpha: 0.15))
                            .withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$usos',
                    style: TextStyle(
                      color: usos > 0
                          ? color
                          : Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (activa)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'ACTIVA',
                        style: TextStyle(
                          color: color,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _EstadoRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
