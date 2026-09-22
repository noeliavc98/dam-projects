import 'package:flutter/foundation.dart';

enum ModuloZeroDay { red, logs, procesos, archivos }

class OpcionZeroDay {
  final String id;
  final String titulo;
  final String descripcion;

  const OpcionZeroDay({
    required this.id,
    required this.titulo,
    required this.descripcion,
  });
}

class CasoZeroDay {
  final String sistema;
  final String descripcion;
  final String pregunta;
  final String vectorCorrecto;
  final Map<ModuloZeroDay, String> hallazgos;
  final List<OpcionZeroDay> opciones;

  const CasoZeroDay({
    required this.sistema,
    required this.descripcion,
    required this.pregunta,
    required this.vectorCorrecto,
    required this.hallazgos,
    required this.opciones,
  });
}

const casosZeroDay = <CasoZeroDay>[
  CasoZeroDay(
    sistema: 'SERVIDOR WEB CORPORATIVO',
    descripcion:
        'El servicio responde con lentitud y hay código activo sin archivo visible.',
    pregunta: '¿Qué tipo de amenaza estás observando?',
    vectorCorrecto: 'fileless',
    hallazgos: {
      ModuloZeroDay.red:
          'Tráfico TLS válido. No hay MITM ni red abierta activa.',
      ModuloZeroDay.logs:
          'Eventos incompletos. El atacante borra rastros después de ejecutar.',
      ModuloZeroDay.procesos:
          'Se detecta código ejecutándose en memoria, pero no hay ningún .exe o programa visible.',
      ModuloZeroDay.archivos:
          'No se detectan instaladores, USB ni documentos infectados.',
    },
    opciones: [
      OpcionZeroDay(
        id: 'webshell',
        titulo: 'WEBSHELL',
        descripcion: 'Archivo oculto persistente dentro del servidor web.',
      ),
      OpcionZeroDay(
        id: 'fileless',
        titulo: 'ATAQUE FILELESS',
        descripcion:
            'Código ejecutado directamente en memoria sin binario visible.',
      ),
      OpcionZeroDay(
        id: 'ransomware',
        titulo: 'RANSOMWARE',
        descripcion: 'Cifrado masivo de archivos locales y nota de rescate.',
      ),
      OpcionZeroDay(
        id: 'mitm',
        titulo: 'MAN IN THE MIDDLE',
        descripcion:
            'Intercepción activa del tráfico entre cliente y servidor.',
      ),
    ],
  ),
  CasoZeroDay(
    sistema: 'EQUIPO DE DIRECCIÓN',
    descripcion:
        'Se detecta acceso legítimo desde una ubicación inusual tras un correo interno.',
    pregunta: '¿Cómo se obtuvo este acceso?',
    vectorCorrecto: 'credenciales',
    hallazgos: {
      ModuloZeroDay.red:
          'Inicio de sesión desde IP desconocida usando credenciales válidas.',
      ModuloZeroDay.logs:
          'Login correcto minutos después de abrir un enlace de soporte falso.',
      ModuloZeroDay.procesos:
          'No hay malware persistente ni payload activo en memoria.',
      ModuloZeroDay.archivos:
          'No hay USB ni instaladores. Solo rastro de navegación a un login clonado.',
    },
    opciones: [
      OpcionZeroDay(
        id: 'credenciales',
        titulo: 'ROBO DE CREDENCIALES',
        descripcion: 'Acceso usando usuario y contraseña obtenidos por engaño.',
      ),
      OpcionZeroDay(
        id: 'usb',
        titulo: 'USB INFECTADO',
        descripcion: 'Ejecución local iniciada desde un dispositivo externo.',
      ),
      OpcionZeroDay(
        id: 'bruteforce',
        titulo: 'FUERZA BRUTA',
        descripcion: 'Intentos repetidos hasta adivinar la contraseña.',
      ),
      OpcionZeroDay(
        id: 'rootkit',
        titulo: 'ROOTKIT',
        descripcion: 'Persistencia oculta en el sistema operativo.',
      ),
    ],
  ),
  CasoZeroDay(
    sistema: 'ESTACIÓN DE LABORATORIO',
    descripcion:
        'El equipo queda comprometido justo después de transferir documentación técnica.',
    pregunta: '¿Cuál fue el origen de la infección?',
    vectorCorrecto: 'usb_oculto',
    hallazgos: {
      ModuloZeroDay.red: 'No hay conexión externa previa al compromiso.',
      ModuloZeroDay.logs: 'Ejecución local iniciada desde unidad extraíble.',
      ModuloZeroDay.procesos:
          'Proceso temporal iniciado por autorun y finalizado tras instalar dropper.',
      ModuloZeroDay.archivos:
          'Se detecta archivo oculto en USB con firma no válida.',
    },
    opciones: [
      OpcionZeroDay(
        id: 'wifi',
        titulo: 'RED ABIERTA',
        descripcion: 'Compromiso provocado por una red inalámbrica insegura.',
      ),
      OpcionZeroDay(
        id: 'usb_oculto',
        titulo: 'ARCHIVO OCULTO EN USB',
        descripcion:
            'Dropper ejecutado desde unidad extraíble con firma inválida.',
      ),
      OpcionZeroDay(
        id: 'phishing',
        titulo: 'CORREO FALSO',
        descripcion: 'Engaño por email con enlace a una página clonada.',
      ),
      OpcionZeroDay(
        id: 'supply_chain',
        titulo: 'UPDATE COMPROMETIDO',
        descripcion: 'Actualización legítima alterada antes de instalarse.',
      ),
    ],
  ),
];

class Nivel20Game extends ChangeNotifier {
  int vidas = 3;
  int xp = 0;
  int casoActual = 0;

  final Set<ModuloZeroDay> modulosAnalizados = {};
  String? vectorSeleccionado;

  bool misionCumplida = false;
  bool misionFallida = false;

  CasoZeroDay get caso => casosZeroDay[casoActual];
  bool get juegoTerminado => misionCumplida || misionFallida;
  int get progreso => modulosAnalizados.length;
  bool get puedeEmitirVeredicto => modulosAnalizados.length >= 3;

  void analizarModulo(ModuloZeroDay modulo) {
    if (juegoTerminado) return;
    if (modulosAnalizados.contains(modulo)) return;
    if (modulosAnalizados.length >= 3) return;

    modulosAnalizados.add(modulo);
    xp += 15;
    notifyListeners();
  }

  void seleccionarVector(String vector) {
    if (juegoTerminado) return;

    vectorSeleccionado = vector;
    notifyListeners();
  }

  bool confirmar() {
    if (juegoTerminado || !puedeEmitirVeredicto || vectorSeleccionado == null) {
      return false;
    }

    final correcto = vectorSeleccionado == caso.vectorCorrecto;

    if (correcto) {
      xp += 100 + (casoActual * 25);

      if (casoActual >= casosZeroDay.length - 1) {
        misionCumplida = true;
      } else {
        casoActual++;
        modulosAnalizados.clear();
        vectorSeleccionado = null;
      }
    } else {
      vidas--;

      if (vidas <= 0) {
        vidas = 0;
        misionFallida = true;
      } else if (casoActual >= casosZeroDay.length - 1) {
        misionFallida = true;
      } else {
        casoActual++;
        modulosAnalizados.clear();
        vectorSeleccionado = null;
      }
    }

    notifyListeners();
    return correcto;
  }

  void reiniciar() {
    vidas = 3;
    xp = 0;
    casoActual = 0;
    modulosAnalizados.clear();
    vectorSeleccionado = null;
    misionCumplida = false;
    misionFallida = false;
    notifyListeners();
  }
}
