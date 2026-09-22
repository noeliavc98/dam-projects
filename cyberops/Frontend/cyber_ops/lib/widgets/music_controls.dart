import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_colors.dart';
import '../services/music_service.dart';

class MusicControls extends StatefulWidget {
  const MusicControls({super.key});

  @override
  State<MusicControls> createState() => _MusicControlsState();
}

class _MusicControlsState extends State<MusicControls> {
  late double _musicVolume;
  late bool _musicMuted;

  @override
  void initState() {
    super.initState();
    _syncFromMusicService();
    MusicService().addListener(_syncFromMusicService);
  }

  void _syncFromMusicService() {
    if (!mounted) return;

    setState(() {
      _musicVolume = MusicService().musicVolume;
      _musicMuted = MusicService().musicMuted;
    });
  }

  @override
  void dispose() {
    MusicService().removeListener(_syncFromMusicService);
    super.dispose();
  }

  Future<void> _saveMusicVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('volMusica', value);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try { 
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('ajustes')
          .doc('ui')
          .set(
            {
              'volMusica': value,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('No se pudo guardar volMusica en Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: SafeArea(
        child: PopupMenuButton<int>(
          tooltip: 'Audio',
          color: AppColors.bgCard,
          offset: const Offset(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: AppColors.purple.withValues(alpha: 0.45),
            ),
          ),
          itemBuilder: (context) => [
            PopupMenuItem<int>(
              enabled: false,
              child: StatefulBuilder(
                builder: (context, menuSetState) {
                  return SizedBox(
                    width: 180,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: _musicMuted
                                  ? 'Activar música'
                                  : 'Silenciar música',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              iconSize: 20,
                              icon: Icon(
                                _musicMuted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                color: AppColors.cyan,
                              ),
                              onPressed: () {
                                setState(() {
                                  MusicService().toggleMusicMuted();
                                  _musicMuted = MusicService().musicMuted;
                                  _musicVolume = MusicService().musicVolume;
                                });

                                menuSetState(() {});
                              },
                            ),
                            Expanded(
                              child: Slider(
                                value: _musicVolume,
                                min: 0,
                                max: 1,
                                onChanged: (value) {
                                  setState(() {
                                    _musicVolume = value;
                                    MusicService().setMusicVolume(value);
                                    _musicMuted = MusicService().musicMuted;
                                  });

                                  _saveMusicVolume(value);
                                  menuSetState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgCard.withValues(alpha: 0.85),
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.45),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _musicMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              color: AppColors.cyan,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}