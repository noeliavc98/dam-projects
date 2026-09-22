import '../components/ddos_packet.dart';

abstract class DdosData {
  static const List<DdosScenario> ronda1 = [
    DdosScenario(
      titulo: 'Pico normal de usuarios',
      protocolo: 'HTTPS',
      captura: 'GET /login\nUsuarios: 120\nErrores: 0\nOrigen: red corporativa',
      nota: 'El tráfico coincide con el horario habitual de entrada.',
      tipoCorrecto: DdosType.legitimo,
      explicacion:
          'Es tráfico legítimo. No hay saturación ni patrón de ataque.',
    ),
    DdosScenario(
      titulo: 'Miles de conexiones incompletas',
      protocolo: 'TCP',
      captura: 'SYN recibidos: 8500/min\nACK completados: 120/min\nCPU: 92%',
      nota: 'Muchas conexiones se quedan a medias.',
      tipoCorrecto: DdosType.synFlood,
      explicacion:
          'Es un SYN Flood. El atacante abre muchas conexiones TCP sin completarlas.',
    ),
    DdosScenario(
      titulo: 'Tráfico UDP masivo',
      protocolo: 'UDP',
      captura:
          'UDP packets: 120000/min\nPuertos destino: aleatorios\nOrigen: múltiples IPs',
      nota: 'El servidor no puede responder a todas las peticiones.',
      tipoCorrecto: DdosType.udpFlood,
      explicacion:
          'Es un UDP Flood. Se envía tráfico UDP masivo para saturar recursos.',
    ),
    DdosScenario(
      titulo: 'Muchas peticiones web repetidas',
      protocolo: 'HTTP',
      captura: 'GET /productos\nGET /productos\nGET /productos\nBots: 4000',
      nota: 'Las peticiones parecen normales, pero llegan en volumen excesivo.',
      tipoCorrecto: DdosType.httpFlood,
      explicacion:
          'Es un HTTP Flood. Usa peticiones web para agotar el servidor.',
    ),
  ];

  static const List<DdosScenario> ronda2 = [
    DdosScenario(
      titulo: 'Respuestas DNS enormes',
      protocolo: 'DNS/UDP',
      captura:
          'Respuesta DNS: 4096 bytes\nConsulta original: no registrada\nOrigen: resolvers públicos',
      nota: 'La víctima recibe respuestas que nunca solicitó.',
      tipoCorrecto: DdosType.dnsAmplification,
      explicacion:
          'Es DNS Amplification. Se falsifica la IP de la víctima para recibir respuestas amplificadas.',
    ),
    DdosScenario(
      titulo: 'Ataque desde miles de equipos',
      protocolo: 'Mixto',
      captura: 'IPs origen: 25000\nPaíses: 38\nPatrón: sincronizado',
      nota: 'El tráfico procede de muchos dispositivos comprometidos.',
      tipoCorrecto: DdosType.botnet,
      explicacion:
          'Es una botnet. Muchos equipos infectados atacan al mismo objetivo.',
    ),
    DdosScenario(
      titulo: 'Transferencia interna autorizada',
      protocolo: 'SFTP',
      captura: 'Backup nocturno\nServidor origen autorizado\nFirma válida',
      nota: 'La tarea está programada en mantenimiento.',
      tipoCorrecto: DdosType.legitimo,
      explicacion:
          'Es tráfico legítimo. Corresponde a una copia de seguridad autorizada.',
    ),
  ];

  static const List<DdosMitigationScenario> ronda3 = [
    DdosMitigationScenario(
      titulo: 'Mitigar SYN Flood',
      descripcion:
          'El servidor recibe miles de SYN sin completar el handshake.',
      opciones: ['Activar SYN cookies', 'Borrar usuarios', 'Apagar Firebase'],
      opcionCorrecta: 'Activar SYN cookies',
      explicacion:
          'Las SYN cookies ayudan a resistir conexiones TCP incompletas.',
    ),
    DdosMitigationScenario(
      titulo: 'Mitigar HTTP Flood',
      descripcion: 'Bots realizan miles de peticiones GET contra la web.',
      opciones: [
        'Rate limiting',
        'Desactivar HTTPS',
        'Eliminar la base de datos',
      ],
      opcionCorrecta: 'Rate limiting',
      explicacion: 'El rate limiting limita peticiones por IP o cliente.',
    ),
    DdosMitigationScenario(
      titulo: 'Mitigar tráfico distribuido',
      descripcion: 'El ataque llega desde muchas zonas y supera al servidor.',
      opciones: ['Usar CDN/WAF', 'Permitir todo', 'Quitar autenticación'],
      opcionCorrecta: 'Usar CDN/WAF',
      explicacion:
          'Una CDN o WAF filtra tráfico malicioso antes de llegar al servidor.',
    ),
  ];
}
