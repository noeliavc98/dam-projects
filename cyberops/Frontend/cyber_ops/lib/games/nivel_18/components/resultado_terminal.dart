class ResultadoTerminal {
  final String salida;
  final bool correcto;
  final bool pierdeVida;
  final bool nivelCompletado;
  final bool easterEgg;
  final int xpGanada;

  const ResultadoTerminal({
    required this.salida,
    this.correcto = false,
    this.pierdeVida = false,
    this.nivelCompletado = false,
    this.easterEgg = false,
    this.xpGanada = 0,
  });
}