import 'package:cyber_ops/games/nivel_12/component/accion_respuesta.dart';
import 'package:cyber_ops/games/nivel_12/component/estado_filtracion.dart';
import 'package:cyber_ops/games/nivel_12/component/evidencia_digital.dart';
import 'data/sombra_digital_data.dart';





enum FaseNivel12 {
  investigar,
  confirmarRobo,
  contener,
  recuperar,
  verificar,
}

extension FaseNivel12Label on FaseNivel12 {
  String get label {
    switch (this) {
      case FaseNivel12.investigar:
        return 'INVESTIGAR';
      case FaseNivel12.confirmarRobo:
        return 'CONFIRMAR ROBO';
      case FaseNivel12.contener:
        return 'CONTENER';
      case FaseNivel12.recuperar:
        return 'RECUPERAR';
      case FaseNivel12.verificar:
        return 'VERIFICAR';
    }
  }
}

class Nivel12Game {
  int xp = 0;
  int exposicion = 0;
  FaseNivel12 faseActual = FaseNivel12.investigar;

  bool analisisCompleto = false;
  bool respuestaDesbloqueada = false;
  bool completado = false;
  bool fallido = false;

  bool logroOculto = false;
  final List<String> eventosSistema = [];

bool glitchModerado = false;
bool glitchCritico = false;

  final Set<String> evidenciasSeleccionadasIds = {};
  final Set<String> accionesSeleccionadasIds = {};

  List<EvidenciaDigital> get evidencias => SombraDigitalData.evidencias;
 late final List<AccionRespuesta> acciones =
    List.from(SombraDigitalData.acciones)..shuffle();
  List<EstadoFiltracion> get datosEnRiesgo => SombraDigitalData.datosEnRiesgo;

  List<String> get dialogosIntro => SombraDigitalData.dialogosIntro;
  List<String> get dialogosFinales => SombraDigitalData.dialogosFinales;

  Set<String> get evidenciasRealesIds {
    return evidencias
        .where((evidencia) => evidencia.esRastroStealer)
        .map((evidencia) => evidencia.id)
        .toSet();
  }

  Set<String> get evidenciasFalsasIds {
    return evidencias
        .where((evidencia) => !evidencia.esRastroStealer)
        .map((evidencia) => evidencia.id)
        .toSet();
  }

  Set<String> get accionesNecesariasIds {
    return acciones
        .where((accion) => accion.esNecesaria)
        .map((accion) => accion.id)
        .toSet();
  }

  Set<String> get accionesPeligrosasIds {
    return acciones
        .where((accion) => accion.esPeligrosa)
        .map((accion) => accion.id)
        .toSet();
  }

  void toggleEvidencia(EvidenciaDigital evidencia) {
    if (analisisCompleto || completado || fallido) return;

    if (evidenciasSeleccionadasIds.contains(evidencia.id)) {
      evidenciasSeleccionadasIds.remove(evidencia.id);
    } else {
      evidenciasSeleccionadasIds.add(evidencia.id);
    }
  }

  String analizarStealer() {
    if (completado || fallido) return 'La misión ya ha terminado.';

    final seleccionadasReales =
        evidenciasSeleccionadasIds.intersection(evidenciasRealesIds);
    final seleccionadasFalsas =
        evidenciasSeleccionadasIds.intersection(evidenciasFalsasIds);

    final faltan = evidenciasRealesIds.length - seleccionadasReales.length;
    final falsas = seleccionadasFalsas.length;

    if (faltan == 0 && falsas == 0) {
      analisisCompleto = true;
      respuestaDesbloqueada = true;
      xp += 500;
faseActual = FaseNivel12.contener;
      return 'Infostealer identificado: cookies, sesiones, credenciales y datos sensibles han sido extraídos.';
    }

    exposicion += (faltan * 10) + (falsas * 8);
    actualizarEstadoVisual();

    if (exposicion >= 100) {
      exposicion = 100;
      fallido = true;
      return 'Exposición máxima. Los datos robados ya circulan fuera del sistema.';
    }

    return 'Análisis incompleto: quedan rastros sin relacionar o has marcado falsos positivos.';
  }

  void toggleAccion(AccionRespuesta accion) {
    if (!respuestaDesbloqueada || completado || fallido) return;

    if (accionesSeleccionadasIds.contains(accion.id)) {
      accionesSeleccionadasIds.remove(accion.id);
    } else {
      accionesSeleccionadasIds.add(accion.id);
    }
    _actualizarFaseRespuesta();
  }

  String verificarRespuesta() {
    if (!respuestaDesbloqueada) {
      return 'Primero debes identificar correctamente el infostealer.';
    }

    if (completado || fallido) return 'La misión ya ha terminado.';

    final necesariasSeleccionadas =
        accionesSeleccionadasIds.intersection(accionesNecesariasIds);
    final peligrosasSeleccionadas =
        accionesSeleccionadasIds.intersection(accionesPeligrosasIds);

    final faltan = accionesNecesariasIds.length - necesariasSeleccionadas.length;
    final peligrosas = peligrosasSeleccionadas.length;

    if (faltan == 0 && peligrosas == 0) {
      completado = true;
      xp += 600;

      if (exposicion <= 25 &&
          evidenciasSeleccionadasIds.intersection(evidenciasFalsasIds).isEmpty) {
        logroOculto = true;
        xp += 200;
      }

      return logroOculto
          ? 'Respuesta perfecta. Has contenido la fuga sin dejar que la exposición creciera.'
          : 'Fuga contenida. Sesiones, tokens y credenciales han sido protegidos.';
    }

    exposicion += (faltan * 12) + (peligrosas * 18);
    actualizarEstadoVisual();

    if (exposicion >= 100) {
      exposicion = 100;
      fallido = true;
      return 'Respuesta fallida. Las sesiones robadas siguen activas y la exposición se ha disparado.';
    }

    return 'Respuesta incompleta: quedan accesos abiertos o has elegido acciones peligrosas.';
  }
  void _actualizarFaseRespuesta() {
  final contiene = accionesSeleccionadasIds.any((id) {
    final accion = acciones.firstWhere((a) => a.id == id);
    return accion.tipo == TipoAccionRespuesta.contener;
  });

  final recupera = accionesSeleccionadasIds.any((id) {
    final accion = acciones.firstWhere((a) => a.id == id);
    return accion.tipo == TipoAccionRespuesta.recuperar;
  });

  final verifica = accionesSeleccionadasIds.any((id) {
    final accion = acciones.firstWhere((a) => a.id == id);
    return accion.tipo == TipoAccionRespuesta.verificar;
  });

  if (verifica) {
    faseActual = FaseNivel12.verificar;
  } else if (recupera) {
    faseActual = FaseNivel12.recuperar;
  } else if (contiene) {
    faseActual = FaseNivel12.contener;
  } else if (respuestaDesbloqueada) {
    faseActual = FaseNivel12.contener;
  }
}
void actualizarEstadoVisual() {
  eventosSistema.clear();

  if (exposicion >= 25) {
    eventosSistema.add(
      'Actividad sospechosa detectada en sesión de navegador.',
    );
  }

  if (exposicion >= 40) {
    glitchModerado = true;

    eventosSistema.add(
      'Cookie reutilizada desde una ubicación desconocida.',
    );
  }

  if (exposicion >= 60) {
    eventosSistema.add(
      'Nueva sesión activa detectada en Discord.',
    );
  }

  if (exposicion >= 75) {
    glitchCritico = true;

    eventosSistema.add(
      'Wallet marcada como comprometida.',
    );
  }

  if (exposicion >= 90) {
    eventosSistema.add(
      'Exfiltración masiva en progreso.',
    );
  }
}
}