import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:otp/otp.dart';


class AuthService {

  // Instancia de FirebaseAuth para comunicarnos con Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── REGISTRO DE USUARIO NUEVO ──────────────────────────────────────────────
  // Crea una cuenta en Firebase Auth Y guarda los datos en Firestore
  // Devuelve null si todo va bien, o un mensaje de error si falla
  Future<String?> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Paso 1: Creamos el usuario en Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Paso 2: Actualizamos el nombre en Firebase Auth
      await credential.user!.updateDisplayName(username);

      await credential.user!.reload();
      //Enviar correo de verificación
      await credential.user!.sendEmailVerification();

      // Paso 3: Guardamos los datos del usuario en Firestore
      // Esto es lo que faltaba antes — sin esto el perfil no tiene datos
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'uid': credential.user!.uid,
        'email': email,
        'name': username,
        'created_at': Timestamp.now(),
        'puntuacion_total': 0,
        'partidas_jugadas': 0,
        'nivel': 1,
        'alias': '',
        'bio': '',
        'fotoPerfil': null,
      });

      debugPrint('Usuario registrado y guardado en Firestore correctamente');
 
      // null significa que no hay error
      return null;

    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (e) {
      debugPrint('Error inesperado en el registro: $e');
      
      return 'Error en registro: ${e.toString()}';
    }
  }

  // ── LOGIN DE USUARIO EXISTENTE ─────────────────────────────────────────────
  // Inicia sesión con email y contraseña
  // Devuelve null si todo va bien, o un mensaje de error si falla
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Recargamos usuario desde Firebase
      await credential.user!.reload();

      final refreshedUser =
        FirebaseAuth.instance.currentUser;

      // Verificamos email
      if (refreshedUser != null &&
          !refreshedUser.emailVerified) {

        return 'EMAIL_NOT_VERIFIED';
      }

      return null; // null = éxito

    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    }
  }

  // ── CERRAR SESIÓN ──────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _auth.signOut();
      debugPrint('Sesión cerrada correctamente');
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
  }

  // ── USUARIO ACTUAL ─────────────────────────────────────────────────────────
  // Devuelve el usuario que tiene sesión iniciada, o null si no hay ninguno
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // ── ESCUCHAR CAMBIOS DE SESIÓN ─────────────────────────────────────────────
  // Stream que emite un evento cada vez que el estado de sesión cambia
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  get base32 => null;
  
  get OTP => null;

  // ── RECUPERACIÓN DE CONTRASEÑA ─────────────────────────────────────────────
  Future<String?> sendPasswordResetEmail({required String email}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      return 'No se pudo enviar el correo. Inténtalo de nuevo.';
    }
  }

  // ── 2FA / TOTP ────────────────────────────────────────────────────────────

  String generateTotpSecret() {
    final bytes = Uint8List.fromList(
      List<int>.generate(20, (_) => Random.secure().nextInt(256)),
    );
    return _base32Encode(bytes);
  }

  String _base32Encode(Uint8List data) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    var result = '';
    var buffer = 0;
    var bitsLeft = 0;
    for (final byte in data) {
      buffer = (buffer << 8) | byte;
      bitsLeft += 8;
      while (bitsLeft >= 5) {
        bitsLeft -= 5;
        result += alphabet[(buffer >> bitsLeft) & 0x1F];
      }
    }
    if (bitsLeft > 0) {
      result += alphabet[(buffer << (5 - bitsLeft)) & 0x1F];
    }
    return result;
  }

  Future<bool> isTotpEnabled() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data()?['totp_enabled'] == true;
  }

  Future<void> saveTotpSecret(String secret) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'totp_secret': secret, 'totp_enabled': true});
  }

  Future<bool> validateTotpCode(String code) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final secret = doc.data()?['totp_secret'] as String?;
    if (secret == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final drift in [-1, 0, 1]) {
      final expected = OTP.generateTOTPCodeString(
        secret,
        now + drift * 30000,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      if (expected == code) return true;
    }
    return false;
  }

  Future<void> disableTotp() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'totp_secret': FieldValue.delete(), 'totp_enabled': false});
  }

  // ── MAPEO DE ERRORES ───────────────────────────────────────────────────────
  // Convierte los códigos de error de Firebase en mensajes en español
  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con ese email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'El formato del email no es válido';
      case 'email-already-in-use':
        return 'Este email ya está registrado';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'invalid-credential':
        return 'Email o contraseña incorrectos';
      default:
        return 'Error inesperado: $code';
    }
  }
}