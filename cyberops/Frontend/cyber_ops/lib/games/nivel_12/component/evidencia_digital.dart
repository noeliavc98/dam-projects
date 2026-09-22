enum CategoriaEvidenciaDigital {
  navegador,
  procesos,
  archivos,
  sesiones,
  wallets,
  red,
}

extension CategoriaEvidenciaDigitalLabel on CategoriaEvidenciaDigital {
  String get label {
    switch (this) {
      case CategoriaEvidenciaDigital.navegador:
        return 'NAVEGADOR';
      case CategoriaEvidenciaDigital.procesos:
        return 'PROCESOS';
      case CategoriaEvidenciaDigital.archivos:
        return 'ARCHIVOS';
      case CategoriaEvidenciaDigital.sesiones:
        return 'SESIONES';
      case CategoriaEvidenciaDigital.wallets:
        return 'WALLETS';
      case CategoriaEvidenciaDigital.red:
        return 'RED';
    }
  }
}

class EvidenciaDigital {
  final String id;
  final CategoriaEvidenciaDigital categoria;
  final String titulo;
  final String subtitulo;
  final String descripcion;
  final bool esRastroStealer;
  final String explicacion;

  const EvidenciaDigital({
    required this.id,
    required this.categoria,
    required this.titulo,
    required this.subtitulo,
    required this.descripcion,
    required this.esRastroStealer,
    required this.explicacion,
  });
}