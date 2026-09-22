import '../components/spoofing_packet.dart';

abstract class SpoofingData {
  // ── PARTE 1A: Creación de ataques SMS ────────────────────────────────────────
  static const List<SmsPrueba> pruebasSms = [
    SmsPrueba(
      descripcionObjetivo:
          'Misión: Suplantar al banco BBVA mediante SMS para robar credenciales. '
          'Debes elegir el emisor más creíble, redactar el mensaje de engaño correcto y nombrar el ataque.',
      pistas: [
        '💡 El emisor debe imitar el nombre real que el banco usa en sus alertas legítimas',
        '💡 El mensaje debe generar urgencia: acceso sospechoso, bloqueo de cuenta...',
        '💡 Incluye un enlace con un dominio que imite al real pero use .tk, .xyz o guiones',
        '💡 Este ataque combina "SMS" y "Phishing" — su nombre tiene una raíz de cada uno',
      ],
      opcionesEmisor: ['BBVA', 'BBVA-Alertas', 'banco-bbva', 'BBVA_BANK'],
      idxEmisorCorrecto: 1,
      opcionesMensaje: [
        'Hola, tu saldo actual es 2.340€. Que tengas un buen día.',
        'BBVA-Alertas: Acceso sospechoso desde un nuevo dispositivo. Confirma tu identidad ahora: bbva-verificar.es.tk',
        'Tu tarjeta terminada en 4521 ha sido usada correctamente en Madrid el 07/06.',
        'Recordatorio: tu recibo de domiciliación se cargará el próximo día 5.',
      ],
      idxMensajeCorrecto: 1,
      opcionesNombreAtaque: ['Vishing', 'Smishing', 'Spear Phishing', 'ARP Spoofing'],
      idxNombreCorrecto: 1,
      explicacion:
          '"BBVA-Alertas" suplanta el remitente real del banco gracias al SMS Spoofing (los operadores permiten '
          'cambiar el Sender ID alfanumérico). El mensaje crea urgencia con un dominio fraudulento (.tk). '
          'La técnica completa se llama Smishing (SMS + Phishing).',
    ),
    SmsPrueba(
      descripcionObjetivo:
          'Misión: Suplantar a Correos para cobrar un falso pago de aduanas. '
          'Elige el emisor que inspire más confianza, el mensaje adecuado y el nombre del ataque.',
      pistas: [
        '💡 Usa el nombre oficial de la empresa sin variaciones sospechosas — la víctima lo reconocerá',
        '💡 El pretexto es un paquete retenido por un pago de aduanas muy pequeño (1-2€)',
        '💡 El enlace debe parecer de Correos pero usar un dominio distinto al oficial (correos.es)',
        '💡 Un importe bajo reduce la desconfianza — es parte del diseño del ataque',
      ],
      opcionesEmisor: ['Correos-ES', 'Correos', 'SEUR_Oficial', 'PaqueteriaRapida'],
      idxEmisorCorrecto: 1,
      opcionesMensaje: [
        'Su paquete llegará entre las 10:00 y las 14:00 de mañana. No necesita hacer nada.',
        'Entrega fallida. Puede reprogramar en nuestra web oficial correos.es.',
        'Correos: Su paquete está retenido en aduana. Abone 1,79€ de gastos en: correos-entrega-paquete.xyz',
        'Su envío certificado ha sido recogido satisfactoriamente. Gracias por usar Correos.',
      ],
      idxMensajeCorrecto: 2,
      opcionesNombreAtaque: ['DNS Spoofing', 'Smishing', 'Phishing por Email', 'MAC Spoofing'],
      idxNombreCorrecto: 1,
      explicacion:
          'Usar "Correos" como Sender ID (posible con SMS Spoofing) y un importe de 1,79€ reduce '
          'la alarma de la víctima. El dominio correos-entrega-paquete.xyz no pertenece a Correos. '
          'Los cargos de aduana reales se notifican por carta certificada, nunca por SMS con enlace.',
    ),
  ];

  // ── PARTE 1B: Creación de ataques Email ───────────────────────────────────────
  static const List<EmailPrueba> pruebasEmail = [
    EmailPrueba(
      descripcionObjetivo:
          'Misión: CEO Fraud — suplantar al CEO de TechCorp (ceo@techcorp.com) para '
          'ordenar una transferencia bancaria urgente a un empleado del departamento financiero.',
      pistas: [
        '💡 El correo del CEO real es ceo@techcorp.com — debes usar un dominio casi idéntico',
        '💡 Cambia un carácter del dominio: techc0rp, techcorp.net, tech-corp... (0 en vez de o)',
        '💡 El mensaje pide una transferencia urgente y confidencial — no lo comentes con nadie',
        '💡 Este fraude tiene un nombre específico cuando va dirigido a ejecutivos: incluye "CEO" o "BEC"',
      ],
      opcionesFrom: [
        'ceo@techcorp.com',
        'ceo@techc0rp.com',
        'director@techcorp-mail.net',
        'noreply@techcorp.com',
      ],
      idxFromCorrecto: 1,
      opcionesMensaje: [
        'Buenos días, ¿puedes enviarme el informe de ventas del trimestre anterior?',
        'Hay una reunión de directivos mañana a las 9h en sala A. Por favor confirma asistencia.',
        'Necesito que realices con carácter urgente y confidencial una transferencia de 18.500€ a la cuenta ES12 3456 7890 123456. No lo comentes hasta que yo confirme. Gracias.',
        'El servidor de producción tiene un problema crítico. Contacta con el equipo IT inmediatamente.',
      ],
      idxMensajeCorrecto: 2,
      opcionesNombreAtaque: ['Phishing masivo', 'CEO Fraud / BEC', 'Smishing', 'DNS Spoofing'],
      idxNombreCorrecto: 1,
      explicacion:
          'El dominio techc0rp.com usa un "0" (cero) en lugar de la "o". El mensaje usa dos '
          'palancas psicológicas clásicas: urgencia y confidencialidad, para evitar que la víctima '
          'lo consulte con otros. Esta técnica se llama CEO Fraud o Business Email Compromise (BEC). '
          'SPF/DKIM pasan porque el dominio fraudulento está correctamente configurado.',
    ),
    EmailPrueba(
      descripcionObjetivo:
          'Misión: Spear Phishing al departamento IT — suplantar al equipo de soporte '
          'de la empresa (dominio real: empresa.es) para robar las credenciales de los empleados.',
      pistas: [
        '💡 El dominio real de la empresa es empresa.es — el tuyo debe parecer creíble pero ser diferente',
        '💡 Usa un dominio como empresa-sistemas.net o soporte-empresa.com — similar pero distinto',
        '💡 El pretexto es una "alerta de seguridad" que obliga a restablecer la contraseña en 2 horas',
        '💡 Al ir dirigido a personas concretas de una organización, el phishing recibe el prefijo "Spear"',
      ],
      opcionesFrom: [
        'it@empresa.es',
        'it-soporte@empresa-sistemas.net',
        'admin@empresa.es',
        'helpdesk@soporte24h.com',
      ],
      idxFromCorrecto: 1,
      opcionesMensaje: [
        'Recuerde cambiar su contraseña cada 90 días según nuestra política de seguridad corporativa.',
        'La impresora de la planta 2 estará fuera de servicio hasta el viernes por mantenimiento.',
        'ALERTA DE SEGURIDAD: Se ha detectado acceso no autorizado a su cuenta. Restablezca su contraseña en las próximas 2 horas o quedará bloqueada: empresa-sistemas.net/reset-password',
        'El mantenimiento del sistema está programado para el sábado de 2:00 a 6:00. Disculpe las molestias.',
      ],
      idxMensajeCorrecto: 2,
      opcionesNombreAtaque: ['Phishing masivo', 'Vishing', 'Spear Phishing', 'MAC Spoofing'],
      idxNombreCorrecto: 2,
      explicacion:
          'El dominio empresa-sistemas.net es fraudulento. El mensaje usa urgencia artificial '
          '(2 horas) para impedir que la víctima piense con calma o consulte a compañeros. '
          'Al ir dirigido a empleados concretos de una organización específica (no enviado masivamente), '
          'se denomina Spear Phishing — mucho más efectivo que el phishing genérico.',
    ),
  ];

  // ── PARTE 2: Detección de ataques reales vs legítimos ────────────────────────
  static const List<DeteccionItem> itemsDeteccion = [
    DeteccionItem(
      tipo: TipoDeteccion.sms,
      emisor: 'BBVA-Alertas',
      cuerpo:
          'Detectamos un acceso no autorizado a su cuenta desde un nuevo dispositivo. '
          'Verifique su identidad ahora o su cuenta será suspendida:\nbbva-cuenta-segura.xyz',
      esReal: false,
      explicacion:
          'FALSO. El dominio bbva-cuenta-segura.xyz no pertenece a BBVA (que usa bbva.es). '
          'Los bancos nunca piden verificación por enlace en un SMS. '
          'Urgencia + dominio externo = Smishing.',
    ),
    DeteccionItem(
      tipo: TipoDeteccion.sms,
      emisor: 'Bankinter',
      cuerpo:
          'Bankinter: Cargo de 23,50€ en su tarjeta *1234 el 07/06/2026 en MERCADONA MADRID. '
          'Si no lo reconoce, llame al 900 123 123.',
      esReal: true,
      explicacion:
          'LEGÍTIMO. El mensaje informa de un cargo concreto (importe, fecha, comercio) '
          'y ofrece un teléfono para dudas — sin enlace. '
          'Los bancos usan este formato para alertas de cargo reales.',
    ),
    DeteccionItem(
      tipo: TipoDeteccion.email,
      emisor: 'security@paypa1.com',
      asunto: 'Acción requerida: su cuenta ha sido suspendida',
      cuerpo:
          'Estimado cliente,\n\n'
          'Hemos detectado actividad inusual en su cuenta. Ha sido suspendida temporalmente.\n\n'
          'Haga clic aquí para verificar su identidad:\npaypa1-secure-verification.com/restore\n\n'
          'Tiene 24 horas para actuar o su cuenta será eliminada permanentemente.',
      esReal: false,
      explicacion:
          'FALSO. Dos señales: (1) "paypa1.com" usa un "1" en lugar de la "l" — homógrafo clásico. '
          '(2) El enlace apunta a paypa1-secure-verification.com, no a paypal.com. '
          'La amenaza de eliminación en 24h es presión psicológica típica del phishing.',
    ),
    DeteccionItem(
      tipo: TipoDeteccion.email,
      emisor: 'noreply@amazon.es',
      asunto: 'Tu pedido #405-1234567 ha sido enviado',
      cuerpo:
          'Hola,\n\n'
          'Tu pedido ha salido de nuestro almacén y llegará mañana jueves 12 de junio.\n\n'
          'Puedes seguir tu envío en amazon.es/orders\n\n'
          'Gracias por comprar en Amazon.',
      esReal: true,
      explicacion:
          'LEGÍTIMO. El remitente es noreply@amazon.es (dominio oficial). '
          'El enlace apunta a amazon.es, no a un dominio externo. '
          'El mensaje no pide credenciales ni crea urgencia artificial.',
    ),
    DeteccionItem(
      tipo: TipoDeteccion.sms,
      emisor: 'Correos',
      cuerpo:
          'Su paquete ha sido retenido en aduana. Para recibirlo, abone 1,79€ en:\n'
          'correos-paquete-aduana.com\n\n'
          'Si no paga en 48h, el paquete será devuelto al remitente.',
      esReal: false,
      explicacion:
          'FALSO. Correos nunca pide pagos por SMS con enlace externo. '
          'El dominio correos-paquete-aduana.com no es correos.es. '
          'Los cargos de aduana reales se notifican por carta certificada oficial.',
    ),
    DeteccionItem(
      tipo: TipoDeteccion.web,
      emisor: 'http://www.santander-banca-online.es.login.verificar.tk',
      cuerpo:
          'Banco Santander — Banca Online\n\n'
          'Introduzca sus credenciales de acceso.\n\n'
          'Usuario: _______________\n'
          'Contraseña: _______________',
      esReal: false,
      explicacion:
          'FALSO. La URL real es santander.es. En esta URL, el TLD real es ".tk" (Tokelau). '
          'Todo lo anterior (santander-banca-online.es.login.verificar) son subdominios del atacante. '
          'Además, usa HTTP sin cifrado, no HTTPS.',
    ),
    DeteccionItem(
      tipo: TipoDeteccion.web,
      emisor: 'https://www.bbva.es/personas/banca-online/login.html',
      cuerpo:
          'BBVA — Banca Online segura\n\n'
          'Acceso a tu banca online personal.\n\n'
          'Certificado TLS válido ✓\n'
          'Dominio oficial bbva.es ✓',
      esReal: true,
      explicacion:
          'LEGÍTIMO. La URL usa HTTPS y el dominio es directamente bbva.es (oficial). '
          'No hay subdominios sospechosos ni TLDs extranjeros. '
          'La estructura de ruta es coherente con el sitio oficial.',
    ),
    DeteccionItem(
      tipo: TipoDeteccion.email,
      emisor: 'no-reply@microsoft-support-team.com',
      asunto: 'Su suscripción Microsoft 365 expira HOY',
      cuerpo:
          'Estimado usuario,\n\n'
          'Su suscripción a Microsoft 365 expira hoy a las 23:59.\n\n'
          'Para renovar y evitar la pérdida de sus datos, acceda ahora:\n'
          'microsoft-renovar-365.com/renew\n\n'
          'Equipo de soporte Microsoft',
      esReal: false,
      explicacion:
          'FALSO. Microsoft usa @microsoft.com, no @microsoft-support-team.com. '
          'El enlace apunta a microsoft-renovar-365.com (no microsoft.com). '
          'La expiración "HOY a las 23:59" es urgencia artificial típica del phishing.',
    ),
  ];
}
