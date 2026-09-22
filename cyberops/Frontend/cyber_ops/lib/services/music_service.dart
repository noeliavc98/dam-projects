import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicService extends ChangeNotifier {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  Future<void> _musicOperation = Future<void>.value();
  String? _currentMusic;

  String? get currentMusic => _currentMusic;

  double _musicVolume = 0.7;
  double _lastMusicVolume = 0.7;
  bool _musicMuted = false;
  double _sfxVolume = 0.55;

  double get musicVolume => _musicVolume;
  bool get musicMuted => _musicMuted;

  MusicService._internal();

  Future<void> _runMusicOperation(Future<void> Function() operation) {
    _musicOperation = _musicOperation
        .catchError((_) {})
        .then((_) => operation());
    return _musicOperation;
  }
  

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _musicVolume = prefs.getDouble('volMusica')  ?? 0.7;
    _sfxVolume   = prefs.getDouble('volEfectos') ?? 0.55;
    _player.setVolume(_musicVolume);
  }

  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);

    if (_musicVolume > 0) {
      _lastMusicVolume = _musicVolume;
      _musicMuted = false;
    } else {
      _musicMuted = true;
    }

    _player.setVolume(_musicMuted ? 0.0 : _musicVolume);
    notifyListeners();
  }

  void toggleMusicMuted() {
    _musicMuted = !_musicMuted;

    if (_musicMuted) {
      _player.setVolume(0.0);
    } else {
      _musicVolume = _lastMusicVolume <= 0 ? 0.7 : _lastMusicVolume;
      _player.setVolume(_musicVolume);
    }

    notifyListeners();
  }

  void setMusicMuted(bool muted) {
    if (_musicMuted == muted) return;

    _musicMuted = muted;

    if (_musicMuted) {
      _player.setVolume(0.0);
    } else {
      _musicVolume = _lastMusicVolume <= 0 ? 0.7 : _lastMusicVolume;
      _player.setVolume(_musicVolume);
    }

    notifyListeners();
  }

  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  Future<void> playMenuMusic() async {
    await _runMusicOperation(() async {
      if (_currentMusic == 'menu' && _player.playing) return;

    await _player.stop();
    await _player.setAsset('assets/audio/menu_music.ogg');
    await _player.setLoopMode(LoopMode.one);
    await _player.setVolume(_musicVolume);
    _currentMusic = 'menu';
    unawaited(_player.play());
    });
  }

  Future<void> playNivel2Music({bool restart = false}) async {
    if (!restart && _currentMusic == 'nivel2' && _player.playing) return;

      await _player.stop();
      await _player.setAsset('assets/audio/cancionNivel2.ogg');
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(_musicMuted ? 0.0 : _musicVolume);
      _currentMusic = 'nivel2';
      unawaited(_player.play());
      debugPrint('NIVEL 2 MUSIC SONANDO');
    }

  Future<void> playNivel17Music() async {
    await _player.stop();
    await _player.setAsset('assets/audio/nivel17_music.ogg');
    await _player.setLoopMode(LoopMode.one);
    await _player.setVolume(_musicVolume);
    unawaited(_player.play());
  }

  Future<void> playNiveles21to25Music() async {
    await _player.stop();
    await _player.setAsset('assets/audio/niveles21to25_music.ogg');
    await _player.setLoopMode(LoopMode.one);
    await _player.setVolume(_musicVolume);
    _player.play();
  }
  Future<void> playNiveles6to10Music() async {
    if (_currentMusic == 'niveles6to10' && _player.playing) return;
    await _player.stop();
    await _player.setAsset('assets/audio/niveles6to10_music.ogg');
    await _player.setLoopMode(LoopMode.one);
    await _player.setVolume(_musicVolume);
    _currentMusic = 'niveles6to10';
    unawaited(_player.play());
  }

  Future<void> playNiveles11to15Music() async {
    if (_currentMusic == 'niveles11to15' && _player.playing) return;
    await _player.stop();
    await _player.setAsset('assets/audio/niveles11to15_music.ogg');
    await _player.setLoopMode(LoopMode.one);
    await _player.setVolume(_musicVolume);
    _currentMusic = 'niveles11to15';
    _player.play();
  }


  Future<void> stopMusic() async {
    await _runMusicOperation(() async {
      if (_currentMusic == null && !_player.playing) return;

      await _player.stop();
      _currentMusic = null;
      debugPrint('MUSIC PARADA');
    });
  }

  Future<void> playDisparo() async {
    await _playSfx(
      asset: 'assets/audio/disparo.mp3',
      volume: _sfxVolume,
      label: 'DISPARO',
    );
  }

  Future<void> playToqueNodo() async {
    await _playSfx(
      asset: 'assets/audio/nodo.mp3',
      volume: _sfxVolume,
      label: 'NODO',
    );
  }

  Future<void> playEscudo() async {
    await _playSfx(
      asset: 'assets/audio/pulso.mp3',
      volume: _sfxVolume,
      label: 'ESCUDO',
    );
  }

  Future<void> playExplosion() async {
    await _playSfx(
      asset: 'assets/audio/explosion_enemigo.ogg',
      volume: _sfxVolume,
      label: 'EXPLOSION',
    );
  }

  Future<void> _playSfx({
    required String asset,
    required double volume,
    required String label,
  }) async {
    final player = AudioPlayer();

    try {
      await player.setAsset(asset);
      await player.setVolume(volume);
      unawaited(_playAndDispose(player, label));
      debugPrint('SFX $label');
    } catch (e) {
      await player.dispose();
      debugPrint('ERROR SFX $label: $e');
    }
  }

  Future<void> _playAndDispose(AudioPlayer player, String label) async {
    try {
      await player.play();
    } catch (e) {
      debugPrint('ERROR SFX $label: $e');
    } finally {
      await player.dispose();
    }
  }
}
