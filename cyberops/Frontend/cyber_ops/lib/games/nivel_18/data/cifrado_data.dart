import '../components/archivo_terminal.dart';
import '../components/comando_terminal.dart';

class CifradoData {
  static const String nombreNivel = 'NIVEL 18 - CIFRADO';

  static const List<String> dialogosIntro = [
    'Una puerta cifrada no se rompe con fuerza.',
    'Se entiende.',
    'Hoy no vas a perseguir malware.',
    'Vas a entrar en una cámara cerrada por matemáticas.',
    'El cifrado protege secretos. Pero las personas suelen esconder las llaves demasiado cerca.',
    'Observa los archivos. Lee los errores. Carga la clave correcta.',
    'Y recuerda: no todo lo ilegible puede descifrarse.',
  ];

  static const List<String> dialogosFinales = [
    'Has abierto la cámara.',
    'No has roto el cifrado.',
    'Has entendido cómo estaba construido.',
    'La criptografía fuerte no suele caer por las matemáticas.',
    'Cae por claves mal guardadas, IV reutilizados y errores humanos.',
    'Esa es la lección.',
  ];

  static const List<ArchivoTerminal> archivos = [
    ArchivoTerminal(
      nombre: 'vault.enc',
      descripcion: 'Archivo principal cifrado con AES.',
      contenido:
          'Archivo binario cifrado.\n'
          'Cabecera detectada: AES-256-CBC\n'
          'Estado: bloqueado\n'
          'Requiere clave e IV.',
    ),
    ArchivoTerminal(
      nombre: 'notas.txt',
      descripcion: 'Notas internas del administrador.',
      contenido:
          'Nota del administrador:\n\n'
          'El backup de la clave está separado del IV.\n'
          'No guardar ambos juntos parecía una buena idea.\n'
          'Revisar script.sh si algo falla.',
    ),
    ArchivoTerminal(
      nombre: 'script.sh',
      descripcion: 'Script antiguo de descifrado.',
      contenido:
          '#!/bin/bash\n'
          'openssl enc -d -aes-256-cbc \\\n'
          '  -in vault.enc \\\n'
          '  -K backup.key \\\n'
          '  -iv iv.txt\n\n'
          '# TODO: no dejar pistas tan obvias en producción.',
    ),
    ArchivoTerminal(
      nombre: 'backup.key',
      descripcion: 'Clave AES recuperada del backup.',
      contenido:
          'KEY=VX-19-DELTA-K7\n'
          'Tipo: clave simétrica\n'
          'Uso esperado: AES',
    ),
    ArchivoTerminal(
      nombre: 'iv.txt',
      descripcion: 'Vector de inicialización.',
      contenido:
          'IV=04A7F92C11D8AB77\n'
          'Uso esperado: AES-CBC\n'
          'Advertencia: reutilizar IV puede filtrar patrones.',
    ),
    ArchivoTerminal(
      nombre: 'hash_admin.sha256',
      descripcion: 'Hash de comprobación.',
      contenido:
          'SHA256=8f14e45fceea167a5a36dedd4bea2543\n'
          'Nota: esto no es un archivo cifrado reversible.',
    ),
    ArchivoTerminal(
      nombre: 'base64.txt',
      descripcion: 'Texto codificado.',
      contenido:
          'VmF1bHQgZGUgY2lmcmFkbyAtIG5vIGVzIGVuY3JpcHRhY2lvbg==\n\n'
          'Pista: Base64 representa datos. No los protege.',
    ),
    ArchivoTerminal(
      nombre: '.dev_vault',
      descripcion: 'Archivo oculto del equipo de desarrollo.',
      oculto: true,
      contenido:
          'DEV VAULT // ACCESO INTERNO\n\n'
          'Si has llegado hasta aquí, has mirado donde no todos miran.\n'
          'Los mejores analistas no solo siguen el camino marcado.\n'
          'También prueban los bordes del sistema.\n\n'
          'Comando desbloqueado: unlock jackpot',
    ),
  ];

  static const List<ComandoTerminal> comandosSugeridos = [
    ComandoTerminal(
      texto: 'help',
      descripcion: 'Muestra comandos disponibles.',
    ),
    ComandoTerminal(
      texto: 'ls',
      descripcion: 'Lista archivos visibles.',
    ),
    ComandoTerminal(
      texto: 'ls -a',
      descripcion: 'Lista archivos visibles y ocultos.',
    ),
    ComandoTerminal(
      texto: 'cat notas.txt',
      descripcion: 'Lee las notas del administrador.',
    ),
    ComandoTerminal(
      texto: 'cat script.sh',
      descripcion: 'Lee el script de descifrado.',
    ),
    ComandoTerminal(
      texto: 'inspect vault.enc',
      descripcion: 'Inspecciona el archivo cifrado.',
    ),
    ComandoTerminal(
      texto: 'load backup.key',
      descripcion: 'Carga la clave AES.',
    ),
    ComandoTerminal(
      texto: 'load iv.txt',
      descripcion: 'Carga el IV.',
    ),
    ComandoTerminal(
      texto: 'decrypt vault.enc',
      descripcion: 'Intenta descifrar el vault.',
    ),
    ComandoTerminal(
      texto: 'status',
      descripcion: 'Muestra estado actual.',
    ),
    ComandoTerminal(
  texto: 'decode base64.txt',
  descripcion: 'Decodifica el texto Base64.',
),
ComandoTerminal(
  texto: 'verify hash_admin.sha256',
  descripcion: 'Verifica integridad con hash.',
),
ComandoTerminal(
  texto: 'hint',
  descripcion: 'Pide una pista a FRACTURA.',
),
  ];
}