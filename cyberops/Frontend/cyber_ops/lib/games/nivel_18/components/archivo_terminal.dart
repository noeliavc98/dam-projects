class ArchivoTerminal {
  final String nombre;
  final String contenido;
  final bool oculto;
  final String descripcion;

  const ArchivoTerminal({
    required this.nombre,
    required this.contenido,
    required this.descripcion,
    this.oculto = false,
  });
}