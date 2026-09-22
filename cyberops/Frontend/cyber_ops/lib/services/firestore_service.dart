import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio centralizado para todas las operaciones con Firestore.
/// Todos los métodos son estáticos para usarlos sin instanciar la clase.
class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── GUARDAR PUNTUACIÓN Y DESBLOQUEAR SIGUIENTE NIVEL ────────────────────────
  /// Guarda los puntos obtenidos y desbloquea el siguiente nivel.
  /// - Si es entrenamiento: NO guarda nada
  /// - Si es normal: guarda progreso completo
  static Future<void> guardarPuntuacion({
    required int puntos,
    required int nivelCompletado,
    bool soloEntrenamiento = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // ❌ ENTRENAMIENTO: NO SE GUARDA NADA
    if (soloEntrenamiento) return;

    final ref = _db.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (!doc.exists) return;

    final datos = doc.data()!;
    final puntuacionActual = datos['puntuacion_total'] ?? 0;
    final nivelActual = datos['nivel'] ?? 1;
    final partidas = datos['partidas_jugadas'] ?? 0;

    await ref.update({
      // ✔️ Suma de puntos SOLO en modo normal
      'puntuacion_total': puntuacionActual + puntos,

      // ✔️ Partidas SOLO en modo normal
      'partidas_jugadas': partidas + 1,

      // ✔️ Progreso de nivel SOLO en modo normal
      'nivel': nivelActual <= nivelCompletado
          ? nivelCompletado + 1
          : nivelActual,

      'ultimo_nivel_completado': nivelCompletado,
      'ultima_partida': DateTime.now().toIso8601String(),
    });
  }

  // ── GUARDAR MISIÓN COMPLETADA ────────────────────────────────────────────────
  static Future<void> guardarMision({
    required int nivel,
    required int mision,
    required int puntos,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('misiones')
        .doc('nivel${nivel}_mision$mision')
        .set(
      {
        'completada': true,
        'puntos': puntos,
        'nivel': nivel,
        'mision': mision,
        'fecha': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  // ── OBTENER USUARIO ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> obtenerUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.exists ? doc.data()! : {};
  }
}