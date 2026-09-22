enum DdosType {
  legitimo,
  synFlood,
  udpFlood,
  httpFlood,
  dnsAmplification,
  botnet,
}

extension DdosTypeLabel on DdosType {
  String get label {
    switch (this) {
      case DdosType.legitimo:
        return 'LEGÍTIMO';
      case DdosType.synFlood:
        return 'SYN FLOOD';
      case DdosType.udpFlood:
        return 'UDP FLOOD';
      case DdosType.httpFlood:
        return 'HTTP FLOOD';
      case DdosType.dnsAmplification:
        return 'DNS AMPLIFICATION';
      case DdosType.botnet:
        return 'BOTNET';
    }
  }
}

class DdosScenario {
  final String titulo;
  final String protocolo;
  final String captura;
  final String nota;
  final DdosType tipoCorrecto;
  final String explicacion;

  const DdosScenario({
    required this.titulo,
    required this.protocolo,
    required this.captura,
    required this.nota,
    required this.tipoCorrecto,
    required this.explicacion,
  });
}

class DdosMitigationScenario {
  final String titulo;
  final String descripcion;
  final List<String> opciones;
  final String opcionCorrecta;
  final String explicacion;

  const DdosMitigationScenario({
    required this.titulo,
    required this.descripcion,
    required this.opciones,
    required this.opcionCorrecta,
    required this.explicacion,
  });
}
