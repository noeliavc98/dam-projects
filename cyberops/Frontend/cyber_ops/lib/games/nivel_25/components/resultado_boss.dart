class ResultadoBoss {
  final bool correcto;
  final bool victoria;
  final bool derrota;
  final String mensaje;
  final int xpGanada;
  final bool fragmentoDesbloqueado;

  const ResultadoBoss({
    required this.correcto,
    required this.victoria,
    required this.derrota,
    required this.mensaje,
    this.xpGanada = 0,
    this.fragmentoDesbloqueado = false,
  });
}