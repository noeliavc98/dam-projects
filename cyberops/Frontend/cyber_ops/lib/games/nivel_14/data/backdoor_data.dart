import '../components/backdoor_action.dart';
import '../components/backdoor_evidence.dart';

class BackdoorData {
  static const String serverName = 'MEDAC-FILES-03';

  static const String alertTitle = 'CONEXIÓN EXTERNA FUERA DE HORARIO';

  static const String alertDescription =
      'El servidor mantiene actividad remota después de eliminar el malware principal. '
      'Todo apunta a una puerta oculta usada para recuperar acceso.';

  static const List<BackdoorEvidence> evidences = [
    BackdoorEvidence(
      id: 'log_0314_external',
      category: BackdoorEvidenceCategory.logs,
      severity: BackdoorEvidenceSeverity.high,
      title: 'Acceso a las 03:14',
      subtitle: 'IP externa no autorizada',
      description:
          'Registro de autenticación remota desde 185.22.91.44 durante una franja sin actividad prevista.',
      isBackdoorSignal: true,
      explanation:
          'Una conexión remota fuera de horario puede indicar que el atacante conserva una vía de entrada.',
    ),
    BackdoorEvidence(
      id: 'process_update_helper',
      category: BackdoorEvidenceCategory.processes,
      severity: BackdoorEvidenceSeverity.high,
      title: 'update_helper.exe',
      subtitle: 'Proceso desde carpeta temporal',
      description:
          'Proceso activo ejecutándose desde C:/Temp/update_helper.exe con permisos elevados.',
      isBackdoorSignal: true,
      explanation:
          'Los procesos con nombres genéricos en rutas temporales son una señal típica de persistencia sospechosa.',
    ),
    BackdoorEvidence(
      id: 'user_backup_admin',
      category: BackdoorEvidenceCategory.users,
      severity: BackdoorEvidenceSeverity.critical,
      title: 'Usuario backup_admin',
      subtitle: 'Cuenta creada recientemente',
      description:
          'Cuenta local creada hace 2 días y añadida al grupo de administradores.',
      isBackdoorSignal: true,
      explanation:
          'Una cuenta administrativa creada sin autorización puede funcionar como acceso oculto.',
    ),
    BackdoorEvidence(
      id: 'port_4444',
      category: BackdoorEvidenceCategory.network,
      severity: BackdoorEvidenceSeverity.critical,
      title: 'Puerto 4444 abierto',
      subtitle: 'Servicio desconocido escuchando',
      description:
          'El servidor escucha conexiones entrantes en el puerto 4444 sin servicio documentado.',
      isBackdoorSignal: true,
      explanation:
          'Un puerto abierto sin justificación puede ser el canal de comunicación de la backdoor.',
    ),
    BackdoorEvidence(
      id: 'task_system_health',
      category: BackdoorEvidenceCategory.persistence,
      severity: BackdoorEvidenceSeverity.critical,
      title: 'SystemHealthCheck',
      subtitle: 'Tarea programada al iniciar',
      description:
          'Tarea programada que ejecuta update_helper.exe cada vez que arranca el sistema.',
      isBackdoorSignal: true,
      explanation:
          'Las tareas programadas permiten que una backdoor vuelva a activarse tras reiniciar.',
    ),
    BackdoorEvidence(
      id: 'process_svchost',
      category: BackdoorEvidenceCategory.processes,
      severity: BackdoorEvidenceSeverity.low,
      title: 'svchost.exe',
      subtitle: 'Proceso del sistema',
      description:
          'Proceso de Windows ejecutándose desde C:/Windows/System32 con firma válida.',
      isBackdoorSignal: false,
      explanation:
          'No todo proceso técnico es malicioso. La ruta y la firma ayudan a distinguir procesos legítimos.',
    ),
    BackdoorEvidence(
      id: 'network_beacon_dns',
      category: BackdoorEvidenceCategory.network,
      severity: BackdoorEvidenceSeverity.high,
      title: 'Beacon DNS cada 45s',
      subtitle: 'Dominio recién registrado',
      description:
          'Consultas repetidas a cdn-sync-status.net desde el servidor, siempre con el mismo intervalo.',
      isBackdoorSignal: true,
      explanation:
          'Un patrón periódico hacia un dominio nuevo puede ser una baliza de mando y control.',
    ),
    BackdoorEvidence(
      id: 'registry_run_sync',
      category: BackdoorEvidenceCategory.persistence,
      severity: BackdoorEvidenceSeverity.high,
      title: 'Clave Run: SyncProvider',
      subtitle: 'Arranque automático no documentado',
      description:
          'Entrada HKLM/Software/Microsoft/Windows/CurrentVersion/Run que lanza C:/Temp/update_helper.exe.',
      isBackdoorSignal: true,
      explanation:
          'Una clave Run apuntando al mismo binario sospechoso refuerza la persistencia de la backdoor.',
    ),
    BackdoorEvidence(
      id: 'log_backup_job',
      category: BackdoorEvidenceCategory.logs,
      severity: BackdoorEvidenceSeverity.low,
      title: 'Copia de seguridad 02:00',
      subtitle: 'Actividad programada',
      description:
          'Proceso de backup nocturno ejecutado según la planificación del departamento.',
      isBackdoorSignal: false,
      explanation:
          'La actividad nocturna puede ser normal si coincide con tareas documentadas.',
    ),
    BackdoorEvidence(
      id: 'user_maria',
      category: BackdoorEvidenceCategory.users,
      severity: BackdoorEvidenceSeverity.low,
      title: 'Usuario maria.lopez',
      subtitle: 'Cuenta corporativa activa',
      description:
          'Cuenta de empleada con permisos estándar y último acceso dentro del horario laboral.',
      isBackdoorSignal: false,
      explanation:
          'Una cuenta conocida con permisos normales no es una señal de backdoor por si sola.',
    ),
    BackdoorEvidence(
      id: 'log_failed_vpn',
      category: BackdoorEvidenceCategory.logs,
      severity: BackdoorEvidenceSeverity.medium,
      title: 'Fallos VPN 23:58',
      subtitle: 'Credenciales antiguas rechazadas',
      description:
          'Tres intentos fallidos contra la VPN corporativa desde una IP bloqueada por geolocalización.',
      isBackdoorSignal: false,
      explanation:
          'Los fallos rechazados pueden ser ruido de fuerza bruta si no terminan en acceso ni persistencia local.',
    ),
    BackdoorEvidence(
      id: 'network_443_cloud',
      category: BackdoorEvidenceCategory.network,
      severity: BackdoorEvidenceSeverity.medium,
      title: 'Conexión HTTPS 443',
      subtitle: 'Repositorio de actualizaciones',
      description:
          'Tráfico saliente hacia updates.vendor-secure.com firmado por el agente de inventario.',
      isBackdoorSignal: false,
      explanation:
          'El puerto 443 no es sospechoso por si mismo si el destino y el proceso están documentados.',
    ),
    BackdoorEvidence(
      id: 'user_service_backup',
      category: BackdoorEvidenceCategory.users,
      severity: BackdoorEvidenceSeverity.medium,
      title: 'svc_backup',
      subtitle: 'Cuenta de servicio limitada',
      description:
          'Cuenta creada hace 18 meses, sin inicio interactivo y usada solo por la tarea de copias.',
      isBackdoorSignal: false,
      explanation:
          'Las cuentas de servicio legítimas suelen tener antigüedad, permisos limitados y uso predecible.',
    ),
    BackdoorEvidence(
      id: 'task_inventory_agent',
      category: BackdoorEvidenceCategory.persistence,
      severity: BackdoorEvidenceSeverity.medium,
      title: 'InventoryAgent',
      subtitle: 'Tarea programada firmada',
      description:
          'Tarea de inventario que ejecuta un agente firmado desde Archivos de programa cada 6 horas.',
      isBackdoorSignal: false,
      explanation:
          'Una tarea programada no es mala por si sola; la firma, ruta y documentación cambian el veredicto.',
    ),
  ];

  static const List<BackdoorAction> actions = [
    BackdoorAction(
      id: 'close_port_4444',
      type: BackdoorActionType.contain,
      title: 'Cerrar puerto 4444',
      description: 'Bloquea el canal de entrada no autorizado.',
      isRequired: true,
      isDangerous: false,
      feedback:
          'Cerrar el puerto corta el canal remoto, pero no elimina la persistencia por si solo.',
    ),
    BackdoorAction(
      id: 'disable_task',
      type: BackdoorActionType.remove,
      title: 'Deshabilitar SystemHealthCheck',
      description: 'Impide que la backdoor vuelva a ejecutarse al iniciar.',
      isRequired: true,
      isDangerous: false,
      feedback:
          'Eliminar la tarea programada corta uno de los mecanismos de persistencia.',
    ),
    BackdoorAction(
      id: 'remove_backup_admin',
      type: BackdoorActionType.remove,
      title: 'Eliminar backup_admin',
      description: 'Retira la cuenta administrativa no autorizada.',
      isRequired: true,
      isDangerous: false,
      feedback:
          'Eliminar cuentas ocultas reduce las vías de acceso persistente.',
    ),
    BackdoorAction(
      id: 'rotate_credentials',
      type: BackdoorActionType.recover,
      title: 'Rotar credenciales',
      description: 'Cambia claves de cuentas y servicios afectados.',
      isRequired: true,
      isDangerous: false,
      feedback:
          'Rotar credenciales evita que el atacante use claves ya comprometidas.',
    ),
    BackdoorAction(
      id: 'audit_logs',
      type: BackdoorActionType.verify,
      title: 'Revisar logs posteriores',
      description: 'Comprueba que no hay nuevos intentos de reconexión.',
      isRequired: true,
      isDangerous: false,
      feedback: 'La verificación confirma que la limpieza ha sido efectiva.',
    ),
    BackdoorAction(
      id: 'quarantine_helper',
      type: BackdoorActionType.remove,
      title: 'Cuarentenar update_helper.exe',
      description: 'Aisla el binario sospechoso para análisis forense.',
      isRequired: true,
      isDangerous: false,
      feedback:
          'Cuarentenar el binario evita ejecuciones nuevas sin destruir evidencia útil.',
    ),
    BackdoorAction(
      id: 'block_c2_domain',
      type: BackdoorActionType.contain,
      title: 'Bloquear dominio C2',
      description: 'Corta las consultas hacia cdn-sync-status.net.',
      isRequired: true,
      isDangerous: false,
      feedback:
          'Bloquear el dominio de mando impide que la backdoor reciba instrucciones.',
    ),
    BackdoorAction(
      id: 'delete_all_logs',
      type: BackdoorActionType.remove,
      title: 'Borrar todos los logs',
      description: 'Elimina el historial de eventos del servidor.',
      isRequired: false,
      isDangerous: true,
      feedback:
          'Borrar logs destruye evidencia y dificulta entender el alcance del incidente.',
    ),
    BackdoorAction(
      id: 'shutdown_server',
      type: BackdoorActionType.contain,
      title: 'Apagar servidor sin análisis',
      description: 'Detiene el equipo inmediatamente.',
      isRequired: false,
      isDangerous: true,
      feedback:
          'Apagar sin analizar puede interrumpir servicios y no garantiza eliminar la backdoor.',
    ),
    BackdoorAction(
      id: 'delete_svchost',
      type: BackdoorActionType.remove,
      title: 'Eliminar svchost.exe',
      description: 'Borra un proceso crítico del sistema.',
      isRequired: false,
      isDangerous: true,
      feedback:
          'Eliminar procesos legítimos puede romper el sistema y no soluciona el acceso oculto.',
    ),
    BackdoorAction(
      id: 'format_server',
      type: BackdoorActionType.remove,
      title: 'Formatear servidor',
      description: 'Borra el servidor completo sin preservar evidencia.',
      isRequired: false,
      isDangerous: true,
      feedback:
          'Formatear sin contención ni forense destruye evidencias y puede causar una parada innecesaria.',
    ),
    BackdoorAction(
      id: 'whitelist_update_helper',
      type: BackdoorActionType.verify,
      title: 'Permitir update_helper.exe',
      description: 'Evita que el antivirus bloquee el binario sospechoso.',
      isRequired: false,
      isDangerous: true,
      feedback:
          'Permitir el binario sospechoso facilita que la puerta oculta siga activa.',
    ),
  ];
}
