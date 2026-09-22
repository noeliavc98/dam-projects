import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_colors.dart';
import '../services/music_service.dart';
import 'package:cyber_ops/config/app_routes.dart';
import 'nivel01_screen.dart';
import 'nivel02_screen.dart';
import 'nivel03_screen.dart';
import 'nivel04_screen.dart';
import 'nivel05_screen.dart';
import 'nivel06_screen.dart';
import 'nivel07_screen.dart';
import 'nivel08_screen.dart';
import 'nivel09_screen.dart';
import 'nivel10_screen.dart';
import 'nivel11_screen.dart';
import 'nivel12_screen.dart';
import 'nivel13_screen.dart';
import 'nivel14_screen.dart';
import 'nivel15_screen.dart';
import 'nivel16_screen.dart';
import 'nivel17_screen.dart';
import 'nivel18_screen.dart';
import 'nivel19_screen.dart';
import 'nivel20_screen.dart';
import 'nivel21_screen.dart';
import 'nivel22_screen.dart';
import 'nivel23_screen.dart';
import 'nivel24_screen.dart';
import 'nivel25_screen.dart';

// ── GRUPOS TEMÁTICOS ──────────────────────────────────────────────────────────
class _GrupoTematico {
  final String nombre;
  final String descripcion;
  final Color color;
  final IconData icono;
  final int nivelInicio;
  final int nivelFin;

  const _GrupoTematico({
    required this.nombre,
    required this.descripcion,
    required this.color,
    required this.icono,
    required this.nivelInicio,
    required this.nivelFin,
  });
}

const List<_GrupoTematico> _grupos = [
  _GrupoTematico(
    nombre: 'RECONOCIMIENTO',
    descripcion: 'Fundamentos de ciberseguridad',
    color: Color(0xFF1D9E75),
    icono: Icons.search_rounded,
    nivelInicio: 1,
    nivelFin: 5,
  ),
  _GrupoTematico(
    nombre: 'INTRUSIÓN',
    descripcion: 'Phishing · Fuerza bruta · Inyecciones',
    color: Color(0xFF378ADD),
    icono: Icons.lock_open_rounded,
    nivelInicio: 6,
    nivelFin: 10,
  ),
  _GrupoTematico(
    nombre: 'MALWARE',
    descripcion: 'Ransomware · Keylogger · Botnet',
    color: Color(0xFFD4537E),
    icono: Icons.coronavirus_outlined,
    nivelInicio: 11,
    nivelFin: 15,
  ),
  _GrupoTematico(
    nombre: 'DEFENSA',
    descripcion: 'Firewall · VPN · Cifrado · Zero Day',
    color: Color(0xFFBA7517),
    icono: Icons.shield_rounded,
    nivelInicio: 16,
    nivelFin: 20,
  ),
  _GrupoTematico(
    nombre: 'ÉLITE',
    descripcion: 'Exploit · APT · Privilege escalation',
    color: Color(0xFF7F77DD),
    icono: Icons.whatshot_rounded,
    nivelInicio: 21,
    nivelFin: 25,
  ),
];

_GrupoTematico _grupoDeNivel(int nivel) {
  return _grupos.firstWhere(
    (g) => nivel >= g.nivelInicio && nivel <= g.nivelFin,
    orElse: () => _grupos.last,
  );
}

// ── SCREEN ────────────────────────────────────────────────────────────────────

class LevelMapScreen extends StatefulWidget {
  final int? nivelInicial;
  const LevelMapScreen({super.key, this.nivelInicial});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen>
    with TickerProviderStateMixin, RouteAware {
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  int _nivelActual = 1;
  bool _cargando = true;
  bool _routeObserverSubscribed = false;
  bool _nivelInicialConsumido = false;
  static const int _totalNiveles = 25;

  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();
  final ScrollController _scrollController = ScrollController();
  bool _scrollInicialHecho = false;

  static const List<String> _missionNames = [
    // Grupo 1: Reconocimiento (1-5) — preguntas generales de ciberseguridad
    'CONCEPTOS BASE',
    'CONCEPTOS BASE',
    'CONCEPTOS BASE',
    'CONCEPTOS BASE',
    'CONCEPTOS BASE',
    // Grupo 2: Intrusión (6-10)
    'CLAVE VULNERABLE',
    'FUERZA BRUTA',
    'SQL INJECTION',
    'XSS ATTACK',
    'PHISHING',
    // Grupo 3: Malware (11-15)
    'RANSOMWARE',
    'SOMBRA DIGITAL',
    'BOTNET',
    'BACKDOOR',
    'ROOTKIT',
    // Grupo 4: Defensa (16-20)
    'FIREWALL',
    'VPN TUNNEL',
    'CIFRADO',
    'IDS/IPS',
    'ZERO DAY',
    // Grupo 5: Élite (21-25)
    'EXPLOIT',
    'SPOOFING',
    'DDoS',
    'PRIVILEGE ESC',
    'HORA CERO',
  ];

  @override
  void initState() {
    super.initState();

    // Solo actuar si hay música de nivel sonando (no la del menú)
    final music = MusicService();
    if (music.currentMusic != 'menu') {
      music.stopMusic().then((_) {
        if (mounted) music.playMenuMusic();
      });
    }

    _particleController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 50),
          )
          ..addListener(_updateParticles)
          ..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _cargarNivelUsuario();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeObserverSubscribed) return;

    final route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.subscribe(this, route);
      _routeObserverSubscribed = true;
    }
  }

  @override
  void didPopNext() {
    if (_navegandoANivel) {
      return;
    }
    _reanudarMapaSiEsVisible();
  }

  @override
  void didPush() {
  }

  void _initParticles(Size size) {
    if (_particles.isNotEmpty) return;
    for (int i = 0; i < 60; i++) {
      _particles.add(_Particle.random(_random, size));
    }
  }

  void _updateParticles() {
    if (_particles.isEmpty) return;
    for (final p in _particles) {
      p.update();
    }
    if (mounted) setState(() {});
  }

  Future<void> _cargarNivelUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _cargando = false);
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        _nivelActual = doc.data()?['nivel'] ?? 1;
        _cargando = false;
      });

      if (!_scrollInicialHecho) {
        _scrollInicialHecho = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }

      if (widget.nivelInicial != null && !_nivelInicialConsumido) {
        _nivelInicialConsumido = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _onNivelTap(widget.nivelInicial!);
        });
      }
    } else {
      setState(() => _cargando = false);
    }
  }

  Future<void> _reanudarMapaSiEsVisible({bool recargarNivel = true}) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    try {
      await MusicService().playMenuMusic();
    } catch (e) {
      debugPrint('No se pudo reanudar la musica del menu: $e');
    }

    if (mounted && recargarNivel) _cargarNivelUsuario();
  }

  @override
  void dispose() {
    if (_routeObserverSubscribed) {
      appRouteObserver.unsubscribe(this);
    }
    _particleController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          _initParticles(size);

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _ParticlePainter(_particles)),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildBarraProgreso(),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _cargando
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.cyan,
                              ),
                            )
                          : _buildMapaConGrupos(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Tooltip(
            message: 'Volver al menú',
            child: GestureDetector(
              onTap: _volverAlMenu,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.cyan,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.cyan, AppColors.blue, AppColors.purple],
                ).createShader(bounds),
                child: const Text(
                  'MAPA DE MISIONES',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              ),
              Text(
                'CYBER OPS  //  OPERACIÓN CLASIFICADA',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.purple.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.3),
                      AppColors.cyan.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 
                      _glowAnimation.value * 0.6,
                    ),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 
                        _glowAnimation.value * 0.3,
                      ),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'AGENTE',
                      style: TextStyle(
                        color: AppColors.cyan.withValues(alpha: 0.7),
                        fontSize: 8,
                        letterSpacing: 3,
                      ),
                    ),
                    Text(
                      'NV.$_nivelActual',
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'DE $_totalNiveles',
                      style: TextStyle(
                        color: AppColors.purple.withValues(alpha: 0.8),
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── BARRA PROGRESO ────────────────────────────────────────────────────────
  Widget _buildBarraProgreso() {
    final double progreso = (_nivelActual - 1) / _totalNiveles;
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PROGRESO DE INFILTRACIÓN',
                  style: TextStyle(
                    color: AppColors.cyan.withValues(alpha: 0.7),
                    fontSize: 9,
                    letterSpacing: 2,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.cyan, AppColors.purple],
                  ).createShader(bounds),
                  child: Text(
                    '${(progreso * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: AppColors.bgCard,
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: FractionallySizedBox(
                  widthFactor: progreso,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.purple,
                          AppColors.blue,
                          AppColors.cyan,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withValues(alpha: 
                            _glowAnimation.value * 0.8,
                          ),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                final int marca = i * 5;
                final bool alcanzado = (_nivelActual - 1) >= marca;
                return Text(
                  marca == 0 ? 'START' : 'L$marca',
                  style: TextStyle(
                    color: alcanzado
                        ? AppColors.cyan.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.2),
                    fontSize: 8,
                    fontWeight: alcanzado ? FontWeight.bold : FontWeight.normal,
                    letterSpacing: 1,
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  // ── MAPA CON GRUPOS ───────────────────────────────────────────────────────
  Widget _buildMapaConGrupos() {
    final gruposOrdenados = _grupos.reversed.toList();

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          for (final grupo in gruposOrdenados) ...[
            _buildSeparadorGrupo(grupo),
            const SizedBox(height: 10),
            _buildFilaGrupo(grupo),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── SEPARADOR DE GRUPO ────────────────────────────────────────────────────
  Widget _buildSeparadorGrupo(_GrupoTematico grupo) {
    final bool grupoAlcanzado = _nivelActual > grupo.nivelInicio;
    final bool grupoCompletado = _nivelActual > grupo.nivelFin;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: grupo.color.withValues(alpha: grupoAlcanzado ? 0.1 : 0.04),
            border: Border.all(
              color: grupo.color.withValues(alpha: 
                grupoAlcanzado ? _glowAnimation.value * 0.5 : 0.15,
              ),
              width: grupoAlcanzado ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: grupo.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(grupo.icono, color: grupo.color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grupo.nombre,
                      style: TextStyle(
                        color: grupoAlcanzado
                            ? grupo.color
                            : grupo.color.withValues(alpha: 0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    Text(
                      grupo.descripcion,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 
                          grupoAlcanzado ? 0.45 : 0.2,
                        ),
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (grupoCompletado)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: grupo.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: grupo.color.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: grupo.color,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'COMPLETADO',
                        style: TextStyle(
                          color: grupo.color,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'NV.${grupo.nivelInicio}–${grupo.nivelFin}',
                  style: TextStyle(
                    color: grupo.color.withValues(alpha: grupoAlcanzado ? 0.7 : 0.25),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── FILA DE HEXÁGONOS CON LÍNEA CONECTORA ────────────────────────────────
  Widget _buildFilaGrupo(_GrupoTematico grupo) {
    final niveles = List.generate(5, (i) => grupo.nivelInicio + i);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double ancho = constraints.maxWidth;
        const double hexW = 60.0;
        const double hexH = 68.0;

        return SizedBox(
          height: hexH + 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Línea conectora
              Positioned(
                top: hexH / 2 + 10,
                left: hexW / 2,
                right: hexW / 2,
                child: SizedBox(
                  height: 2, // altura mínima para que el painter tenga canvas
                  child: CustomPaint(
                    painter: _LineaConectoraPainter(
                      color: grupo.color,
                      niveles: niveles,
                      nivelActual: _nivelActual,
                      anchoTotal: ancho - hexW,
                      numNiveles: 5,
                    ),
                  ),
                ),
              ),
              // Hexágonos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: niveles
                    .map((nivel) => _buildHexagono(nivel, grupo.color))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── HEXÁGONO INDIVIDUAL ───────────────────────────────────────────────────
  Widget _buildHexagono(int nivel, Color colorGrupo) {
    final bool completado = nivel < _nivelActual;
    final bool actual = nivel == _nivelActual;
    final bool bloqueado = nivel > _nivelActual;
    final String nombre = _missionNames[nivel - 1];

    return GestureDetector(
      onTap: (actual || completado) ? () => _onNivelTap(nivel) : null,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: actual ? _pulseAnimation.value : 1.0,
            child: child,
          );
        },
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return SizedBox(
              width: 60,
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (actual)
                    CustomPaint(
                      size: const Size(60, 68),
                      painter: _HexPainter(
                        color: colorGrupo.withValues(alpha: 
                          _glowAnimation.value * 0.35,
                        ),
                        filled: true,
                        scale: 1.18,
                      ),
                    ),
                  CustomPaint(
                    size: const Size(60, 68),
                    painter: _HexPainter(
                      color: _colorHex(
                        completado,
                        actual,
                        bloqueado,
                        colorGrupo,
                      ),
                      borderColor: _borderHex(
                        completado,
                        actual,
                        bloqueado,
                        colorGrupo,
                      ),
                      filled: true,
                      borderWidth: actual ? 2.5 : (completado ? 1.5 : 1.0),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildIconoHex(
                        completado,
                        actual,
                        bloqueado,
                        nivel,
                        colorGrupo,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bloqueado ? '?' : '$nivel',
                        style: TextStyle(
                          color: _colorTextoHex(
                            completado,
                            actual,
                            bloqueado,
                            colorGrupo,
                          ),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (!bloqueado)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            nombre,
                            style: TextStyle(
                              color: _colorTextoHex(
                                completado,
                                actual,
                                bloqueado,
                                colorGrupo,
                              ).withValues(alpha: 0.65),
                              fontSize: 4.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  if (actual)
                    Positioned(
                      top: 3,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: colorGrupo,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: colorGrupo.withValues(alpha: 
                                _glowAnimation.value,
                              ),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Text(
                          'ON',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 6,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  if (completado)
                    Positioned(
                      top: 3,
                      right: 5,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: colorGrupo,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorGrupo.withValues(alpha: 0.5),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 8,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIconoHex(
    bool completado,
    bool actual,
    bool bloqueado,
    int nivel,
    Color colorGrupo,
  ) {
    if (bloqueado) {
      return Text(
        '☠',
        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.1)),
      );
    }
    if (completado) {
      return Icon(
        _iconsPorNivel(nivel),
        color: colorGrupo.withValues(alpha: 0.8),
        size: 14,
      );
    }
    return Icon(_iconsPorNivel(nivel), color: colorGrupo, size: 16);
  }

  IconData _iconsPorNivel(int nivel) {
    const icons = [
      Icons.search,
      Icons.search,
      Icons.search,
      Icons.search,
      Icons.search,
      Icons.email_outlined,
      Icons.lock_open_rounded,
      Icons.storage_rounded,
      Icons.code_rounded,
      Icons.swap_horiz_rounded,
      Icons.coronavirus_outlined,
      Icons.keyboard_rounded,
      Icons.device_hub_rounded,
      Icons.door_back_door,
      Icons.admin_panel_settings,
      Icons.shield_rounded,
      Icons.vpn_lock_rounded,
      Icons.enhanced_encryption,
      Icons.security_update_warning,
      Icons.warning_amber_rounded,
      Icons.bug_report_rounded,
      Icons.wifi_tethering,
      Icons.cloud_off_rounded,
      Icons.security_update_warning,
      Icons.whatshot_rounded,
    ];
    return icons[(nivel - 1).clamp(0, icons.length - 1)];
  }

  Color _colorHex(bool completado, bool actual, bool bloqueado, Color c) {
    if (completado) return c.withValues(alpha: 0.18);
    if (actual) return c.withValues(alpha: 0.12);
    return AppColors.bgCard.withValues(alpha: 0.4);
  }

  Color _borderHex(bool completado, bool actual, bool bloqueado, Color c) {
    if (completado) return c.withValues(alpha: 0.7);
    if (actual) return c;
    return Colors.white.withValues(alpha: 0.07);
  }

  Color _colorTextoHex(bool completado, bool actual, bool bloqueado, Color c) {
    if (completado) return c.withValues(alpha: 0.85);
    if (actual) return c;
    return Colors.white.withValues(alpha: 0.18);
  }

  // ── DIÁLOGO DE NIVEL ──────────────────────────────────────────────────────
  void _onNivelTap(int nivel) {
    final String nombre = _missionNames[nivel - 1];
    final bool completado = nivel < _nivelActual;
    final Color colorGrupo = _grupoDeNivel(nivel).color;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgMain,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorGrupo.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: colorGrupo.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorGrupo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorGrupo.withValues(alpha: 0.4)),
                    ),
                    child: Icon(
                      _iconsPorNivel(nivel),
                      color: colorGrupo,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [colorGrupo, AppColors.purple],
                        ).createShader(bounds),
                        child: Text(
                          'NIVEL $nivel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      Text(
                        nombre,
                        style: TextStyle(
                          color: colorGrupo.withValues(alpha: 0.7),
                          fontSize: 11,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (completado) ...[
                const SizedBox(height: 20),
                const Text(
                  'Completa este nivel nuevamente\npara entrenar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Los puntos no se guardarán.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.purple.withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorGrupo.withValues(alpha: 0.5),
                      AppColors.purple.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatDialogo(
                    '5',
                    'MISIONES',
                    Icons.flag_rounded,
                    colorGrupo,
                  ),
                  _buildStatDialogo(
                    '+${nivel * 100}',
                    'PUNTOS',
                    Icons.emoji_events_rounded,
                    AppColors.purple,
                  ),
                  _buildStatDialogo(
                    'NV.$nivel',
                    'DIFICULTAD',
                    Icons.bolt_rounded,
                    AppColors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (completado) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBadge('COMPLETADO', Icons.check_circle, colorGrupo),
                    const SizedBox(width: 8),
                    _buildBadge(
                      'ENTRENAR',
                      Icons.fitness_center_rounded,
                      AppColors.cyan,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.purple.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'VOLVER',
                        style: TextStyle(
                          color: AppColors.purple.withValues(alpha: 0.7),
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _navegarANivel(nivel, completado),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colorGrupo, AppColors.purple],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: colorGrupo.withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          child: Text(
                            completado ? 'ENTRENAR' : 'INICIAR MISIÓN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String texto, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDialogo(
    String valor,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 8,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ── NAVEGACIÓN ────────────────────────────────────────────────────────────
  void _volverAlMenu() {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed(AppRoutes.menu);
  }

  bool _navegandoANivel = false;

  Future<void> _navegarANivel(int nivel, bool completado) async {
    Widget? pantalla;

    if (nivel == 1) {
      pantalla = Nivel01Screen(soloEntrenamiento: completado);
    } else if (nivel == 2) {
      pantalla = Nivel02Screen(soloEntrenamiento: completado);
    } else if (nivel == 3) {
      pantalla = Nivel03Screen(soloEntrenamiento: completado);
    } else if (nivel == 4) {
      pantalla = Nivel04Screen(soloEntrenamiento: completado);
    } else if (nivel == 5) {
      pantalla = Nivel05Screen(soloEntrenamiento: completado);
    } else if (nivel == 6) {
      pantalla = Nivel06Screen(soloEntrenamiento: completado);
    } else if (nivel == 7) {
      pantalla = Nivel07Screen(soloEntrenamiento: completado);
    } else if (nivel == 8) {
      pantalla = Nivel08Screen(soloEntrenamiento: completado);
    } else if (nivel == 9) {
      pantalla = Nivel09Screen(soloEntrenamiento: completado);
    } else if (nivel == 10) {
      pantalla = Nivel10Screen(soloEntrenamiento: completado);
    } else if (nivel == 11) {
      pantalla = Nivel11Screen(soloEntrenamiento: completado);
    } else if (nivel == 12) {
      pantalla = Nivel12Screen(soloEntrenamiento: completado);
    } else if (nivel == 13) {
      pantalla = Nivel13Screen(soloEntrenamiento: completado);
    } else if (nivel == 14) {
      pantalla = Nivel14Screen(soloEntrenamiento: completado);
    } else if (nivel == 15) {
      pantalla = Nivel15Screen(soloEntrenamiento: completado);
    } else if (nivel == 16) {
      pantalla = Nivel16Screen(soloEntrenamiento: completado);
    } else if (nivel == 17) {
      pantalla = Nivel17Screen(soloEntrenamiento: completado);
    } else if (nivel == 18) {
      pantalla = Nivel18Screen(soloEntrenamiento: completado);
    } else if (nivel == 19) {
      pantalla = Nivel19Screen(soloEntrenamiento: completado);
    } else if (nivel == 20) {
      pantalla = Nivel20Screen(soloEntrenamiento: completado);
    } else if (nivel == 21) {
      pantalla = Nivel21Screen(soloEntrenamiento: completado);
    } else if (nivel == 22) {
      pantalla = Nivel22Screen(soloEntrenamiento: completado);
    } else if (nivel == 23) {
      pantalla = Nivel23Screen(soloEntrenamiento: completado);
    } else if (nivel == 24) {
      pantalla = Nivel24Screen(soloEntrenamiento: completado);
    } else if (nivel == 25) {
      pantalla = Nivel25Screen(soloEntrenamiento: completado);
    }
    if (pantalla != null) {
      _navegandoANivel = true; // bloquea didPopNext

      //Para la música ANTES de hacer cualquier navegación
      try {
        await MusicService().stopMusic();
      } catch (e) {
        debugPrint('No se pudo detener la musica del menu: $e');
      }

      if (!mounted) return;

      //Pop del diálogo/modal actual
      Navigator.pop(context);

      if (!mounted) return;

      //Navega al nivel
      await Navigator.push(context, AppRoutes.fade(pantalla));

      _navegandoANivel = false;

      // Solo reanudar si realmente volvimos al mapa
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _reanudarMapaSiEsVisible();
      }
    }
  }
}

// ── LÍNEA CONECTORA ───────────────────────────────────────────────────────────
class _LineaConectoraPainter extends CustomPainter {
  final Color color;
  final List<int> niveles;
  final int nivelActual;
  final double anchoTotal;
  final int numNiveles;

  _LineaConectoraPainter({
    required this.color,
    required this.niveles,
    required this.nivelActual,
    required this.anchoTotal,
    required this.numNiveles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double paso = anchoTotal / (numNiveles - 1);
    // Radio aproximado del hexágono (ajusta si cambias hexW)
    const double hexRadius = 26.0;

    for (int i = 0; i < niveles.length - 1; i++) {
      final int nivelA = niveles[i];
      final int nivelB = niveles[i + 1];
      final bool segmentoAlcanzado =
          nivelA < nivelActual && nivelB <= nivelActual;
      final bool segmentoParcial =
          nivelA < nivelActual && nivelB == nivelActual;

      // Inicio: centro del hex izquierdo + radio → borde derecho
      final double xInicio = i * paso + hexRadius;
      // Fin: centro del hex derecho - radio → borde izquierdo
      final double xFin = (i + 1) * paso - hexRadius;

      // Si no hay espacio entre bordes, no dibujamos
      if (xInicio >= xFin) continue;

      final Paint paint = Paint()
        ..strokeWidth = segmentoAlcanzado || segmentoParcial ? 2.0 : 1.0
        ..color = segmentoAlcanzado || segmentoParcial
            ? color.withValues(alpha: 0.7)
            : color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (!segmentoAlcanzado && !segmentoParcial) {
        final Path dashPath = Path();
        double x = xInicio;
        while (x < xFin) {
          dashPath.moveTo(x, 0);
          dashPath.lineTo(math.min(x + 6, xFin), 0);
          x += 10;
        }
        canvas.drawPath(dashPath, paint);
      } else {
        canvas.drawLine(Offset(xInicio, 0), Offset(xFin, 0), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_LineaConectoraPainter old) =>
      old.nivelActual != nivelActual;
}

// ── HEXÁGONO PAINTER ──────────────────────────────────────────────────────────
class _HexPainter extends CustomPainter {
  final Color color;
  final Color? borderColor;
  final bool filled;
  final double borderWidth;
  final double scale;

  _HexPainter({
    required this.color,
    this.borderColor,
    required this.filled,
    this.borderWidth = 1.5,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (math.min(size.width, size.height) / 2) * scale;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 180) * (60 * i - 30);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    if (filled) canvas.drawPath(path, Paint()..color = color);
    if (borderColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
    }
  }

  @override
  bool shouldRepaint(_HexPainter old) =>
      old.color != color || old.scale != scale;
}

// ── PARTÍCULA ─────────────────────────────────────────────────────────────────
class _Particle {
  double x, y, vx, vy, radius, opacity;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
    required this.color,
  });

  static final List<Color> _colors = [
    AppColors.cyan,
    AppColors.purple,
    AppColors.blue,
    AppColors.pink,
  ];

  factory _Particle.random(math.Random rnd, Size size) {
    return _Particle(
      x: rnd.nextDouble() * size.width,
      y: rnd.nextDouble() * size.height,
      vx: (rnd.nextDouble() - 0.5) * 0.6,
      vy: (rnd.nextDouble() - 0.5) * 0.6,
      radius: rnd.nextDouble() * 2.5 + 0.5,
      opacity: rnd.nextDouble() * 0.5 + 0.1,
      color: _colors[rnd.nextInt(_colors.length)],
    );
  }

  void update() {
    x += vx;
    y += vy;
  }
}

// ── PARTICLE PAINTER ──────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.x < 0 || p.x > size.width) p.vx *= -1;
      if (p.y < 0 || p.y > size.height) p.vy *= -1;
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.radius,
        Paint()..color = p.color.withValues(alpha: p.opacity),
      );
      for (final other in particles) {
        final dx = p.x - other.x;
        final dy = p.y - other.y;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < 80 && dist > 0) {
          canvas.drawLine(
            Offset(p.x, p.y),
            Offset(other.x, other.y),
            Paint()
              ..color = p.color.withValues(alpha: (1 - dist / 80) * 0.15)
              ..strokeWidth = 0.5,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
