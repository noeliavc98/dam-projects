class EstadoFiltracion {
  final String id;
  final String nombre;
  final String descripcion;
  final bool critico;

  const EstadoFiltracion({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.critico = false,
  });
}