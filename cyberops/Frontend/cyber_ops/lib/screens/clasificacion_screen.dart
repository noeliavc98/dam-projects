import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_colors.dart';

class ClasificacionScreen extends StatefulWidget {
  const ClasificacionScreen({super.key});

  @override
  State<ClasificacionScreen> createState() => _ClasificacionScreenState();
}

class _ClasificacionScreenState extends State<ClasificacionScreen>
    with TickerProviderStateMixin {

  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<Map<String, dynamic>> _jugadores = [];
  bool _cargando = true;
  String? _uidActual;

  @override
  void initState() {
    super.initState();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _uidActual = FirebaseAuth.instance.currentUser?.uid;
    _cargarClasificacion();
  }

  Future<void> _cargarClasificacion() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('puntuacion_total', descending: true)
          .limit(10)
          .get();

      final jugadores = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name'] ?? 'Agente',
          'puntuacion_total': data['puntuacion_total'] ?? 0,
          'nivel': data['nivel'] ?? 1,
          'partidas_jugadas': data['partidas_jugadas'] ?? 0,
          'fotoUrl': data['fotoUrl'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _jugadores = jugadores;
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error al cargar clasificación: $e');
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: Stack(
        children: [

          // ── FONDO ANIMADO ───────────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BackgroundPainter(_rotateController.value),
                );
              },
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                // ── CABECERA ────────────────────────────────────────────
                _buildHeader(),

                // ── CONTENIDO ───────────────────────────────────────────
                Expanded(
                  child: _cargando
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.cyan,
                          ),
                        )
                      : _jugadores.isEmpty
                          ? _buildVacio()
                          : _buildContenido(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CABECERA ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.4)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.cyan,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    AppColors.cyan,
                    AppColors.blue,
                    AppColors.purple,
                  ],
                ).createShader(bounds),
                child: const Text(
                  'CLASIFICACIÓN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
              Text(
                'TOP 10 AGENTES GLOBALES',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.purple.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Botón refrescar
          GestureDetector(
            onTap: () {
              setState(() => _cargando = true);
              _cargarClasificacion();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.4)),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppColors.purple,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CONTENIDO PRINCIPAL ───────────────────────────────────────────────────
  Widget _buildContenido() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [

          const SizedBox(height: 8),

          // Podio solo si hay al menos 3 jugadores
          if (_jugadores.length >= 3) _buildPodio(),

          const SizedBox(height: 24),

          // Separador
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.purple.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'RANKING COMPLETO',
                  style: TextStyle(
                    color: AppColors.purple.withValues(alpha: 0.7),
                    fontSize: 9,
                    letterSpacing: 3,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.purple.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lista top 10
          ...List.generate(
            _jugadores.length,
            (index) => _buildFilaJugador(index),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── PODIO ─────────────────────────────────────────────────────────────────
  Widget _buildPodio() {
    return SizedBox(
      height: 210,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          // 2º puesto
          Expanded(
            child: _buildPodioItem(
              jugador: _jugadores[1],
              posicion: 2,
              altura: 95,
              color: const Color(0xFFC0C0C0),
              esActual: _jugadores[1]['uid'] == _uidActual,
            ),
          ),

          const SizedBox(width: 6),

          // 1º puesto con pulso
          Expanded(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: _buildPodioItem(
                jugador: _jugadores[0],
                posicion: 1,
                altura: 125,
                color: const Color(0xFFFFD700),
                esActual: _jugadores[0]['uid'] == _uidActual,
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 3º puesto
          Expanded(
            child: _buildPodioItem(
              jugador: _jugadores[2],
              posicion: 3,
              altura: 75,
              color: const Color(0xFFCD7F32),
              esActual: _jugadores[2]['uid'] == _uidActual,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodioItem({
    required Map<String, dynamic> jugador,
    required int posicion,
    required double altura,
    required Color color,
    required bool esActual,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [

        // Avatar
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(
              color: esActual ? AppColors.cyan : color,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: esActual ? 14 : 6,
              ),
            ],
          ),
          child: jugador['fotoUrl'] != null
              ? ClipOval(
                  child: Image.network(
                    jugador['fotoUrl'],
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.person_rounded,
                  color: color,
                  size: 22,
                ),
        ),

        const SizedBox(height: 4),

        // Nombre
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            jugador['name'] ?? 'Agente',
            style: TextStyle(
              color: esActual ? AppColors.cyan : Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 2),

        // Puntuación
        Text(
          '${jugador['puntuacion_total']}pts',
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        // Columna del podio
        Container(
          width: double.infinity,
          height: altura,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.35),
                color.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                posicion == 1
                    ? '🥇'
                    : posicion == 2
                        ? '🥈'
                        : '🥉',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 2),
              Text(
                '#$posicion',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── FILA DE JUGADOR ───────────────────────────────────────────────────────
  Widget _buildFilaJugador(int index) {
    final jugador = _jugadores[index];
    final bool esActual = jugador['uid'] == _uidActual;
    final int posicion = index + 1;

    Color colorPosicion;
    if (posicion == 1) {
      colorPosicion = const Color(0xFFFFD700);
    } else if (posicion == 2) {
      colorPosicion = const Color(0xFFC0C0C0);
    } else if (posicion == 3) {
      colorPosicion = const Color(0xFFCD7F32);
    } else {
      colorPosicion = AppColors.purple.withValues(alpha: 0.7);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: esActual
            ? AppColors.cyan.withValues(alpha: 0.08)
            : AppColors.bgCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esActual
              ? AppColors.cyan.withValues(alpha: 0.5)
              : AppColors.purple.withValues(alpha: 0.2),
          width: esActual ? 1.5 : 1,
        ),
        boxShadow: esActual
            ? [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [

          // Posición
          SizedBox(
            width: 32,
            child: Text(
              '#$posicion',
              style: TextStyle(
                color: colorPosicion,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgCard,
              border: Border.all(
                color: esActual
                    ? AppColors.cyan
                    : colorPosicion.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: jugador['fotoUrl'] != null
                ? ClipOval(
                    child: Image.network(
                      jugador['fotoUrl'],
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    color: esActual ? AppColors.cyan : colorPosicion,
                    size: 20,
                  ),
          ),

          const SizedBox(width: 12),

          // Nombre y stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        jugador['name'] ?? 'Agente',
                        style: TextStyle(
                          color: esActual ? AppColors.cyan : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (esActual) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppColors.cyan.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'TÚ',
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: AppColors.purple.withValues(alpha: 0.6),
                      size: 11,
                    ),
                    Text(
                      ' Nv.${jugador['nivel']}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.flag_rounded,
                      color: AppColors.purple.withValues(alpha: 0.6),
                      size: 11,
                    ),
                    Text(
                      ' ${jugador['partidas_jugadas']} partidas',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Puntuación
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: posicion <= 3
                      ? [colorPosicion, colorPosicion.withValues(alpha: 0.7)]
                      : [AppColors.cyan, AppColors.purple],
                ).createShader(bounds),
                child: Text(
                  '${jugador['puntuacion_total']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                'PTS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 8,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── ESTADO VACÍO ──────────────────────────────────────────────────────────
  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            color: AppColors.purple.withValues(alpha: 0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'SIN DATOS AÚN',
            style: TextStyle(
              color: AppColors.purple.withValues(alpha: 0.5),
              fontSize: 14,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completa misiones para aparecer en el ranking',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── FONDO ANIMADO ─────────────────────────────────────────────────────────────
class _BackgroundPainter extends CustomPainter {
  final double progress;
  _BackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final rings = [
      (radius: 280.0, opacity: 0.04),
      (radius: 200.0, opacity: 0.06),
      (radius: 130.0, opacity: 0.05),
    ];

    for (final ring in rings) {
      canvas.drawCircle(
        Offset(cx, cy),
        ring.radius,
        Paint()
          ..color = AppColors.purple.withValues(alpha: ring.opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    final dotPaint = Paint()..style = PaintingStyle.fill;
    final dots = [
      (angle: progress * 2 * math.pi,                   radius: 280.0, color: AppColors.purple, size: 3.0),
      (angle: progress * 2 * math.pi + math.pi,         radius: 280.0, color: AppColors.blue,   size: 3.0),
      (angle: -progress * 2 * math.pi + math.pi / 3,    radius: 200.0, color: AppColors.cyan,   size: 2.5),
      (angle: -progress * 2 * math.pi + math.pi * 1.33, radius: 200.0, color: AppColors.purple, size: 2.5),
    ];

    for (final dot in dots) {
      dotPaint.color = dot.color.withValues(alpha: 0.7);
      canvas.drawCircle(
        Offset(
          cx + dot.radius * math.cos(dot.angle),
          cy + dot.radius * math.sin(dot.angle),
        ),
        dot.size,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.progress != progress;
}