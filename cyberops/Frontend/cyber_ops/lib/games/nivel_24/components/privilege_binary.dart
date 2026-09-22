/// Representa un binario del sistema con sus flags de permisos
class PrivilegeBinary {
  final String id;
  final String nombre;
  final String permisos;       // ej: "-rwsr-xr-x"
  final String propietario;    // ej: "root"
  final String descripcion;
  final bool esSuidVulnerable; // true = este es el binario correcto
 
  const PrivilegeBinary({
    required this.id,
    required this.nombre,
    required this.permisos,
    required this.propietario,
    required this.descripcion,
    required this.esSuidVulnerable,
  });
}