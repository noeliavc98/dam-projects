import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class FracturaAvatar extends StatefulWidget {
  final bool hablando;
  final double size;

  const FracturaAvatar({super.key, required this.hablando, this.size = 220});

  @override
  State<FracturaAvatar> createState() => _FracturaAvatarState();
}

class _FracturaAvatarState extends State<FracturaAvatar> {
  final Random _random = Random();
  Timer? _timer;
  int _bocaActual = 0;
  int _frameAnimacion = 0;

  final List<String> _bocas = const [
    'assets/images/fractura_boca_cerrada.png',
    'assets/images/fractura_boca_media.png',
    'assets/images/fractura_boca_abierta.png',
  ];

  @override
  void initState() {
    super.initState();
    _actualizarAnimacion();
  }

  @override
  void didUpdateWidget(covariant FracturaAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.hablando != widget.hablando) {
      _actualizarAnimacion();
    }
  }

  void _actualizarAnimacion() {
    _timer?.cancel();

    if (!widget.hablando) {
      setState(() {
        _bocaActual = 0;
        _frameAnimacion++;
      });
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 110), (_) {
      if (!mounted) return;

      setState(() {
        final siguienteBoca = 1 + _random.nextInt(2);
        if (siguienteBoca == _bocaActual) return;
        _bocaActual = siguienteBoca;
        _frameAnimacion++;
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 80),
      child: Image.asset(
        _bocas[_bocaActual],
        key: ValueKey(_frameAnimacion),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
      ),
    );
  }
}
