enum AlertSeveridad { baja, media, alta, critica }

enum AlertCategoria { autenticacion, red, endpoint, malware, sistema, acceso }

enum AlertAccion { escalar, ignorar, contener }

class SocAlert {
  final String id;
  final String titulo;
  final String descripcion;
  final AlertSeveridad severidad;
  final AlertCategoria categoria;
  final AlertAccion accionCorrecta;
  final String explicacion;

  const SocAlert({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.severidad,
    required this.categoria,
    required this.accionCorrecta,
    required this.explicacion,
  });
}
