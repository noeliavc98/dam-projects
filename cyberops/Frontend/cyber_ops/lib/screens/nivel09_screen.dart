import 'dart:async';
import 'package:cyber_ops/widgets/fractura/fractura_dialogo.dart';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_routes.dart';
import '../games/nivel_09/nivel09_game.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';
import 'level_map_screen.dart';

class Nivel09Screen extends StatefulWidget {
  const Nivel09Screen({
    super.key,
    this.onPatchHelp,
    this.soloEntrenamiento = false,
  });

  final ValueChanged<String>? onPatchHelp;
  final bool soloEntrenamiento;

  @override
  State<Nivel09Screen> createState() => _Nivel09ScreenState();
}

class _Nivel09ScreenState extends State<Nivel09Screen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _siteScrollController = ScrollController();

  Nivel09Game _game = Nivel09Game();
  bool _cargando = true;
  bool _nivelYaCompletado = false;
  bool _resultadoMostrado = false;
  int _mobileIndex = 1;

  // ── FRACTURA ──────────────────────────────────────────────────────────────
  bool _mostrarFractura = true;
  final List<String> _dialogosFractura = [
    'Los navegadores confían en el código que reciben. Es su trabajo ejecutarlo.',
    'XSS explota esa confianza. Inyectas script en una web y el navegador de la víctima lo ejecuta sin saberlo.',
    'Puedes robar cookies de sesión, redirigir usuarios, capturar teclado... todo desde el navegador.',
    'La web no fue hackeada. Solo mostró lo que alguien introdujo sin filtrarlo.',
    'Hoy vas a ver exactamente cómo se inyecta, y por qué es tan difícil de detectar.',
  ];


  @override
  void initState() {
    super.initState();
    _iniciarJuego();
  }

  List<StepXSS> get _steps => Nivel09Game.steps;
  List<ChipXSS> get _chips => Nivel09Game.chips;
  List<ComentarioForo> get _comments => _game.comentarios;
  Set<int> get _doneChips => _game.chipsCompletados;
  int get _currentStep => _game.stepActual;
  int get _pts => _game.puntos;
  int get _vidas => _game.vidas;
  bool get _waitingForNext => _game.esperandoSiguiente;
  bool get _dead => _game.juegoTerminado;
  ResultadoIntento? get _lastResult => _game.ultimoResultado;
  int get _safeStepIndex => _currentStep.clamp(0, _steps.length - 1).toInt();

  Future<void> _iniciarJuego() async {
    if (widget.soloEntrenamiento) {
      _nivelYaCompletado = true;
    } else {
      try {
        final Map<String, dynamic> datos =
            await FirestoreService.obtenerUsuario();
        final int nivelUsuario = (datos['nivel'] as num?)?.toInt() ?? 1;
        if (nivelUsuario > 9) {
          _nivelYaCompletado = true;
        }
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }

    unawaited(MusicService().playNiveles6to10Music());
    setState(() {
      _cargando = false;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _siteScrollController.dispose();
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
            subtitulo: 'NIVEL 9 // XSS ATTACK',
            textoBotonFinal: 'JUGAR',
            usarVoz: true,
            permitirSaltarIntro: true,
            permitirCambiarVoz: true,
            velocidadVoz: 0.66,
            milisegundosPorCaracter: 18,
            onFinalizado: () async {
              setState(() {
                _mostrarFractura = false;
                _cargando = true;
              });

              await _iniciarJuego();
            },
          ),
        ),
      );
    }
    if (_cargando) {
      return const Scaffold(
        backgroundColor: _cRoot,
        body: Center(child: CircularProgressIndicator(color: _cCyan)),
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

  Widget _buildCyberBar() {
    final StepXSS current = _steps[_safeStepIndex];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 680;
        final Widget title = const Text(
          'CYBEROPS // NV.09 // XSS ATTACK',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _cCyan,
            fontFamily: _monoFont,
            fontFamilyFallback: _monoFallback,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: _cCyberBar,
            border: Border(
              bottom: BorderSide(color: _rgba(108, 99, 255, .25), width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: compact
              ? Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _buildBackButton(),
                        const SizedBox(width: 8),
                        Expanded(child: title),
                        const SizedBox(width: 8),
                        _buildPointsBadge(),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: <Widget>[
                        Expanded(child: _buildAddressBar(current)),
                        const SizedBox(width: 8),
                        _buildLivesRow(),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: <Widget>[
                    _buildBackButton(),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: title,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildAddressBar(current)),
                    const SizedBox(width: 10),
                    _buildLivesRow(),
                    const SizedBox(width: 8),
                    _buildPointsBadge(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBackButton() {
    return Tooltip(
      message: 'Volver al mapa',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _volverAlMapa,
          child: Container(
            width: 28,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _rgba(255, 255, 255, .05),
              border: Border.all(color: _rgba(6, 182, 212, .35)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _cCyan,
              size: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressBar(StepXSS current) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _rgba(255, 255, 255, .05),
        border: Border.all(color: _rgba(255, 255, 255, .10)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'https://${current.url}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _rgba(255, 255, 255, .40),
          fontFamily: _monoFont,
          fontFamilyFallback: _monoFallback,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildLivesRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(3, (int index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Icon(
            Icons.favorite_rounded,
            color: index < _vidas ? _cPink : _rgba(236, 72, 153, .18),
            size: 13,
          ),
        );
      }),
    );
  }

  Widget _buildPointsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: _rgba(108, 99, 255, .20),
        border: Border.all(color: _rgba(108, 99, 255, .40)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$_pts PTS',
        style: const TextStyle(
          color: Color(0xFFA89FFF),
          fontFamily: _monoFont,
          fontFamilyFallback: _monoFallback,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  void _volverAlMapa() {
    Navigator.pushAndRemoveUntil(
      context,
      AppRoutes.fade(const LevelMapScreen()),
      (Route<dynamic> route) => route.settings.name == 'menu',
    );
  }

  Widget _buildProgressBar() {
    final double progress = (_currentStep / _steps.length)
        .clamp(0.0, 1.0)
        .toDouble();

    return Container(
      height: 2,
      color: _rgba(255, 255, 255, .05),
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: progress),
        duration: const Duration(milliseconds: 500),
        builder: (BuildContext context, double value, Widget? child) {
          return FractionallySizedBox(
            widthFactor: value,
            child: Container(height: 2, color: _cBlue),
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
              'MODO ENTRENAMIENTO — Puntuación no se guardará',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _rgba(168, 159, 255, .90),
                fontFamily: _monoFont,
                fontFamilyFallback: _monoFallback,
                fontSize: 10,
                letterSpacing: 2,
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
        if (constraints.maxWidth >= 900) {
          return Column(
            children: <Widget>[
              Expanded(child: _buildLayout()),
              _buildArsenalBar(),
            ],
          );
        }

        if (constraints.maxWidth >= 640) {
          final double sidebarHeight = (constraints.maxHeight * .34)
              .clamp(150.0, 230.0)
              .toDouble();
          return Column(
            children: <Widget>[
              SizedBox(height: sidebarHeight, child: _buildSidebar()),
              Expanded(child: _buildBrowserPane()),
              _buildArsenalBar(),
            ],
          );
        }

        return Column(
          children: <Widget>[
            Expanded(
              child: IndexedStack(
                index: _mobileIndex,
                children: <Widget>[
                  _buildSidebar(),
                  _buildBrowserPane(),
                  _buildArsenalPanel(),
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
                  icon: Icon(Icons.flag_outlined),
                  selectedIcon: Icon(Icons.flag_rounded),
                  label: 'Objetivos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.language_outlined),
                  selectedIcon: Icon(Icons.language_rounded),
                  label: 'Portal',
                ),
                NavigationDestination(
                  icon: Icon(Icons.code_outlined),
                  selectedIcon: Icon(Icons.code_rounded),
                  label: 'Arsenal',
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildBrowserPane() {
    return Column(
      children: <Widget>[
        _buildWindowChrome(),
        Expanded(child: _buildSiteWrap()),
      ],
    );
  }

  Widget _buildLayout() {
    return Row(
      children: <Widget>[
        SizedBox(width: 185, child: _buildSidebar()),
        Expanded(child: _buildBrowserPane()),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: _cSidebar,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(bottom: 6),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _rgba(255, 255, 255, .05)),
              ),
            ),
            child: Text(
              'OBJETIVOS',
              style: TextStyle(
                color: _rgba(255, 255, 255, .25),
                fontFamily: _monoFont,
                fontFamilyFallback: _monoFallback,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List<Widget>.generate(_steps.length, (int index) {
                  return _buildSidebarItem(_steps[index], index);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(StepXSS step, int index) {
    final _StepStatus status = index < _currentStep
        ? _StepStatus.done
        : index == _currentStep
        ? _StepStatus.active
        : _StepStatus.locked;

    Color background = Colors.transparent;
    Color border = Colors.transparent;
    Color pointsColor = _rgba(255, 255, 255, .15);
    String pointsText = '???';
    double opacity = 1;

    if (status == _StepStatus.done) {
      background = _rgba(29, 158, 117, .09);
      border = _rgba(29, 158, 117, .25);
      pointsColor = _cGreen;
      pointsText = '✓ +${step.pts} pts';
    } else if (status == _StepStatus.active) {
      background = _rgba(0, 120, 212, .10);
      border = _rgba(0, 120, 212, .40);
      pointsColor = _cBlue;
      pointsText = '+${step.pts} pts';
    } else {
      opacity = .22;
    }

    return Opacity(
      opacity: opacity,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '0${index + 1}',
              style: TextStyle(
                color: _rgba(255, 255, 255, .25),
                fontFamily: _monoFont,
                fontFamilyFallback: _monoFallback,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              step.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: _uiFont,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              pointsText,
              style: TextStyle(
                color: pointsColor,
                fontFamily: _monoFont,
                fontFamilyFallback: _monoFallback,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowChrome() {
    final StepXSS current = _steps[_safeStepIndex];

    return Container(
      color: _cWinChrome,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 32,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Row(
                      children: <Widget>[
                        _buildWindowsLogo(16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Internet Explorer — SecureNet Intranet Portal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _rgba(255, 255, 255, .70),
                              fontFamily: _uiFont,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: const <Widget>[
                    _WindowButton(label: '–'),
                    _WindowButton(label: '□'),
                    _WindowButton(label: '✕', close: true),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _MenuItem('Archivo'),
                  _MenuItem('Edición'),
                  _MenuItem('Ver'),
                  _MenuItem('Favoritos'),
                  _MenuItem('Herramientas'),
                  _MenuItem('Ayuda'),
                ],
              ),
            ),
          ),
          Container(
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(bottom: BorderSide(color: Color(0xFF111111))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: <Widget>[
                const _AddressButton('←'),
                const SizedBox(width: 6),
                const _AddressButton('→'),
                const SizedBox(width: 6),
                const _AddressButton('✕'),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 22,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      border: Border.all(color: _rgba(0, 120, 212, .40)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'https://${current.url}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFA0C4FF),
                        fontFamily: _monoFont,
                        fontFamilyFallback: _monoFallback,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const _AddressButton('↻'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteWrap() {
    final StepXSS current = _steps[_safeStepIndex];

    return Container(
      color: const Color(0xFFF3F3F3),
      child: Column(
        children: <Widget>[
          _buildSiteHeader(),
          _buildBreadcrumb(current),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 520;
                return SingleChildScrollView(
                  controller: _siteScrollController,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 18,
                      vertical: compact ? 10 : 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _buildSiteBody(),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildSiteHeader() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool showNavigation = constraints.maxWidth >= 820;

        return Container(
          color: _cBlue,
          padding: EdgeInsets.symmetric(
            horizontal: showNavigation ? 18 : 12,
            vertical: 10,
          ),
          child: Row(
            children: <Widget>[
              _buildWindowsLogo(20),
              const SizedBox(width: 8),
              const Text(
                'SecureNet',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: _uiFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  showNavigation
                      ? 'Portal de Intranet Corporativa'
                      : 'Intranet Corporativa',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _rgba(255, 255, 255, .60),
                    fontFamily: _uiFont,
                    fontSize: 10,
                  ),
                ),
              ),
              if (showNavigation) ...const <Widget>[
                Spacer(),
                _SiteNavItem('Inicio', selected: true),
                _SiteNavItem('Foro'),
                _SiteNavItem('Usuarios'),
                _SiteNavItem('Admin'),
                _SiteNavItem('Soporte técnico'),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreadcrumb(StepXSS current) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFE8E8E8),
        border: Border(bottom: BorderSide(color: Color(0xFFD0D0D0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Text(
        _decodeHtml(current.bread),
        style: const TextStyle(
          color: Color(0xFF555555),
          fontFamily: _uiFont,
          fontSize: 11,
        ),
      ),
    );
  }

  List<Widget> _buildSiteBody() {
    if (_dead) {
      return <Widget>[_buildDeadView()];
    }

    if (_currentStep >= _steps.length) {
      return <Widget>[_buildVictoryView()];
    }

    final StepXSS current = _steps[_currentStep];
    final List<Widget> body = <Widget>[
      _buildHintBox(current.hint),
      const SizedBox(height: 11),
      _buildTheoryBox(current.theory),
    ];

    if (_lastResult != null) {
      body
        ..add(const SizedBox(height: 11))
        ..add(_buildFeedbackBox(_lastResult!));
    }

    body
      ..add(const SizedBox(height: 11))
      ..add(_buildCommentsPanel());

    if (_waitingForNext) {
      body
        ..add(const SizedBox(height: 11))
        ..add(
          Align(
            alignment: Alignment.centerLeft,
            child: _ActionButton(
              label: 'Siguiente objetivo ›',
              background: _cGreenDark,
              foreground: Colors.white,
              border: Colors.transparent,
              horizontalPadding: 20,
              onPressed: () {
                setState(() {
                  _game.avanzarSiguiente();
                });
              },
            ),
          ),
        );
    } else {
      body
        ..add(const SizedBox(height: 11))
        ..add(_buildFormArea());
    }

    return body;
  }

  Widget _buildHintBox(String html) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        border: Border.all(color: const Color(0xFFF0A000)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(width: 4, color: const Color(0xFFF0A000)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: _HtmlText(
                  html,
                  baseStyle: const TextStyle(
                    color: Color(0xFF4A3000),
                    fontFamily: _uiFont,
                    fontSize: 11,
                    height: 1.75,
                  ),
                  boldStyle: const TextStyle(
                    color: Color(0xFFB35C00),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  codeStyle: TextStyle(
                    color: const Color(0xFFAA0000),
                    backgroundColor: _rgba(180, 0, 0, .08),
                    fontFamily: _monoFont,
                    fontFamilyFallback: _monoFallback,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTheoryBox(String html) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC8D8F8)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FE),
              border: Border(bottom: BorderSide(color: Color(0xFFC8D8F8))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: const Text(
              'Contexto técnico',
              style: TextStyle(
                color: Color(0xFF1A3A8A),
                fontFamily: _uiFont,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _HtmlText(
              html,
              baseStyle: const TextStyle(
                color: Color(0xFF333333),
                fontFamily: _uiFont,
                fontSize: 12,
                height: 1.75,
              ),
              boldStyle: const TextStyle(
                color: _cBlue,
                fontWeight: FontWeight.w700,
              ),
              codeStyle: const TextStyle(
                color: Color(0xFFAA0000),
                backgroundColor: Color(0xFFF0F0F0),
                fontFamily: _monoFont,
                fontFamilyFallback: _monoFallback,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBox(ResultadoIntento result) {
    final Color background = result.ok
        ? const Color(0xFFDFF6DD)
        : const Color(0xFFFDE7E9);
    final Color accent = result.ok ? _cGreenDark : _cRed;
    final Color text = result.ok
        ? const Color(0xFF0A3A0A)
        : const Color(0xFF4A0A0A);

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(3),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${result.ok ? '✓' : '✗'} ${result.title}',
                      style: TextStyle(
                        color: accent,
                        fontFamily: _uiFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _HtmlText(
                      result.why,
                      baseStyle: TextStyle(
                        color: text,
                        fontFamily: _uiFont,
                        fontSize: 12,
                        height: 1.7,
                      ),
                      boldStyle: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                      codeStyle: TextStyle(
                        color: const Color(0xFFAA0000),
                        backgroundColor: _rgba(255, 255, 255, .45),
                        fontFamily: _monoFont,
                        fontFamilyFallback: _monoFallback,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD0D0D0)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF0F0F0),
              border: Border(bottom: BorderSide(color: Color(0xFFD0D0D0))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: <Widget>[
                Container(
                  width: 14,
                  height: 14,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _cBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'F',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: _uiFont,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Foro corporativo — Hilo general',
                  style: TextStyle(
                    color: Color(0xFF222222),
                    fontFamily: _uiFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...List<Widget>.generate(_comments.length, (int index) {
            return _buildCommentItem(
              _comments[index],
              index == _comments.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCommentItem(ComentarioForo comment, bool last) {
    final bool xss = _hasXss(comment.text);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: comment.avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  comment.avatar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: _uiFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  comment.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontFamily: _uiFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                comment.time,
                style: const TextStyle(
                  color: Color(0xFF999999),
                  fontFamily: _uiFont,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Container(
              padding: xss
                  ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
                  : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: xss ? const Color(0xFFFFF0F0) : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                xss
                    ? '[CÓDIGO EJECUTADO EN NAVEGADOR] ${comment.text}'
                    : comment.text,
                style: TextStyle(
                  color: xss ? _cRed : const Color(0xFF333333),
                  fontFamily: xss ? _monoFont : _uiFont,
                  fontFamilyFallback: xss ? _monoFallback : null,
                  fontSize: xss ? 11 : 12,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD0D0D0)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF0F0F0),
              border: Border(bottom: BorderSide(color: Color(0xFFD0D0D0))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Text(
              'Publicar nuevo comentario',
              style: TextStyle(
                color: Color(0xFF222222),
                fontFamily: _uiFont,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Escribe tu mensaje o inserta un payload del arsenal:',
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontFamily: _uiFont,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _inputController,
                  minLines: 3,
                  maxLines: 3,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontFamily: _monoFont,
                    fontFamilyFallback: _monoFallback,
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Escribe aquí...',
                    hintStyle: TextStyle(
                      color: _rgba(34, 34, 34, .45),
                      fontFamily: _monoFont,
                      fontFamilyFallback: _monoFallback,
                      fontSize: 12,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: const BorderSide(color: Color(0xFFAAAAAA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: const BorderSide(color: _cBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _ActionButton(
                      label: 'Publicar',
                      background: _cBlue,
                      foreground: Colors.white,
                      border: Colors.transparent,
                      horizontalPadding: 22,
                      onPressed: _submitComment,
                    ),
                    _ActionButton(
                      label: 'Limpiar',
                      background: const Color(0xFFF0F0F0),
                      foreground: const Color(0xFF444444),
                      border: const Color(0xFFAAAAAA),
                      horizontalPadding: 14,
                      onPressed: _inputController.clear,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      color: _cBlue,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Row(
        children: <Widget>[
          _StatusItem(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7FBA00),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Flexible(
                  child: Text(
                    'Conectado a win-intranet.securenet.local',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const _StatusItem(text: 'Zona: Intranet local'),
          const SizedBox(width: 16),
          const _StatusItem(text: r'Usuario: CORP\invitado'),
        ],
      ),
    );
  }

  Widget _buildArsenalBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF08081A),
        border: Border(top: BorderSide(color: _rgba(108, 99, 255, .15))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'ARSENAL:',
              style: TextStyle(
                color: _rgba(255, 255, 255, .25),
                fontFamily: _monoFont,
                fontFamilyFallback: _monoFallback,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List<Widget>.generate(_chips.length, (int index) {
                final bool done = _doneChips.contains(index);
                final bool current =
                    index == _currentStep &&
                    !done &&
                    _currentStep < _steps.length &&
                    !_dead;
                return _PayloadChip(
                  label: done
                      ? '✓ ${_chips[index].label}'
                      : _chips[index].label,
                  done: done,
                  current: current,
                  onTap: current
                      ? () {
                          _inputController.text = _chips[index].code;
                          _inputController
                              .selection = TextSelection.fromPosition(
                            TextPosition(offset: _inputController.text.length),
                          );
                        }
                      : null,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArsenalPanel() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF08081A),
        border: Border(top: BorderSide(color: _rgba(108, 99, 255, .15))),
      ),
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'ARSENAL:',
              style: TextStyle(
                color: _rgba(255, 255, 255, .25),
                fontFamily: _monoFont,
                fontFamilyFallback: _monoFallback,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List<Widget>.generate(_chips.length, (int index) {
                final bool done = _doneChips.contains(index);
                final bool current =
                    index == _currentStep &&
                    !done &&
                    _currentStep < _steps.length &&
                    !_dead;
                return _PayloadChip(
                  label: done
                      ? 'OK ${_chips[index].label}'
                      : _chips[index].label,
                  done: done,
                  current: current,
                  onTap: current
                      ? () {
                          _inputController.text = _chips[index].code;
                          _inputController
                              .selection = TextSelection.fromPosition(
                            TextPosition(offset: _inputController.text.length),
                          );
                          setState(() => _mobileIndex = 1);
                        }
                      : null,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVictoryView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'SISTEMA COMPROMETIDO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _cCyan,
              fontFamily: _uiFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Has completado los 8 vectores XSS del portal Windows SecureNet.\n'
            'Reconocimiento · HTML injection · Reflected XSS · Event handlers · '
            'Cookie theft · Bypass de filtro · Stored XSS · Exfiltración con fetch()',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _rgba(255, 255, 255, .50),
              fontFamily: _uiFont,
              fontSize: 12,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_pts PTS',
            style: const TextStyle(
              color: Color(0xFF6C63FF),
              fontFamily: _monoFont,
              fontFamilyFallback: _monoFallback,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: '¿Cómo se parchea en Windows Server? ↗',
            background: _cBlue,
            foreground: Colors.white,
            border: Colors.transparent,
            horizontalPadding: 24,
            verticalPadding: 10,
            onPressed: () {
              widget.onPatchHelp?.call(
                'Completé el nivel XSS de CyberOps atacando un portal Windows. '
                '¿Cómo configura IIS y Windows Server las cabeceras '
                'Content-Security-Policy para defenderse?',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeadView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'DETECTADO POR WINDOWS DEFENDER ATP',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _cRed,
              fontFamily: _uiFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Demasiados intentos fallidos han generado una alerta en el SIEM corporativo.\n'
            'El equipo de respuesta a incidentes ha bloqueado tu sesión.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _rgba(255, 255, 255, .55),
              fontFamily: _uiFont,
              fontSize: 12,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_pts PTS',
            style: const TextStyle(
              color: _cRed,
              fontFamily: _monoFont,
              fontFamilyFallback: _monoFallback,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Reintentar misión',
            background: _cRed,
            foreground: Colors.white,
            border: Colors.transparent,
            horizontalPadding: 24,
            verticalPadding: 10,
            onPressed: _restartMission,
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsLogo(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: GridView.count(
        padding: EdgeInsets.zero,
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        physics: const NeverScrollableScrollPhysics(),
        children: const <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFF25022),
              borderRadius: BorderRadius.all(Radius.circular(1)),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFF7FBA00),
              borderRadius: BorderRadius.all(Radius.circular(1)),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFF00A4EF),
              borderRadius: BorderRadius.all(Radius.circular(1)),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFFFB900),
              borderRadius: BorderRadius.all(Radius.circular(1)),
            ),
          ),
        ],
      ),
    );
  }

  void _submitComment() {
    final String value = _inputController.text.trim();
    if (value.isEmpty || _currentStep >= _steps.length || _dead) {
      return;
    }

    setState(() {
      _game.publicarComentario(value);
      _inputController.clear();
    });

    if (_game.nivelCompletado) {
      _mostrarVictoria();
    } else if (_game.juegoTerminado) {
      _mostrarGameOver();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_siteScrollController.hasClients) {
        return;
      }
      _siteScrollController.animateTo(
        _siteScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _mostrarVictoria() async {
    if (_resultadoMostrado) {
      return;
    }

    _resultadoMostrado = true;

    if (!_nivelYaCompletado) {
      await FirestoreService.guardarPuntuacion(
        puntos: _game.puntos,
        nivelCompletado: 9,
      );
      await FirestoreService.guardarMision(
        nivel: 9,
        mision: 9,
        puntos: _game.puntos,
      );
    }

    if (!mounted) {
      return;
    }

    _mostrarDialogoResultado(
      titulo: 'SISTEMA COMPROMETIDO',
      subtitulo: _nivelYaCompletado
          ? 'Modo entrenamiento'
          : 'Exfiltración completada con éxito',
      exito: true,
    );
  }

  void _mostrarGameOver() {
    if (_resultadoMostrado || !mounted) {
      return;
    }

    _resultadoMostrado = true;
    _mostrarDialogoResultado(
      titulo: 'MISIÓN FALLIDA',
      subtitulo: 'Detectado por Windows Defender ATP',
      exito: false,
    );
  }

  void _mostrarDialogoResultado({
    required String titulo,
    required String subtitulo,
    required bool exito,
  }) {
    final BuildContext screenContext = context;
    showDialog<void>(
      context: screenContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => _DialogoResultadoNivel09(
        titulo: titulo,
        subtitulo: subtitulo,
        puntos: _game.puntos,
        exito: exito,
        nivelYaCompletado: _nivelYaCompletado,
        onReintentar: () {
          Navigator.pop(dialogContext);
          Navigator.pushReplacement(
            screenContext,
            MaterialPageRoute<void>(
              builder: (_) => Nivel09Screen(
                soloEntrenamiento: widget.soloEntrenamiento,
                onPatchHelp: widget.onPatchHelp,
              ),
            ),
          );
        },
        onSalir: () {
          Navigator.pop(dialogContext);
          if (exito) {
            Navigator.pushAndRemoveUntil(
              screenContext,
              AppRoutes.fade(LevelMapScreen()),
              (Route<dynamic> route) => route.settings.name == 'menu',
            );
          } else {
            Navigator.pop(screenContext);
          }
        },
      ),
    );
  }

  void _restartMission() {
    setState(() {
      _game = Nivel09Game();
      _resultadoMostrado = false;
      _inputController.clear();
    });
  }
}

class _DialogoResultadoNivel09 extends StatelessWidget {
  const _DialogoResultadoNivel09({
    required this.titulo,
    required this.subtitulo,
    required this.puntos,
    required this.exito,
    required this.nivelYaCompletado,
    required this.onReintentar,
    required this.onSalir,
  });

  final String titulo;
  final String subtitulo;
  final int puntos;
  final bool exito;
  final bool nivelYaCompletado;
  final VoidCallback onReintentar;
  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context) {
    final Color color = exito ? AppColors.cyan : AppColors.pink;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.bgMain,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .50)),
          boxShadow: <BoxShadow>[
            BoxShadow(color: color.withValues(alpha: .20), blurRadius: 30),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              exito ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: color,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .50),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$puntos PUNTOS',
              style: const TextStyle(
                color: AppColors.purple,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            if (nivelYaCompletado && exito) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: .30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.purple.withValues(alpha: .70),
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Modo entrenamiento - puntos no guardados',
                        style: TextStyle(
                          color: AppColors.purple.withValues(alpha: .70),
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onReintentar,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.purple.withValues(alpha: .50),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'REINTENTAR',
                  style: TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSalir,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  exito ? 'CONTINUAR' : 'SALIR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
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

class _HtmlText extends StatelessWidget {
  const _HtmlText(
    this.html, {
    required this.baseStyle,
    required this.boldStyle,
    required this.codeStyle,
  });

  final String html;
  final TextStyle baseStyle;
  final TextStyle boldStyle;
  final TextStyle codeStyle;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(style: baseStyle, children: _parseHtml()),
    );
  }

  List<InlineSpan> _parseHtml() {
    if (!RegExp(r'<br\s*\/?>', caseSensitive: false).hasMatch(html) &&
        html.contains('\n\n')) {
      final int split = html.indexOf('\n\n');
      return <InlineSpan>[
        TextSpan(text: _decodeHtml(html.substring(0, split)), style: boldStyle),
        const TextSpan(text: '\n\n'),
        TextSpan(
          text: _decodeHtml(html.substring(split + 2)),
          style: baseStyle,
        ),
      ];
    }

    final List<InlineSpan> spans = <InlineSpan>[];
    final RegExp token = RegExp(r'(<br\s*\/?>)', caseSensitive: false);
    int cursor = 0;
    bool bold = false;
    bool code = false;

    for (final RegExpMatch match in token.allMatches(html)) {
      if (match.start > cursor) {
        spans.add(_span(html.substring(cursor, match.start), bold, code));
      }

      final String tag = match.group(0)!.toLowerCase();
      if (tag.startsWith('<br')) {
        spans.add(const TextSpan(text: '\n'));
      }

      cursor = match.end;
    }

    if (cursor < html.length) {
      spans.add(_span(html.substring(cursor), bold, code));
    }

    return spans;
  }

  TextSpan _span(String raw, bool bold, bool code) {
    TextStyle style = baseStyle;
    if (bold) {
      style = style.merge(boldStyle);
    }
    if (code) {
      style = style.merge(codeStyle);
    }

    return TextSpan(text: _decodeHtml(raw), style: style);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
    required this.onPressed,
    this.horizontalPadding = 16,
    this.verticalPadding = 8,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color border;
  final VoidCallback? onPressed;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: verticalPadding * 2 + 16,
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: WidgetStateProperty.all(Size.zero),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.hovered)) {
              if (background == _cBlue) {
                return const Color(0xFF005A9E);
              }
              if (background == _cGreenDark) {
                return const Color(0xFF0A5C0A);
              }
              if (background == const Color(0xFFF0F0F0)) {
                return const Color(0xFFE0E0E0);
              }
            }
            return background;
          }),
          foregroundColor: WidgetStateProperty.all(foreground),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
              side: BorderSide(color: border),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: _uiFont,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _PayloadChip extends StatelessWidget {
  const _PayloadChip({
    required this.label,
    required this.done,
    required this.current,
    required this.onTap,
  });

  final String label;
  final bool done;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color background = _rgba(255, 255, 255, .06);
    Color border = _rgba(255, 255, 255, .15);
    Color text = _rgba(255, 255, 255, .40);

    if (done) {
      background = _rgba(29, 158, 117, .08);
      border = _rgba(29, 158, 117, .28);
      text = _cGreen;
    } else if (current) {
      background = _rgba(236, 72, 153, .12);
      border = _rgba(236, 72, 153, .45);
      text = _cPink;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontFamily: _monoFont,
            fontFamilyFallback: _monoFallback,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({required this.label, this.close = false});

  final String label;
  final bool close;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 32,
      child: TextButton(
        onPressed: () {},
        style: ButtonStyle(
          padding: WidgetStateProperty.all(EdgeInsets.zero),
          minimumSize: WidgetStateProperty.all(Size.zero),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: WidgetStateProperty.resolveWith((
            Set<WidgetState> states,
          ) {
            if (close && states.contains(WidgetState.hovered)) {
              return Colors.white;
            }
            return _rgba(255, 255, 255, .60);
          }),
          backgroundColor: WidgetStateProperty.resolveWith((
            Set<WidgetState> states,
          ) {
            if (close && states.contains(WidgetState.hovered)) {
              return _cRed;
            }
            if (states.contains(WidgetState.hovered)) {
              return _rgba(255, 255, 255, .10);
            }
            return Colors.transparent;
          }),
          shape: WidgetStateProperty.all(const RoundedRectangleBorder()),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontFamily: _uiFont, fontSize: 11),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _AddressButton extends StatelessWidget {
  const _AddressButton(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _rgba(255, 255, 255, .05),
        border: Border.all(color: _rgba(255, 255, 255, .10)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _rgba(255, 255, 255, .50),
          fontFamily: _uiFont,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        label,
        style: TextStyle(
          color: _rgba(255, 255, 255, .70),
          fontFamily: _uiFont,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SiteNavItem extends StatelessWidget {
  const _SiteNavItem(this.label, {this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? _rgba(255, 255, 255, .20) : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _rgba(255, 255, 255, .75),
          fontFamily: _uiFont,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({this.text, this.child});

  final String? text;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: DefaultTextStyle(
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _rgba(255, 255, 255, .85),
          fontFamily: _uiFont,
          fontSize: 10,
        ),
        child: child ?? Text(text ?? ''),
      ),
    );
  }
}

enum _StepStatus { done, active, locked }

const String _uiFont = 'Segoe UI';
const String _monoFont = 'Consolas';
const List<String> _monoFallback = <String>['Courier New', 'monospace'];

const Color _cRoot = Color(0xFF050510);
const Color _cCyberBar = Color(0xFF0A0A20);
const Color _cSidebar = Color(0xFF070718);
const Color _cWinChrome = Color(0xFF202020);
const Color _cBlue = Color(0xFF0078D4);
const Color _cCyan = Color(0xFF06B6D4);
const Color _cPink = Color(0xFFEC4899);
const Color _cGreen = Color(0xFF1D9E75);
const Color _cGreenDark = Color(0xFF107C10);
const Color _cRed = Color(0xFFC42B1C);

Color _rgba(int r, int g, int b, double opacity) {
  return Color.fromRGBO(r, g, b, opacity);
}

String _decodeHtml(String value) {
  return value
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&');
}

bool _hasXss(String text) {
  return RegExp(
    r'<script|onerror|onload|fetch',
    caseSensitive: false,
  ).hasMatch(text);
}

extension _StepXssScreenAccess on StepXSS {
  String get name => nombre;
  String get bread => breadcrumb;
  String get theory => teoria;
}

extension _ChipXssScreenAccess on ChipXSS {
  String get label => etiqueta;
  String get code => codigo;
}

extension _ComentarioForoScreenAccess on ComentarioForo {
  String get author => autor;
  String get avatar => avatarLetras;
  String get text => texto;
  String get time => hora;

  Color get avatarColor {
    switch (avatarTipo) {
      case 'sys':
        return _cGreenDark;
      case 'adm':
        return _cBlue;
      case 'usr':
        return const Color(0xFF8764B8);
      case 'hack':
        return _cRed;
      default:
        return _cRed;
    }
  }
}

extension _ResultadoIntentoScreenAccess on ResultadoIntento {
  bool get ok => correcto;
  String get title => titulo;
  String get why => explicacion;
}
