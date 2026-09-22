import 'package:cyber_ops/games/nivel_10/components/email_component.dart';
import 'package:cyber_ops/games/nivel_10/components/email_model.dart';
import 'package:cyber_ops/games/nivel_10/components/inspection_element.dart';
 
class Acto3Email {
  final EmailModel email;
  final List<InspectionElement> inspectionElements;

  const Acto3Email({
    required this.email,
    required this.inspectionElements,
  });
}

class PhishingData {
 
  // ── ACTO 1 — Opciones para construir el email ─────────────────────────────
 
  static const List<EmailComponent> senderOptions = [
    EmailComponent(
      id: 's1',
      type: ComponentType.sender,
      value: 'soporte@gmail.com',
      credibility: 1,
      hackerComment: 'Demasiado obvio. Nadie se lo creería.',
    ),
    EmailComponent(
      id: 's2',
      type: ComponentType.sender,
      value: 'soporte@sede-gob-es.net',
      credibility: 3,
      hackerComment: 'Perfecto. Nadie lee bien los dominios con guiones.',
    ),
    EmailComponent(
      id: 's3',
      type: ComponentType.sender,
      value: 'soporte@sede.gob.es',
      credibility: 0,
      hackerComment: 'Este es el dominio real. No puedes usarlo, te lo bloquearán al instante.',
    ),
  ];
 
  static const List<EmailComponent> subjectOptions = [
    EmailComponent(
      id: 'su1',
      type: ComponentType.subject,
      value: 'Información sobre certificados',
      credibility: 1,
      hackerComment: 'Sin urgencia, fácil de ignorar.',
    ),
    EmailComponent(
      id: 'su2',
      type: ComponentType.subject,
      value: 'Recordatorio: certificado digital',
      credibility: 2,
      hackerComment: 'Creíble pero sin presión suficiente.',
    ),
    EmailComponent(
      id: 'su3',
      type: ComponentType.subject,
      value: '⚠️ Su certificado expira HOY — Renuévelo ahora',
      credibility: 3,
      hackerComment: 'El miedo a perder acceso es tu mejor aliado.',
    ),
  ];
 
  static const List<EmailComponent> manipulationOptions = [
    EmailComponent(
      id: 'm1',
      type: ComponentType.manipulation,
      value: 'Miedo — perderá acceso a todos los servicios',
      credibility: 3,
      hackerComment: 'El miedo es el atajo más corto al clic.',
    ),
    EmailComponent(
      id: 'm2',
      type: ComponentType.manipulation,
      value: 'Recompensa — ha sido seleccionado para una subvención',
      credibility: 2,
      hackerComment: 'Funciona, pero levanta más sospechas.',
    ),
    EmailComponent(
      id: 'm3',
      type: ComponentType.manipulation,
      value: 'Culpa — no completó su verificación obligatoria',
      credibility: 2,
      hackerComment: 'Efectivo en contexto laboral.',
    ),
  ];
 
  static const List<EmailComponent> linkOptions = [
    EmailComponent(
      id: 'l1',
      type: ComponentType.link,
      value: 'http://renovar-certificado.net',
      credibility: 1,
      hackerComment: 'Sin HTTPS. Demasiado sospechoso.',
    ),
    EmailComponent(
      id: 'l2',
      type: ComponentType.link,
      value: 'https://sede-gob-es.net/renovar',
      credibility: 3,
      hackerComment: 'HTTPS no significa seguro. Solo significa cifrado.',
    ),
    EmailComponent(
      id: 'l3',
      type: ComponentType.link,
      value: 'https://sede.gob.es/renovar',
      credibility: 0,
      hackerComment: 'El enlace real. Si lo usas te rastrearán en segundos.',
    ),
  ];
 
  // ── ACTO 2 — Bandeja de entrada ───────────────────────────────────────────
 
  static const List<EmailModel> inbox = [
    EmailModel(
      id: 'e1',
      sender: 'noreply@sede.gob.es',
      subject: 'Confirmación de solicitud de certificado digital',
      body:
          'Su solicitud de renovación ha sido registrada con número de expediente 2024-78432. Puede consultar el estado en sede.gob.es.',
      isPhishing: false,
      educationalTip:
          'Dominio oficial .gob.es, sin urgencia y sin enlaces directos.',
    ),
    EmailModel(
      id: 'e2',
      sender: 'soporte@sede-gob-es.net',
      subject: '⚠️ Su certificado digital expira HOY — Renuévelo ahora',
      body:
          'Su certificado vence en menos de 24 horas. Haga clic aquí para renovarlo inmediatamente o perderá acceso a todos los servicios.',
      isPhishing: true,
      educationalTip:
          'Dominio falso con guiones, urgencia artificial y amenaza de pérdida de acceso. ¡Es el email que construiste!',
    ),
    EmailModel(
      id: 'e3',
      sender: 'rrhh@ayuntamiento-madrid.es',
      subject: 'Recordatorio: Formación obligatoria 15 de enero',
      body:
          'Le recordamos que el próximo martes 15 de enero tiene asignada la formación en protección de datos. El aula es la B-204.',
      isPhishing: false,
      educationalTip:
          'Sin enlaces, sin adjuntos e información concreta y verificable.',
    ),
    EmailModel(
      id: 'e4',
      sender: 'ministrerio.hacienda@gmail.com',
      subject: 'Revisión urgente de su nómina de diciembre',
      body:
          'Detectamos un error en su nómina de diciembre. Descargue el documento adjunto, fírmelo y devuélvalo antes de las 18:00h de hoy.',
      attachment: 'nomina_correccion_dic.exe',
      isPhishing: true,
      educationalTip:
          'Organismo oficial usando Gmail, adjunto ejecutable .exe y presión horaria.',
    ),
    EmailModel(
      id: 'e5',
      sender: 'notificaciones@agenciatributaria.gob.es',
      subject: 'Tiene una notificación pendiente en su buzón',
      body:
          'Tiene una notificación disponible en la sede electrónica. Acceda a través de sede.agenciatributaria.gob.es con su certificado digital.',
      isPhishing: false,
      educationalTip:
          'No incluye enlace directo e indica acceder manualmente al dominio oficial.',
    ),
    EmailModel(
      id: 'e6',
      sender: 'director.general@ayuntarniento-madrid.es',
      subject: 'Transferencia urgente — Confidencial',
      body:
          'Necesito que proceses una transferencia de 4.200€ a un proveedor externo antes de las 14:00h. Es confidencial, no lo comentes con nadie.',
      isPhishing: true,
      educationalTip:
          'La "m" está reemplazada por "rn" en el dominio. Petición inusual con confidencialidad forzada.',
    ),
  ];
 
  // ── ACTO 3 — Email ambiguo e inspeccionable ───────────────────────────────
 
  static const List<Acto3Email> acto3Emails = [
    Acto3Email(
      email: EmailModel(
        id: 'e7',
        sender: 'seguridad@correos.es',
        subject: 'Su paquete no ha podido ser entregado — Reprogramar entrega',
        body:
            'Hemos intentado entregar su paquete hoy sin éxito. Para reprogramar la entrega acceda a: correos-entregas.es/reprogramar?id=84729',
        isPhishing: true,
        educationalTip:
            'Un email legítimo de Correos siempre incluye el número de envío y usa el dominio correos.es directamente.',
      ),
      inspectionElements: [
        InspectionElement(
        type: ElementType.sender,
        label: 'Remitente',
        value: 'seguridad@correos.es',
        revelation:
            'Correos nunca usa "seguridad@" para notificaciones de entrega.',
        isSuspicious: true,
      ),
      InspectionElement(
        type: ElementType.url,
        label: 'Enlace',
        value: 'correos-entregas.es/reprogramar?id=84729',
        revelation:
            'El dominio oficial es correos.es. Este es un dominio distinto registrado para engañar.',
        isSuspicious: true,
      ),
      InspectionElement(
        type: ElementType.body,
        label: 'Cuerpo del mensaje',
        value: 'Sin número de paquete ni remitente',
        revelation:
            'Un email real de Correos siempre incluye el número de envío y el nombre del remitente.',
        isSuspicious: true,
      ),
    ],
  ),
    Acto3Email(
      email: EmailModel(
        id: 'e8',
        sender: 'notificaciones@correo.aeat.es',
        subject: 'Aviso de nueva notificación disponible',
        body:
            'Tiene una nueva notificación disponible en la sede electrónica. Acceda escribiendo sede.agenciatributaria.gob.es en su navegador.',
        isPhishing: false,
        educationalTip:
            'Un aviso legítimo puede recomendar acceder manualmente a la sede oficial en vez de presionar con un enlace sospechoso.',
      ),
      inspectionElements: [
        InspectionElement(
          type: ElementType.sender,
          label: 'Remitente',
          value: 'notificaciones@correo.aeat.es',
          revelation:
              'El remitente pertenece a un dominio institucional relacionado con la AEAT.',
          isSuspicious: false,
        ),
        InspectionElement(
          type: ElementType.url,
          label: 'Enlace',
          value: 'sede.agenciatributaria.gob.es',
          revelation:
              'El mensaje indica el dominio oficial de la sede electrónica y recomienda acceder manualmente.',
          isSuspicious: false,
        ),
        InspectionElement(
          type: ElementType.body,
          label: 'Cuerpo del mensaje',
          value: 'No solicita claves ni datos bancarios',
          revelation:
              'El texto no pide credenciales, pagos ni descargas urgentes.',
          isSuspicious: false,
        ),
      ],
    ),

    Acto3Email(
      email: EmailModel(
        id: 'e9',
        sender: 'notificaciones@correos.es',
        subject: 'Entrega programada de su paquete',
        body:
            'Su envío PQ4A892731ES está previsto para entrega mañana. Puede consultar el seguimiento en: correos.es/seguimiento',
        isPhishing: false,
        educationalTip:
            'El email usa el dominio oficial correos.es, incluye número de envío y no fuerza una acción urgente.',
      ),
      inspectionElements: [
        InspectionElement(
          type: ElementType.sender,
          label: 'Remitente',
          value: 'notificaciones@correos.es',
          revelation:
              'El remitente usa el dominio oficial correos.es.',
          isSuspicious: false,
        ),
        InspectionElement(
          type: ElementType.url,
          label: 'Enlace',
          value: 'correos.es/seguimiento',
          revelation:
              'El enlace apunta directamente al dominio oficial, sin palabras añadidas ni dominios parecidos.',
          isSuspicious: false,
        ),
        InspectionElement(
          type: ElementType.body,
          label: 'Cuerpo del mensaje',
          value: 'Incluye número de envío verificable',
          revelation:
              'El mensaje incluye un número de envío concreto y no amenaza con bloquear ni cancelar nada.',
          isSuspicious: false,
        ),
      ],
    ),

    Acto3Email(
      email: EmailModel(
      id: 'e10',
      sender: 'facturacion@netflix-pagos.com',
      subject: 'No hemos podido procesar su último pago',
      body:
          'Su suscripción quedará suspendida hoy si no actualiza sus datos de pago en: netflix-pagos.com/actualizar?id=93210',
      isPhishing: true,
      educationalTip:
          'Netflix usa dominios propios como netflix.com, no sitios externos con palabras añadidas como "-pagos".',
    ),
 
      inspectionElements: [
        InspectionElement(
          type: ElementType.sender,
          label: 'Remitente',
          value: 'facturacion@netflix-pagos.com',
          revelation:
              'El dominio imita a Netflix, pero no pertenece al servicio oficial.',
          isSuspicious: true,
        ),
        InspectionElement(
          type: ElementType.url,
          label: 'Enlace',
          value: 'netflix-pagos.com/actualizar?id=93210',
          revelation:
              'El enlace pide actualizar pagos desde un dominio ajeno al oficial.',
          isSuspicious: true,
        ),
        InspectionElement(
          type: ElementType.body,
          label: 'Cuerpo del mensaje',
          value: 'Amenaza de suspensión inmediata',
          revelation:
              'La urgencia busca que actúes sin comprobar el dominio ni entrar manualmente en la cuenta.',
          isSuspicious: true,
        ),
      ],
    ),
  ];
 
  // ── HELPERS ───────────────────────────────────────────────────────────────
 
  static List<EmailComponent> optionsForType(ComponentType type) {
    switch (type) {
      case ComponentType.sender:
        return senderOptions;
      case ComponentType.subject:
        return subjectOptions;
      case ComponentType.manipulation:
        return manipulationOptions;
      case ComponentType.link:
        return linkOptions;
    }
  }
 
  static String labelForType(ComponentType type) {
    switch (type) {
      case ComponentType.sender:
        return 'REMITENTE';
      case ComponentType.subject:
        return 'ASUNTO';
      case ComponentType.manipulation:
        return 'TÉCNICA';
      case ComponentType.link:
        return 'ENLACE';
    }
  }
}