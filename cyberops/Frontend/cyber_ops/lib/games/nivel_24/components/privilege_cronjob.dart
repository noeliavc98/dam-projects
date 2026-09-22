/// Representa una entrada del crontab del sistema
class PrivilegeCronjob {
  final String id;
  final String schedule;    // ej: "*/1 * * * *"
  final String usuario;     // ej: "root"
  final String rutaScript;  // ej: "/opt/maintenance/cleanup.sh"
  final String descripcion;
  final bool esVulnerable;  // true = este cronjob apunta a carpeta escribible
 
  const PrivilegeCronjob({
    required this.id,
    required this.schedule,
    required this.usuario,
    required this.rutaScript,
    required this.descripcion,
    required this.esVulnerable,
  });
}