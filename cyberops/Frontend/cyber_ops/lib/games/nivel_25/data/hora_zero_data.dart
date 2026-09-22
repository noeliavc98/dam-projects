import '../components/ataque_boss.dart';
import '../components/defensa_boss.dart';
import '../components/fragmento_origen.dart';

class HoraCeroData {
  static const String nombreNivel = 'NIVEL 25 - HORA CERO';

  static const List<String> dialogosIntro = [
    'Se acabó el entrenamiento.',
    'No queda una sola puerta. Quedan todas.',
    'El enemigo no es un virus. Es una cadena completa de errores.',
    'Phishing. Tokens robados. Persistencia. Escalada. Exfiltración.',
    'Cada golpe que recibas será algo que ya has visto antes.',
    'Cada defensa correcta demostrará que ya no memorizas. Analizas.',
    'Bienvenido a Hora Cero.',
  ];

  static const List<String> dialogosVictoria = [
    'El Núcleo Cero ha caído.',
    'No has ganado por fuerza.',
    'Has ganado porque has entendido la cadena.',
    'Ese era el verdadero objetivo de Cyber Ops.',
  ];

  static const List<DefensaBoss> defensas = [
    DefensaBoss(
      id: 'mfa',
      nombre: 'MFA',
      descripcion: 'Añade una segunda verificación frente a robo de credenciales.',
    ),
    DefensaBoss(
      id: 'filtro_correo',
      nombre: 'Filtro de correo',
      descripcion: 'Reduce phishing y adjuntos maliciosos.',
    ),
    DefensaBoss(
      id: 'revocar_tokens',
      nombre: 'Revocar tokens',
      descripcion: 'Cierra sesiones robadas o reutilizadas.',
    ),
    DefensaBoss(
      id: 'rotar_claves',
      nombre: 'Rotar claves',
      descripcion: 'Cambia credenciales comprometidas.',
    ),
    DefensaBoss(
      id: 'backups_offline',
      nombre: 'Backups offline',
      descripcion: 'Permiten recuperar datos tras ransomware.',
    ),
    DefensaBoss(
      id: 'segmentacion',
      nombre: 'Segmentación',
      descripcion: 'Limita movimiento lateral.',
    ),
    DefensaBoss(
      id: 'edr',
      nombre: 'EDR',
      descripcion: 'Detecta procesos, persistencia y comportamiento sospechoso.',
    ),
    DefensaBoss(
      id: 'siem',
      nombre: 'SIEM',
      descripcion: 'Centraliza logs y detección.',
    ),
    DefensaBoss(
      id: 'dlp',
      nombre: 'DLP',
      descripcion: 'Ayuda a detectar o bloquear fuga de datos.',
    ),
    DefensaBoss(
      id: 'minimo_privilegio',
      nombre: 'Mínimo privilegio',
      descripcion: 'Reduce impacto de cuentas comprometidas.',
    ),
    DefensaBoss(
      id: 'parchear',
      nombre: 'Parchear',
      descripcion: 'Corrige vulnerabilidades explotables.',
    ),
    DefensaBoss(
      id: 'revisar_persistencia',
      nombre: 'Revisar persistencia',
      descripcion: 'Busca tareas programadas, servicios falsos o usuarios ocultos.',
    ),
  ];

  static const List<AtaqueBoss> ataques = [
    AtaqueBoss(
      id: 'a1',
      titulo: 'PHISHING PAYLOAD',
      descripcion: 'Un usuario recibe un correo falso con enlace de acceso corporativo.',
      tipo: TipoAtaqueBoss.phishing,
      defensasCorrectas: ['mfa', 'filtro_correo'],
      explicacion: 'El phishing se corta mejor combinando prevención y segunda verificación.',
      danoSiFalla: 14,
      danoAlBoss: 16,
    ),
    AtaqueBoss(
      id: 'a2',
      titulo: 'TOKEN ROBADO',
      descripcion: 'El atacante reutiliza una sesión válida desde otra ubicación.',
      tipo: TipoAtaqueBoss.tokenRobado,
      defensasCorrectas: ['revocar_tokens', 'rotar_claves'],
      explicacion: 'Cambiar contraseña no basta si el token sigue activo.',
      danoSiFalla: 16,
      danoAlBoss: 18,
    ),
    AtaqueBoss(
      id: 'a3',
      titulo: 'BACKDOOR ACTIVO',
      descripcion: 'Aparece un servicio falso ejecutándose al iniciar el sistema.',
      tipo: TipoAtaqueBoss.persistencia,
      defensasCorrectas: ['edr', 'revisar_persistencia'],
      explicacion: 'La persistencia exige detección y revisión de mecanismos de arranque.',
      danoSiFalla: 16,
      danoAlBoss: 18,
    ),
    AtaqueBoss(
      id: 'a4',
      titulo: 'PRIVILEGE ESCALATION',
      descripcion: 'Una cuenta limitada intenta obtener permisos de administrador.',
      tipo: TipoAtaqueBoss.privilegios,
      defensasCorrectas: ['minimo_privilegio', 'parchear'],
      explicacion: 'Se reduce combinando corrección de fallo y control de privilegios.',
      danoSiFalla: 18,
      danoAlBoss: 20,
    ),
    AtaqueBoss(
      id: 'a5',
      titulo: 'RANSOMWARE BURST',
      descripcion: 'El sistema intenta cifrar directorios compartidos de la red.',
      tipo: TipoAtaqueBoss.ransomware,
      defensasCorrectas: ['backups_offline', 'segmentacion'],
      explicacion: 'Los backups recuperan. La segmentación limita propagación.',
      danoSiFalla: 20,
      danoAlBoss: 22,
    ),
    AtaqueBoss(
      id: 'a6',
      titulo: 'EXFILTRACIÓN CIFRADA',
      descripcion: 'Se detecta salida anómala de datos hacia un destino externo.',
      tipo: TipoAtaqueBoss.exfiltracion,
      defensasCorrectas: ['dlp', 'siem'],
      explicacion: 'DLP y SIEM ayudan a detectar y responder a fuga de datos.',
      danoSiFalla: 20,
      danoAlBoss: 22,
    ),
    AtaqueBoss(
      id: 'a7',
      titulo: 'CADENA FINAL',
      descripcion: 'Infostealer, token robado, VPN activa y movimiento lateral.',
      tipo: TipoAtaqueBoss.comboFinal,
      defensasCorrectas: ['revocar_tokens', 'segmentacion', 'siem'],
      explicacion: 'En una cadena avanzada debes cortar sesión, movimiento y visibilidad.',
      danoSiFalla: 24,
      danoAlBoss: 28,
    ),
  ];

  static const List<FragmentoOrigen> fragmentos = [
    FragmentoOrigen(
      id: 'f1',
      titulo: 'FRAGMENTO 01',
      mensaje: 'FRACTURA no apareció para romper sistemas. Apareció para enseñarte a leerlos.',
    ),
    FragmentoOrigen(
      id: 'f2',
      titulo: 'FRAGMENTO 02',
      mensaje: 'Cada nivel anterior era una pieza. Hora Cero es la cadena completa.',
    ),
    FragmentoOrigen(
      id: 'f3',
      titulo: 'FRAGMENTO 03',
      mensaje: 'Si has llegado hasta aquí, ya no sigues instrucciones. Piensas como analista.',
    ),
  ];
}