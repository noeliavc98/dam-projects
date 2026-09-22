import 'package:cyber_ops/games/nivel_12/component/accion_respuesta.dart';
import 'package:cyber_ops/games/nivel_12/component/evidencia_digital.dart';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../games/nivel_12/data/sombra_digital_data.dart';
import '../games/nivel_12/nivel12_game.dart';
import '../services/music_service.dart';
import '../widgets/fractura/fractura_dialogo.dart';
import 'dart:async';

class Nivel12Screen extends StatefulWidget {
  final bool soloEntrenamiento;

  const Nivel12Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel12Screen> createState() => _Nivel12ScreenState();
}

enum _Nivel12Layout { mobile, tablet, desktop }

_Nivel12Layout _nivel12LayoutFor(double width) {
  if (width < 700) return _Nivel12Layout.mobile;
  if (width < 1100) return _Nivel12Layout.tablet;
  return _Nivel12Layout.desktop;
}

class _Nivel12ScreenState extends State<Nivel12Screen> {
  final Nivel12Game _game = Nivel12Game();

  CategoriaEvidenciaDigital _categoriaSeleccionada =
      CategoriaEvidenciaDigital.navegador;
  EvidenciaDigital? _evidenciaInspeccionada;

  // ── FRACTURA ──────────────────────────────────────────────────────────────
  bool _mostrarFractura = true;
  final List<String> _dialogosFractura = [
    'El equipo sigue funcionando. Nadie ha notado nada.',
    'Pero alguien lleva días dentro. Silencioso. Paciente.',
    'No destruye, no cifra, no deja mensajes. Solo observa y extrae.',
    'Cookies de sesión, tokens activos, credenciales en memoria. Todo viaja fuera sin hacer ruido.',
    'Tu trabajo es analizar el equipo infectado y encontrar las huellas que dejó.',
    'Busca lo que no debería estar ahí.',
    ];

  String? _avisoVisual;
  bool _avisoEsError = false;
  Timer? _glitchTimer;
  int _glitchTick = 0;

  String _mensaje =
      'Investiga el equipo y marca las evidencias que indiquen robo de datos.';

  @override
  void initState() {
    super.initState();
  }

  List<EvidenciaDigital> get _evidenciasFiltradas {
    return _game.evidencias
        .where((evidencia) => evidencia.categoria == _categoriaSeleccionada)
        .toList();
  }

  void _actualizarTimerGlitch() {
    if (_game.exposicion < 50) {
      _glitchTimer?.cancel();
      _glitchTimer = null;
      return;
    }

    if (_glitchTimer != null) return;

    _glitchTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() {
        _glitchTick++;
      });
    });
  }

  void _inspeccionarEvidencia(EvidenciaDigital evidencia) {
    setState(() {
      _evidenciaInspeccionada = evidencia;
      _mensaje = 'Elemento cargado para inspección: ${evidencia.titulo}';
    });
  }

  void _marcarEvidenciaInspeccionada() {
    final evidencia = _evidenciaInspeccionada;
    if (evidencia == null) {
      setState(() {
        _mensaje = 'Selecciona primero un elemento para investigarlo.';
      });
      return;
    }

    setState(() {
      _game.toggleEvidencia(evidencia);
      _mensaje = evidencia.explicacion;
    });
  }

  void _analizarStealer() {
    final exposicionAntes = _game.exposicion;

    setState(() {
      _mensaje = _game.analizarStealer();
      _actualizarTimerGlitch();
    });

    if (_game.fallido) {
      _mostrarAvisoVisual('EXFILTRACIÓN CRÍTICA', error: true);
      _mostrarGameOver();
      return;
    }

    if (_game.exposicion > exposicionAntes) {
      _mostrarAvisoVisual('COOKIE FILTRADA', error: true);
    } else if (_game.analisisCompleto) {
      _mostrarAvisoVisual('ANÁLISIS CORRECTO');
    }
  }

  void _mostrarAvisoVisual(String texto, {bool error = false}) {
    setState(() {
      _avisoVisual = texto;
      _avisoEsError = error;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;

      setState(() {
        _avisoVisual = null;
      });
    });
  }

  void _toggleAccion(AccionRespuesta accion) {
    setState(() {
      _game.toggleAccion(accion);
      _mensaje = accion.feedback;
    });
  }

  void _verificarRespuesta() {
    final exposicionAntes = _game.exposicion;

    setState(() {
      _mensaje = _game.verificarRespuesta();
      _actualizarTimerGlitch();
    });

    if (_game.completado) {
      _mostrarAvisoVisual(_game.logroOculto ? 'SOMBRA PURA' : 'FUGA CONTENIDA');
      _mostrarVictoria();
      return;
    }

    if (_game.fallido) {
      _mostrarAvisoVisual('SESIÓN COMPROMETIDA', error: true);
      _mostrarGameOver();
      return;
    }

    if (_game.exposicion > exposicionAntes) {
      _mostrarAvisoVisual('TOKEN EXPUESTO', error: true);
    }
  }

  void _mostrarGameOver() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogoResultadoNivel12(
        titulo: 'FUGA INCONTROLABLE',
        subtitulo: 'La exposición digital ha alcanzado el máximo',
        puntos: _game.xp,
        exposicion: _game.exposicion,
        exito: false,
        logroOculto: false,
        onReintentar: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  Nivel12Screen(soloEntrenamiento: widget.soloEntrenamiento),
            ),
          );
        },
        onSalir: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _mostrarVictoria() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogoResultadoNivel12(
        titulo: _game.logroOculto ? 'SOMBRA PURA' : 'FUGA CONTENIDA',
        subtitulo: _game.logroOculto
            ? 'Logro oculto desbloqueado: No dejes rastro'
            : 'Sesiones, tokens y credenciales han sido protegidos',
        puntos: _game.xp,
        exposicion: _game.exposicion,
        exito: true,
        logroOculto: _game.logroOculto,
        onReintentar: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  Nivel12Screen(soloEntrenamiento: widget.soloEntrenamiento),
            ),
          );
        },
        onSalir: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _corromperTexto(String texto) {
    if (_game.exposicion < 50) return texto;

    final Map<String, List<String>> reemplazos = {
      'a': ['4', '@'],
      'e': ['3'],
      'i': ['1', '!'],
      'o': ['0'],
      's': ['5', r'$'],
      't': ['7'],
      'b': ['8'],
    };

    final random = _glitchTick;

    String resultado = '';

    for (int i = 0; i < texto.length; i++) {
      final letra = texto[i];
      final lower = letra.toLowerCase();

      bool debeCorromper = false;

      if (_game.exposicion >= 50) {
        debeCorromper = (random + i) % 7 == 0;
      }

      if (_game.exposicion >= 75) {
        debeCorromper = (random + i) % 5 == 0;
      }

      if (_game.exposicion >= 90) {
        debeCorromper = (random + i) % 3 == 0;
      }

      if (debeCorromper && reemplazos.containsKey(lower)) {
        final opciones = reemplazos[lower]!;
        resultado += opciones[(random + i) % opciones.length];
      } else {
        resultado += letra;
      }
    }

    return resultado;
  }

  Widget _buildPhaseBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgMain.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timeline_rounded, color: AppColors.cyan, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'FASE ACTUAL: ${_game.faseActual.label}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemEvents() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.pink.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EVENTOS DEL SISTEMA',
            style: TextStyle(
              color: AppColors.pink.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          ..._game.eventosSistema.map(
            (evento) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.pink,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _corromperTexto(evento),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
            subtitulo: 'NIVEL 12 // SOMBRA DIGITAL',
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
              MusicService().playNiveles11to15Music();
              _verificarRespuesta();
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return switch (_nivel12LayoutFor(constraints.maxWidth)) {
                        _Nivel12Layout.mobile => _buildMobileLayout(
                          constraints,
                        ),
                        _Nivel12Layout.tablet => _buildTabletLayout(
                          constraints,
                        ),
                        _Nivel12Layout.desktop => _buildDesktopLayout(),
                      };
                    },
                  ),
                ),
              ],
            ),
            _GlitchOverlayNivel12(exposicion: _game.exposicion),
            _AvisoVisualNivel12(texto: _avisoVisual, error: _avisoEsError),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bool alertaMedia = _game.exposicion >= 40;
    final bool alertaCritica = _game.exposicion >= 75;

    final Color colorAlerta = alertaCritica
        ? AppColors.pink
        : alertaMedia
        ? AppColors.purple
        : AppColors.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: alertaCritica
            ? AppColors.pink.withValues(alpha: 0.08)
            : alertaMedia
            ? AppColors.purple.withValues(alpha: 0.08)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorAlerta.withValues(
            alpha: alertaMedia || alertaCritica ? 0.8 : 1,
          ),
          width: alertaMedia || alertaCritica ? 2 : 1,
        ),
        boxShadow: alertaCritica
            ? [
                BoxShadow(
                  color: AppColors.pink.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ]
            : alertaMedia
            ? [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;

          if (compact) {
            return Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Volver al mapa',
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.cyan,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'NIVEL 12 · SOMBRA DIGITAL',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStat(
                        'EXPOSICION',
                        '${_game.exposicion}%',
                        AppColors.pink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStat('XP', '${_game.xp}', AppColors.purple),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              IconButton(
                tooltip: 'Volver al mapa',
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.cyan,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'NIVEL 12 · SOMBRA DIGITAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              _buildStat('EXPOSICIÓN', '${_game.exposicion}%', AppColors.pink),
              const SizedBox(width: 8),
              _buildStat('XP', '${_game.xp}', AppColors.purple),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgMain,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 8,
              letterSpacing: 1.4,
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

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildStatusPanel()),
          const SizedBox(width: 14),
          Expanded(flex: 5, child: _buildEvidencePanel()),
          const SizedBox(width: 14),
          Expanded(flex: 4, child: _buildResponsePanel()),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BoxConstraints constraints) {
    final statusHeight = (constraints.maxHeight * 0.42)
        .clamp(300.0, 430.0)
        .toDouble();
    final workHeight = (constraints.maxHeight * 0.62)
        .clamp(460.0, 660.0)
        .toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      children: [
        SizedBox(height: statusHeight, child: _buildStatusPanel()),
        const SizedBox(height: 12),
        SizedBox(
          height: workHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildEvidencePanel()),
              const SizedBox(width: 12),
              Expanded(child: _buildResponsePanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BoxConstraints constraints) {
    final evidenceHeight = (constraints.maxHeight * 0.72)
        .clamp(430.0, 620.0)
        .toDouble();
    final responseHeight = (constraints.maxHeight * 0.62)
        .clamp(380.0, 560.0)
        .toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
      children: [
        _buildStatusPanel(expandChild: false),
        const SizedBox(height: 12),
        SizedBox(height: evidenceHeight, child: _buildEvidencePanel()),
        const SizedBox(height: 12),
        SizedBox(height: responseHeight, child: _buildResponsePanel()),
      ],
    );
  }

  Widget _buildStatusPanel({bool expandChild = true}) {
    return _Panel(
      title: 'EQUIPO INFECTADO',
      expandChild: expandChild,
      child: expandChild
          ? SingleChildScrollView(child: _buildStatusContent())
          : _buildStatusContent(),
    );
  }

  Widget _buildStatusContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SombraDigitalData.nombreEquipo,
          style: const TextStyle(
            color: AppColors.cyan,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          SombraDigitalData.tituloAlerta,
          style: const TextStyle(
            color: AppColors.pink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          SombraDigitalData.descripcionAlerta,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 18),
        _buildExposureBar(),
        const SizedBox(height: 18),
        _buildPhaseBox(),
        const SizedBox(height: 18),
        _buildRiskList(),
        const SizedBox(height: 18),
        if (_game.eventosSistema.isNotEmpty) ...[
          _buildSystemEvents(),
          const SizedBox(height: 18),
        ],
        _buildMessageBox(),
      ],
    );
  }

  Widget _buildExposureBar() {
    final value = (_game.exposicion / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXPOSICIÓN DIGITAL',
          style: TextStyle(
            color: AppColors.pink.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 12,
            backgroundColor: AppColors.bgMain,
            color: AppColors.pink,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATOS EN RIESGO',
          style: TextStyle(
            color: AppColors.cyan.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 10),
        ..._game.datosEnRiesgo.map(
          (dato) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  dato.critico
                      ? Icons.warning_amber_rounded
                      : Icons.radio_button_checked_rounded,
                  color: dato.critico ? AppColors.pink : AppColors.cyan,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _corromperTexto(dato.nombre),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgMain.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
      ),
      child: Text(
        _mensaje,
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
      ),
    );
  }

  Widget _buildEvidencePanel() {
    return _Panel(
      title: 'RASTROS DIGITALES',
      child: Column(
        children: [
          _buildCategoryTabs(),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _evidenciasFiltradas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final evidencia = _evidenciasFiltradas[index];
                final selected = _game.evidenciasSeleccionadasIds.contains(
                  evidencia.id,
                );

                return _EvidenceTile(
                  evidencia: evidencia,
                  selected: selected,
                  inspected: _evidenciaInspeccionada?.id == evidencia.id,
                  tituloMostrado: _corromperTexto(evidencia.titulo),
                  subtituloMostrado: _corromperTexto(evidencia.subtitulo),
                  onTap: () => _inspeccionarEvidencia(evidencia),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildInspectionBox(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _game.analisisCompleto ? null : _analizarStealer,
              child: const Text('ANALIZAR INFOSTEALER'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionBox() {
    final evidencia = _evidenciaInspeccionada;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgMain.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: evidencia == null
              ? AppColors.border
              : AppColors.purple.withValues(alpha: 0.45),
        ),
      ),
      child: evidencia == null
          ? Text(
              'Selecciona un rastro para inspeccionarlo antes de marcarlo.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                height: 1.5,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INSPECCIÓN ACTIVA',
                  style: TextStyle(
                    color: AppColors.purple.withValues(alpha: 0.85),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  evidencia.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  evidencia.descripcion,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _game.analisisCompleto
                        ? null
                        : _marcarEvidenciaInspeccionada,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.cyan.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      _game.evidenciasSeleccionadasIds.contains(evidencia.id)
                          ? 'QUITAR DE RASTROS SOSPECHOSOS'
                          : 'MARCAR COMO RASTRO SOSPECHOSO',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryTabs() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CategoriaEvidenciaDigital.values.map((categoria) {
        final selected = categoria == _categoriaSeleccionada;

        return GestureDetector(
          onTap: () {
            setState(() {
              _categoriaSeleccionada = categoria;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.cyan.withValues(alpha: 0.12)
                  : AppColors.bgMain.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? AppColors.cyan.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
            ),
            child: Text(
              categoria.label,
              style: TextStyle(
                color: selected
                    ? AppColors.cyan
                    : Colors.white.withValues(alpha: 0.55),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResponsePanel() {
    return _Panel(
      title: 'RESPUESTA',
      child: Column(
        children: [
          Expanded(
            child: _game.respuestaDesbloqueada
                ? ListView.separated(
                    itemCount: _game.acciones.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final accion = _game.acciones[index];
                      final selected = _game.accionesSeleccionadasIds.contains(
                        accion.id,
                      );

                      return _ActionTile(
                        accion: accion,
                        selected: selected,
                        onTap: () => _toggleAccion(accion),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      'Identifica primero qué datos han sido robados para desbloquear la respuesta.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _game.respuestaDesbloqueada
                  ? _verificarRespuesta
                  : null,
              child: const Text('VERIFICAR RESPUESTA'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final bool expandChild;

  const _Panel({
    required this.title,
    required this.child,
    this.expandChild = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  final EvidenciaDigital evidencia;
  final bool selected;
  final bool inspected;
  final VoidCallback onTap;
  final String tituloMostrado;
  final String subtituloMostrado;

  const _EvidenceTile({
    required this.evidencia,
    required this.selected,
    required this.inspected,
    required this.onTap,
    required this.tituloMostrado,
    required this.subtituloMostrado,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.cyan
        : inspected
        ? AppColors.purple
        : Colors.white.withValues(alpha: 0.55);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : AppColors.bgMain.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.cyan.withValues(alpha: 0.7)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? color : Colors.white.withValues(alpha: 0.35),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tituloMostrado,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtituloMostrado,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    evidencia.descripcion,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final AccionRespuesta accion;
  final bool selected;
  final VoidCallback onTap;

  const _ActionTile({
    required this.accion,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.cyan
        : Colors.white.withValues(alpha: 0.55);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : AppColors.bgMain.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.7) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.task_alt_rounded
                  : Icons.add_circle_outline_rounded,
              color: selected ? color : Colors.white.withValues(alpha: 0.35),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accion.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    accion.tipo.label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    accion.descripcion,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogoResultadoNivel12 extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final int puntos;
  final int exposicion;
  final bool exito;
  final bool logroOculto;
  final VoidCallback onReintentar;
  final VoidCallback onSalir;

  const _DialogoResultadoNivel12({
    required this.titulo,
    required this.subtitulo,
    required this.puntos,
    required this.exposicion,
    required this.exito,
    required this.logroOculto,
    required this.onReintentar,
    required this.onSalir,
  });

  @override
  Widget build(BuildContext context) {
    final color = exito ? AppColors.cyan : AppColors.pink;
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: size.height * 0.86,
        ),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 26),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                exito ? Icons.shield_moon_rounded : Icons.warning_amber_rounded,
                color: color,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              if (logroOculto) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.purple,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'LOGRO OCULTO: NO DEJES RASTRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ResultMiniStat(
                      label: 'XP',
                      value: '$puntos',
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ResultMiniStat(
                      label: 'EXPOSICIÓN',
                      value: '$exposicion%',
                      color: AppColors.pink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReintentar,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: color.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'REINTENTAR',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSalir,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'SALIR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
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

class _ResultMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultMiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgMain.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlitchOverlayNivel12 extends StatefulWidget {
  final int exposicion;

  const _GlitchOverlayNivel12({required this.exposicion});

  @override
  State<_GlitchOverlayNivel12> createState() => _GlitchOverlayNivel12State();
}

class _GlitchOverlayNivel12State extends State<_GlitchOverlayNivel12> {
  Timer? _timer;
  bool _mostrarPulso = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;

      setState(() {
        _mostrarPulso = !_mostrarPulso;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exposicion < 60) return const SizedBox.shrink();

    final bool critico = widget.exposicion >= 80;

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: critico
            ? (_mostrarPulso ? 0.34 : 0.18)
            : (_mostrarPulso ? 0.18 : 0.08),
        duration: const Duration(milliseconds: 250),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 90,
              child: Container(
                height: 2,
                color: AppColors.cyan.withValues(alpha: 0.45),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 180,

              child: Container(
                height: 1,
                color: AppColors.pink.withValues(alpha: 0.55),
              ),
            ),
            if (_mostrarPulso)
              Positioned(
                left: 40,
                right: 40,
                top: critico ? 260 : 320,
                child: Container(
                  height: 2,
                  color: critico
                      ? AppColors.pink.withValues(alpha: 0.7)
                      : AppColors.cyan.withValues(alpha: 0.45),
                ),
              ),
            Positioned(
              left: 24,
              right: 80,
              bottom: 160,
              child: Container(
                height: 3,
                color: AppColors.purple.withValues(alpha: 0.45),
              ),
            ),
            if (critico)
              Positioned(
                left: 0,
                right: 0,
                bottom: 70,
                child: Container(
                  height: 2,
                  color: AppColors.pink.withValues(alpha: 0.7),
                ),
              ),
            if (critico)
              Center(
                child: Text(
                  'SESIÓN FILTRADA',
                  style: TextStyle(
                    color: AppColors.pink.withValues(alpha: 0.22),
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                  ),
                ),
              ),
            if (widget.exposicion >= 60)
              Positioned(
                right: 24,
                bottom: critico ? 120 : 80,
                child: Container(
                  width: 310,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.18),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontSize: 11,
                      height: 1.45,
                      fontFamily: 'monospace',
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r'C:\Users\Alba\AppData\Temp> stealer.exe',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('[OK] browser cookies dumped'),
                        const Text('[OK] discord token cached'),
                        const Text('[OK] saved passwords indexed'),
                        Text(
                          critico
                              ? '[!!] uploading archive... 91%'
                              : '[..] uploading archive... 42%',
                          style: TextStyle(
                            color: critico ? AppColors.pink : AppColors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

class _AvisoVisualNivel12 extends StatelessWidget {
  final String? texto;
  final bool error;

  const _AvisoVisualNivel12({required this.texto, required this.error});

  @override
  Widget build(BuildContext context) {
    if (texto == null) return const SizedBox.shrink();

    final color = error ? AppColors.pink : AppColors.cyan;

    return IgnorePointer(
      child: Center(
        child: AnimatedOpacity(
          opacity: texto == null ? 0 : 1,
          duration: const Duration(milliseconds: 180),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgCard.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.65),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              texto!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
