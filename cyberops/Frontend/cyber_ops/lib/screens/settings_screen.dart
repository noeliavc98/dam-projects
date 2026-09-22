import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cyber_ops/screens/change_password_screen.dart';
import 'package:cyber_ops/screens/change_profile_photo_screen.dart';
import 'package:cyber_ops/screens/home_screen.dart';
import 'package:cyber_ops/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_colors.dart';
import '../services/music_service.dart';

enum AppLanguage { es, en }

extension AppLanguageExt on AppLanguage {
  String get label     => this == AppLanguage.es ? 'Español'  : 'Inglés';
  String get native    => this == AppLanguage.es ? 'Español'  : 'English';
  String get flagEmoji => this == AppLanguage.es ? '🇪🇸'       : '🇬🇧';
}
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {


  // Categoría seleccionada
  String _selectedCategory = "Idioma";

  final List<String> categories = [
    "Idioma",
    "Audio",
    "Pantalla",
    "Cuenta",
    "Información",
  ];


  // Animación del fondo
  late AnimationController _rotateController;

  //Ajustes de Audio
  double _volMusica        = 0.7;
  double _volEfectos       = 0.55;
  bool   _sonidoEnSilencio = false;
  bool   _vibracion        = true;

  //Ajustes de pantalla
  String _textSize = 'md';
  bool _animaciones = true;

  //Info Cuenta
  String _username    = '';
  String _email       = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _cargarAjustes();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      setState(() {
        _username    = doc.data()?['name'] ?? '';
        _email       = doc.data()?['email'] ?? '';
      });
    }
  }

  // ─── GUARDAR UN AJUSTE INDIVIDUAL ─────────────────────
  Future<void> _guardarAjuste(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();

    // Guardar en SharedPreferences
    if (value is double)  await prefs.setDouble(key, value);
    if (value is bool)    await prefs.setBool(key, value);
    if (value is String)  await prefs.setString(key, value);

    // Guardar en Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('ajustes')
        .doc('ui')
        .set(
          {key: value, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true), // ← importante: no sobreescribe el resto
        );
  }

  Future<void> _cargarAjustes() async {
    final prefs = await SharedPreferences.getInstance();

    // Primero carga local (instantáneo)
    setState(() {
      _selectedLang    = prefs.getString('lang') == 'en'
          ? AppLanguage.en : AppLanguage.es;
      _textSize        = prefs.getString('textSize')        ?? 'md';
      _animaciones     = prefs.getBool('animaciones')       ?? true;
      _volMusica       = prefs.getDouble('volMusica')       ?? 0.7;
      _volEfectos      = prefs.getDouble('volEfectos')      ?? 0.55;
      _sonidoEnSilencio = prefs.getBool('sonidoEnSilencio') ?? false;
      _vibracion       = prefs.getBool('vibracion')         ?? true;
    });

    // Aplica volúmenes inmediatamente
    MusicService().setMusicVolume(_volMusica);
    MusicService().setSfxVolume(_volEfectos);
    MusicService().setMusicMuted(_sonidoEnSilencio);

    // Luego sincroniza desde Firestore (por si cambió en otro dispositivo)
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('ajustes')
        .doc('ui')
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;

    setState(() {
      _selectedLang     = data['lang'] == 'en'
          ? AppLanguage.en : AppLanguage.es;
      _textSize         = data['textSize']         ?? 'md';
      _animaciones      = data['animaciones']      ?? true;
      _volMusica        = (data['volMusica']        ?? 0.7).toDouble();
      _volEfectos       = (data['volEfectos']       ?? 0.55).toDouble();
      _sonidoEnSilencio = data['sonidoEnSilencio']  ?? false;
      _vibracion        = data['vibracion']         ?? true;
    });

    // Aplica volúmenes con los datos de Firestore
    MusicService().setMusicVolume(_volMusica);
    MusicService().setSfxVolume(_volEfectos);
    MusicService().setMusicMuted(_sonidoEnSilencio);

    // Sincroniza Firestore → SharedPreferences
    await prefs.setString('lang',             data['lang'] ?? 'es');
    await prefs.setString('textSize',         data['textSize'] ?? 'md');
    await prefs.setBool('animaciones',        data['animaciones'] ?? true);
    await prefs.setDouble('volMusica',        (data['volMusica'] ?? 0.7).toDouble());
    await prefs.setDouble('volEfectos',       (data['volEfectos'] ?? 0.55).toDouble());
    await prefs.setBool('sonidoEnSilencio',   data['sonidoEnSilencio'] ?? false);
    await prefs.setBool('vibracion',          data['vibracion'] ?? true);
  }

  // Cierra la sesión y vuelve a la home screen
  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (route) => false,
    );
  }

  //Elimina la cuenta 
  void _eliminarCuenta() {
  final passwordController = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF0D1033),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF3A1A1A), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠ Eliminar cuenta',
              style: TextStyle(
                color: Color(0xFFE24B4A),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Esta acción es permanente. Se borrarán todos tus datos, progreso y logros. Introduce tu contraseña para confirmar.',
              style: TextStyle(
                color: Color(0xFF5B6FA8),
                fontSize: 11,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: _inputDecoration('Contraseña actual'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF151D4A),
                    foregroundColor: const Color(0xFF7A8FC4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF1A2560)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8,
                    ),
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final password = passwordController.text.trim();
                    if (password.isEmpty) return;

                    try {
                      final user = FirebaseAuth.instance.currentUser!;

                      // 1. Reautenticar
                      final credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: password,
                      );
                      await user.reauthenticateWithCredential(credential);

                      // 2. Borrar documento en Firestore
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .delete();

                      // 3. Borrar cuenta en Firebase Auth
                      await user.delete();

                      // 4. Cerrar sesión y navegar al login
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login', // ← tu ruta de login
                        (route) => false,
                      );

                    } on FirebaseAuthException catch (e) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.code == 'wrong-password'
                                ? 'Contraseña incorrecta.'
                                : 'Error: ${e.message}',
                          ),
                          backgroundColor: const Color(0xFF7F1D1D),
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF7F1D1D),
                    foregroundColor: const Color(0xFFFCA5A5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF991B1B)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8,
                    ),
                  ),
                  child: const Text('Eliminar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF3D4F8C)),
      filled: true,
      fillColor: const Color(0xFF0A0E28),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1A2560)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1A2560)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF5B52D4)),
      ),
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
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
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
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
                  colors: [AppColors.cyan, AppColors.blue, AppColors.purple],
                ).createShader(bounds),
                child: const Text(
                  'AJUSTES',
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
        ],
      ),
    );
  }

  // PANEL PRINCIPAL DIVIDIDO EN DOS COLUMNAS
  Widget _buildSettingsPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.purple, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            )
          ],
        ),

        child: Row(
          children: [

            // ───────────────────────────────
            // COLUMNA IZQUIERDA (CATEGORÍAS)
            // ───────────────────────────────
            SizedBox(
              width: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildCategoryItem("Idioma", Icons.language),
                  _buildCategoryItem("Audio", Icons.volume_up_rounded),
                  _buildCategoryItem("Pantalla", Icons.monitor_rounded),
                  _buildCategoryItem("Cuenta", Icons.person_rounded),
                  _buildCategoryItem("Información", Icons.info_rounded),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ───────────────────────────────
            // COLUMNA DERECHA (CONTENIDO)
            // ───────────────────────────────
            Expanded(
              child: _buildCategoryContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    final bool selected = _selectedCategory == title;                
      
    return Tooltip(
      message: title,
      preferBelow: false,
      child: GestureDetector(
        onTap: () {
          setState(() {
          _selectedCategory = title;
        });
      },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.purple.withValues(alpha: 0.35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
              ? Border.all(color: AppColors.purple.withValues(alpha: 0.6))
              : null,
          ),
          child: Icon(
            icon,
            color: selected ? Colors.white : Colors.white54,
            size: 20,
          ),
        ),
      ),
    );
  }

  // CONTENIDO SEGÚN CATEGORÍA
  Widget _buildCategoryContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(20), 
          child: SizedBox(
            width: double.infinity,
            height: constraints.maxHeight,  
            child: _buildCategoryBody(),     
          ),
        );
      },
    );
  }

  Widget _buildCategoryBody() {
    if (_selectedCategory == "Idioma") {
      return _buildLanguagePanel();
    }

    if (_selectedCategory == "Audio") {
      return _buildAudioPanel();
    }

    if (_selectedCategory == "Pantalla") {
      return _buildPantallaPanel();
    }

    if (_selectedCategory == "Cuenta") {
      return _buildCuentaPanel();
    }

    if (_selectedCategory == "Información") {
      return _buildInformacionPanel();
    }

    return const SizedBox();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: Stack(
        children: [
          // Fondo animado
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: _buildHeader(),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: _buildSettingsPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ─────────────────────────────────────────────
// IDIOMA
// ─────────────────────────────────────────────

// ─── ESTADO ───────────────────────────────────────────
AppLanguage _selectedLang = AppLanguage.es;
// ─── PANEL IDIOMA ─────────────────────────────────────
Widget _buildLanguagePanel() {
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(), 
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Título
        const Text(
          'Idioma',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Selecciona el idioma en el que se mostrará la interfaz.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 20),

        // Etiqueta sección
        _buildSectionLabel('Idioma de la aplicación'),
        const SizedBox(height: 8),

        // Grid de idiomas
        Row(
          children: [
            Expanded(child: _buildLangCard(AppLanguage.es)),
            const SizedBox(width: 10),
            Expanded(child: _buildLangCard(AppLanguage.en)),
          ],
        ),
        const SizedBox(height: 20),

        // Vista previa
        _buildLangPreview(),
      ],
    ),
    );
  }
// ─── TARJETA DE IDIOMA ────────────────────────────────
Widget _buildLangCard(AppLanguage lang) {
  final bool selected = _selectedLang == lang;

  return GestureDetector(
    onTap: () {
      setState(() => _selectedLang = lang);
      final langStr = lang == AppLanguage.es ? 'es' : 'en';
      _guardarAjuste('lang', langStr);
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.purple.withValues(alpha: 0.15)
            : const Color(0xFF0A0E28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.purple.withValues(alpha: 0.7)
              : const Color(0xFF1A2560),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Bandera
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2560),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                lang.flagEmoji,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  lang.native,
                  style: const TextStyle(
                    color: Color(0xFF3D4F8C),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Check
          AnimatedOpacity(
            opacity: selected ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.6),
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
// ─── VISTA PREVIA ─────────────────────────────────────
Widget _buildLangPreview() {
  final Map<AppLanguage, List<Map<String, String>>> previews = {
    AppLanguage.es: [
      {'label': 'Pantalla de ajustes', 'value': 'Ajustes'},
      {'label': 'Botón de inicio',     'value': 'Jugar'},
      {'label': 'Mensaje de error',    'value': 'Inténtalo de nuevo'},
    ],
    AppLanguage.en: [
      {'label': 'Settings screen', 'value': 'Settings'},
      {'label': 'Start button',    'value': 'Play'},
      {'label': 'Error message',   'value': 'Try again'},
    ],
  };

  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF0A0E28),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF1A2560)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Vista previa'),
        const SizedBox(height: 10),
        ...previews[_selectedLang]!.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${item['label']} → ',
                        style: const TextStyle(
                          color: Color(0xFF7A8FC4),
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: item['value'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    ),
  );
}
// ─── HELPER: etiqueta de sección ──────────────────────
Widget _buildSectionLabel(String text) {
  return Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: Color(0xFF3D4F8C),
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.0,
    ),
  );
}
// ─────────────────────────────────────────────
// AUDIO
// ─────────────────────────────────────────────
Widget _buildAudioPanel() {
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Título
        const Text(
          'Audio',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ajusta el volumen y comportamiento del sonido.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 20),

        // Sección volumen
        _buildSectionLabel('Volumen'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2560)),
          ),
          child: Column(
            children: [
              _buildSliderRow(
                icon: Icons.music_note_rounded,
                label: 'Música de fondo',
                subtitle: 'Banda sonora del juego',
                value: _volMusica,
                onChanged: (v) {
                  setState(() => _volMusica = v);
                  MusicService().setMusicVolume(v);
                },
              ),
              const Divider(color: Color(0xFF1A2560), height: 24),
              _buildSliderRow(
                icon: Icons.auto_awesome_rounded,
                label: 'Efectos de sonido',
                subtitle: 'Botones y animaciones',
                value: _volEfectos,
                onChanged: (v) {
                  setState(() => _volEfectos = v);
                  MusicService().setSfxVolume(v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Sección opciones
        _buildSectionLabel('Opciones'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2560)),
          ),
          child: Column(
            children: [
              _buildToggleRow(
                icon: Icons.volume_off_rounded,
                label: 'Silenciar música',
                subtitle: 'Desactiva la música de fondo',
                value: _sonidoEnSilencio,
                onChanged: (v) {
                  setState(() => _sonidoEnSilencio = v);
                  MusicService().setMusicMuted(v);
                  _guardarAjuste('sonidoEnSilencio', v);
                },
              ),
              const Divider(color: Color(0xFF1A2560), height: 24),
              _buildToggleRow(
                icon: Icons.vibration_rounded,
                label: 'Vibración háptica',
                subtitle: 'Al completar retos y alertas',
                value: _vibracion,
                onChanged: (v) {
                  setState(() => _vibracion = v);
                  _guardarAjuste('vibracion', v);
                },
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }
// ─── SLIDER ROW ───────────────────────────────────────
Widget _buildSliderRow({
  required IconData icon,
  required String label,
  required String subtitle,
  required double value,
  required ValueChanged<double> onChanged,
  ValueChanged<double>? onChangeEnd,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF151D4A),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: const Color(0xFF1A2560)),
              ),
              child: Icon(icon, color: AppColors.purple, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFC8D0F0),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF3D4F8C),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                color: Color(0xFF5B8FFF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: AppColors.purple,
            inactiveTrackColor: const Color(0xFF1A2560),
            thumbColor: const Color(0xFF5B52D4),
            overlayColor: AppColors.purple.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }
  // ─── TOGGLE ROW ───────────────────────────────────────
  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF151D4A),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFF1A2560)),
          ),
          child: Icon(icon, color: AppColors.purple, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFC8D0F0),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF3D4F8C),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.purple,
          inactiveThumbColor: Colors.white54,
          inactiveTrackColor: const Color(0xFF151D4A),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // PANTALLA
  // ─────────────────────────────────────────────
  // ─── PANEL PANTALLA ───────────────────────────────────────────
  Widget _buildPantallaPanel() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Título
          const Text(
            'Pantalla',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Personaliza la apariencia y el comportamiento visual.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Sección tamaño de texto
          _buildSectionLabel('Tamaño de texto'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A2560)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF151D4A),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: const Color(0xFF1A2560)),
                      ),
                      child: Icon(
                        Icons.text_fields_rounded,
                        color: AppColors.purple, size: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tamaño de fuente',
                            style: TextStyle(
                              color: Color(0xFFC8D0F0),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Afecta a todos los textos de la app',
                            style: TextStyle(
                              color: Color(0xFF3D4F8C),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Botones de tamaño
                Row(
                  children: [
                    _buildSizeBtn('xs', 'Pequeño', 11),
                    const SizedBox(width: 8),
                    _buildSizeBtn('md', 'Normal',  14),
                    const SizedBox(width: 8),
                    _buildSizeBtn('lg', 'Grande',  18),
                    const SizedBox(width: 8),
                    _buildSizeBtn('xl', 'Extra',   22),
                  ],
                ),
                const SizedBox(height: 12),

                // Vista previa
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1140),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1A2560)),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: _textSizeValue,
                        color: const Color(0xFF7A8FC4),
                      ),
                      children: const [
                        TextSpan(text: 'Vista previa: '),
                        TextSpan(
                          text: 'Bienvenido al reto de ciberseguridad.',
                          style: TextStyle(
                            color: Color(0xFFC8D0F0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sección animaciones
          _buildSectionLabel('Animaciones'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A2560)),
            ),
            child: Column(
              children: [
                _buildToggleRow(
                  icon: Icons.animation_rounded,
                  label: 'Animaciones de interfaz',
                  subtitle: 'Transiciones y efectos visuales',
                  value: _animaciones,
                  onChanged: (v) {
                    setState(() => _animaciones = v);
                    _guardarAjuste('animaciones', v);
                  },
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1140),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1A2560)),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: _animaciones
                              ? AppColors.purple
                              : AppColors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _animaciones
                              ? 'Animaciones activas — las transiciones se verán suaves'
                              : 'Animaciones desactivadas — la app irá más directa',
                          style: const TextStyle(
                            color: Color(0xFF5B6FA8),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    }

// ─── BOTÓN DE TAMAÑO ──────────────────────────────────────────
Widget _buildSizeBtn(String key, String label, double fontSize) {
  final bool selected = _textSize == key;

  return Expanded(
    child: GestureDetector(
      onTap: () {
        setState(() => _textSize = key);
        _guardarAjuste('textSize', key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purple.withValues(alpha: 0.15)
              : const Color(0xFF151D4A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.purple.withValues(alpha: 0.7)
                : const Color(0xFF1A2560),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              'A',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: selected
                    ? const Color(0xFF9D97FF)
                    : const Color(0xFFC8D0F0),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected
                    ? const Color(0xFF6B64B0)
                    : const Color(0xFF3D4F8C),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── HELPER — tamaño numérico según clave ─────────────────────
double get _textSizeValue {
  switch (_textSize) {
    case 'xs': return 11;
    case 'lg': return 15;
    case 'xl': return 18;
    default:   return 13; // md
  }
} 
// ─────────────────────────────────────────────
// CUENTA
// ─────────────────────────────────────────────
Widget _buildCuentaPanel() {
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        const Text(
          'Cuenta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Gestiona tu perfil y credenciales de acceso.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 20),
        // Sección perfil de usuario
        _buildSectionLabel('Perfil'),
        const SizedBox(height: 8),
        _buildAvatarCard(),
        const SizedBox(height: 20),
        //Credenciales
        _buildSectionLabel('Credenciales'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2560)),
          ),
          child: Column(
            children: [
              _buildActionRow(
                icon: Icons.person_rounded,
                label: 'Nombre de usuario',
                subtitle: _username.isEmpty ? 'Cargando...' : _username,
                onTap: () => _showConfirmDialog(
                  title: 'Cambiar nombre de usuario',
                  desc: 'Si deseas cambiar el nombre de usuario pulsa Ok.',
                  confirmLabel: 'Ok',
                  danger: false,
                  onConfirm: () {
                    Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfileScreen()),
                          );
                  },
                ),
              ),
              _buildDivider(),
              _buildActionRow(
                icon: Icons.email_rounded,
                label: 'Email',
                subtitle:  _email.isEmpty ? 'Cargando...' : _email,
                onTap: () => _showConfirmDialog(
                  title: 'Cambiar email',
                  desc: 'Si deseas cambiar el email de tu cuenta pulsa Ok.',
                  confirmLabel: 'Ok',
                  danger: false,
                  onConfirm: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                      );
                  },
                ),
              ),
              _buildDivider(),
              _buildActionRow(
                icon: Icons.lock_rounded,
                label: 'Contraseña',
                subtitle: 'Modifica tu contraseña',
                onTap: () => _showConfirmDialog(
                  title: 'Cambiar contraseña',
                  desc: '¿Estás seguro de que deseas cambiar la contraseña actual?',
                  confirmLabel: 'Confirmar',
                  danger: false,
                  onConfirm: () {
                    Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
                          );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Sesión
        _buildSectionLabel('Sesión'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2560)),
          ),
          child: _buildActionRow(
            icon: Icons.logout_rounded,
            label: 'Cerrar sesión',
            subtitle: 'Salir de tu cuenta en este dispositivo',
            onTap: () => _showConfirmDialog(
              title: 'Cerrar sesión',
              desc: '¿Seguro que quieres cerrar sesión en este dispositivo?',
              confirmLabel: 'Cerrar sesión',
              danger: false,
              onConfirm: () {
                _cerrarSesion();
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Zona de peligro
        Text(
          '⚠ ZONA DE PELIGRO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B2020),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _eliminarCuenta(),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0814),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3A1A1A)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A0E0E),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xFF5A1A1A)),
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Color(0xFFE24B4A),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eliminar cuenta',
                        style: TextStyle(
                          color: Color(0xFFE24B4A),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Acción permanente e irreversible',
                        style: TextStyle(
                          color: Color(0xFF3D4F8C),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF6B2020),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  }

// ─── AVATAR ───────────────────────────────────
Widget _buildAvatarCard() {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF0A0E28),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF1A2560)),
    ),
    child: StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 52,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5B52D4),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final datos = snapshot.data!;

        return Row(
          children: [
            // Avatar
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeProfilePhotoScreen(),
                ),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF5B52D4),
                backgroundImage: (datos['fotoPerfil'] != null &&
                        datos['fotoPerfil'].toString().startsWith('/'))
                    ? MemoryImage(base64Decode(datos['fotoPerfil']))
                    : null,
                child: (datos['fotoPerfil'] == null ||
                        datos['fotoPerfil'].toString().isEmpty)
                    ? const Icon(
                        Icons.person,
                        size: 26,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    datos['name'] ?? 'Usuario',
                    style: const TextStyle(
                      color: Color(0xFFE8E4FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    datos['email'] ?? '',
                    style: const TextStyle(
                      color: Color(0xFF3D4F8C),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeProfilePhotoScreen(),
                      ),
                    ),
                    child: const Text(
                      'Cambiar avatar →',
                      style: TextStyle(
                        color: Color(0xFF5B8FFF),
                        fontSize: 11,
                      ),
                    ),
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
// ─── FILA DE ACCIÓN ───────────────────────────────────
Widget _buildActionRow({
  required IconData icon,
  required String label,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF151D4A),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFF1A2560)),
            ),
            child: Icon(icon, color: AppColors.purple, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFC8D0F0),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF3D4F8C),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF3D4F8C),
            size: 16,
          ),
        ],
      ),
    ),
  );
}

// ─── DIÁLOGO DE CONFIRMACIÓN ──────────────────────────
void _showConfirmDialog({
  required String title,
  required String desc,
  required String confirmLabel,
  required bool danger,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF0D1033),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF2A3A8A), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFE8E4FF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: const TextStyle(
                color: Color(0xFF5B6FA8),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF151D4A),
                    foregroundColor: const Color(0xFF7A8FC4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF1A2560)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8,
                    ),
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onConfirm();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: danger
                        ? const Color(0xFF7F1D1D)
                        : AppColors.purple,
                    foregroundColor: danger
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFFC4BFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: danger
                            ? const Color(0xFF991B1B)
                            : AppColors.purple.withValues(alpha: 0.7),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8,
                    ),
                  ),
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(fontSize: 12),
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

// ─── HELPER ───────────────────────────────────────────
Widget _buildDivider() => const Divider(
  color: Color(0xFF1A2560),
  height: 1,
  indent: 14,
  endIndent: 14,
);

// ─────────────────────────────────────────────
// INFORMACIÓN
// ─────────────────────────────────────────────
Widget _buildInformacionPanel() {
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Título
        const Text(
          'Información',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Detalles de la app, legal y contacto.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 20),

        // Versión
        _buildSectionLabel('Aplicación'),
        const SizedBox(height: 8),
        _buildVersionCard(),
        const SizedBox(height: 20),

        // Legal
        _buildSectionLabel('Legal'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2560)),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons.description_rounded,
                label: 'Términos y condiciones',
                subtitle: 'Condiciones de uso de la app',
                onTap: () => _showInfoModal(
                  title: 'Términos y condiciones',
                  content: _termsContent,
                ),
              ),
              _buildDivider(),
              _buildInfoRow(
                icon: Icons.shield_rounded,
                label: 'Política de privacidad',
                subtitle: 'Cómo tratamos tus datos',
                onTap: () => _showInfoModal(
                  title: 'Política de privacidad',
                  content: _privacyContent,
                ),
              ),
              _buildDivider(),
              _buildInfoRow(
                icon: Icons.code_rounded,
                label: 'Licencias de terceros',
                subtitle: 'Librerías y recursos utilizados',
                onTap: () => _showInfoModal(
                  title: 'Licencias de terceros',
                  content: _licensesContent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Soporte
        _buildSectionLabel('Soporte'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2560)),
          ),
          child: _buildInfoRow(
            icon: Icons.email_rounded,
            label: 'Contacto / Soporte',
            subtitle: 'soporte@cyberops.com',
            onTap: () => _showInfoModal(
              title: 'Contacto / Soporte',
              content: _contactContent,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Créditos
        _buildSectionLabel('Créditos'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A2560)),
          ),
          child: _buildInfoRow(
            icon: Icons.group_rounded,
            label: 'Créditos del equipo',
            subtitle: 'Proyecto DAM 2026',
            onTap: () => _showInfoModal(
              title: 'Créditos del equipo',
              content: _creditsContent,
            ),
          ),
        ),
      ],
    ),
  );
}
// ─── TARJETA DE VERSIÓN ───────────────────────────────
Widget _buildVersionCard() {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF0A0E28),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF1A2560)),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/logo.png', 
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cyber Ops', 
                style: TextStyle(
                  color: Color(0xFFE8E4FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Versión 1.0.0 · Build 2026',
                style: TextStyle(
                  color: Color(0xFF3D4F8C),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2560),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0xFF2A3A8A)),
          ),
          child: const Text(
            'DAM 2026',
            style: TextStyle(
              color: Color(0xFF5B8FFF),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
// ─── FILA DE INFO ─────────────────────────────────────
Widget _buildInfoRow({
  required IconData icon,
  required String label,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF151D4A),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFF1A2560)),
            ),
            child: Icon(icon, color: AppColors.purple, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFC8D0F0),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF3D4F8C),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF3D4F8C),
            size: 16,
          ),
        ],
      ),
    ),
  );
}
// ─── MODAL DE INFORMACIÓN ─────────────────────────────
void _showInfoModal({
  required String title,
  required String content,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF0D1033),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF2A3A8A), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFE8E4FF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  content,
                  style: const TextStyle(
                    color: Color(0xFF5B6FA8),
                    fontSize: 12,
                    height: 1.7,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: const Color(0xFFC4BFFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: AppColors.purple.withValues(alpha: 0.7),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8,
                  ),
                ),
                child: const Text('Cerrar', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
// ─── CONTENIDOS DE LOS MODALES ────────────────────────

static const String _termsContent = '''
1. Uso de la app
Esta aplicación es un proyecto desarrollado como Trabajo de Prácticas DAM 2026.

2. Cuenta de usuario
El usuario es responsable de mantener la confidencialidad de sus credenciales de acceso.

3. Contenido
Todo el contenido de la app es propiedad de sus creadores. Queda prohibida su reproducción sin autorización.

4. Modificaciones
Nos reservamos el derecho de modificar estos términos en cualquier momento.
''';

static const String _privacyContent = '''
Datos que recogemos
Recogemos nombre de usuario, email y foto de perfil para el funcionamiento de la cuenta.

Uso de los datos
Los datos se usan exclusivamente para identificar al usuario dentro de la app. No se comparten con terceros.

Almacenamiento
Los datos se almacenan en Firebase (Google) con cifrado en tránsito y en reposo.

Tus derechos
Puedes solicitar la eliminación de tus datos en cualquier momento desde Ajustes → Cuenta.
''';

static const String _licensesContent = '''
Flutter — BSD 3-Clause License
Copyright © Google LLC

Firebase — Apache License 2.0
Copyright © Google LLC

firebase_auth — BSD 3-Clause

cloud_firestore — BSD 3-Clause

package_info_plus — BSD 3-Clause

url_launcher — BSD 3-Clause
''';

static const String _contactContent = '''
Para cualquier duda, sugerencia o reporte de errores puedes contactarnos en:

soporte@cyberops.com

Intentamos responder en un plazo máximo de 48 horas laborables.
''';

static const String _creditsContent = '''
Desarrollo y diseño
Gerardo Eliud Fernández Gómez
Iván Pérez Pérez
Marisol Poffer Mercado

Música y sonido
Recursos libres de derechos

Proyecto DAM 2026
Trabajo de Prácticas · Ciclo Formativo de Grado Superior en Desarrollo de Aplicaciones Multiplataforma.
''';

}
// ─────────────────────────────────────────────
// BACKGROUND PAINTER (MISMO QUE MENU SCREEN)
// ─────────────────────────────────────────────

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
      final paint = Paint()
        ..color = AppColors.purple.withValues(alpha: ring.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawCircle(Offset(cx, cy), ring.radius, paint);
    }

    final dotPaint = Paint()..style = PaintingStyle.fill;

    final dots = [
      (angle: progress * 2 * math.pi, radius: 280.0, color: AppColors.purple, size: 3.0),
      (angle: progress * 2 * math.pi + math.pi, radius: 280.0, color: AppColors.blue, size: 3.0),
      (angle: -progress * 2 * math.pi + math.pi / 3, radius: 200.0, color: AppColors.cyan, size: 2.5),
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
