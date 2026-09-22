import 'elemento_nivel06.dart';

class DatosNivel06 {
  static const String passwordCorrecta = 'amparo0201';

  static const List<String> dialogosIntro = [
    'Has llegado más lejos de lo esperado.',
    'Los primeros sistemas cayeron por reflejos. Este caerá por algo mucho más humano.',
    'Tu objetivo no es cuidadoso. Es sentimental.',
    'Se aferra a nombres que ya no le pertenecen. A fechas que no puede olvidar.',
    'Encontrarás correos, recuerdos y rastros de una obsesión que nunca desapareció.',
    'No busques una clave fuerte.',
    'Busca la herida que sigue abierta.',
  ];

  static const List<String> dialogosFinales = [
    'La puerta se ha abierto.',
    'No porque la contraseña fuera débil por sí sola...',
    'Sino porque la persona detrás de ella lo era aún más.',
    'Los nombres, los recuerdos, la culpa, la nostalgia... todo deja patrones.',
    'Y cuando alguien convierte su vida en una contraseña, también convierte su intimidad en una vulnerabilidad.',
    'La ciberseguridad no trata solo de sistemas. Trata de hábitos. De decisiones. De personas.',
    'Recuérdalo: una mente descuidada puede ser tan peligrosa como un sistema sin defensa.',
  ];

  static const List<ElementoNivel06> correos = [
    ElementoNivel06(
      titulo: 'Borrador no enviado',
      subtitulo: 'No sé si debería ir...',
      contenido:
          'No sé si debería ir...\n\n'
          'No sé si me quiere ver.\n\n'
          'Pero sé que ese día estará allí.\n'
          'Siempre ha sido importante para ella.\n\n'
          'Quizá debería mantenerme lejos.',
    ),
    ElementoNivel06(
      titulo: 'Informe del detective',
      subtitulo: 'Mantiene sus rutinas',
      contenido:
          'He seguido sus movimientos las últimas semanas.\n\n'
          'No hay cambios relevantes.\n\n'
          'Mantiene sus rutinas.\n'
          'Especialmente... esa fecha.',
    ),
    ElementoNivel06(
      titulo: 'Correo antiguo',
      subtitulo: 'Antes siempre venías...',
      contenido:
          'Antes siempre venías...\n\n'
          'Aunque fuera tarde.\n\n'
          'Supongo que este año será diferente.',
    ),
    ElementoNivel06(
      titulo: 'Angustias',
      subtitulo: 'No vuelvas a aparecer',
      contenido:
          'No vuelvas a aparecer por allí.\n\n'
          'Ya hiciste suficiente.',
    ),
    ElementoNivel06(
      titulo: 'Recordatorio',
      subtitulo: 'Evento guardado',
      contenido:
          'Evento guardado:\n\n'
          '02/01',
    ),
  ];

  static const List<ElementoNivel06> archivos = [
    ElementoNivel06(
      titulo: 'IMG_amparo_02.png',
      subtitulo: 'Archivo de imagen',
      contenido:
          'Nombre del archivo: IMG_amparo_02.png\n\n'
          'La miniatura está dañada.\n'
          'No se puede previsualizar correctamente.',
    ),
    ElementoNivel06(
      titulo: 'direccion.txt',
      subtitulo: 'Texto simple',
      contenido:
          'Dirección actualizada:\n\n'
          'Avenida Catalina',
    ),
    ElementoNivel06(
      titulo: 'mascota.txt',
      subtitulo: 'Nota antigua',
      contenido:
          'Rock sigue esperando en la puerta cuando oye pasos.',
    ),
    ElementoNivel06(
      titulo: 'agenda_0705.txt',
      subtitulo: 'Anotación',
      contenido:
          '07/05\n\n'
          'El día que se fueron.',
    ),
  ];

  static const Map<String, String> pistasPorTitulo = {
    'Borrador no enviado':
        'El objetivo duda en acudir a un día importante para ella.',
    'Informe del detective':
        'El detective confirma que hay una fecha especialmente relevante.',
    'Correo antiguo':
        'La hija sigue siendo el vínculo emocional más fuerte.',
    'Recordatorio':
        'Fecha detectada: 02/01',
    'IMG_amparo_02.png':
        'Nombre importante detectado: Amparo',
    'agenda_0705.txt':
        '07/05 parece importante, pero podría ser ruido emocional.',
  };
}