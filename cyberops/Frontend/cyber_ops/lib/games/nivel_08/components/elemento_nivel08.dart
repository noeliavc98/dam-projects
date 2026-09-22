//  SQL INJECTION (Lab Interactivo)

///  FRACTURA. Cada estado mapea a una imagen concreta
library;


enum EstadoFractura {
  neutral,
  pensando,
  atenta,
  aprobando,
  alerta,
  triunfal;

  String get assetPath => 'assets/images/nivel_08/fractura_$name.png';
}

/// Categoría de cada pieza del arsenal. Identifica QUÉ HACE la pieza
/// dentro del ataque, no su sintaxis SQL.
enum CategoriaPieza {
  /// Rompe la cadena de entrada para que SQL la interprete como código.
  escape,

  /// Inyecta una condición siempre verdadera para forzar autenticación.
  bypass,

  /// Extrae datos de otras tablas mediante UNION.
  extraer,

  /// Anula el resto de la consulta para que el AND password se ignore.
  silencio,

  /// Pieza distractora útil pero no esencial
  senuelo,

  /// Pieza destructiva: si la incluyes en el payload, pierdes vida.
  trampa,
}

/// Una pieza concreta del arsenal del jugador.
class PiezaSql {
  /// Identificador único (para detectar duplicados).
  final String id;

  /// El texto SQL que representa la pieza.
  final String token;

  /// Categoría que determina su color y comportamiento.
  final CategoriaPieza categoria;

  const PiezaSql({
    required this.id,
    required this.token,
    required this.categoria,
  });
}

class Lab {
  /// Número del lab (1, 2, 3).
  final int numero;

  /// Título  "BYPASS DE LOGIN", "EXTRACCIÓN"
  final String titulo;

  /// Misión que se muestra al jugador en el panel ámbar.
  final String mision;

  /// Nombre del servidor víctima
  final String victimaUrl;

  /// Snippet de código vulnerable. Cada elemento es una línea.

  final List<String> codigoLineas;

  /// Índice (base 0) de la línea que tiene la grieta.
  final int lineaVulnerable;

  /// Texto del aviso debajo del código (
  final String avisoCodigo;

  /// Piezas disponibles en el arsenal de este lab.
  final List<PiezaSql> arsenal;

  /// Categorías que el payload DEBE incluir para considerarse exitoso.
  final List<CategoriaPieza> categoriasNecesarias;

  /// Plantilla SQL con un placeholder {payload} que se sustituye.

  final String queryPlantilla;

  /// Texto que el servidor devuelve cuando el bypass funciona.
  final String mensajeExito;

  const Lab({
    required this.numero,
    required this.titulo,
    required this.mision,
    required this.victimaUrl,
    required this.codigoLineas,
    required this.lineaVulnerable,
    required this.avisoCodigo,
    required this.arsenal,
    required this.categoriasNecesarias,
    required this.queryPlantilla,
    required this.mensajeExito,
  });
}

class MomentoFractura {
  final String texto;
  final EstadoFractura estado;

  const MomentoFractura({required this.texto, required this.estado});
}

/// Resultado de ejecutar un payload contra el servidor simulado.
enum TipoResultado {
  /// El payload era válido  bypass / extracción / etc. conseguido.
  exito,

  /// Tenía una pieza trampa: pierdes vida y FRACTURA te avisa.
  trampaEjecutada,

  /// El payload era válido sintácticamente pero no completo.
  payloadIncompleto,

  /// Payload vacío.
  payloadVacio,
}

class ResultadoEjecucion {
  /// Texto SQL final que se construyó.
  final String sqlGenerado;

  /// Texto que muestra la "consola" del servidor.
  final String respuestaServidor;

  /// Tipo de resultado.
  final TipoResultado tipo;

  /// Si se debe descontar una vida.
  final bool perdioVida;

  ResultadoEjecucion({
    required this.sqlGenerado,
    required this.respuestaServidor,
    required this.tipo,
    required this.perdioVida,
  });
}
