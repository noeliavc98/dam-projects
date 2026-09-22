import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {

  // TÍTULOS PRINCIPALES
  static const titleMain = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w900,
    color: Colors.white, // necesario para que ShaderMask funcione
    letterSpacing: 10,
  );

  // SUBTÍTULOS EN MAYÚSCULAS
  static const subtitle = TextStyle(
    fontSize: 11,
    color: AppColors.purple,
    letterSpacing: 5,
  );

  // TEXTO DE BOTONES
  static const buttonPrimary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 4,
  );

  static const buttonSecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.purple,
    letterSpacing: 4,
  );

  // TEXTO DE CUERPO
  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  // TEXTO PEQUEÑO (versión, créditos)
  static const small = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 3,
  );

  // ETIQUETAS E HINTS EN INPUTS
  static const hint = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.purple,
  );

  // TÍTULOS DE PANTALLA (login, registro, etc.)
  static const screenTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 6,
  );
}