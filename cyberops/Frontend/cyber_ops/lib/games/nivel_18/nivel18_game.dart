import 'dart:math';

import 'package:cyber_ops/games/nivel_18/components/linea_terminal.dart';

import 'components/archivo_terminal.dart';
import 'components/comando_terminal.dart';
import 'components/resultado_terminal.dart';
import 'data/cifrado_data.dart';

enum FaseCifrado {
  reconocimiento,
  investigacion,
  preparacion,
  descifrado,
  proteccion,
  finalizado,
}

extension FaseCifradoLabel on FaseCifrado {
  String get label {
    switch (this) {
      case FaseCifrado.reconocimiento:
        return 'RECONOCIMIENTO';
      case FaseCifrado.investigacion:
        return 'INVESTIGACIÓN';
      case FaseCifrado.preparacion:
        return 'PREPARACIÓN';
      case FaseCifrado.descifrado:
        return 'DESCIFRADO';
      case FaseCifrado.proteccion:
        return 'PROTECCIÓN';
      case FaseCifrado.finalizado:
        return 'FINALIZADO';
    }
  }
}

class Nivel18Game {
  int vidas = 3;
  int xp = 0;
  FaseCifrado faseActual = FaseCifrado.reconocimiento;

  bool vaultInspeccionado = false;
  bool scriptLeido = false;
  bool hashInspeccionado = false;
  bool base64Inspeccionado = false;

  bool jackpotReclamado = false;

  bool claveCargada = false;
  bool ivCargado = false;
  bool vaultDescifrado = false;
  bool completado = false;
  bool fallido = false;

  bool archivoOcultoDescubierto = false;
  bool jackpotDesbloqueado = false;
  int tiradasJackpot = 0;
  int xpJackpot = 0;
  bool devVaultLeido = false;
  final Set<String> recompensasCobradas = {};

  final List<LineaTerminal> historial = [
    const LineaTerminal(
      texto: 'Sistema BLACK VAULT inicializado.',
      tipo: TipoLineaTerminal.sistema,
    ),
    const LineaTerminal(
      texto: 'Escribe help para ver comandos disponibles.',
      tipo: TipoLineaTerminal.normal,
    ),
  ];
  List<ArchivoTerminal> get archivos => CifradoData.archivos;
  List<ComandoTerminal> get comandosSugeridos {
    bool incluir(String texto) {
      if (['help', 'ls', 'inspect vault.enc', 'status'].contains(texto)) {
        return true;
      }

      if (vaultInspeccionado &&
          [
            'cat notas.txt',
            'cat script.sh',
            'inspect hash_admin.sha256',
            'inspect base64.txt',
            'decode base64.txt',
            'verify hash_admin.sha256',
            'hint',
          ].contains(texto)) {
        return true;
      }

      if (scriptLeido && ['load backup.key', 'load iv.txt'].contains(texto)) {
        return true;
      }

      if (claveCargada && ivCargado && texto == 'decrypt vault.enc') {
        return true;
      }

      if (archivoOcultoDescubierto &&
          ['cat .dev_vault', 'unlock jackpot'].contains(texto)) {
        return true;
      }

      if (jackpotDesbloqueado && tiradasJackpot > 0 && texto == 'spin') {
        return true;
      }

      return false;
    }

    return CifradoData.comandosSugeridos
        .where((comando) => incluir(comando.texto))
        .toList();
  }

  List<String> get dialogosIntro => CifradoData.dialogosIntro;
  List<String> get dialogosFinales => CifradoData.dialogosFinales;

  ArchivoTerminal? buscarArchivo(String nombre, {bool incluirOcultos = false}) {
    try {
      return archivos.firstWhere(
        (archivo) =>
            archivo.nombre == nombre &&
            (incluirOcultos || !archivo.oculto || archivoOcultoDescubierto),
      );
    } catch (_) {
      return null;
    }
  }

  ResultadoTerminal ejecutarComando(String entrada) {
    final comando = entrada.trim();

    if (comando.isEmpty) {
      return const ResultadoTerminal(salida: '');
    }

    historial.add(
      LineaTerminal(texto: '> $comando', tipo: TipoLineaTerminal.comando),
    );

    switch (comando) {
      case 'help':
        return _ok(
          'Comandos disponibles:\n'
          'help\n'
          'ls\n'
          'ls -a\n'
          'cat <archivo>\n'
          'inspect <archivo>\n'
          'load <archivo>\n'
          'decrypt <archivo>\n'
          'status\n'
          'unlock jackpot\n'
          'spin'
          'decode <archivo>\n'
          'verify <archivo>\n'
          'hint\n',
        );

      case 'ls':
        return _ok(
          archivos
              .where((archivo) => !archivo.oculto)
              .map((archivo) => archivo.nombre)
              .join('\n'),
        );

      case 'ls -a':
        archivoOcultoDescubierto = true;
        return _ok(
          archivos.map((archivo) => archivo.nombre).join('\n'),
          xpGanada: 50,
        );

      case 'status':
        return _ok(
          'VIDAS: $vidas\n'
          'XP: $xp\n'
          'CLAVE AES: ${claveCargada ? "CARGADA" : "NO CARGADA"}\n'
          'IV: ${ivCargado ? "CARGADO" : "NO CARGADO"}\n'
          'VAULT: ${vaultDescifrado ? "DESCIFRADO" : "BLOQUEADO"}\n'
          'JACKPOT: ${jackpotDesbloqueado ? "$tiradasJackpot tiradas" : "BLOQUEADO"}',
        );
    }

    if (comando.startsWith('cat ')) {
      return _cat(comando.replaceFirst('cat ', '').trim());
    }

    if (comando.startsWith('inspect ')) {
      return _inspect(comando.replaceFirst('inspect ', '').trim());
    }

    if (comando.startsWith('load ')) {
      return _load(comando.replaceFirst('load ', '').trim());
    }

    if (comando.startsWith('decrypt ')) {
      return _decrypt(comando.replaceFirst('decrypt ', '').trim());
    }
    if (comando.startsWith('decode ')) {
      return _decode(comando.replaceFirst('decode ', '').trim());
    }

    if (comando.startsWith('verify ')) {
      return _verify(comando.replaceFirst('verify ', '').trim());
    }

    if (comando == 'hint') {
      return _hint();
    }

    if (comando == 'unlock jackpot') {
      return _unlockJackpot();
    }

    if (comando == 'spin') {
      return _spinJackpot();
    }

    return _error('Comando no reconocido. Escribe help.', pierdeVida: false);
  }

  ResultadoTerminal _cat(String nombre) {
    final archivo = buscarArchivo(
      nombre,
      incluirOcultos: archivoOcultoDescubierto,
    );

    if (archivo == null) {
      return _error('Archivo no encontrado: $nombre');
    }

    if (archivo.nombre == '.dev_vault') {
      devVaultLeido = true;

      return _ok(
        archivo.contenido,
        easterEgg: true,
        idRecompensa: 'cat_dev_vault',
        xpGanada: 100,
      );
    }

    if (archivo.nombre == 'script.sh') {
      scriptLeido = true;
      faseActual = FaseCifrado.preparacion;
    }

    return _ok(
      archivo.contenido,
      idRecompensa: 'cat_${archivo.nombre}',
      xpGanada: 20,
    );
  }

  ResultadoTerminal _inspect(String nombre) {
    final archivo = buscarArchivo(
      nombre,
      incluirOcultos: archivoOcultoDescubierto,
    );

    if (archivo == null) {
      return _error('No se puede inspeccionar. Archivo no encontrado.');
    }

    if (archivo.nombre == 'vault.enc') {
      vaultInspeccionado = true;
      faseActual = FaseCifrado.investigacion;
      return _ok(
        'INSPECCIÓN DE vault.enc\n\n'
        'Algoritmo probable: AES-256-CBC\n'
        'Requisitos: clave simétrica + IV\n'
        'Estado: esperando material criptográfico.',
        idRecompensa: 'inspect_vault',
        xpGanada: 80,
      );
    }

    if (archivo.nombre == 'hash_admin.sha256') {
      return _ok(
        'INSPECCIÓN DE hash_admin.sha256\n\n'
        'Tipo detectado: HASH SHA-256\n'
        'Resultado: no reversible.\n'
        'Un hash verifica. No descifra.',
        idRecompensa: 'inspect_hash',
        xpGanada: 80,
      );
    }

    if (archivo.nombre == 'base64.txt') {
      return _ok(
        'INSPECCIÓN DE base64.txt\n\n'
        'Tipo detectado: codificación Base64.\n'
        'No proporciona confidencialidad.\n'
        'Codificar no es cifrar.',
        idRecompensa: 'inspect_base64',
        xpGanada: 80,
      );
    }

    return _ok('INSPECCIÓN\n\n${archivo.descripcion}', xpGanada: 30);
  }

  ResultadoTerminal _load(String nombre) {
    if (nombre == 'backup.key') {
      claveCargada = true;

      if (ivCargado) {
        faseActual = FaseCifrado.descifrado;
      }

      return _ok('Clave AES cargada correctamente.', xpGanada: 100);
    }

    if (nombre == 'iv.txt') {
      ivCargado = true;

      if (claveCargada) {
        faseActual = FaseCifrado.descifrado;
      }

      return _ok('IV cargado correctamente.', xpGanada: 100);
    }

    if (nombre == 'hash_admin.sha256') {
      return _falloDidactico(
        'No puedes cargar un hash como clave.\n'
        'SHA-256 no sirve para descifrar.',
      );
    }

    if (nombre == 'base64.txt') {
      return _falloDidactico(
        'Base64 no es una clave criptográfica.\n'
        'Es una forma de representar datos.',
      );
    }

    return _falloDidactico('Ese archivo no sirve como material de descifrado.');
  }

  ResultadoTerminal _decrypt(String nombre) {
    if (nombre == 'hash_admin.sha256') {
      return _falloDidactico(
        'ERROR: un hash no se descifra.\n'
        'No hay camino de vuelta desde SHA-256.',
      );
    }

    if (nombre == 'base64.txt') {
      return _falloDidactico(
        'ERROR: Base64 no es cifrado.\n'
        'Puedes decodificarlo, pero no protege secretos.',
      );
    }

    if (nombre != 'vault.enc') {
      return _falloDidactico('Ese archivo no es el vault cifrado.');
    }

    if (!claveCargada && !ivCargado) {
      return _falloDidactico(
        'ERROR: faltan clave AES e IV.\n'
        'AES-CBC no puede descifrar sin ambos.',
      );
    }

    if (!claveCargada) {
      return _falloDidactico('ERROR: falta clave AES.');
    }

    if (!ivCargado) {
      return _falloDidactico('ERROR: falta IV.');
    }

    vaultDescifrado = true;
    completado = true;

    return _ok(
      'DESCIFRADO COMPLETADO\n\n'
      'vault.enc → vault.txt\n\n'
      'Contenido recuperado:\n'
      '"La clave nunca fue el secreto. El secreto era dónde la escondieron."',
      correcto: true,
      nivelCompletado: true,
      xpGanada: 500,
    );
  }

  ResultadoTerminal _decode(String nombre) {
    if (nombre != 'base64.txt') {
      return _falloDidactico(
        'Solo hay una muestra compatible con decodificación Base64.',
      );
    }

    base64Inspeccionado = true;

    return _ok(
      'BASE64 DECODIFICADO\n\n'
      'Texto recuperado:\n'
      '"Vault de cifrado - no es encriptación."\n\n'
      'Lección: Base64 transforma la representación de los datos, '
      'pero no los protege. No es cifrado.',
      idRecompensa: 'decode_base64',
      xpGanada: 120,
    );
  }

  ResultadoTerminal _verify(String nombre) {
    if (nombre != 'hash_admin.sha256') {
      return _falloDidactico('Ese archivo no contiene una huella verificable.');
    }

    hashInspeccionado = true;

    return _ok(
      'VERIFICACIÓN SHA-256\n\n'
      'Hash leído correctamente.\n'
      'Integridad: comprobada.\n\n'
      'Lección: un hash sirve para verificar si algo cambió. '
      'No sirve para recuperar el contenido original.',
      idRecompensa: 'verify_hash',
      xpGanada: 120,
    );
  }

  ResultadoTerminal _hint() {
    String pista;

    switch (faseActual) {
      case FaseCifrado.reconocimiento:
        pista =
            'FRACTURA: Antes de abrir una puerta, averigua qué tipo de cerradura tienes. Prueba a inspeccionar el vault.';
        break;

      case FaseCifrado.investigacion:
        pista =
            'FRACTURA: Los administradores suelen dejar pistas en scripts, notas y registros. Lee antes de cargar nada.';
        break;

      case FaseCifrado.preparacion:
        pista =
            'FRACTURA: AES-CBC necesita dos piezas: una clave y un IV. Una sola no basta.';
        break;

      case FaseCifrado.descifrado:
        pista =
            'FRACTURA: Ya tienes el material. Ahora intenta descifrar el archivo principal.';
        break;

      case FaseCifrado.proteccion:
        pista =
            'FRACTURA: Recuperar información sensible no es el final. Ahora debes protegerla correctamente.';
        break;

      case FaseCifrado.finalizado:
        pista =
            'FRACTURA: La cámara ya está abierta. Lo importante es qué hiciste con lo encontrado.';
        break;
    }

    return _ok(pista, xpGanada: 0);
  }

ResultadoTerminal _unlockJackpot() {
  if (!archivoOcultoDescubierto) {
    return _error(
      'Acceso denegado.\n'
      'No existe ninguna sala jackpot visible.',
    );
  }

  if (!devVaultLeido) {
    return _error(
      'Acceso denegado.\n'
      'Primero debes leer el archivo secreto.',
    );
  }

  if (jackpotReclamado) {
    return _error(
      'La sala jackpot ya fue desbloqueada.\n'
      'No puedes reclamar tiradas iniciales otra vez.',
    );
  }

  jackpotReclamado = true;
  jackpotDesbloqueado = true;
  tiradasJackpot += 3;

  return _ok(
    'SALA JACKPOT DESBLOQUEADA\n\n'
    'Has encontrado el mensaje secreto del equipo.\n'
    '+3 tiradas disponibles.\n\n'
    'Usa: spin',
    easterEgg: true,
    idRecompensa: 'unlock_jackpot',
    xpGanada: 150,
  );
}

  ResultadoTerminal _spinJackpot() {
    if (!jackpotDesbloqueado || tiradasJackpot <= 0) {
      return _error('No tienes tiradas disponibles.');
    }

    tiradasJackpot--;

    final premios = [50, 75, 100, 150, 250, 500];
    final premio = premios[Random().nextInt(premios.length)];

    xpJackpot += premio;

    return _ok(
      'JACKPOT RUN\n\n'
      '[ ${_slot()} ] [ ${_slot()} ] [ ${_slot()} ]\n\n'
      '+$premio XP\n'
      'Tiradas restantes: $tiradasJackpot',
      easterEgg: true,
      xpGanada: premio,
    );
  }

  String _slot() {
    const icons = ['7', 'KEY', 'AES', 'IV', 'XP', 'DEV'];
    return icons[Random().nextInt(icons.length)];
  }

  ResultadoTerminal _ok(
    String salida, {
    bool correcto = false,
    bool nivelCompletado = false,
    bool easterEgg = false,
    int xpGanada = 0,
    String? idRecompensa,
  }) {
    int xpFinal = xpGanada;

    if (idRecompensa != null) {
      if (recompensasCobradas.contains(idRecompensa)) {
        xpFinal = 0;
      } else {
        recompensasCobradas.add(idRecompensa);
      }
    }

    xp += xpFinal;

    historial.add(
      LineaTerminal(
        texto: salida,
        tipo: easterEgg
            ? TipoLineaTerminal.easterEgg
            : xpFinal >= 200
            ? TipoLineaTerminal.jackpot
            : TipoLineaTerminal.correcto,
      ),
    );

    return ResultadoTerminal(
      salida: salida,
      correcto: correcto,
      nivelCompletado: nivelCompletado,
      easterEgg: easterEgg,
      xpGanada: xpFinal,
    );
  }

  ResultadoTerminal _error(String salida, {bool pierdeVida = false}) {
    historial.add(LineaTerminal(texto: salida, tipo: TipoLineaTerminal.error));

    return ResultadoTerminal(salida: salida, pierdeVida: pierdeVida);
  }

  ResultadoTerminal _falloDidactico(String salida) {
    vidas--;

    if (vidas <= 0) {
      vidas = 0;
      fallido = true;
    }

    historial.add(LineaTerminal(texto: salida, tipo: TipoLineaTerminal.error));

    return ResultadoTerminal(salida: salida, pierdeVida: true);
  }
}
