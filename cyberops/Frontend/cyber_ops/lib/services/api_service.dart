import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // ── Cambia esta URL cuando despliegues el backend en producción ──────────
  static const String _baseUrl = 'http://127.0.0.1:8080';

  // ── Obtener preguntas de una misión ──────────────────────────────────────
  static Future<List<Map<String, dynamic>>> obtenerPreguntas({
    required int nivel,
    required int mision,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/nivel/$nivel/mision/$mision/preguntas'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['preguntas']);
      }
      return [];
    } catch (e) {
      debugPrint('Error obteniendo preguntas: $e');
      return [];
    }
  }

  // ── Guardar puntuación en Firestore ──────────────────────────────────────
  static Future<bool> guardarPuntuacion({
    required String usuarioId,
    required int puntos,
    required int nivel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/puntuacion/guardar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuario_id': usuarioId,
          'puntos': puntos,
          'nivel': nivel,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error guardando puntuación: $e');
      return false;
    }
  }
}