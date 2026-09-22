// ── Modelos de datos — Nivel 22: Operación Spoofing ───────────────────────────

class SmsPrueba {
  final String descripcionObjetivo;
  final List<String> pistas;
  final List<String> opcionesEmisor;
  final int idxEmisorCorrecto;
  final List<String> opcionesMensaje;
  final int idxMensajeCorrecto;
  final List<String> opcionesNombreAtaque;
  final int idxNombreCorrecto;
  final String explicacion;

  const SmsPrueba({
    required this.descripcionObjetivo,
    required this.pistas,
    required this.opcionesEmisor,
    required this.idxEmisorCorrecto,
    required this.opcionesMensaje,
    required this.idxMensajeCorrecto,
    required this.opcionesNombreAtaque,
    required this.idxNombreCorrecto,
    required this.explicacion,
  });
}

class EmailPrueba {
  final String descripcionObjetivo;
  final List<String> pistas;
  final List<String> opcionesFrom;
  final int idxFromCorrecto;
  final List<String> opcionesMensaje;
  final int idxMensajeCorrecto;
  final List<String> opcionesNombreAtaque;
  final int idxNombreCorrecto;
  final String explicacion;

  const EmailPrueba({
    required this.descripcionObjetivo,
    required this.pistas,
    required this.opcionesFrom,
    required this.idxFromCorrecto,
    required this.opcionesMensaje,
    required this.idxMensajeCorrecto,
    required this.opcionesNombreAtaque,
    required this.idxNombreCorrecto,
    required this.explicacion,
  });
}

enum TipoDeteccion { sms, email, web }

class DeteccionItem {
  final TipoDeteccion tipo;
  final String emisor;
  final String asunto;
  final String cuerpo;
  final bool esReal;
  final String explicacion;

  const DeteccionItem({
    required this.tipo,
    required this.emisor,
    this.asunto = '',
    required this.cuerpo,
    required this.esReal,
    required this.explicacion,
  });
}
