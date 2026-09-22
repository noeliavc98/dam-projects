class DatosNivel07 {
  static const String password = 'enigma1939';
  static const int puntosNivel = 800;
  static const int vidasIniciales = 3;
  static const int intentosPorVida = 3;

  static const List<String> dialogosIntro = [
    'La siguiente puerta no cae con una pista perfecta.',
    'Cae con intentos. Con comparaciones. Con paciencia.',
    'Vas a ver la fuerza bruta como la vería una máquina: probar, medir, corregir, repetir.',
    'Cada carácter acertado en su posición se iluminará en verde.',
    'No atacarás ningún sistema real. Esto es un laboratorio cerrado.',
  ];

  static const List<String> dialogosFinales = [
    'Acceso simulado concedido.',
    'Has hecho a mano lo que un ordenador haría a gran velocidad: generar candidatos y compararlos con una condición de éxito.',
    'En fuerza bruta pura, la máquina prueba todas las combinaciones posibles hasta encontrar la clave.',
    'Si sabe longitud, caracteres permitidos o patrones humanos, reduce muchísimo el espacio de búsqueda.',
    'Un ataque de diccionario prueba palabras comunes. Un ataque por máscara prueba formatos probables, como palabra más año.',
    'Las defensas son esenciales: contraseñas largas, MFA, bloqueo por intentos, rate limiting, salts y hashing fuerte.',
    'La lección es simple: cada pista sobre tu contraseña reduce el trabajo del atacante.',
  ];

  static const List<String> pistasDesbloqueables = [
    'Máquina de cifrado Alemana.',
    'Evento importante relacionado con esta máquina.',
    '¿Has probado fechas?.',
    'Año del conflicto',
  ];
}
