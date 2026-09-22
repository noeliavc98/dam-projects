enum TipoAccionRespuesta {
  contener,
  recuperar,
  limpiar,
  verificar,
}

extension TipoAccionRespuestaLabel on TipoAccionRespuesta {
  String get label {
    switch (this) {
      case TipoAccionRespuesta.contener:
        return 'CONTENER';
      case TipoAccionRespuesta.recuperar:
        return 'RECUPERAR';
      case TipoAccionRespuesta.limpiar:
        return 'LIMPIAR';
      case TipoAccionRespuesta.verificar:
        return 'VERIFICAR';
    }
  }
}

class AccionRespuesta {
  final String id;
  final TipoAccionRespuesta tipo;
  final String titulo;
  final String descripcion;
  final bool esNecesaria;
  final bool esPeligrosa;
  final String feedback;

  const AccionRespuesta({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.esNecesaria,
    required this.esPeligrosa,
    required this.feedback,
  });
}