import 'dart:async';
import 'dart:math' as math;

import 'package:cyber_ops/widgets/fractura/fractura_dialogo.dart';
import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_routes.dart';
import '../games/nivel_11/nivel11_game.dart';
import '../services/firestore_service.dart';
import 'level_map_screen.dart';
import '../services/music_service.dart';

class Nivel11Screen extends StatefulWidget {
  const Nivel11Screen({super.key, this.soloEntrenamiento = false});

  final bool soloEntrenamiento;

  @override
  State<Nivel11Screen> createState() => _Nivel11ScreenState();
}

class _Nivel11ScreenState extends State<Nivel11Screen> {
  final Nivel11Game _game = Nivel11Game();
  Timer? _ticker;

  String _selectedHostId = 'rrhh';
  int _mobileIndex = 0;
  bool _loading = true;
  bool _showIntro = true;
  bool _nivelYaCompletado = false;
  bool _resultadoMostrado = false;

  // ── FRACTURA ──────────────────────────────────────────────────────────────
  bool _mostrarFractura = true;
  final List<String> _dialogosFractura = [
    'El ransomware no destruye datos. Los toma como rehenes.',
    'Entra silencioso: un adjunto, un enlace, una vulnerabilidad sin parchear.',
    'Una vez dentro, cifra todo lo que encuentra. Documentos, bases de datos, copias de seguridad.',
    'Cuando termina, aparece el mensaje. Paga o pierdes todo.',
    'Los atacantes no necesitan ser sofisticados. Hoy el ransomware se alquila como un servicio.',
    'Entender cómo opera es el primer paso para detenerlo.',
    'Elige entre dos modos: defensa o atacante.',
  ];

  @override
  void initState() {
    super.initState();
    _iniciarJuego();
  }

  Future<void> _iniciarJuego() async {
      try {
      await MusicService().playNiveles11to15Music();
    } catch (e) {
      debugPrint('Error iniciando musica de combate del nivel 1: $e');
    }

    if (widget.soloEntrenamiento) {
      _nivelYaCompletado = true;
    } else {
      try {
        final Map<String, dynamic> datos =
            await FirestoreService.obtenerUsuario();
        final int nivelUsuario = (datos['nivel'] as num?)?.toInt() ?? 1;
        if (nivelUsuario > 11) {
          _nivelYaCompletado = true;
        }
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_mostrarFractura) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        body: Container(
          color: Colors.black.withValues(alpha: 0.80),
          child: FracturaDialogo(
            dialogos: _dialogosFractura,
            subtitulo: 'NIVEL 11 // RAMSONWARE - SALA DE CRISIS',
            textoBotonFinal: 'JUGAR',
            usarVoz: true,
            permitirSaltarIntro: true,
            permitirCambiarVoz: true,
            velocidadVoz: 0.66,
            milisegundosPorCaracter: 18,
            onFinalizado: () async {
              setState(() {
                _mostrarFractura = false;
                _loading = true;
              });

              await _iniciarJuego();
            },
          ),
        ),
      );
    }
    if (_loading) {
      return const Scaffold(
        backgroundColor: _cRoot,
        body: Center(child: CircularProgressIndicator(color: _cCyan)),
      );
    }

    if (_showIntro) {
      return Scaffold(
        backgroundColor: _cRoot,
        body: SafeArea(child: _buildIntro()),
      );
    }

    return Scaffold(
      backgroundColor: _cRoot,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: _cRoot,
              child: Column(
                children: <Widget>[
                  _buildCyberBar(),
                  _buildProgressBar(),
                  if (_nivelYaCompletado) _buildTrainingBanner(),
                  Expanded(child: _buildResponsiveLayout()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 720;
        return Stack(
          children: <Widget>[
            Positioned.fill(child: CustomPaint(painter: _IntroGridPainter())),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _buildBackButton(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const <Widget>[
                                Text(
                                  'CYBEROPS // NIVEL 11',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _cCyan,
                                    fontFamily: _monoFont,
                                    fontFamilyFallback: _monoFallback,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 3,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'RANSOMWARE // SALA DE CRISIS',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: _uiFont,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _finishIntro('general'),
                            child: const Text(
                              'SALTAR INTRO',
                              style: TextStyle(
                                color: _cPurple,
                                fontFamily: _monoFont,
                                fontFamilyFallback: _monoFallback,
                                fontSize: 11,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      compact
                          ? Column(
                              children: <Widget>[
                                _buildIntroTerminal(),
                                const SizedBox(height: 12),
                                _buildIntroRansomNote(),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(flex: 5, child: _buildIntroTerminal()),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 4,
                                  child: _buildIntroRansomNote(),
                                ),
                              ],
                            ),
                      const SizedBox(height: 18),
                      _buildIntroChoicePanel(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIntroTerminal() {
    const List<String> lines = <String>[
      '08:42:13  winword.exe abre factura_abril.docm',
      '08:42:18  proceso desconocido: svhost32.exe',
      '08:42:21  142 archivos modificados',
      '08:42:25  extension detectada: .locked',
      '08:42:31  conexion SMB hacia FILE-SRV-01',
      '08:42:39  alerta EDR: escritura masiva',
    ];

    return _Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.monitor_heart_rounded, color: _cCyan, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'EDR ALERT // PRIMER CIFRADO DETECTADO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _rgba(255, 255, 255, .88),
                    fontFamily: _monoFont,
                    fontFamilyFallback: _monoFallback,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...lines.map(
            (String line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                line,
                style: const TextStyle(
                  color: _cGreen,
                  fontFamily: _monoFont,
                  fontFamilyFallback: _monoFallback,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _rgba(236, 72, 153, .10),
              border: Border.all(color: _rgba(236, 72, 153, .32)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'El ransomware ya esta activo. Tu objetivo es contener, erradicar y recuperar en el orden correcto.',
              style: TextStyle(
                color: Colors.white,
                fontFamily: _uiFont,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroRansomNote() {
    return _Panel(
      color: const Color(0xFF160815),
      borderColor: _rgba(236, 72, 153, .42),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _rgba(236, 72, 153, .16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _rgba(236, 72, 153, .45)),
                ),
                child: const Icon(Icons.lock_rounded, color: _cPink, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[
                    Text(
                      'YOUR FILES ARE LOCKED',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _cPink,
                        fontFamily: _monoFont,
                        fontFamilyFallback: _monoFallback,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'No pagues. Responde.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: _uiFont,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'La nota de rescate aparece en RRHH-PC-04 mientras el servidor de ficheros empieza a recibir escrituras anormales. Si restauras demasiado pronto, el malware cifrara los datos recuperados. Si investigas demasiado lento, saltara a Finanzas.',
            style: TextStyle(
              color: _rgba(255, 255, 255, .72),
              fontFamily: _uiFont,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _IntroNetworkPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroChoicePanel() {
    return _Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Elige perspectiva',
            style: TextStyle(
              color: _rgba(255, 255, 255, .90),
              fontFamily: _uiFont,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Defensa juega la sala de crisis. Atacante simula la cadena y termina preguntando que controles la habrian frenado.',
            style: TextStyle(
              color: _rgba(255, 255, 255, .55),
              fontFamily: _uiFont,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _IntroChoiceButton(
                icon: Icons.shield_rounded,
                label: 'Modo defensa',
                onTap: () => _finishIntro('procesos'),
              ),
              _IntroChoiceButton(
                icon: Icons.visibility_rounded,
                label: 'Modo atacante',
                onTap: () => _finishIntro('attacker'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _finishIntro(String focus) {
    if (focus == 'attacker') {
      setState(() {
        _showIntro = false;
        _selectedHostId = 'rrhh';
        _mobileIndex = 2;
        _game.startAttackerMode();
      });
      _startTicker();
      return;
    }

    final Map<String, ActionResult> lessons = <String, ActionResult>{
      'procesos': const ActionResult(
        positive: true,
        title: 'Primer enfoque: procesos',
        explanation:
            'Busca el binario que cifra archivos. Si confirmas su hash, podras bloquearlo en EDR.',
        lesson:
            'El proceso malicioso convierte una alerta en un indicador accionable.',
      ),
      'red': const ActionResult(
        positive: true,
        title: 'Primer enfoque: red',
        explanation:
            'Sigue las conexiones SMB para entender hacia donde se mueve el ransomware.',
        lesson:
            'La propagacion lateral suele apoyarse en recursos compartidos y credenciales reutilizadas.',
      ),
      'archivos': const ActionResult(
        positive: true,
        title: 'Primer enfoque: archivos',
        explanation:
            'Las extensiones .locked y la escritura masiva confirman el cifrado.',
        lesson:
            'Los indicadores de impacto ayudan a saber que recuperar despues.',
      ),
      'backup': const ActionResult(
        positive: true,
        title: 'Primer enfoque: backup',
        explanation:
            'Verifica la copia, pero no restaures hasta contener y limpiar.',
        lesson:
            'Restaurar antes de erradicar puede reinfectar los datos recuperados.',
      ),
    };

    setState(() {
      _showIntro = false;
      _game.lastResult = lessons[focus] ?? lessons['procesos'];
      if (focus == 'backup') {
        _selectedHostId = 'backup';
        _mobileIndex = 2;
      } else if (focus == 'red') {
        _selectedHostId = 'files';
      } else {
        _selectedHostId = 'rrhh';
      }
    });
    _startTicker();
  }

  Widget _buildCyberBar() {
    final bool compact = MediaQuery.sizeOf(context).width < 720;
    final bool attacker = _game.isAttackerMode;
    final String title = attacker
        ? 'CYBEROPS // NV.11 // ATACANTE'
        : 'CYBEROPS // NV.11 // DEFENSA';
    final String subtitle = attacker
        ? 'ATTACK SIM // ACCESO // LATERAL // IMPACTO'
        : 'INCIDENT RESPONSE // CONTENER // ERRADICAR // RECUPERAR';
    return Container(
      decoration: BoxDecoration(
        color: _cCyberBar,
        border: Border(
          bottom: BorderSide(color: _rgba(108, 99, 255, .25), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: <Widget>[
          _buildBackButton(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _cCyan,
                    fontFamily: _monoFont,
                    fontFamilyFallback: _monoFallback,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                if (!compact)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _rgba(255, 255, 255, .32),
                      fontFamily: _monoFont,
                      fontFamilyFallback: _monoFallback,
                      fontSize: 9,
                      letterSpacing: 2,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Wrap(
            spacing: 6,
            children: <Widget>[
              _MetricBadge(
                icon: Icons.timer_rounded,
                label: '${_game.minute} MIN',
                color: _cCyan,
              ),
              _MetricBadge(
                icon: Icons.warning_amber_rounded,
                label: attacker
                    ? '${_game.attackerDetection}% DET'
                    : '${_game.activeThreats} IOC',
                color: _cPink,
              ),
              _MetricBadge(
                icon: Icons.favorite_rounded,
                label: '${_game.lives}',
                color: _cPink,
              ),
              _MetricBadge(
                icon: Icons.military_tech_rounded,
                label: '${_game.points} PTS',
                color: _cPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Tooltip(
      message: 'Volver al mapa',
      child: InkWell(
        onTap: _volverAlMapa,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _rgba(255, 255, 255, .05),
            border: Border.all(color: _rgba(6, 182, 212, .35)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _cCyan,
            size: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final double progress = _game.currentProgress.clamp(0.0, 1.0).toDouble();
    return Container(
      height: 3,
      color: _rgba(255, 255, 255, .05),
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: progress),
        duration: const Duration(milliseconds: 350),
        builder: (BuildContext context, double value, Widget? child) {
          return FractionallySizedBox(
            widthFactor: value,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: <Color>[_cPink, _cCyan]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrainingBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _rgba(108, 99, 255, .12),
        border: Border.all(color: _rgba(108, 99, 255, .45)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.fitness_center_rounded,
            color: _rgba(168, 159, 255, .90),
            size: 14,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'MODO ENTRENAMIENTO - la puntuacion no se guardara',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _rgba(168, 159, 255, .90),
                fontFamily: _monoFont,
                fontFamilyFallback: _monoFallback,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveLayout() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= 1120) {
          return Row(
            children: <Widget>[
              Expanded(flex: 5, child: _buildNetworkPanel()),
              SizedBox(width: 330, child: _buildHostPanel()),
              SizedBox(width: 360, child: _buildCommandPanel()),
            ],
          );
        }

        if (constraints.maxWidth >= 760) {
          return Column(
            children: <Widget>[
              Expanded(flex: 5, child: _buildNetworkPanel()),
              SizedBox(
                height: 290,
                child: Row(
                  children: <Widget>[
                    Expanded(child: _buildHostPanel()),
                    Expanded(child: _buildCommandPanel()),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          children: <Widget>[
            Expanded(
              child: IndexedStack(
                index: _mobileIndex,
                children: <Widget>[
                  _buildNetworkPanel(compact: true),
                  _buildHostPanel(),
                  _buildCommandPanel(),
                ],
              ),
            ),
            NavigationBar(
              backgroundColor: _cCyberBar,
              indicatorColor: _rgba(6, 182, 212, .15),
              selectedIndex: _mobileIndex,
              onDestinationSelected: (int value) {
                setState(() => _mobileIndex = value);
              },
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.hub_outlined),
                  selectedIcon: Icon(Icons.hub_rounded),
                  label: 'Red',
                ),
                NavigationDestination(
                  icon: Icon(Icons.dns_outlined),
                  selectedIcon: Icon(Icons.dns_rounded),
                  label: 'Host',
                ),
                NavigationDestination(
                  icon: Icon(Icons.terminal_outlined),
                  selectedIcon: Icon(Icons.terminal_rounded),
                  label: 'Acciones',
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildNetworkPanel({bool compact = false}) {
    final bool attacker = _game.isAttackerMode;
    return _Panel(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionHeader(
            icon: Icons.hub_rounded,
            title: 'Mapa de red',
            trailing: attacker
                ? '${_game.attackerDetection}% deteccion'
                : '${_game.totalEncryptedFiles} archivos cifrados',
          ),
          const SizedBox(height: 10),
          Expanded(
            child: compact
                ? _buildCompactNodeGrid()
                : LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          return Stack(
                            children: <Widget>[
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _ConnectionPainter(
                                    hosts: _game.hosts,
                                    selectedHostId: _selectedHostId,
                                  ),
                                ),
                              ),
                              ..._game.hosts.map((HostNode host) {
                                const double cardW = 150;
                                const double cardH = 82;
                                final double maxLeft = math.max(
                                  0,
                                  constraints.maxWidth - cardW,
                                );
                                final double maxTop = math.max(
                                  0,
                                  constraints.maxHeight - cardH,
                                );
                                final double left = (host.x * maxLeft)
                                    .clamp(0, maxLeft)
                                    .toDouble();
                                final double top = (host.y * maxTop)
                                    .clamp(0, maxTop)
                                    .toDouble();
                                return Positioned(
                                  left: left,
                                  top: top,
                                  width: cardW,
                                  height: cardH,
                                  child: _buildNodeCard(host),
                                );
                              }),
                            ],
                          );
                        },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNodeGrid() {
    return GridView.builder(
      itemCount: _game.hosts.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisExtent: 94,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (BuildContext context, int index) {
        return _buildNodeCard(_game.hosts[index]);
      },
    );
  }

  Widget _buildNodeCard(HostNode host) {
    final bool selected = host.id == _selectedHostId;
    final Color color = _statusColor(host.status);

    return Tooltip(
      message: 'Seleccionar ${host.name}',
      child: InkWell(
        onTap: () => setState(() => _selectedHostId = host.id),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: .16)
                : _rgba(255, 255, 255, .05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: .35),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: host.status == HostStatus.encrypting
                ? <BoxShadow>[
                    BoxShadow(
                      color: color.withValues(alpha: .20),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(_statusIcon(host.status), color: color, size: 17),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      host.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: _monoFont,
                        fontFamilyFallback: _monoFallback,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                host.role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _rgba(255, 255, 255, .45),
                  fontFamily: _uiFont,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  _StatusPill(label: host.status.label, color: color),
                  const Spacer(),
                  Text(
                    host.encryptedFiles > 0 ? '${host.encryptedFiles}' : '',
                    style: const TextStyle(
                      color: _cPink,
                      fontFamily: _monoFont,
                      fontFamilyFallback: _monoFallback,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  Widget _buildHostPanel() {
    final HostNode host = _game.hostById(_selectedHostId);
    final Color color = _statusColor(host.status);

    return _Panel(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionHeader(
            icon: Icons.dns_rounded,
            title: 'Host seleccionado',
            trailing: host.status.label,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .14),
                  border: Border.all(color: color.withValues(alpha: .46)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_statusIcon(host.status), color: color, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      host.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: _monoFont,
                        fontFamilyFallback: _monoFallback,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${host.segment} // ${host.role}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _rgba(255, 255, 255, .45),
                        fontFamily: _uiFont,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _FactChip(
                icon: Icons.folder_copy_rounded,
                label: '${host.encryptedFiles} cifrados',
                color: _cPink,
              ),
              _FactChip(
                icon: Icons.memory_rounded,
                label: host.processesChecked ? 'procesos vistos' : 'procesos ?',
                color: _cCyan,
              ),
              _FactChip(
                icon: Icons.article_rounded,
                label: host.logsChecked ? 'logs vistos' : 'logs ?',
                color: _cPurple,
              ),
              if (host.isolated)
                const _FactChip(
                  icon: Icons.link_off_rounded,
                  label: 'aislado',
                  color: _cGreen,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Indicadores',
            style: TextStyle(
              color: _rgba(255, 255, 255, .82),
              fontFamily: _uiFont,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: host.clues.length,
              separatorBuilder: (context, index) => const SizedBox(height: 7),
              itemBuilder: (BuildContext context, int index) {
                final bool revealed =
                    host.processesChecked ||
                    host.logsChecked ||
                    host.id == 'backup' ||
                    index == 0;
                return _ClueRow(
                  text: revealed
                      ? host.clues[index]
                      : 'Indicador oculto: revisa procesos o logs.',
                  revealed: revealed,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandPanel() {
    if (_game.phase == Nivel11Phase.attackerReport ||
        _game.phase == Nivel11Phase.report ||
        _game.phase == Nivel11Phase.victory) {
      return _buildReportPanel();
    }

    if (_game.phase == Nivel11Phase.attacker) {
      return _buildAttackerCommandPanel();
    }

    return _Panel(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _SectionHeader(
            icon: Icons.terminal_rounded,
            title: 'Acciones',
            trailing: 'playbook',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <_ActionButtonData>[
              _ActionButtonData(
                action: Nivel11Action.inspectProcesses,
                icon: Icons.memory_rounded,
              ),
              _ActionButtonData(
                action: Nivel11Action.reviewLogs,
                icon: Icons.article_rounded,
              ),
              _ActionButtonData(
                action: Nivel11Action.isolateHost,
                icon: Icons.link_off_rounded,
              ),
              _ActionButtonData(
                action: Nivel11Action.blockHash,
                icon: Icons.gpp_maybe_rounded,
              ),
              _ActionButtonData(
                action: Nivel11Action.cutSegment,
                icon: Icons.account_tree_rounded,
              ),
              _ActionButtonData(
                action: Nivel11Action.verifyBackup,
                icon: Icons.settings_backup_restore_rounded,
              ),
              _ActionButtonData(
                action: Nivel11Action.cleanHost,
                icon: Icons.cleaning_services_rounded,
              ),
              _ActionButtonData(
                action: Nivel11Action.restoreBackup,
                icon: Icons.restore_rounded,
              ),
              _ActionButtonData(
                action: Nivel11Action.notifySoc,
                icon: Icons.campaign_rounded,
              ),
            ].map(_buildActionButton).toList(),
          ),
          const SizedBox(height: 12),
          _buildFeedbackBox(),
          const SizedBox(height: 12),
          const _SectionHeader(
            icon: Icons.receipt_long_rounded,
            title: 'Feed de alertas',
            trailing: 'live',
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildEventFeed()),
        ],
      ),
    );
  }

  Widget _buildAttackerCommandPanel() {
    return _Panel(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionHeader(
            icon: Icons.visibility_rounded,
            title: 'Cadena atacante',
            trailing: _game.attackerStage,
          ),
          const SizedBox(height: 10),
          Container(
            height: 7,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _rgba(255, 255, 255, .08),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (_game.attackerDetection / 100)
                  .clamp(0.0, 1.0)
                  .toDouble(),
              child: Container(color: _cPink),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <_AttackActionButtonData>[
              _AttackActionButtonData(
                action: Nivel11AttackAction.phishing,
                icon: Icons.mark_email_unread_rounded,
              ),
              _AttackActionButtonData(
                action: Nivel11AttackAction.reconNetwork,
                icon: Icons.travel_explore_rounded,
              ),
              _AttackActionButtonData(
                action: Nivel11AttackAction.smbJump,
                icon: Icons.lan_rounded,
              ),
              _AttackActionButtonData(
                action: Nivel11AttackAction.enumeratePermissions,
                icon: Icons.manage_search_rounded,
              ),
              _AttackActionButtonData(
                action: Nivel11AttackAction.searchBackup,
                icon: Icons.settings_backup_restore_rounded,
              ),
              _AttackActionButtonData(
                action: Nivel11AttackAction.prepareEncryption,
                icon: Icons.folder_zip_rounded,
              ),
              _AttackActionButtonData(
                action: Nivel11AttackAction.executeEncryption,
                icon: Icons.lock_rounded,
              ),
              _AttackActionButtonData(
                action: Nivel11AttackAction.hideTrace,
                icon: Icons.visibility_off_rounded,
              ),
            ].map(_buildAttackActionButton).toList(),
          ),
          const SizedBox(height: 12),
          _buildFeedbackBox(),
          const SizedBox(height: 12),
          const _SectionHeader(
            icon: Icons.receipt_long_rounded,
            title: 'Feed de deteccion',
            trailing: 'live',
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildEventFeed()),
        ],
      ),
    );
  }

  Widget _buildActionButton(_ActionButtonData data) {
    return Tooltip(
      message: data.action.label,
      child: SizedBox(
        height: 42,
        child: ElevatedButton.icon(
          onPressed: () => _applyAction(data.action),
          icon: Icon(data.icon, size: 17),
          label: Text(data.action.label, overflow: TextOverflow.ellipsis),
          style: ElevatedButton.styleFrom(
            backgroundColor: _rgba(255, 255, 255, .06),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: _rgba(255, 255, 255, .10)),
            ),
            textStyle: const TextStyle(
              fontFamily: _uiFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttackActionButton(_AttackActionButtonData data) {
    return Tooltip(
      message: data.action.label,
      child: SizedBox(
        height: 42,
        child: ElevatedButton.icon(
          onPressed: () => _applyAttackAction(data.action),
          icon: Icon(data.icon, size: 17),
          label: Text(data.action.label, overflow: TextOverflow.ellipsis),
          style: ElevatedButton.styleFrom(
            backgroundColor: _rgba(236, 72, 153, .09),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: _rgba(236, 72, 153, .22)),
            ),
            textStyle: const TextStyle(
              fontFamily: _uiFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackBox() {
    final ActionResult? result = _game.lastResult;
    if (result == null) {
      final String emptyText = _game.isAttackerMode
          ? 'Selecciona RRHH-PC-04 y empieza la cadena. La deteccion sube con el tiempo y con cada error.'
          : 'Selecciona un host y ejecuta una accion. El orden importa: contener, erradicar, recuperar.';
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _rgba(6, 182, 212, .08),
          border: Border.all(color: _rgba(6, 182, 212, .25)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          emptyText,
          style: TextStyle(
            color: _rgba(255, 255, 255, .70),
            fontFamily: _uiFont,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      );
    }

    final Color color = result.positive ? _cGreen : _cPink;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        border: Border.all(color: color.withValues(alpha: .32)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                result.positive
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                color: color,
                size: 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  result.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontFamily: _uiFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            result.explanation,
            style: TextStyle(
              color: _rgba(255, 255, 255, .72),
              fontFamily: _uiFont,
              fontSize: 12,
              height: 1.42,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            result.lesson,
            style: TextStyle(
              color: _rgba(6, 182, 212, .82),
              fontFamily: _uiFont,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventFeed() {
    final List<IncidentEvent> events = _game.events;
    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (BuildContext context, int index) {
        final IncidentEvent event = events[index];
        final Color color = _eventColor(event.severity);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .07),
            border: Border.all(color: color.withValues(alpha: .18)),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                event.minute.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: color,
                  fontFamily: _monoFont,
                  fontFamilyFallback: _monoFallback,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '[${event.severity}] ${event.message}',
                  style: TextStyle(
                    color: _rgba(255, 255, 255, .70),
                    fontFamily: _monoFont,
                    fontFamilyFallback: _monoFallback,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportPanel() {
    final List<PreventionMeasure> measures = _game.reportMeasures;

    return _Panel(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionHeader(
            icon: Icons.assignment_turned_in_rounded,
            title: 'Informe final',
            trailing: _game.reportTrailing,
          ),
          const SizedBox(height: 10),
          Text(
            _game.reportPrompt,
            style: TextStyle(
              color: _rgba(255, 255, 255, .62),
              fontFamily: _uiFont,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: measures.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final PreventionMeasure measure = measures[index];
                final bool selected = _game.selectedReportAnswers.contains(
                  measure.id,
                );
                final Color color = selected
                    ? (measure.correct ? _cGreen : _cPink)
                    : _rgba(255, 255, 255, .55);
                return InkWell(
                  onTap: selected ? null : () => _submitPrevention(measure.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: .10)
                          : _rgba(255, 255, 255, .04),
                      border: Border.all(color: color.withValues(alpha: .30)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          selected
                              ? (measure.correct
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded)
                              : Icons.radio_button_unchecked_rounded,
                          color: color,
                          size: 18,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                measure.title,
                                style: TextStyle(
                                  color: selected ? color : Colors.white,
                                  fontFamily: _uiFont,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                selected ? measure.feedback : measure.detail,
                                style: TextStyle(
                                  color: _rgba(255, 255, 255, .58),
                                  fontFamily: _uiFont,
                                  fontSize: 11,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _buildFeedbackBox(),
        ],
      ),
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || _showIntro || !_game.isTimedPhase) {
        return;
      }

      setState(_game.advanceTime);
      _handlePhaseEnd();
    });
  }

  void _applyAction(Nivel11Action action) {
    setState(() {
      _game.applyAction(action, _selectedHostId);
    });
    _handlePhaseEnd();
  }

  void _applyAttackAction(Nivel11AttackAction action) {
    setState(() {
      _game.applyAttackAction(action, _selectedHostId);
      if (_game.lastResult?.positive ?? false) {
        _selectNextAttackHost(action);
      }
    });
    _handlePhaseEnd();
  }

  void _selectNextAttackHost(Nivel11AttackAction action) {
    switch (action) {
      case Nivel11AttackAction.reconNetwork:
        _selectedHostId = 'files';
      case Nivel11AttackAction.searchBackup:
        _selectedHostId = 'files';
      case Nivel11AttackAction.phishing:
      case Nivel11AttackAction.smbJump:
      case Nivel11AttackAction.enumeratePermissions:
      case Nivel11AttackAction.prepareEncryption:
      case Nivel11AttackAction.executeEncryption:
      case Nivel11AttackAction.hideTrace:
        break;
    }
  }

  void _submitPrevention(String id) {
    setState(() {
      _game.submitReportAnswer(id);
    });
    _handlePhaseEnd();
  }

  Future<void> _handlePhaseEnd() async {
    if (_resultadoMostrado) {
      return;
    }

    if (_game.phase == Nivel11Phase.victory) {
      await _mostrarResultado(exito: true);
    } else if (_game.phase == Nivel11Phase.defeat) {
      await _mostrarResultado(exito: false);
    }
  }

  Future<void> _mostrarResultado({required bool exito}) async {
    if (_resultadoMostrado || !mounted) {
      return;
    }
    _resultadoMostrado = true;
    _ticker?.cancel();
    final BuildContext screenContext = context;
    final int puntosFinales = _game.points;

    if (exito && !_nivelYaCompletado) {
      await FirestoreService.guardarPuntuacion(
        puntos: puntosFinales,
        nivelCompletado: 11,
      );
      await FirestoreService.guardarMision(
        nivel: 11,
        mision: 11,
        puntos: puntosFinales,
      );
    }

    if (!screenContext.mounted) {
      return;
    }

    showDialog<void>(
      context: screenContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _DialogoResultadoNivel11(
          exito: exito,
          puntos: puntosFinales,
          entrenamiento: _nivelYaCompletado,
          modoAtacante: _game.isAttackerMode,
          onReintentar: () {
            Navigator.pop(dialogContext);
            Navigator.pushReplacement(
              screenContext,
              AppRoutes.fade(
                Nivel11Screen(soloEntrenamiento: widget.soloEntrenamiento),
              ),
            );
          },
          onSalir: () {
            Navigator.pop(dialogContext);
            if (exito) {
              Navigator.pushAndRemoveUntil(
                screenContext,
                AppRoutes.fade(const LevelMapScreen()),
                (Route<dynamic> route) => route.settings.name == 'menu',
              );
            } else {
              Navigator.pop(screenContext);
            }
          },
        );
      },
    );
  }

  void _volverAlMapa() {
    _ticker?.cancel();
    Navigator.pushAndRemoveUntil(
      context,
      AppRoutes.fade(const LevelMapScreen()),
      (Route<dynamic> route) => route.settings.name == 'menu',
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.color = _cPanel,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor ?? _rgba(255, 255, 255, .09)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: _cCyan, size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: _monoFont,
              fontFamilyFallback: _monoFallback,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        Text(
          trailing.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _rgba(255, 255, 255, .36),
            fontFamily: _monoFont,
            fontFamilyFallback: _monoFallback,
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        border: Border.all(color: color.withValues(alpha: .28)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontFamily: _monoFont,
              fontFamilyFallback: _monoFallback,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        border: Border.all(color: color.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontFamily: _uiFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontFamily: _monoFont,
          fontFamilyFallback: _monoFallback,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: .7,
        ),
      ),
    );
  }
}

class _ClueRow extends StatelessWidget {
  const _ClueRow({required this.text, required this.revealed});

  final String text;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          revealed ? Icons.search_rounded : Icons.lock_outline_rounded,
          color: revealed ? _cCyan : _rgba(255, 255, 255, .22),
          size: 15,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: revealed
                  ? _rgba(255, 255, 255, .72)
                  : _rgba(255, 255, 255, .32),
              fontFamily: _uiFont,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroChoiceButton extends StatelessWidget {
  const _IntroChoiceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: _rgba(6, 182, 212, .12),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: _rgba(6, 182, 212, .32)),
          ),
          textStyle: const TextStyle(
            fontFamily: _uiFont,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ActionButtonData {
  const _ActionButtonData({required this.action, required this.icon});

  final Nivel11Action action;
  final IconData icon;
}

class _AttackActionButtonData {
  const _AttackActionButtonData({required this.action, required this.icon});

  final Nivel11AttackAction action;
  final IconData icon;
}

class _DialogoResultadoNivel11 extends StatelessWidget {
  const _DialogoResultadoNivel11({
    required this.exito,
    required this.puntos,
    required this.entrenamiento,
    required this.modoAtacante,
    required this.onReintentar,
    required this.onSalir,
  });

  final bool exito;
  final int puntos;
  final bool entrenamiento;
  final bool modoAtacante;
  final VoidCallback onReintentar;
  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context) {
    final Color color = exito ? _cCyan : _cPink;
    final String titulo = modoAtacante
        ? (exito ? 'CADENA ANALIZADA' : 'ATAQUE DETECTADO')
        : (exito ? 'INCIDENTE CONTENIDO' : 'CONTENCION FALLIDA');
    final String detalle = modoAtacante
        ? (exito
              ? 'Has completado la simulacion y detectado los controles que la habrian frenado.'
              : 'El SOC cerro la ventana antes de completar la cadena atacante.')
        : (exito
              ? 'Has contenido, limpiado, restaurado y cerrado el informe.'
              : 'El ransomware se propago antes de completar el playbook.');
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cRoot,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: .52)),
            boxShadow: <BoxShadow>[
              BoxShadow(color: color.withValues(alpha: .20), blurRadius: 30),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                exito
                    ? Icons.verified_user_rounded
                    : Icons.warning_amber_rounded,
                color: color,
                size: 48,
              ),
              const SizedBox(height: 14),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontFamily: _monoFont,
                  fontFamilyFallback: _monoFallback,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detalle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _rgba(255, 255, 255, .68),
                  fontFamily: _uiFont,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$puntos PTS',
                style: TextStyle(
                  color: color,
                  fontFamily: _monoFont,
                  fontFamilyFallback: _monoFallback,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (entrenamiento && exito) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Modo entrenamiento - puntos no guardados',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _rgba(168, 159, 255, .78),
                    fontFamily: _uiFont,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReintentar,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _rgba(108, 99, 255, .50)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'REINTENTAR',
                        style: TextStyle(
                          color: _cPurple,
                          fontFamily: _uiFont,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSalir,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        exito ? 'CONTINUAR' : 'SALIR',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: _uiFont,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
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
}

class _ConnectionPainter extends CustomPainter {
  _ConnectionPainter({required this.hosts, required this.selectedHostId});

  final List<HostNode> hosts;
  final String selectedHostId;

  @override
  void paint(Canvas canvas, Size size) {
    final Map<String, HostNode> byId = <String, HostNode>{
      for (final HostNode host in hosts) host.id: host,
    };
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    for (final HostNode host in hosts) {
      final Offset a = Offset(host.x * size.width, host.y * size.height);
      for (final String neighborId in host.neighbors) {
        final HostNode? neighbor = byId[neighborId];
        if (neighbor == null || host.id.compareTo(neighbor.id) > 0) {
          continue;
        }
        final Offset b = Offset(
          neighbor.x * size.width,
          neighbor.y * size.height,
        );
        final bool active =
            host.id == selectedHostId || neighbor.id == selectedHostId;
        paint.color = active
            ? _cCyan.withValues(alpha: .40)
            : _rgba(255, 255, 255, .10);
        canvas.drawLine(a, b, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) {
    return oldDelegate.selectedHostId != selectedHostId ||
        oldDelegate.hosts != hosts;
  }
}

class _IntroGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = _rgba(6, 182, 212, .055)
      ..strokeWidth = 1;

    const double gap = 36;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final Paint glow = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[_cPink.withValues(alpha: .18), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .72, size.height * .35),
              radius: math.min(size.width, size.height) * .45,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IntroNetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final List<Offset> points = <Offset>[
      Offset(size.width * .18, size.height * .30),
      Offset(size.width * .52, size.height * .28),
      Offset(size.width * .80, size.height * .22),
      Offset(size.width * .50, size.height * .70),
      Offset(size.width * .20, size.height * .74),
    ];

    final Paint line = Paint()
      ..color = _rgba(255, 255, 255, .16)
      ..strokeWidth = 1.4;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], line);
    }

    for (int i = 0; i < points.length; i++) {
      final bool infected = i < 2;
      final Color color = infected ? _cPink : _cCyan;
      canvas.drawCircle(
        points[i],
        infected ? 13 : 10,
        Paint()..color = color.withValues(alpha: .20),
      );
      canvas.drawCircle(points[i], infected ? 7 : 5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _statusColor(HostStatus status) {
  switch (status) {
    case HostStatus.healthy:
      return _cGreen;
    case HostStatus.suspicious:
      return _cAmber;
    case HostStatus.encrypting:
      return _cPink;
    case HostStatus.isolated:
      return _cCyan;
    case HostStatus.cleaned:
      return _cPurple;
    case HostStatus.restored:
      return _cBlue;
  }
}

IconData _statusIcon(HostStatus status) {
  switch (status) {
    case HostStatus.healthy:
      return Icons.check_circle_rounded;
    case HostStatus.suspicious:
      return Icons.report_problem_rounded;
    case HostStatus.encrypting:
      return Icons.lock_rounded;
    case HostStatus.isolated:
      return Icons.link_off_rounded;
    case HostStatus.cleaned:
      return Icons.cleaning_services_rounded;
    case HostStatus.restored:
      return Icons.restore_rounded;
  }
}

Color _eventColor(String severity) {
  switch (severity) {
    case 'ALERT':
    case 'FAIL':
      return _cPink;
    case 'WARN':
      return _cAmber;
    case 'PHISH':
    case 'RECON':
    case 'SMB':
    case 'PERM':
    case 'STAGE':
    case 'STEALTH':
      return _cPurple;
    case 'DETECT':
    case 'IMPACT':
      return _cPink;
    case 'OK':
    case 'CLEAN':
    case 'RESTORE':
      return _cGreen;
    case 'EDR':
    case 'NET':
    case 'SOC':
      return _cCyan;
    default:
      return _cPurple;
  }
}

Color _rgba(int r, int g, int b, double opacity) {
  return Color.fromRGBO(r, g, b, opacity);
}

const String _uiFont = 'Segoe UI';
const String _monoFont = 'Consolas';
const List<String> _monoFallback = <String>['Courier New', 'monospace'];

const Color _cRoot = Color(0xFF050510);
const Color _cCyberBar = Color(0xFF0A0A20);
const Color _cPanel = Color(0xFF0D0D1F);
const Color _cCyan = AppColors.cyan;
const Color _cPurple = AppColors.purple;
const Color _cPink = AppColors.pink;
const Color _cBlue = AppColors.blue;
const Color _cGreen = Color(0xFF1D9E75);
const Color _cAmber = Color(0xFFF59E0B);
