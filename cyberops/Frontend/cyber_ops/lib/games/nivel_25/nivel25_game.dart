import 'package:cyber_ops/games/nivel_25/components/resultado_boss.dart';
import 'package:cyber_ops/games/nivel_25/data/hora_zero_data.dart';
import 'components/ataque_boss.dart';
import 'components/defensa_boss.dart';
import 'components/fragmento_origen.dart';

class Nivel25Game {
  int vidaJugador = 100;
  int vidaBoss = 100;
  int xp = 0;
  int combo = 0;
  int rondaActual = 0;
  int pistasUsadas = 0;
  String? defensaBloqueada;
  
  

  bool victoria = false;
  bool derrota = false;
  bool protocoloOrigen = false;
  String? ultimaFaseMostrada;

  final Set<String> defensasSeleccionadas = {};
  final Set<String> fragmentosDesbloqueados = {};

  List<AtaqueBoss> get ataques => HoraCeroData.ataques;
  List<DefensaBoss> get defensas => HoraCeroData.defensas;
  List<FragmentoOrigen> get fragmentos => HoraCeroData.fragmentos;

  List<String> get dialogosIntro => HoraCeroData.dialogosIntro;
  List<String> get dialogosVictoria => HoraCeroData.dialogosVictoria;

  AtaqueBoss get ataqueActual => ataques[rondaActual];

String get faseActual {
  if (vidaBoss <= 10) return 'NÚCLEO FINAL';
  if (vidaBoss <= 40) return 'IMPACTO';
  if (vidaBoss <= 70) return 'PERSISTENCIA';
  return 'INTRUSIÓN';
}

String? comprobarCambioFase() {
  if (ultimaFaseMostrada == null) {
    ultimaFaseMostrada = faseActual;
    return null;
  }

  if (ultimaFaseMostrada != faseActual) {
    ultimaFaseMostrada = faseActual;

    switch (faseActual) {
      case 'PERSISTENCIA':
        return '⚠ EL NÚCLEO CERO HA EVOLUCIONADO\n\nAhora intenta permanecer oculto dentro de la red.';
      case 'IMPACTO':
        return '⚠ EL NÚCLEO CERO HA EVOLUCIONADO\n\nLa intrusión ha tenido éxito. Comienza la fase de impacto.';
      case 'NÚCLEO FINAL':
        return '☠ NÚCLEO FINAL ACTIVADO\n\nTodas las cadenas de ataque convergen.';
      default:
        return null;
    }
  }

  return null;
}

  bool get puedeResolver => defensasSeleccionadas.isNotEmpty;

  void actualizarDefensaBloqueada() {
  defensaBloqueada = null;

  if (vidaBoss <= 70 && vidaBoss > 40) {
    defensaBloqueada = 'mfa';
  }

  if (vidaBoss <= 40 && vidaBoss > 10) {
    defensaBloqueada = 'siem';
  }

  if (vidaBoss <= 10) {
    defensaBloqueada = 'segmentacion';
  }
}

  void toggleDefensa(DefensaBoss defensa) {
    if (defensa.id == defensaBloqueada) {
  return;
}
    if (victoria || derrota) return;

    if (defensasSeleccionadas.contains(defensa.id)) {
      defensasSeleccionadas.remove(defensa.id);
      return;
    }

    if (defensasSeleccionadas.length >= 5) {
      return;
    }
    defensasSeleccionadas.add(defensa.id);
  }

  ResultadoBoss resolverRonda() {
    if (victoria || derrota) {
      return const ResultadoBoss(
        correcto: false,
        victoria: false,
        derrota: false,
        mensaje: 'La batalla ya ha terminado.',
      );
    }

    if (!puedeResolver) {
      return const ResultadoBoss(
        correcto: false,
        victoria: false,
        derrota: false,
        mensaje: 'Selecciona todas las defensas necesarias antes de responder.',
      );
    }

    final correctas = ataqueActual.defensasCorrectas.toSet();
    final seleccionadas = defensasSeleccionadas.toSet();

    final incluyeTodas = seleccionadas.containsAll(correctas);
    final defensasExtra = seleccionadas.difference(correctas).length;

    final correcto = incluyeTodas && defensasExtra <= 1;

    if (correcto) {
      combo++;

      final bonusPrecision = defensasExtra == 0 ? 8 : 0;
      final penalizacionExtra = defensasExtra * 4;

      final dano =
          ataqueActual.danoAlBoss +
          (combo >= 3 ? 6 : 0) +
          bonusPrecision -
          penalizacionExtra;

      final xpGanada = 120 + (combo * 25) + (defensasExtra == 0 ? 40 : 0);

      vidaBoss = (vidaBoss - dano).clamp(0, 100).toInt();
      actualizarDefensaBloqueada();
      xp += xpGanada;

      _intentarDesbloquearFragmento();

      if (vidaBoss <= 0 || rondaActual >= ataques.length - 1) {
        victoria = true;
        _evaluarProtocoloOrigen();

        return ResultadoBoss(
          correcto: true,
          victoria: true,
          derrota: false,
          mensaje: _mensajeVictoria(),
          xpGanada: xpGanada,
          fragmentoDesbloqueado: fragmentosDesbloqueados.isNotEmpty,
        );
      }

      rondaActual++;
      defensasSeleccionadas.clear();

      return ResultadoBoss(
        correcto: true,
        victoria: false,
        derrota: false,
        mensaje: defensasExtra == 0
            ? 'Defensa perfecta. ${ataqueActual.explicacion}'
            : 'Defensa válida, aunque has usado una acción extra. ${ataqueActual.explicacion}',
        xpGanada: xpGanada,
        fragmentoDesbloqueado: fragmentosDesbloqueados.isNotEmpty,
      );
    }

    combo = 0;
    vidaJugador = (vidaJugador - ataqueActual.danoSiFalla)
        .clamp(0, 100)
        .toInt();

    if (vidaJugador <= 0) {
      derrota = true;

      return ResultadoBoss(
        correcto: false,
        victoria: false,
        derrota: true,
        mensaje: 'El Núcleo Cero ha roto la defensa final.',
      );
    }

    defensasSeleccionadas.clear();

    return ResultadoBoss(
      correcto: false,
      victoria: false,
      derrota: false,
      mensaje: !incluyeTodas
          ? 'Defensa incompleta. Te faltó cortar una parte clave del ataque. ${ataqueActual.explicacion}'
          : 'Defensa sobrecargada. Has elegido demasiadas acciones sin criterio. ${ataqueActual.explicacion}',
    );
  }

  String pedirPista() {
    pistasUsadas++;

    switch (ataqueActual.tipo) {
      case TipoAtaqueBoss.phishing:
        return 'FRACTURA: Si el engaño roba credenciales, no confíes solo en la contraseña.';
      case TipoAtaqueBoss.tokenRobado:
        return 'FRACTURA: Cambiar la contraseña no siempre cierra una sesión ya robada.';
      case TipoAtaqueBoss.persistencia:
        return 'FRACTURA: El enemigo quiere sobrevivir al reinicio. Busca lo que arranca solo.';
      case TipoAtaqueBoss.privilegios:
        return 'FRACTURA: Reduce permisos y corrige el fallo que permite subir de nivel.';
      case TipoAtaqueBoss.ransomware:
        return 'FRACTURA: No basta con parar el cifrado. También debes poder recuperar.';
      case TipoAtaqueBoss.exfiltracion:
        return 'FRACTURA: Cuando los datos salen, necesitas visibilidad y control de fuga.';
      case TipoAtaqueBoss.comboFinal:
        return 'FRACTURA: Corta sesión, limita movimiento y observa la red.';
    }
  }

  void _intentarDesbloquearFragmento() {
    if (combo == 2 && !fragmentosDesbloqueados.contains('f1')) {
      fragmentosDesbloqueados.add('f1');
    }

    if (combo == 4 && !fragmentosDesbloqueados.contains('f2')) {
      fragmentosDesbloqueados.add('f2');
    }

    if (vidaBoss <= 25 && !fragmentosDesbloqueados.contains('f3')) {
      fragmentosDesbloqueados.add('f3');
    }
  }

  void _evaluarProtocoloOrigen() {
    protocoloOrigen =
        vidaJugador >= 85 &&
        pistasUsadas <= 2 &&
        fragmentosDesbloqueados.length == fragmentos.length;
  }

  String _mensajeVictoria() {
    if (protocoloOrigen) {
      xp += 5000;
      return 'PROTOCOLO ORIGEN DESBLOQUEADO\n\n'
          'Has derrotado al Núcleo Cero con integridad casi perfecta.\n'
          '+5000 XP\n'
          '+5 tiradas legendarias';
    }

    return 'Núcleo Cero neutralizado.\n'
        'Has demostrado que entiendes la cadena completa del ataque.';
  }
}
