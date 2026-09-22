enum TipoAtaqueBoss {
  phishing,
  tokenRobado,
  ransomware,
  privilegios,
  exfiltracion,
  persistencia,
  comboFinal,
}

class AtaqueBoss {
  final String id;
  final String titulo;
  final String descripcion;
  final TipoAtaqueBoss tipo;
  final List<String> defensasCorrectas;
  final String explicacion;
  final int danoSiFalla;
  final int danoAlBoss;

  const AtaqueBoss({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.defensasCorrectas,
    required this.explicacion,
    required this.danoSiFalla,
    required this.danoAlBoss,
  });
}