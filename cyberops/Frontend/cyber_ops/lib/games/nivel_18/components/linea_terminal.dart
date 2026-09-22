enum TipoLineaTerminal {
  normal,
  comando,
  correcto,
  error,
  sistema,
  easterEgg,
  jackpot,
}

class LineaTerminal {
  final String texto;
  final TipoLineaTerminal tipo;

  const LineaTerminal({
    required this.texto,
    this.tipo = TipoLineaTerminal.normal,
  });
}