import 'dart:io';
import 'dart:convert';

import 'package:cyber_ops/config/app_styles.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:cyber_ops/config/app_colors.dart';

class ChangeProfilePhotoScreen extends StatefulWidget {
  final String? fotoActual;

  const ChangeProfilePhotoScreen({super.key, this.fotoActual});

  @override
  State<ChangeProfilePhotoScreen> createState() => _ChangeProfilePhotoScreenState();
}

class _ChangeProfilePhotoScreenState extends State<ChangeProfilePhotoScreen> {
  XFile? _selectedImageMobile;
  Uint8List? _selectedImageWeb;
  Uint8List? _previewBytes;
  bool _subiendo = false;

  // Tamaño máximo recomendado para Firestore (~900 KB para ir segura)
  static const int maxBytesFirestore = 900000;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  // -------------------------------------------------------------
  // PROCESADO DE IMAGEN 
  // -------------------------------------------------------------
  Future<Uint8List?> _processImageBytes(Uint8List originalBytes) async {
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) return null;

    //Redimensionar manteniendo proporción
    final resized = img.copyResize(
      decoded,
      width: 256,
      maintainAspect: true,
    );

    //Comprimir directamente la imagen redimensionada
    final encoder = img.JpegEncoder(quality: 65);
    Uint8List jpgBytes = Uint8List.fromList(encoder.encode(resized));

    int quality = 60;
    while (jpgBytes.length > maxBytesFirestore && quality > 40) {
      final enc = img.JpegEncoder(quality: quality);
      jpgBytes = Uint8List.fromList(enc.encode(resized));
      quality -= 10;
    }

    return jpgBytes;
  }

  // -------------------------------------------------------------
  // CARGAR PREVIEW
  // -------------------------------------------------------------
  Future<void> _loadPreview() async {
    Uint8List? bytes;

    if (_selectedImageWeb != null) {
      bytes = await _processImageBytes(_selectedImageWeb!);
    } else if (_selectedImageMobile != null) {
      bytes = await _processImageBytes(
        File(_selectedImageMobile!.path).readAsBytesSync(),
      );
    } else if (widget.fotoActual != null) {
      bytes = await _processImageBytes(
        base64Decode(widget.fotoActual!),
      );
    }

    setState(() => _previewBytes = bytes);
  }
  // -------------------------------------------------------------
  // SELECCIONAR IMAGEN
  // -------------------------------------------------------------
  Future<void> _pickImage() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedImageWeb = result.files.single.bytes!;
          _selectedImageMobile = null;
        });
        _loadPreview();
      }
    } else {
      final picker = ImagePicker();
      final imgPicked = await picker.pickImage(source: ImageSource.gallery);
      if (imgPicked != null) {
        setState(() {
          _selectedImageMobile = imgPicked;
          _selectedImageWeb = null;
      });
      _loadPreview();
      }
    }
  }

   // -------------------------------------------------------------
  // SUBIR IMAGEN
  // -------------------------------------------------------------
  Future<void> _uploadImage() async {
    if (_previewBytes == null) return;

    setState(() => _subiendo = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final base64Image = base64Encode(_previewBytes!);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'fotoPerfil': base64Image}, SetOptions(merge: true));

    if (mounted) Navigator.pop(context, base64Image);

    setState(() => _subiendo = false);
  }


  // -------------------------------------------------------------
  // UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
        colors: [AppColors.purple, AppColors.blue, AppColors.cyan],
      ).createShader(bounds),
      child: const Text('CAMBIAR FOTO DE PERFIL', style: AppStyles.body),
    ),
  ),

      body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 90),
            const Text(
              "Selecciona una nueva imagen de perfil:", 
              style: TextStyle(
                color: AppColors.cyan,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 50),
            //Carrusel giratorio
            PhotoSelectorCarousel(
              fotoActualBytes: _previewBytes,
              onPickFromGallery: _pickImage,
              onSelectPreset: (bytes) async {
                final processed = await _processImageBytes(bytes);
                setState(() {
                  _previewBytes = processed;
                  _selectedImageMobile = null;
                  _selectedImageWeb = null;
                });
              },
            ),

            const SizedBox(height: 40),

            //Botón guardar
            HoverZoomButton(
              onTap: _subiendo ? () {} : _uploadImage,
              child: ElevatedButton.icon(
                onPressed: _subiendo ? null : _uploadImage,
                icon: const Icon(Icons.save_rounded),
                label: Text(_subiendo ? "Guardando..." : "Guardar foto"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ],
      ),
    );
  }
}

// -------------------------------------------------------------
// CARRUSEL CON FLECHAS
// -------------------------------------------------------------
class PhotoSelectorCarousel extends StatefulWidget {
  final Uint8List? fotoActualBytes;
  final Function() onPickFromGallery;
  final Function(Uint8List bytes) onSelectPreset;


    const PhotoSelectorCarousel({
    super.key,
    required this.fotoActualBytes,
    required this.onPickFromGallery,
    required this.onSelectPreset, 
  });

  @override
  State<PhotoSelectorCarousel> createState() => _PhotoSelectorCarouselState();
}

class _PhotoSelectorCarouselState extends State<PhotoSelectorCarousel> {
  late PageController _controller;
  int _currentPage = 1; //Empezamos en el centro
  final List<String> presetImages = [
  "assets/images/preset1.jpg",
  "assets/images/preset2.png",
  "assets/images/preset3.jpg",
  ];


  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: 0.33,
      initialPage: 1, //Esto hace que la foto actual salga en el centro
    );
  }

  void _goLeft() {
    if (_currentPage > 0) {
      _currentPage--;
      _controller.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      setState(() {});
    }
  }

  void _goRight() {
    if (_currentPage < 1 + presetImages.length) {
      _currentPage++;
      _controller.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //Flecha izquierda
          IconButton(
            onPressed: _goLeft,
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: _currentPage == 0 ? Colors.white24 : Colors.white,
            ),
            iconSize: 28,
          ),

          //Carrusel
          SizedBox(
            width: 700, 
            height: 260,
            child: PageView.builder(
              controller: _controller,
              itemCount: 2 + presetImages.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double value = 1.0;

                      if (_controller.position.haveDimensions) {
                        value = (_controller.page! - index).abs();
                        value = (1 - value * 0.35).clamp(0.75, 1.0);
                      }

                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: _buildItemContent(index),
                  ),
                );
              },
            ),
          ),

          //Flecha derecha
          IconButton(
            onPressed: _goRight,
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              color: _currentPage == 1 + presetImages.length ? Colors.white24 : Colors.white,
            ),
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildItemType(int index) {
    if (index == 0) {
      return _buildOption(
        icon: Icons.photo_library_rounded,
        label: "Galería",
        color: AppColors.purple,
        onTap: () {
          widget.onPickFromGallery();

          _currentPage = 1;
          _controller.animateToPage(
            1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          setState(() {});
        },
      );
    }

    if (index == 1) {
      return _buildCurrentPhoto();
    }

    final presetIndex = index - 2;
    return _buildPresetPhoto(presetImages[presetIndex]);
  }

  Widget _buildItemContent(int index) {
     return _HoverableItem(
      index: index,
      currentPage: _currentPage,
      child: _buildItemType(index),
    );
  }

  Widget _buildPresetPhoto(String assetPath) {
   return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      GestureDetector(
        onTap: () async {
          //Cargo los bytes de la imagen predeterminada
          final data = await rootBundle.load(assetPath);
          //Procesa y actualiza la foto actual
          widget.onSelectPreset(data.buffer.asUint8List());
          //Muevo el carrusel al centro(index 1)
          _currentPage = 1;
          _controller.animateToPage(
            1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          setState(() {});
        },
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cyan, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.35),
                blurRadius: 18,
                spreadRadius: 2,
              )
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
        const SizedBox(height: 8),
        const Text(
          "Predeterminadas",
          style: TextStyle(color: AppColors.cyan, fontSize: 16),
        ),
      ],
  );
}

  Widget _buildCurrentPhoto() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cyan, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: ClipOval(
            child: widget.fotoActualBytes == null
                ? const Icon(Icons.person, size: 80, color: Colors.white70)
                : Image.memory(widget.fotoActualBytes!, fit: BoxFit.cover),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          "Foto de perfil actual",
          style: TextStyle(color: AppColors.cyan, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        height: 130,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 2,
            )
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 45, color: Colors.white),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
//Zoom al pasar el cursor encima del icono de perfil
class _HoverableItem extends StatefulWidget {
  final int index;
  final int currentPage;
  final Widget child;

  const _HoverableItem({
    required this.index,
    required this.currentPage,
    required this.child,
  });

  @override
  State<_HoverableItem> createState() => _HoverableItemState();
}

class _HoverableItemState extends State<_HoverableItem> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool isCenter = widget.index == widget.currentPage;

    return MouseRegion(
      onEnter: (_) {
        if (isCenter) setState(() => hovering = true);
      },
      onExit: (_) {
        if (isCenter) setState(() => hovering = false);
      },
      child: AnimatedScale(
        scale: isCenter
            ? (hovering ? 1.25 : 1.15) 
            : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

//Zoom para botón guardar
class HoverZoomButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const HoverZoomButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<HoverZoomButton> createState() => _HoverZoomButtonState();
}

class _HoverZoomButtonState extends State<HoverZoomButton> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedScale(
        scale: hovering ? 1.10 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}