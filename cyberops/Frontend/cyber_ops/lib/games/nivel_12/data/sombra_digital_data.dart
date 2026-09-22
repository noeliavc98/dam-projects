import 'package:cyber_ops/games/nivel_12/component/accion_respuesta.dart';
import 'package:cyber_ops/games/nivel_12/component/estado_filtracion.dart';
import 'package:cyber_ops/games/nivel_12/component/evidencia_digital.dart';


class SombraDigitalData {
  static const String nombreEquipo = 'DESKTOP-ALBA-07';

  static const String tituloAlerta = 'ROBO SILENCIOSO DE SESIONES';

  static const String descripcionAlerta =
      'No hay archivos cifrados ni pantallas de rescate. '
      'El sistema parece funcionar, pero varios rastros indican extracción silenciosa de datos.';

  static const List<String> dialogosIntro = [
    'No todos los ataques hacen ruido.',
    'Algunos no rompen puertas. No cifran archivos. No apagan sistemas.',
    'Solo copian.',
    'Contraseñas. Cookies. Sesiones. Recuerdos digitales.',
    'Cuando la víctima se da cuenta... el atacante ya está dentro de sus cuentas.',
    'Esto es un infostealer.',
    'Tu misión no es solo eliminarlo. Es descubrir qué se llevó.',
  ];

  static const List<String> dialogosFinales = [
    'Has contenido la fuga.',
    'Pero recuerda esto:',
    'Una contraseña robada puede cambiarse.',
    'Una sesión olvidada puede seguir abierta.',
    'Una cookie puede ser una llave.',
    'El peligro de un infostealer no está en lo que rompe.',
    'Está en lo que copia sin que nadie mire.',
  ];

  static const List<EstadoFiltracion> datosEnRiesgo = [
    EstadoFiltracion(
      id: 'browser_sessions',
      nombre: 'Sesiones del navegador',
      descripcion: 'Cookies y tokens activos pueden permitir acceso sin contraseña.',
      critico: true,
    ),
    EstadoFiltracion(
      id: 'saved_passwords',
      nombre: 'Contraseñas guardadas',
      descripcion: 'Credenciales almacenadas localmente pueden haber sido extraídas.',
      critico: true,
    ),
    EstadoFiltracion(
      id: 'discord_token',
      nombre: 'Token de Discord',
      descripcion: 'Un token robado permite secuestrar sesión sin iniciar sesión manualmente.',
    ),
    EstadoFiltracion(
      id: 'wallet_data',
      nombre: 'Datos de wallet',
      descripcion: 'Archivos temporales sugieren intento de acceso a cartera digital.',
      critico: true,
    ),
  ];

  static const List<EvidenciaDigital> evidencias = [
  EvidenciaDigital(
    id: 'cookie_dump_chrome',
    categoria: CategoriaEvidenciaDigital.navegador,
    titulo: 'cookie_dump.log',
    subtitulo: 'Exportación de cookies del navegador',
    descripcion:
        'Archivo generado en AppData con registros de cookies activas de Chrome y Edge.',
    esRastroStealer: true,
    explicacion:
        'Las cookies robadas pueden permitir acceder a cuentas sin conocer la contraseña.',
  ),
  EvidenciaDigital(
    id: 'login_data_copy',
    categoria: CategoriaEvidenciaDigital.navegador,
    titulo: 'Login Data.bak',
    subtitulo: 'Copia sospechosa de credenciales guardadas',
    descripcion:
        'Se detecta una copia de la base local donde el navegador guarda contraseñas.',
    esRastroStealer: true,
    explicacion:
        'Los stealers suelen buscar bases de datos locales de contraseñas guardadas.',
  ),
  EvidenciaDigital(
    id: 'process_chrome_sync_helper',
    categoria: CategoriaEvidenciaDigital.procesos,
    titulo: 'chrome_sync_helper.exe',
    subtitulo: 'Proceso desde carpeta temporal',
    descripcion:
        'Proceso con nombre parecido a Chrome ejecutándose desde una ruta temporal.',
    esRastroStealer: true,
    explicacion:
        'Un nombre parecido a software legítimo desde una ruta temporal es un patrón típico de malware.',
  ),
  EvidenciaDigital(
    id: 'discord_token_cache',
    categoria: CategoriaEvidenciaDigital.sesiones,
    titulo: 'discord_token.cache',
    subtitulo: 'Token de sesión exportado',
    descripcion:
        'Archivo temporal con cadenas compatibles con tokens de sesión de Discord.',
    esRastroStealer: true,
    explicacion:
        'Un token robado puede permitir secuestrar una sesión sin introducir usuario y contraseña.',
  ),
  EvidenciaDigital(
    id: 'wallet_export_tmp',
    categoria: CategoriaEvidenciaDigital.wallets,
    titulo: 'wallet_export.tmp',
    subtitulo: 'Datos de cartera en temporal',
    descripcion:
        'Archivo temporal con referencias a seed, wallet y extensión de navegador.',
    esRastroStealer: true,
    explicacion:
        'Los stealers suelen buscar wallets, extensiones cripto y archivos sensibles.',
  ),
  EvidenciaDigital(
    id: 'traffic_unknown_c2',
    categoria: CategoriaEvidenciaDigital.red,
    titulo: 'POST a 91.204.14.88',
    subtitulo: 'Envío comprimido fuera de horario',
    descripcion:
        'Tráfico saliente cifrado hacia una IP desconocida justo después de crear archivos temporales.',
    esRastroStealer: true,
    explicacion:
        'La exfiltración suele verse como tráfico saliente hacia servidores externos.',
  ),

  // FALSOS POSITIVOS
  EvidenciaDigital(
    id: 'chrome_normal',
    categoria: CategoriaEvidenciaDigital.procesos,
    titulo: 'chrome.exe',
    subtitulo: 'Proceso legítimo del navegador',
    descripcion:
        'Proceso de Chrome ejecutándose desde Archivos de programa con firma válida.',
    esRastroStealer: false,
    explicacion:
        'No todo proceso del navegador es malicioso. La ruta y la firma importan.',
  ),
  EvidenciaDigital(
    id: 'backup_job',
    categoria: CategoriaEvidenciaDigital.archivos,
    titulo: 'backup_usuarios.zip',
    subtitulo: 'Copia programada',
    descripcion:
        'Archivo generado por la tarea de backup interno del sistema.',
    esRastroStealer: false,
    explicacion:
        'Una copia de seguridad documentada no implica robo si coincide con tareas legítimas.',
  ),
  EvidenciaDigital(
    id: 'steamwebhelper',
    categoria: CategoriaEvidenciaDigital.procesos,
    titulo: 'steamwebhelper.exe',
    subtitulo: 'Proceso habitual de Steam',
    descripcion:
        'Proceso asociado al cliente de Steam instalado en el equipo.',
    esRastroStealer: false,
    explicacion:
        'Puede parecer sospechoso, pero es un proceso común de Steam.',
  ),
  EvidenciaDigital(
    id: 'windows_defender_log',
    categoria: CategoriaEvidenciaDigital.archivos,
    titulo: 'DefenderScan.log',
    subtitulo: 'Registro de análisis antivirus',
    descripcion:
        'Log normal generado por Windows Defender tras un análisis programado.',
    esRastroStealer: false,
    explicacion:
        'Los logs del antivirus ayudan a investigar, pero no son por sí solos evidencia del stealer.',
  ),
];

 static const List<AccionRespuesta> acciones = [
  AccionRespuesta(
    id: 'close_sessions',
    tipo: TipoAccionRespuesta.contener,
    titulo: 'Cerrar sesiones activas',
    descripcion:
        'Cierra sesiones abiertas en navegador, correo, Discord y servicios críticos.',
    esNecesaria: true,
    esPeligrosa: false,
    feedback:
        'Cerrar sesiones invalida cookies y tokens que el atacante podría reutilizar.',
  ),
  AccionRespuesta(
    id: 'rotate_passwords',
    tipo: TipoAccionRespuesta.recuperar,
    titulo: 'Rotar contraseñas',
    descripcion:
        'Cambia las contraseñas de cuentas afectadas desde un dispositivo limpio.',
    esNecesaria: true,
    esPeligrosa: false,
    feedback:
        'Cambiar contraseñas es necesario, pero debe hacerse tras cerrar sesiones y desde un entorno seguro.',
  ),
  AccionRespuesta(
    id: 'revoke_tokens',
    tipo: TipoAccionRespuesta.contener,
    titulo: 'Revocar tokens',
    descripcion:
        'Revoca tokens de Discord, navegador, correo y servicios vinculados.',
    esNecesaria: true,
    esPeligrosa: false,
    feedback:
        'Revocar tokens evita accesos sin contraseña mediante sesiones robadas.',
  ),
  AccionRespuesta(
    id: 'remove_extension',
    tipo: TipoAccionRespuesta.limpiar,
    titulo: 'Eliminar extensión maliciosa',
    descripcion:
        'Elimina extensiones desconocidas y revisa permisos del navegador.',
    esNecesaria: true,
    esPeligrosa: false,
    feedback:
        'Las extensiones maliciosas pueden capturar sesiones y datos del navegador.',
  ),
  AccionRespuesta(
    id: 'enable_mfa',
    tipo: TipoAccionRespuesta.recuperar,
    titulo: 'Activar MFA',
    descripcion:
        'Activa autenticación multifactor en las cuentas recuperadas.',
    esNecesaria: true,
    esPeligrosa: false,
    feedback:
        'MFA reduce el impacto de credenciales robadas, aunque no sustituye revocar sesiones.',
  ),
  AccionRespuesta(
    id: 'verify_no_exfiltration',
    tipo: TipoAccionRespuesta.verificar,
    titulo: 'Verificar tráfico posterior',
    descripcion:
        'Comprueba que no continúan envíos de datos hacia IPs externas.',
    esNecesaria: true,
    esPeligrosa: false,
    feedback:
        'Verificar tráfico confirma que la exfiltración ha sido contenida.',
  ),

  // ACCIONES PELIGROSAS
  AccionRespuesta(
    id: 'delete_logs',
    tipo: TipoAccionRespuesta.limpiar,
    titulo: 'Borrar logs',
    descripcion:
        'Elimina los registros para limpiar rastros del incidente.',
    esNecesaria: false,
    esPeligrosa: true,
    feedback:
        'Borrar logs destruye evidencia y dificulta saber qué datos fueron robados.',
  ),
  AccionRespuesta(
    id: 'format_without_revoke',
    tipo: TipoAccionRespuesta.limpiar,
    titulo: 'Formatear sin revocar sesiones',
    descripcion:
        'Reinstala el equipo sin cerrar sesiones ni revocar tokens.',
    esNecesaria: false,
    esPeligrosa: true,
    feedback:
        'Formatear no invalida cookies, tokens o sesiones ya robadas.',
  ),
  AccionRespuesta(
    id: 'disable_antivirus',
    tipo: TipoAccionRespuesta.contener,
    titulo: 'Desactivar antivirus',
    descripcion:
        'Desactiva el antivirus para evitar interferencias durante la limpieza.',
    esNecesaria: false,
    esPeligrosa: true,
    feedback:
        'Desactivar protección facilita reinfecciones y no ayuda a contener el robo.',
  ),
  AccionRespuesta(
    id: 'ignore_cookies',
    tipo: TipoAccionRespuesta.verificar,
    titulo: 'Ignorar cookies robadas',
    descripcion:
        'Considera que cambiar la contraseña es suficiente.',
    esNecesaria: false,
    esPeligrosa: true,
    feedback:
        'Las cookies pueden mantener una sesión abierta aunque la contraseña cambie.',
  ),
];
}