import 'package:cyber_ops/widgets/fractura/fractura_dialogo.dart';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';
import '../widgets/fractura/fractura_avatar.dart';

class Nivel06Screen extends StatefulWidget {
  final bool soloEntrenamiento;
  const Nivel06Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel06Screen> createState() => _Nivel06ScreenState();
}

class _Nivel06ScreenState extends State<Nivel06Screen> {
  

  // ── FRACTURA ──────────────────────────────────────────────────────────────
  bool _mostrarFractura = true;
  final List<String> _dialogosFractura = [
    'Has llegado más lejos de lo esperado.',
    'Los primeros sistemas cayeron por reflejos. Este caerá por algo mucho más humano.',
    'Tu objetivo no es cuidadoso. Es sentimental.',
    'Se aferra a nombres que ya no le pertenecen. A fechas que no puede olvidar.',
    'Encontrarás correos, recuerdos y rastros de una obsesión que nunca desapareció.',
    'No busques una clave fuerte.',
    'Busca la herida que sigue abierta.',
  ];


  final List<Map<String, String>> _correos = [
    {
      'titulo': 'Borrador no enviado',
      'subtitulo': 'No sé si debería ir...',
      'contenido':
          'No sé si debería ir...\n\n'
          'No sé si me quiere ver.\n\n'
          'Pero sé que ese día estará allí.\n'
          'Siempre ha sido importante para ella.\n\n'
          'Quizá debería mantenerme lejos.',
    },
    {
      'titulo': 'Informe del detective',
      'subtitulo': 'Mantiene sus rutinas',
      'contenido':
          'He seguido sus movimientos las últimas semanas.\n\n'
          'No hay cambios relevantes.\n\n'
          'Mantiene sus rutinas.\n'
          'Especialmente... esa fecha.',
    },
    {
      'titulo': 'Correo antiguo',
      'subtitulo': 'Antes siempre venías...',
      'contenido':
          'Antes siempre venías...\n\n'
          'Aunque fuera tarde.\n\n'
          'Supongo que este año será diferente.',
    },
    {
      'titulo': 'Angustias',
      'subtitulo': 'No vuelvas a aparecer',
      'contenido':
          'No vuelvas a aparecer por allí.\n\n'
          'Ya hiciste suficiente.',
    },
    {
      'titulo': 'Recordatorio',
      'subtitulo': 'Evento guardado',
      'contenido':
          'Evento guardado:\n\n'
          '02/01',
    },
  ];

  final List<Map<String, String>> _archivos = [
    {
      'titulo': 'IMG_amparo_02.png',
      'subtitulo': 'Archivo de imagen',
      'contenido':
          'Nombre del archivo: IMG_amparo_02.png\n\n'
          'La miniatura está dañada.\n'
          'No se puede previsualizar correctamente.',
    },
    {
      'titulo': 'direccion.txt',
      'subtitulo': 'Texto simple',
      'contenido':
          'Dirección actualizada:\n\n'
          'Avenida Catalina',
    },
    {
      'titulo': 'mascota.txt',
      'subtitulo': 'Nota antigua',
      'contenido': 'Rock sigue esperando en la puerta cuando oye pasos.',
    },
    {
      'titulo': 'agenda_0705.txt',
      'subtitulo': 'Anotación',
      'contenido':
          '07/05\n\n'
          'El día que se fueron.',
    },
  ];
  String _seccionActual = 'correos';
  int _elementoSeleccionado = 0;
  final List<String> _pistasLibreta = [];
  int _intentosFallidos = 0;
  int _fallosAcumuladosParaVida = 0;
  bool _nivelYaCompletado = false;
  bool _progresoGuardado = false;
  bool _guardando = false;
  static const int _xpVictoria = 250;
  List<Map<String, String>> get _itemsActuales =>
      _seccionActual == 'correos' ? _correos : _archivos;
  void _registrarPistaActual() {
    final actual = _itemsActuales[_elementoSeleccionado];
    final titulo = actual['titulo'] ?? '';

    final Map<String, String> pistasPorTitulo = {
      'Borrador no enviado':
          'El objetivo duda en acudir a un día importante para ella.',
      'Informe del detective':
          'El detective confirma que hay una fecha especialmente relevante.',
      'Correo antiguo': 'La hija sigue siendo el vínculo emocional más fuerte.',
      'Recordatorio': 'Fecha detectada: 02/01',
      'IMG_amparo_02.png': 'Nombre importante detectado: Amparo',
      'agenda_0705.txt':
          '07/05 parece importante, pero podría ser ruido emocional.',
    };

    final pista = pistasPorTitulo[titulo];
    if (pista != null && !_pistasLibreta.contains(pista)) {
      setState(() {
        _pistasLibreta.add(pista);
      });
    }
  }

  Future<void> _comprobarPassword() async {
    if (_guardando) return;

    final intento = _passwordController.text.trim().toLowerCase();

    if (intento == 'amparo0201') {
      setState(() => _guardando = true);
      await _guardarProgresoNivel();
      if (!mounted) return;
      setState(() {
        _xp = _xpVictoria;
        _guardando = false;
        _mostrandoFinal = true;
        _dialogoFinalActual = 0;
      });
      return;
    }

    setState(() {
      _intentosFallidos++;
      _fallosAcumuladosParaVida++;

      if (_fallosAcumuladosParaVida >= 3) {
        _vidas--;
        _fallosAcumuladosParaVida = 0;
      }
    });

    if (_vidas <= 0) {
      _mostrarDerrota();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Acceso denegado. Intentos fallidos: $_intentosFallidos',
          ),
        ),
      );
    }

    _passwordController.clear();
  }

  Future<void> _guardarProgresoNivel() async {
    if (_progresoGuardado || _nivelYaCompletado) return;

    _progresoGuardado = true;
    try {
      await FirestoreService.guardarPuntuacion(
        puntos: _xpVictoria,
        nivelCompletado: 6,
        soloEntrenamiento: widget.soloEntrenamiento,
      );
      await FirestoreService.guardarMision(
        nivel: 6,
        mision: 1,
        puntos: _xpVictoria,
      );
    } catch (e) {
      _progresoGuardado = false;
      debugPrint('No se pudo guardar progreso del nivel 6: $e');
    }
  }

  void _mostrarDerrota() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.pink.withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.pink,
                  size: 46,
                ),
                const SizedBox(height: 16),
                const Text(
                  'ACCESO BLOQUEADO',
                  style: TextStyle(
                    color: AppColors.pink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Has generado demasiados intentos sospechosos.\n'
                  'El sistema ha detectado actividad anómala.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _salirDelNivel();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'VOLVER',
                      style: TextStyle(
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
        );
      },
    );
  }

  Future<void> _siguienteDialogoFinal() async {
    if (_dialogoFinalActual < _dialogosFinales.length - 1) {
      setState(() {
        _dialogoFinalActual++;
      });
    } else {
      await _salirDelNivel();
    }
  }

  int _vidas = 3;
  int _xp = 0;
  final TextEditingController _passwordController = TextEditingController();

  bool _mostrandoFinal = false;
  int _dialogoFinalActual = 0;

  final List<String> _dialogosFinales = [
    'La puerta se ha abierto.',
    'No porque la contraseña fuera débil por sí sola...',
    'Sino porque la persona detrás de ella lo era aún más.',
    'Los nombres, los recuerdos, la culpa, la nostalgia... todo deja patrones.',
    'Y cuando alguien convierte su vida en una contraseña, también convierte su intimidad en una vulnerabilidad.',
    'La ciberseguridad no trata solo de sistemas. Trata de hábitos. De decisiones. De personas.',
    'Recuérdalo: una mente descuidada puede ser tan peligrosa como un sistema sin defensa.',
  ];

  @override
  void initState() {
    super.initState();
    _setupNivel6();
  }

  Future<void> _setupNivel6() async {
    _nivelYaCompletado = widget.soloEntrenamiento;
    if (!widget.soloEntrenamiento) {
      try {
        final datos = await FirestoreService.obtenerUsuario();
        final nivelUsuario = datos['nivel'] ?? 1;
        _nivelYaCompletado = nivelUsuario > 6;
      } catch (e) {
        debugPrint('No se pudo comprobar progreso del nivel 6: $e');
      }
    }

    try {
      await MusicService().playNiveles6to10Music();
    } catch (e) {
      debugPrint('Error iniciando musica del nivel 6: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _salirDelNivel() async {
    if (!mounted) return;
    Navigator.pop(context);
  }


  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildTrainingBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.45)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center_rounded, color: AppColors.purple, size: 14),
          SizedBox(width: 6),
          Text(
            'MODO ENTRENAMIENTO - Progreso no guardado',
            style: TextStyle(
              color: AppColors.purple,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutroView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.30)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.08),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: FracturaAvatar(hablando: true, size: 220),
                ),
                const SizedBox(height: 20),
                Text(
                  'FRACTURA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.cyan.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'TRANSMISIÓN FINAL',
                  textAlign: TextAlign.center,
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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.25),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _dialogosFinales[_dialogoFinalActual],
                      key: ValueKey(_dialogoFinalActual),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${_dialogoFinalActual + 1} / ${_dialogosFinales.length}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: _siguienteDialogoFinal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _dialogoFinalActual == _dialogosFinales.length - 1
                          ? 'FINALIZAR'
                          : 'SIGUIENTE',
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

  Widget _buildMainLevelView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 1000;

        if (isMobile) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Tooltip(
                      message: 'Volver al mapa',
                      child: GestureDetector(
                        onTap: () async => await _salirDelNivel(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.purple.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.cyan,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.cyan, AppColors.purple],
                        ).createShader(bounds),
                        child: const Text(
                          'NIVEL 6 · CLAVE VULNERABLE',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: List.generate(
                        3,
                        (i) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.favorite_rounded,
                            color: i < _vidas
                                ? AppColors.pink
                                : AppColors.pink.withValues(alpha: 0.2),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.purple.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '$_xp XP',
                        style: const TextStyle(
                          color: AppColors.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_nivelYaCompletado) _buildTrainingBanner(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: [
                      const _NarratorSideCard(),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 420,
                        child: _WorkspaceCardLevel6(
                          seccionActual: _seccionActual,
                          elementoSeleccionado: _elementoSeleccionado,
                          items: _itemsActuales,
                          onCambiarSeccion: (seccion) {
                            setState(() {
                              _seccionActual = seccion;
                              _elementoSeleccionado = 0;
                            });
                            _registrarPistaActual();
                          },
                          onSeleccionarElemento: (index) {
                            setState(() {
                              _elementoSeleccionado = index;
                            });
                            _registrarPistaActual();
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 260,
                        child: _NotebookCard(pistas: _pistasLibreta),
                      ),
                      const SizedBox(height: 12),
                      _AccessCard(
                        controller: _passwordController,
                        onSubmit: _comprobarPassword,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Tooltip(
                    message: 'Volver al mapa',
                    child: GestureDetector(
                      onTap: () async => await _salirDelNivel(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.purple.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.cyan,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.cyan, AppColors.purple],
                      ).createShader(bounds),
                      child: const Text(
                        'NIVEL 6 · CLAVE VULNERABLE',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: i < _vidas
                              ? AppColors.pink
                              : AppColors.pink.withValues(alpha: 0.2),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.purple.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '$_xp XP',
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_nivelYaCompletado) _buildTrainingBanner(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(flex: 3, child: _LeftDesktopColumn()),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: _WorkspaceCardLevel6(
                        seccionActual: _seccionActual,
                        elementoSeleccionado: _elementoSeleccionado,
                        items: _itemsActuales,
                        onCambiarSeccion: (seccion) {
                          setState(() {
                            _seccionActual = seccion;
                            _elementoSeleccionado = 0;
                          });
                          _registrarPistaActual();
                        },
                        onSeleccionarElemento: (index) {
                          setState(() {
                            _elementoSeleccionado = index;
                          });
                          _registrarPistaActual();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _RightDesktopColumn(
                        pistas: _pistasLibreta,
                        controller: _passwordController,
                        onSubmit: _comprobarPassword,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
            subtitulo: 'NIVEL 6 // CLAVE VULNERABLE',
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

              await _setupNivel6();
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
          child: _mostrandoFinal
              ? _buildOutroView()
              : _buildMainLevelView(),
        ),
      ),
    );
  }
}

class _LeftDesktopColumn extends StatelessWidget {
  const _LeftDesktopColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _NarratorSideCard(),
        SizedBox(height: 12),
        Expanded(child: SingleChildScrollView(child: _DialogPanelCard())),
      ],
    );
  }
}

class _RightDesktopColumn extends StatelessWidget {
  final List<String> pistas;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _RightDesktopColumn({
    required this.pistas,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _NotebookCard(pistas: pistas)),
        SizedBox(height: 12),
        _AccessCard(controller: controller, onSubmit: onSubmit),
      ],
    );
  }
}

class _NarratorSideCard extends StatelessWidget {
  const _NarratorSideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.45),
                width: 2,
              ),
              image: const DecorationImage(
                image: AssetImage('assets/images/narrador_fractura.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FRACTURA',
                  style: TextStyle(
                    color: AppColors.cyan.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ENTIDAD NO CLASIFICADA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 9,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No rompas la puerta.\nLee a quien la cerró.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogPanelCard extends StatelessWidget {
  const _DialogPanelCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_DialogPanelContent()],
      ),
    );
  }
}

class _DialogPanelContent extends StatelessWidget {
  const _DialogPanelContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRANSMISIÓN // NIVEL 6',
          style: TextStyle(
            color: AppColors.purple.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Tu objetivo no protege datos. Protege recuerdos.\n\n'
          'Y lo hace mal.\n\n'
          'Observa lo que guarda. Lo que relee. Lo que no puede soltar.\n\n'
          'Las grietas emocionales suelen dejar patrones. Y los patrones... abren puertas.',
          style: TextStyle(color: Colors.white, fontSize: 14, height: 1.7),
        ),
      ],
    );
  }
}

class _WorkspaceCardLevel6 extends StatelessWidget {
  final String seccionActual;
  final int elementoSeleccionado;
  final List<Map<String, String>> items;
  final ValueChanged<String> onCambiarSeccion;
  final ValueChanged<int> onSeleccionarElemento;

  const _WorkspaceCardLevel6({
    required this.seccionActual,
    required this.elementoSeleccionado,
    required this.items,
    required this.onCambiarSeccion,
    required this.onSeleccionarElemento,
  });

  @override
  Widget build(BuildContext context) {
    final actual = items[elementoSeleccionado];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ESCRITORIO INVESTIGABLE',
            style: TextStyle(
              color: AppColors.cyan.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _DeskTab(
                label: 'CORREOS',
                selected: seccionActual == 'correos',
                onTap: () => onCambiarSeccion('correos'),
              ),
              const SizedBox(width: 8),
              _DeskTab(
                label: 'ARCHIVOS',
                selected: seccionActual == 'archivos',
                onTap: () => onCambiarSeccion('archivos'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgMain.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.purple.withValues(alpha: 0.2),
                      ),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final selected = index == elementoSeleccionado;

                        return GestureDetector(
                          onTap: () => onSeleccionarElemento(index),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.cyan.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppColors.cyan.withValues(alpha: 0.45)
                                    : AppColors.purple.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['titulo'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['subtitulo'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgMain.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.purple.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          actual['titulo'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          actual['subtitulo'] ?? '',
                          style: TextStyle(
                            color: AppColors.cyan.withValues(alpha: 0.75),
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              actual['contenido'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.7,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeskTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DeskTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.cyan.withValues(alpha: 0.12)
              : AppColors.bgMain.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.cyan.withValues(alpha: 0.45)
                : AppColors.purple.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.cyan
                : Colors.white.withValues(alpha: 0.65),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}

class _NotebookCard extends StatelessWidget {
  final List<String> pistas;

  const _NotebookCard({required this.pistas});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LIBRETA',
            style: TextStyle(
              color: AppColors.cyan.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: pistas.isEmpty
                ? Text(
                    '- Aún no has recopilado pistas',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  )
                : ListView.separated(
                    itemCount: pistas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return Text(
                        '• ${pistas[index]}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _AccessCard({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACCESO',
            style: TextStyle(
              color: AppColors.purple.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            onSubmitted: (_) => onSubmit(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Introduce la contraseña...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              filled: true,
              fillColor: AppColors.bgMain.withValues(alpha: 0.6),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.cyan.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.cyan.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'PROBAR ACCESO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
