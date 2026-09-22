enum HostStatus { healthy, suspicious, encrypting, isolated, cleaned, restored }

enum Nivel11Mode { defense, attacker }

enum Nivel11Action {
  inspectProcesses,
  reviewLogs,
  isolateHost,
  blockHash,
  cutSegment,
  verifyBackup,
  cleanHost,
  restoreBackup,
  notifySoc,
}

enum Nivel11AttackAction {
  phishing,
  reconNetwork,
  smbJump,
  enumeratePermissions,
  searchBackup,
  prepareEncryption,
  executeEncryption,
  hideTrace,
}

enum Nivel11Phase {
  attacker,
  incident,
  attackerReport,
  report,
  victory,
  defeat,
}

class HostNode {
  HostNode({
    required this.id,
    required this.name,
    required this.role,
    required this.segment,
    required this.x,
    required this.y,
    required this.neighbors,
    required this.clues,
    this.status = HostStatus.healthy,
    this.encryptedFiles = 0,
    this.processesChecked = false,
    this.logsChecked = false,
    this.wasCompromised = false,
  });

  final String id;
  final String name;
  final String role;
  final String segment;
  final double x;
  final double y;
  final List<String> neighbors;
  final List<String> clues;

  HostStatus status;
  int encryptedFiles;
  bool processesChecked;
  bool logsChecked;
  bool isolated = false;
  bool backupChecked = false;
  bool wasCompromised;

  bool get isCompromised =>
      status == HostStatus.suspicious ||
      status == HostStatus.encrypting ||
      status == HostStatus.isolated;

  bool get canSpread =>
      status == HostStatus.encrypting &&
      !isolated &&
      status != HostStatus.cleaned;

  int get riskScore {
    switch (status) {
      case HostStatus.healthy:
        return 0;
      case HostStatus.restored:
        return 0;
      case HostStatus.cleaned:
        return 1;
      case HostStatus.suspicious:
        return 2;
      case HostStatus.isolated:
        return 2;
      case HostStatus.encrypting:
        return 4;
    }
  }
}

class IncidentEvent {
  const IncidentEvent({
    required this.minute,
    required this.severity,
    required this.message,
  });

  final int minute;
  final String severity;
  final String message;
}

class ActionResult {
  const ActionResult({
    required this.positive,
    required this.title,
    required this.explanation,
    required this.lesson,
    this.points = 0,
  });

  final bool positive;
  final String title;
  final String explanation;
  final String lesson;
  final int points;
}

class PreventionMeasure {
  const PreventionMeasure({
    required this.id,
    required this.title,
    required this.detail,
    required this.correct,
    required this.feedback,
  });

  final String id;
  final String title;
  final String detail;
  final bool correct;
  final String feedback;
}

class Nivel11Game {
  Nivel11Game() {
    _events.addAll(const <IncidentEvent>[
      IncidentEvent(
        minute: 0,
        severity: 'EDR',
        message: 'Escritura masiva detectada en RRHH-PC-04.',
      ),
      IncidentEvent(
        minute: 0,
        severity: 'MAIL',
        message: 'Adjunto factura_abril.docm abierto desde correo externo.',
      ),
      IncidentEvent(
        minute: 1,
        severity: 'FILE',
        message: 'Extensiones .locked creadas en Documentos compartidos.',
      ),
    ]);
  }

  final Map<String, HostNode> _hosts = <String, HostNode>{
    'rrhh': HostNode(
      id: 'rrhh',
      name: 'RRHH-PC-04',
      role: 'Equipo de usuario',
      segment: 'Usuarios',
      x: .18,
      y: .28,
      neighbors: <String>['files', 'dc'],
      status: HostStatus.encrypting,
      encryptedFiles: 142,
      wasCompromised: true,
      clues: <String>[
        'winword.exe abrio factura_abril.docm',
        'svhost32.exe escribe archivos .locked',
        'CPU alta y muchas escrituras por segundo',
      ],
    ),
    'files': HostNode(
      id: 'files',
      name: 'FILE-SRV-01',
      role: 'Servidor de ficheros',
      segment: 'Core',
      x: .48,
      y: .32,
      neighbors: <String>['rrhh', 'finance', 'backup'],
      status: HostStatus.suspicious,
      encryptedFiles: 18,
      wasCompromised: true,
      clues: <String>[
        'Conexion SMB entrante desde RRHH-PC-04',
        'Permisos compartidos usados fuera de horario',
        'Primeros archivos bloqueados en carpeta publica',
      ],
    ),
    'finance': HostNode(
      id: 'finance',
      name: 'FIN-ERP-02',
      role: 'ERP financiero',
      segment: 'Finanzas',
      x: .76,
      y: .22,
      neighbors: <String>['files', 'dc'],
      clues: <String>[
        'Sin cifrado activo',
        'Sesion administrativa abierta',
        'Alto impacto si queda comprometido',
      ],
    ),
    'dc': HostNode(
      id: 'dc',
      name: 'DC-AUTH-01',
      role: 'Controlador de dominio',
      segment: 'Identidad',
      x: .48,
      y: .64,
      neighbors: <String>['rrhh', 'finance', 'director'],
      clues: <String>[
        'Autenticaciones normales',
        'Credenciales compartidas detectadas en endpoint',
        'Debe protegerse antes de movimiento lateral',
      ],
    ),
    'backup': HostNode(
      id: 'backup',
      name: 'BACKUP-OFFLINE',
      role: 'Copia de seguridad',
      segment: 'Recuperacion',
      x: .20,
      y: .74,
      neighbors: <String>['files'],
      clues: <String>[
        'Ultimo snapshot: 03:00',
        'Repositorio offline disponible',
        'Restaurar antes de limpiar puede reintroducir malware',
      ],
    ),
    'director': HostNode(
      id: 'director',
      name: 'CEO-LAPTOP',
      role: 'Direccion',
      segment: 'VIP',
      x: .78,
      y: .72,
      neighbors: <String>['dc'],
      clues: <String>[
        'Equipo aun sano',
        'Objetivo de alto valor',
        'MFA activo en la cuenta principal',
      ],
    ),
  };

  final List<IncidentEvent> _events = <IncidentEvent>[];
  final Set<String> selectedPreventions = <String>{};
  final Set<String> selectedAttackerLessons = <String>{};

  Nivel11Mode mode = Nivel11Mode.defense;
  Nivel11Phase phase = Nivel11Phase.incident;
  int minute = 2;
  int points = 0;
  int lives = 4;
  int attackerDetection = 0;
  bool malwareHashKnown = false;
  bool hashBlocked = false;
  bool segmentCut = false;
  bool backupVerified = false;
  bool socNotified = false;
  bool filesRestored = false;
  bool attackerInitialAccess = false;
  bool attackerReconDone = false;
  bool attackerSmbAccess = false;
  bool attackerPermissionsEnumerated = false;
  bool attackerBackupMapped = false;
  bool attackerEncryptionPrepared = false;
  bool attackerPayloadExecuted = false;
  bool attackerTraceHidden = false;
  ActionResult? lastResult;

  static const List<PreventionMeasure> preventionMeasures = <PreventionMeasure>[
    PreventionMeasure(
      id: 'backup',
      title: 'Backup offline probado',
      detail: 'Copias aisladas, verificadas y con restauracion ensayada.',
      correct: true,
      feedback:
          'Correcto: una copia offline evita que el ransomware cifre tambien la recuperacion.',
    ),
    PreventionMeasure(
      id: 'segmentacion',
      title: 'Segmentacion de red',
      detail: 'Separar usuarios, servidores, finanzas e identidad.',
      correct: true,
      feedback:
          'Correcto: la segmentacion reduce el movimiento lateral entre equipos.',
    ),
    PreventionMeasure(
      id: 'edr',
      title: 'EDR con bloqueo',
      detail: 'Deteccion de cifrado masivo y respuesta automatica.',
      correct: true,
      feedback:
          'Correcto: un EDR puede bloquear procesos antes de que cifren toda la red.',
    ),
    PreventionMeasure(
      id: 'mfa',
      title: 'MFA y minimo privilegio',
      detail: 'Reducir cuentas compartidas y accesos administrativos.',
      correct: true,
      feedback:
          'Correcto: menos privilegios limitan el impacto cuando cae un equipo.',
    ),
    PreventionMeasure(
      id: 'pagar',
      title: 'Pagar el rescate',
      detail: 'Enviar dinero para intentar recibir una clave.',
      correct: false,
      feedback:
          'No es una medida preventiva: no garantiza recuperacion y financia el ataque.',
    ),
    PreventionMeasure(
      id: 'restaurar_rapido',
      title: 'Restaurar sin limpiar',
      detail: 'Traer el backup cuanto antes, aunque haya malware activo.',
      correct: false,
      feedback:
          'Mala idea: restaurar antes de contener puede cifrar tambien los datos recuperados.',
    ),
  ];

  static const List<PreventionMeasure>
  attackerLessonMeasures = <PreventionMeasure>[
    PreventionMeasure(
      id: 'mfa',
      title: 'MFA y minimo privilegio',
      detail: 'Habria frenado el uso de credenciales reutilizadas.',
      correct: true,
      feedback:
          'Correcto: sin privilegios amplios, el atacante no escala con tanta facilidad.',
    ),
    PreventionMeasure(
      id: 'segmentacion',
      title: 'Segmentacion de red',
      detail: 'Habria bloqueado el salto desde RRHH hacia servidores criticos.',
      correct: true,
      feedback:
          'Correcto: segmentar limita el movimiento lateral aunque un endpoint caiga.',
    ),
    PreventionMeasure(
      id: 'edr',
      title: 'EDR con bloqueo',
      detail: 'Habria detectado escritura masiva y procesos anormales.',
      correct: true,
      feedback:
          'Correcto: el EDR convierte el ruido del atacante en una alerta accionable.',
    ),
    PreventionMeasure(
      id: 'backup',
      title: 'Backup offline verificado',
      detail: 'Habria reducido el impacto del cifrado sobre los datos.',
      correct: true,
      feedback:
          'Correcto: una copia aislada quita presion al rescate y acelera la recuperacion.',
    ),
    PreventionMeasure(
      id: 'cifrar_mas',
      title: 'Cifrar mas rapido',
      detail: 'Aumentar impacto sin corregir el fallo defensivo.',
      correct: false,
      feedback:
          'Incorrecto: no es un control defensivo; ademas genera mas ruido de deteccion.',
    ),
    PreventionMeasure(
      id: 'apagar_alertas',
      title: 'Apagar alertas',
      detail: 'Desactivar monitorizacion para que no moleste.',
      correct: false,
      feedback:
          'Incorrecto: quitar alertas favorece al atacante y empeora la respuesta.',
    ),
  ];

  List<HostNode> get hosts => _hosts.values.toList(growable: false);

  List<IncidentEvent> get events =>
      _events.reversed.take(12).toList(growable: false);

  bool get isAttackerMode => mode == Nivel11Mode.attacker;

  bool get isTimedPhase =>
      phase == Nivel11Phase.incident || phase == Nivel11Phase.attacker;

  List<PreventionMeasure> get reportMeasures =>
      isAttackerMode ? attackerLessonMeasures : preventionMeasures;

  Set<String> get selectedReportAnswers =>
      isAttackerMode ? selectedAttackerLessons : selectedPreventions;

  int get selectedReportCorrect {
    return selectedReportAnswers.where((String id) {
      return _measureFrom(reportMeasures, id).correct;
    }).length;
  }

  String get reportPrompt {
    if (isAttackerMode) {
      return 'Elige 3 controles que habrian cortado antes tu cadena de ataque.';
    }
    return 'Elige 3 medidas que reduzcan probabilidad o impacto del proximo ransomware.';
  }

  String get reportTrailing => '$selectedReportCorrect/3 medidas';

  int get activeThreats => hosts.where((HostNode host) {
    return host.status == HostStatus.encrypting ||
        host.status == HostStatus.suspicious;
  }).length;

  int get totalEncryptedFiles {
    return hosts.fold<int>(
      0,
      (int total, HostNode host) => total + host.encryptedFiles,
    );
  }

  double get containmentProgress {
    final int completed = <bool>[
      malwareHashKnown,
      _hosts['rrhh']!.isolated,
      hashBlocked,
      backupVerified,
      _allCompromisedCleaned,
      filesRestored,
    ].where((bool value) => value).length;

    return completed / 6;
  }

  double get attackerProgress {
    final int completed = <bool>[
      attackerInitialAccess,
      attackerReconDone,
      attackerSmbAccess,
      attackerPermissionsEnumerated,
      attackerEncryptionPrepared,
      attackerPayloadExecuted,
    ].where((bool value) => value).length;

    return completed / 6;
  }

  double get currentProgress =>
      isAttackerMode ? attackerProgress : containmentProgress;

  String get attackerStage {
    if (attackerPayloadExecuted) {
      return 'impacto';
    }
    if (attackerEncryptionPrepared) {
      return 'preparado';
    }
    if (attackerPermissionsEnumerated) {
      return 'permisos';
    }
    if (attackerSmbAccess) {
      return 'lateral';
    }
    if (attackerReconDone) {
      return 'recon';
    }
    if (attackerInitialAccess) {
      return 'acceso';
    }
    return 'inicial';
  }

  HostNode hostById(String id) {
    return _hosts[id]!;
  }

  void startAttackerMode() {
    mode = Nivel11Mode.attacker;
    phase = Nivel11Phase.attacker;
    minute = 0;
    points = 0;
    lives = 4;
    attackerDetection = 0;
    malwareHashKnown = false;
    hashBlocked = false;
    segmentCut = false;
    backupVerified = false;
    socNotified = false;
    filesRestored = false;
    attackerInitialAccess = false;
    attackerReconDone = false;
    attackerSmbAccess = false;
    attackerPermissionsEnumerated = false;
    attackerBackupMapped = false;
    attackerEncryptionPrepared = false;
    attackerPayloadExecuted = false;
    attackerTraceHidden = false;
    selectedPreventions.clear();
    selectedAttackerLessons.clear();
    lastResult = const ActionResult(
      positive: true,
      title: 'Perspectiva atacante',
      explanation:
          'Completa la cadena simulada antes de que la deteccion llegue al 100%.',
      lesson:
          'El objetivo es entender que controles defensivos cortan cada paso del ataque.',
    );

    for (final HostNode host in hosts) {
      host.status = HostStatus.healthy;
      host.encryptedFiles = 0;
      host.processesChecked = false;
      host.logsChecked = false;
      host.isolated = false;
      host.backupChecked = false;
      host.wasCompromised = false;
    }

    _events.clear();
    _addEvent(
      'OP',
      'Ventana atacante abierta: 64 segundos antes de deteccion completa.',
    );
  }

  ActionResult applyAction(Nivel11Action action, String selectedHostId) {
    if (phase != Nivel11Phase.incident) {
      return const ActionResult(
        positive: false,
        title: 'Incidente cerrado',
        explanation: 'Ahora toca completar el informe post-incidente.',
        lesson:
            'El trabajo no termina con contener: hay que aprender del ataque.',
      );
    }

    final HostNode host = _hosts[selectedHostId]!;
    late ActionResult result;

    switch (action) {
      case Nivel11Action.inspectProcesses:
        result = _inspectProcesses(host);
      case Nivel11Action.reviewLogs:
        result = _reviewLogs(host);
      case Nivel11Action.isolateHost:
        result = _isolateHost(host);
      case Nivel11Action.blockHash:
        result = _blockHash();
      case Nivel11Action.cutSegment:
        result = _cutSegment();
      case Nivel11Action.verifyBackup:
        result = _verifyBackup(host);
      case Nivel11Action.cleanHost:
        result = _cleanHost(host);
      case Nivel11Action.restoreBackup:
        result = _restoreBackup(host);
      case Nivel11Action.notifySoc:
        result = _notifySoc();
    }

    lastResult = result;
    points = (points + result.points).clamp(0, 9999).toInt();

    if (!result.positive) {
      lives--;
    }

    if (phase == Nivel11Phase.incident) {
      advanceTime();
    }

    _checkDefeat();
    return result;
  }

  ActionResult applyAttackAction(
    Nivel11AttackAction action,
    String selectedHostId,
  ) {
    if (phase != Nivel11Phase.attacker) {
      return const ActionResult(
        positive: false,
        title: 'Simulacion cerrada',
        explanation:
            'Ahora toca responder la pregunta final del modo atacante.',
        lesson:
            'La cadena de ataque termina en aprendizaje defensivo, no en mas impacto.',
      );
    }

    final HostNode host = _hosts[selectedHostId]!;
    late ActionResult result;

    switch (action) {
      case Nivel11AttackAction.phishing:
        result = _attackerPhishing(host);
      case Nivel11AttackAction.reconNetwork:
        result = _attackerRecon(host);
      case Nivel11AttackAction.smbJump:
        result = _attackerSmbJump(host);
      case Nivel11AttackAction.enumeratePermissions:
        result = _attackerEnumeratePermissions(host);
      case Nivel11AttackAction.searchBackup:
        result = _attackerSearchBackup(host);
      case Nivel11AttackAction.prepareEncryption:
        result = _attackerPrepareEncryption(host);
      case Nivel11AttackAction.executeEncryption:
        result = _attackerExecuteEncryption(host);
      case Nivel11AttackAction.hideTrace:
        result = _attackerHideTrace();
    }

    lastResult = result;
    points = (points + result.points).clamp(0, 9999).toInt();

    if (!result.positive) {
      lives--;
    }

    _checkAttackerDefeat();
    return result;
  }

  void advanceTime() {
    if (phase == Nivel11Phase.attacker) {
      minute++;
      _raiseDetection(13);
      _addAttackerTimeEvent();
      _checkAttackerDefeat();
      return;
    }

    if (phase != Nivel11Phase.incident) {
      return;
    }

    minute++;
    _growEncryption();
    _propagateThreat();
    _checkDefeat();
  }

  ActionResult submitReportAnswer(String id) {
    if (isAttackerMode) {
      return _submitAttackerLesson(id);
    }
    return submitPrevention(id);
  }

  ActionResult submitPrevention(String id) {
    final PreventionMeasure measure = preventionMeasures.firstWhere(
      (PreventionMeasure item) => item.id == id,
    );

    if (phase != Nivel11Phase.report || selectedPreventions.contains(id)) {
      return ActionResult(
        positive: measure.correct,
        title: measure.title,
        explanation: measure.feedback,
        lesson:
            'El informe solo acepta nuevas medidas hasta cerrar la leccion.',
      );
    }

    selectedPreventions.add(id);

    if (measure.correct) {
      points += 120;
      _addEvent('POST', 'Medida aceptada: ${measure.title}.');
      if (selectedPreventions
              .where((String itemId) => _measureById(itemId).correct)
              .length >=
          3) {
        phase = Nivel11Phase.victory;
        _addEvent('OK', 'Informe aprobado. Incidente cerrado.');
      }

      lastResult = ActionResult(
        positive: true,
        title: measure.title,
        explanation: measure.feedback,
        lesson:
            'Una buena recuperacion mezcla tecnologia, procesos y habitos de usuario.',
        points: 120,
      );
      return lastResult!;
    }

    lives--;
    _checkDefeat();
    lastResult = ActionResult(
      positive: false,
      title: measure.title,
      explanation: measure.feedback,
      lesson:
          'Una medida post-incidente debe reducir probabilidad o impacto del siguiente ataque.',
    );
    return lastResult!;
  }

  ActionResult _submitAttackerLesson(String id) {
    final PreventionMeasure measure = attackerLessonMeasures.firstWhere(
      (PreventionMeasure item) => item.id == id,
    );

    if (phase != Nivel11Phase.attackerReport ||
        selectedAttackerLessons.contains(id)) {
      return ActionResult(
        positive: measure.correct,
        title: measure.title,
        explanation: measure.feedback,
        lesson:
            'La pregunta atacante se centra en controles que rompen la cadena.',
      );
    }

    selectedAttackerLessons.add(id);

    if (measure.correct) {
      points += 120;
      _addEvent('POST', 'Control defensivo identificado: ${measure.title}.');
      if (selectedAttackerLessons
              .where(
                (String itemId) =>
                    _measureFrom(attackerLessonMeasures, itemId).correct,
              )
              .length >=
          3) {
        phase = Nivel11Phase.victory;
        _addEvent('OK', 'Analisis atacante aprobado.');
      }

      lastResult = ActionResult(
        positive: true,
        title: measure.title,
        explanation: measure.feedback,
        lesson:
            'Pensar como atacante ayuda a priorizar controles defensivos reales.',
        points: 120,
      );
      return lastResult!;
    }

    lives--;
    if (lives <= 0) {
      phase = Nivel11Phase.defeat;
    }
    lastResult = ActionResult(
      positive: false,
      title: measure.title,
      explanation: measure.feedback,
      lesson:
          'La respuesta correcta debe ser un control defensivo, no una accion ofensiva.',
    );
    return lastResult!;
  }

  ActionResult _attackerPhishing(HostNode host) {
    if (attackerInitialAccess) {
      return const ActionResult(
        positive: true,
        title: 'Acceso inicial ya conseguido',
        explanation: 'RRHH-PC-04 ya esta comprometido en la simulacion.',
        lesson:
            'Repetir el mismo vector aumenta ruido sin abrir una ruta nueva.',
      );
    }

    if (host.id != 'rrhh') {
      return _attackerMistake(
        title: 'Objetivo inicial incorrecto',
        explanation:
            'El correo falso estaba preparado para RRHH-PC-04, no para este nodo.',
        lesson:
            'El phishing depende del contexto: un mensaje generico falla antes.',
        noise: 16,
      );
    }

    attackerInitialAccess = true;
    host.status = HostStatus.suspicious;
    host.wasCompromised = true;
    host.processesChecked = true;
    _raiseDetection(4);
    _addEvent('PHISH', 'RRHH-PC-04 abre factura_abril.docm.');
    return const ActionResult(
      positive: true,
      title: 'Acceso inicial simulado',
      explanation:
          'Has conseguido una primera ejecucion controlada en RRHH-PC-04.',
      lesson:
          'El acceso inicial suele venir de un usuario, una credencial o un servicio expuesto.',
      points: 120,
    );
  }

  ActionResult _attackerRecon(HostNode host) {
    if (!attackerInitialAccess) {
      return _attackerMistake(
        title: 'Sin punto de apoyo',
        explanation: 'Primero necesitas comprometer RRHH-PC-04.',
        lesson:
            'El reconocimiento interno solo empieza cuando el atacante ya tiene una puerta.',
        noise: 12,
      );
    }

    if (attackerReconDone) {
      return const ActionResult(
        positive: true,
        title: 'Red ya reconocida',
        explanation:
            'Ya sabes que RRHH-PC-04 habla con FILE-SRV-01 y DC-AUTH-01.',
        lesson: 'El valor esta en avanzar sin generar mas ruido innecesario.',
      );
    }

    if (host.id != 'rrhh') {
      return _attackerMistake(
        title: 'Reconocimiento mal situado',
        explanation:
            'Haz el reconocimiento desde RRHH-PC-04, tu unico punto de apoyo.',
        lesson:
            'Saltar entre nodos sin contexto dispara senales de comportamiento anomalo.',
        noise: 14,
      );
    }

    attackerReconDone = true;
    host.logsChecked = true;
    _hosts['files']!.logsChecked = true;
    _raiseDetection(4);
    _addEvent('RECON', 'Rutas SMB hacia FILE-SRV-01 identificadas.');
    return const ActionResult(
      positive: true,
      title: 'Reconocimiento interno',
      explanation:
          'Has visto conexiones SMB hacia el servidor de ficheros y activos criticos cerca.',
      lesson:
          'La segmentacion de red limita justo este paso: saber que existe un servidor no deberia bastar para alcanzarlo.',
      points: 110,
    );
  }

  ActionResult _attackerSmbJump(HostNode host) {
    if (!attackerReconDone) {
      return _attackerMistake(
        title: 'Ruta lateral desconocida',
        explanation: 'Primero reconoce la red desde RRHH-PC-04.',
        lesson: 'Moverse sin mapa aumenta deteccion y reduce precision.',
        noise: 12,
      );
    }

    if (attackerSmbAccess) {
      return const ActionResult(
        positive: true,
        title: 'Salto SMB ya hecho',
        explanation: 'FILE-SRV-01 ya esta dentro de la cadena simulada.',
        lesson: 'Tras el salto lateral, el siguiente paso es revisar permisos.',
      );
    }

    if (host.id == 'dc') {
      return _attackerMistake(
        title: 'Activo demasiado vigilado',
        explanation:
            'Atacar directamente DC-AUTH-01 dispara alertas de identidad.',
        lesson:
            'Los activos criticos deben tener mas telemetria, MFA y minimo privilegio.',
        noise: 24,
      );
    }

    if (host.id != 'files') {
      return _attackerMistake(
        title: 'Salto sin valor',
        explanation: 'La ruta util del escenario va hacia FILE-SRV-01.',
        lesson:
            'El movimiento lateral efectivo busca sistemas con datos o permisos compartidos.',
        noise: 16,
      );
    }

    attackerSmbAccess = true;
    host.status = HostStatus.suspicious;
    host.wasCompromised = true;
    host.logsChecked = true;
    _raiseDetection(6);
    _addEvent('SMB', 'Movimiento lateral simulado hacia FILE-SRV-01.');
    return const ActionResult(
      positive: true,
      title: 'Salto lateral por SMB',
      explanation:
          'Has llegado al servidor de ficheros usando la relacion con RRHH-PC-04.',
      lesson:
          'La segmentacion y el minimo privilegio cortan este tipo de salto.',
      points: 140,
    );
  }

  ActionResult _attackerEnumeratePermissions(HostNode host) {
    if (!attackerSmbAccess) {
      return _attackerMistake(
        title: 'Sin acceso al servidor',
        explanation: 'Primero salta hacia FILE-SRV-01.',
        lesson:
            'No se pueden enumerar permisos internos sin acceso al recurso.',
        noise: 12,
      );
    }

    if (attackerPermissionsEnumerated) {
      return const ActionResult(
        positive: true,
        title: 'Permisos ya enumerados',
        explanation: 'Ya sabes que hay carpetas compartidas con impacto alto.',
        lesson:
            'Repetir enumeracion solo deja mas huella en logs y telemetria.',
      );
    }

    if (host.id != 'files') {
      return _attackerMistake(
        title: 'Nodo poco util',
        explanation:
            'Enumera permisos en FILE-SRV-01, donde estan los recursos compartidos.',
        lesson:
            'El atacante prioriza sistemas donde los permisos multiplican el impacto.',
        noise: 14,
      );
    }

    attackerPermissionsEnumerated = true;
    host.processesChecked = true;
    _raiseDetection(4);
    _addEvent('PERM', 'Carpetas compartidas de alto impacto localizadas.');
    return const ActionResult(
      positive: true,
      title: 'Permisos enumerados',
      explanation:
          'Has identificado recursos compartidos que amplifican el impacto del cifrado.',
      lesson:
          'Revisar permisos y quitar accesos amplios reduce el radio de explosion.',
      points: 120,
    );
  }

  ActionResult _attackerSearchBackup(HostNode host) {
    if (!attackerReconDone) {
      return _attackerMistake(
        title: 'Backup fuera de mapa',
        explanation:
            'Primero reconoce la red para saber donde esta la recuperacion.',
        lesson:
            'Los backups bien aislados no deberian quedar visibles desde usuarios.',
        noise: 12,
      );
    }

    if (attackerBackupMapped) {
      return const ActionResult(
        positive: true,
        title: 'Backup ya revisado',
        explanation:
            'BACKUP-OFFLINE esta aislado y no aporta una ruta de impacto.',
        lesson:
            'Un backup offline convierte el ransomware en un incidente recuperable.',
      );
    }

    if (host.id != 'backup') {
      return _attackerMistake(
        title: 'Consola equivocada',
        explanation: 'Selecciona BACKUP-OFFLINE para comprobar la defensa.',
        lesson:
            'Tocar sistemas al azar aumenta ruido sin mejorar la cadena de ataque.',
        noise: 12,
      );
    }

    attackerBackupMapped = true;
    host.backupChecked = true;
    _raiseDetection(3);
    _addEvent('BACKUP', 'BACKUP-OFFLINE aparece aislado de la cadena.');
    return const ActionResult(
      positive: true,
      title: 'Backup aislado localizado',
      explanation:
          'Has comprobado que la copia offline no se puede tocar desde la ruta actual.',
      lesson:
          'La recuperacion offline reduce el poder de presion del atacante.',
      points: 80,
    );
  }

  ActionResult _attackerPrepareEncryption(HostNode host) {
    if (!attackerPermissionsEnumerated) {
      return _attackerMistake(
        title: 'Impacto sin preparar',
        explanation:
            'Antes de preparar cifrado debes enumerar permisos en FILE-SRV-01.',
        lesson:
            'Sin inventario de permisos, el ataque hace ruido y consigue poco impacto.',
        noise: 16,
      );
    }

    if (attackerEncryptionPrepared) {
      return const ActionResult(
        positive: true,
        title: 'Cifrado ya preparado',
        explanation: 'Los objetivos de impacto ya estan marcados.',
        lesson:
            'El siguiente paso es ejecutar o asumir que el SOC te alcanzara.',
      );
    }

    if (host.id != 'files') {
      return _attackerMistake(
        title: 'Objetivo de impacto incorrecto',
        explanation:
            'Prepara el impacto sobre FILE-SRV-01, el servidor con datos compartidos.',
        lesson:
            'Los servidores de ficheros suelen concentrar impacto y telemetria.',
        noise: 14,
      );
    }

    attackerEncryptionPrepared = true;
    host.encryptedFiles = 18;
    _raiseDetection(5);
    _addEvent('STAGE', 'Objetivos de cifrado simulados en FILE-SRV-01.');
    return const ActionResult(
      positive: true,
      title: 'Impacto preparado',
      explanation:
          'Has marcado carpetas compartidas y dejado lista la simulacion de cifrado.',
      lesson:
          'El EDR busca justo esta fase: muchas escrituras y preparacion anomala.',
      points: 130,
    );
  }

  ActionResult _attackerExecuteEncryption(HostNode host) {
    if (!attackerEncryptionPrepared) {
      return _attackerMistake(
        title: 'Cifrado prematuro',
        explanation:
            'Ejecutar sin preparar objetivos produce poco impacto y mucha deteccion.',
        lesson:
            'Un EDR con bloqueo convierte el cifrado masivo en una senal inmediata.',
        noise: 20,
      );
    }

    if (host.id != 'files') {
      return _attackerMistake(
        title: 'Impacto mal dirigido',
        explanation: 'El objetivo final de este escenario es FILE-SRV-01.',
        lesson:
            'Atacar nodos de bajo valor consume tiempo y sube la deteccion.',
        noise: 16,
      );
    }

    attackerPayloadExecuted = true;
    _hosts['rrhh']!
      ..status = HostStatus.encrypting
      ..encryptedFiles = 142;
    host
      ..status = HostStatus.encrypting
      ..encryptedFiles = 360;
    _raiseDetection(10);
    phase = Nivel11Phase.attackerReport;
    _addEvent(
      'IMPACT',
      'Cifrado simulado ejecutado sobre recursos compartidos.',
    );
    return const ActionResult(
      positive: true,
      title: 'Impacto simulado conseguido',
      explanation:
          'Has completado la cadena atacante antes de la deteccion completa.',
      lesson:
          'Ahora toca demostrar que sabes que defensas habrian roto la cadena.',
      points: 240,
    );
  }

  ActionResult _attackerHideTrace() {
    if (!attackerInitialAccess) {
      return _attackerMistake(
        title: 'Nada que reducir',
        explanation: 'Sin acceso inicial no hay ruido operativo que gestionar.',
        lesson:
            'Las acciones de evasion tambien generan huella cuando se hacen sin contexto.',
        noise: 10,
      );
    }

    if (attackerTraceHidden) {
      return const ActionResult(
        positive: true,
        title: 'Ruido ya reducido',
        explanation: 'Ya has bajado la exposicion una vez.',
        lesson:
            'La evasion repetida no sustituye una cadena de ataque bien priorizada.',
      );
    }

    attackerTraceHidden = true;
    attackerDetection = (attackerDetection - 16).clamp(0, 100).toInt();
    _addEvent('STEALTH', 'Ruido operativo reducido temporalmente.');
    return const ActionResult(
      positive: true,
      title: 'Ruido reducido',
      explanation:
          'Has bajado la deteccion, pero no has avanzado en la cadena principal.',
      lesson:
          'El SOC gana si el atacante pierde tiempo gestionando su propia exposicion.',
      points: 40,
    );
  }

  ActionResult _attackerMistake({
    required String title,
    required String explanation,
    required String lesson,
    required int noise,
  }) {
    _raiseDetection(noise);
    _addEvent('DETECT', '$title: deteccion +$noise.');
    return ActionResult(
      positive: false,
      title: title,
      explanation: explanation,
      lesson: lesson,
    );
  }

  ActionResult _inspectProcesses(HostNode host) {
    if (host.processesChecked) {
      return ActionResult(
        positive: true,
        title: 'Procesos ya revisados',
        explanation:
            'Ya habias analizado los procesos de ${host.name}. No hay puntos extra por repetir la misma revision.',
        lesson:
            'En una crisis real tambien se evita duplicar trabajo: documenta y pasa al siguiente paso del playbook.',
      );
    }

    host.processesChecked = true;

    if (host.id == 'rrhh' || host.status == HostStatus.encrypting) {
      malwareHashKnown = true;
      _addEvent(
        'PROC',
        'Hash localizado: svhost32.exe / SHA256: 9f2a...locked.',
      );
      return const ActionResult(
        positive: true,
        title: 'Proceso malicioso identificado',
        explanation:
            'Has encontrado svhost32.exe escribiendo cientos de archivos .locked.',
        lesson:
            'Mirar procesos permite encontrar el binario y bloquear su hash en toda la red.',
        points: 140,
      );
    }

    if (host.status == HostStatus.suspicious) {
      _addEvent('PROC', '${host.name}: proceso remoto sospechoso detectado.');
      return const ActionResult(
        positive: true,
        title: 'Actividad sospechosa confirmada',
        explanation:
            'No hay cifrado masivo aun, pero hay ejecucion remota anomala.',
        lesson:
            'Un equipo sospechoso debe tratarse rapido antes de convertirse en foco activo.',
        points: 90,
      );
    }

    return const ActionResult(
      positive: true,
      title: 'Sin proceso malicioso',
      explanation: 'No aparecen procesos de cifrado en este equipo.',
      lesson:
          'Descartar nodos sanos tambien ayuda a priorizar durante una crisis.',
      points: 30,
    );
  }

  ActionResult _reviewLogs(HostNode host) {
    if (host.logsChecked) {
      return ActionResult(
        positive: true,
        title: 'Logs ya revisados',
        explanation:
            'Ya habias revisado los logs de ${host.name}. Esta accion no vuelve a sumar puntos.',
        lesson:
            'Repetir una comprobacion puede confirmar datos, pero no sustituye avanzar en la contencion.',
      );
    }

    host.logsChecked = true;

    if (host.id == 'files' || host.status == HostStatus.suspicious) {
      _addEvent('LOG', '${host.name}: conexiones SMB desde RRHH-PC-04.');
      return const ActionResult(
        positive: true,
        title: 'Movimiento lateral detectado',
        explanation:
            'Los logs muestran acceso SMB desde el paciente cero hacia recursos compartidos.',
        lesson:
            'Los logs cuentan la ruta del atacante: origen, destino y metodo de propagacion.',
        points: 110,
      );
    }

    if (host.id == 'dc') {
      _addEvent('LOG', 'DC-AUTH-01: credenciales compartidas en riesgo.');
      return const ActionResult(
        positive: true,
        title: 'Identidad bajo observacion',
        explanation:
            'El dominio no esta cifrado, pero hay credenciales reutilizadas en endpoints.',
        lesson:
            'Proteger identidad evita que un ransomware se convierta en compromiso total.',
        points: 80,
      );
    }

    return const ActionResult(
      positive: true,
      title: 'Logs sin anomalias graves',
      explanation: 'No se ven conexiones laterales recientes desde este nodo.',
      lesson:
          'La ausencia de indicadores en logs ayuda a no sobreactuar sobre equipos sanos.',
      points: 30,
    );
  }

  ActionResult _isolateHost(HostNode host) {
    if (host.isolated) {
      return ActionResult(
        positive: true,
        title: 'Equipo ya aislado',
        explanation:
            '${host.name} ya estaba fuera de la red. Mantiene la contencion, pero no da puntos extra.',
        lesson:
            'Aislar dos veces no contiene mas: ahora toca identificar indicadores, limpiar o recuperar.',
      );
    }

    if (host.isCompromised || host.id == 'rrhh') {
      host.isolated = true;
      if (host.status == HostStatus.encrypting ||
          host.status == HostStatus.suspicious) {
        host.status = HostStatus.isolated;
      }
      _addEvent('NET', '${host.name} aislado de la red.');
      return ActionResult(
        positive: true,
        title: 'Equipo aislado',
        explanation:
            '${host.name} ya no puede propagar cifrado por recursos compartidos.',
        lesson:
            'Aislar corta la propagacion lateral, pero no recupera archivos ya cifrados.',
        points: host.id == 'rrhh' ? 160 : 100,
      );
    }

    _addEvent('WARN', '${host.name} aislado sin evidencia suficiente.');
    return ActionResult(
      positive: false,
      title: 'Falso positivo operativo',
      explanation:
          '${host.name} parecia sano. Aislarlo genera impacto sin contener el foco real.',
      lesson:
          'En respuesta a incidentes se actua rapido, pero cada accion debe apoyarse en evidencia.',
    );
  }

  ActionResult _blockHash() {
    if (!malwareHashKnown) {
      _addEvent('WARN', 'Bloqueo de hash rechazado: no hay IOC confirmado.');
      return const ActionResult(
        positive: false,
        title: 'Hash desconocido',
        explanation: 'Aun no has identificado el binario malicioso.',
        lesson:
            'Primero analiza procesos del paciente cero para convertir una sospecha en IOC.',
      );
    }

    if (hashBlocked) {
      return const ActionResult(
        positive: true,
        title: 'Hash ya bloqueado',
        explanation: 'El EDR ya esta bloqueando svhost32.exe en endpoints.',
        lesson:
            'Revisar el estado evita repetir acciones y perder tiempo de respuesta.',
      );
    }

    hashBlocked = true;
    for (final HostNode host in hosts) {
      if (host.status == HostStatus.suspicious) {
        host.status = HostStatus.cleaned;
      }
    }
    _addEvent('EDR', 'Hash svhost32.exe bloqueado globalmente.');
    return const ActionResult(
      positive: true,
      title: 'Hash bloqueado en EDR',
      explanation:
          'El binario ya no puede ejecutarse en equipos que aun no han sido cifrados.',
      lesson:
          'Bloquear indicadores confirmados reduce la ventana de propagacion.',
      points: 180,
    );
  }

  ActionResult _cutSegment() {
    if (segmentCut) {
      return const ActionResult(
        positive: true,
        title: 'Segmento ya cortado',
        explanation:
            'La comunicacion entre usuarios, core y finanzas sigue limitada.',
        lesson:
            'La segmentacion temporal compra tiempo mientras investigas y limpias.',
      );
    }

    segmentCut = true;
    _addEvent(
      'NET',
      'Segmentos Usuarios/Core/Finanzas separados temporalmente.',
    );
    return const ActionResult(
      positive: true,
      title: 'Segmento cortado',
      explanation:
          'Has reducido el alcance del ataque y protegido los activos de alto impacto.',
      lesson:
          'Cortar un segmento puede molestar al negocio, pero evita que el incidente se haga global.',
      points: 130,
    );
  }

  ActionResult _verifyBackup(HostNode host) {
    if (host.id != 'backup') {
      return const ActionResult(
        positive: false,
        title: 'Nodo incorrecto',
        explanation:
            'Selecciona BACKUP-OFFLINE para verificar la recuperacion.',
        lesson:
            'Antes de restaurar debes saber si la copia existe, esta limpia y es usable.',
      );
    }

    if (backupVerified) {
      return const ActionResult(
        positive: true,
        title: 'Backup ya verificado',
        explanation:
            'La copia offline de las 03:00 ya esta confirmada como limpia.',
        lesson:
            'Verificar dos veces no suma puntos; el siguiente paso es restaurar solo cuando no quede malware activo.',
      );
    }

    backupVerified = true;
    host.backupChecked = true;
    _addEvent('BACKUP', 'Snapshot offline de las 03:00 verificado.');
    return const ActionResult(
      positive: true,
      title: 'Backup limpio confirmado',
      explanation:
          'La copia esta aislada y es anterior al cifrado detectado en RRHH-PC-04.',
      lesson:
          'Un backup solo salva el incidente si esta separado, probado y fuera del alcance del malware.',
      points: 150,
    );
  }

  ActionResult _cleanHost(HostNode host) {
    if (host.status == HostStatus.cleaned ||
        host.status == HostStatus.restored) {
      return ActionResult(
        positive: true,
        title: 'Host ya limpiado',
        explanation:
            '${host.name} ya no tiene indicadores activos. Repetir la limpieza no suma puntos.',
        lesson:
            'Cuando un nodo esta limpio, el valor esta en pasar a recuperacion o comprobar otros sistemas.',
      );
    }

    if (!host.isCompromised && !host.wasCompromised) {
      return ActionResult(
        positive: true,
        title: 'Nada que limpiar',
        explanation: '${host.name} no presenta indicadores activos.',
        lesson:
            'Limpiar nodos sanos no suma, pero confirma que el foco esta delimitado.',
      );
    }

    if (!host.isolated && !hashBlocked) {
      return const ActionResult(
        positive: false,
        title: 'Limpieza insegura',
        explanation:
            'El host sigue conectado o el hash no esta bloqueado. Puede reinfectarse.',
        lesson:
            'Orden correcto: contener primero, erradicar despues, recuperar al final.',
      );
    }

    host.status = HostStatus.cleaned;
    host.isolated = true;
    _addEvent('CLEAN', '${host.name} limpiado y pendiente de restauracion.');
    return ActionResult(
      positive: true,
      title: 'Host limpiado',
      explanation: '${host.name} queda sin proceso activo de ransomware.',
      lesson:
          'Erradicar elimina el malware; recuperar datos requiere una copia limpia.',
      points: 140,
    );
  }

  ActionResult _restoreBackup(HostNode selectedHost) {
    final bool restoringFromBackupConsole = selectedHost.id == 'backup';
    final bool restoringAffectedHost =
        selectedHost.wasCompromised ||
        selectedHost.status == HostStatus.cleaned ||
        selectedHost.status == HostStatus.isolated;

    if (!restoringFromBackupConsole && !restoringAffectedHost) {
      return ActionResult(
        positive: true,
        title: 'Nada que restaurar',
        explanation:
            '${selectedHost.name} esta sano. Restaurar solo tiene sentido sobre el backup o sobre hosts afectados que ya han sido limpiados.',
        lesson:
            'La recuperacion no se aplica a sistemas sanos: primero identifica que se perdio y despues restaura solo lo necesario.',
      );
    }

    if (!backupVerified) {
      return const ActionResult(
        positive: false,
        title: 'Backup no verificado',
        explanation: 'Todavia no sabes si la copia esta limpia y disponible.',
        lesson:
            'Restaurar a ciegas puede traer datos corruptos o una copia ya comprometida.',
      );
    }

    if (filesRestored) {
      return const ActionResult(
        positive: true,
        title: 'Servicios ya restaurados',
        explanation:
            'Los hosts afectados ya fueron recuperados desde la copia offline.',
        lesson:
            'Repetir una restauracion no aporta valor: el siguiente paso es cerrar el informe post-incidente.',
      );
    }

    if (hosts.any((HostNode host) => host.status == HostStatus.encrypting)) {
      return const ActionResult(
        positive: false,
        title: 'Malware aun activo',
        explanation:
            'Hay equipos cifrando. Restaurar ahora haria que los datos vuelvan a caer.',
        lesson: 'Nunca restaures antes de contener y erradicar el foco activo.',
      );
    }

    if (!_allCompromisedCleaned) {
      return const ActionResult(
        positive: false,
        title: 'Faltan hosts por limpiar',
        explanation:
            'Aun quedan nodos sospechosos o aislados sin erradicacion completa.',
        lesson:
            'La recuperacion llega cuando los indicadores activos han desaparecido.',
      );
    }

    filesRestored = true;
    for (final HostNode host in hosts) {
      if (host.wasCompromised || host.status == HostStatus.cleaned) {
        host.status = HostStatus.restored;
        host.encryptedFiles = 0;
      }
    }
    phase = Nivel11Phase.report;
    _addEvent('RESTORE', 'Servicios restaurados desde backup offline.');
    return const ActionResult(
      positive: true,
      title: 'Servicios restaurados',
      explanation:
          'Has recuperado los datos tras contener, limpiar y verificar la copia.',
      lesson:
          'La recuperacion correcta sigue un orden: contener, erradicar, restaurar y aprender.',
      points: 240,
    );
  }

  ActionResult _notifySoc() {
    if (socNotified) {
      return const ActionResult(
        positive: true,
        title: 'SOC ya informado',
        explanation: 'El equipo de respuesta ya tiene el incidente abierto.',
        lesson: 'La coordinacion evita acciones duplicadas durante una crisis.',
      );
    }

    socNotified = true;
    _addEvent('SOC', 'Incidente escalado con severidad alta.');
    return const ActionResult(
      positive: true,
      title: 'SOC notificado',
      explanation:
          'Has creado un canal de respuesta para coordinar comunicaciones y evidencias.',
      lesson:
          'Documentar y escalar pronto mejora la respuesta tecnica y legal del incidente.',
      points: 70,
    );
  }

  void _growEncryption() {
    for (final HostNode host in hosts) {
      if (host.status == HostStatus.encrypting) {
        host.encryptedFiles += hashBlocked ? 8 : 34;
      }
    }
  }

  void _propagateThreat() {
    final HostNode rrhh = _hosts['rrhh']!;
    final HostNode files = _hosts['files']!;
    final HostNode finance = _hosts['finance']!;
    final HostNode backup = _hosts['backup']!;

    if (!hashBlocked &&
        rrhh.status == HostStatus.encrypting &&
        !rrhh.isolated) {
      files.status = HostStatus.encrypting;
      files.wasCompromised = true;
      _addEvent('ALERT', 'FILE-SRV-01 empieza a cifrar recursos compartidos.');
    }

    if (!hashBlocked &&
        !segmentCut &&
        files.status == HostStatus.encrypting &&
        minute >= 5 &&
        finance.status == HostStatus.healthy) {
      finance.status = HostStatus.suspicious;
      finance.wasCompromised = true;
      finance.encryptedFiles = 11;
      _addEvent('WARN', 'FIN-ERP-02 recibe ejecucion remota sospechosa.');
    }

    if (!hashBlocked &&
        !segmentCut &&
        files.status == HostStatus.encrypting &&
        minute >= 7 &&
        backup.status == HostStatus.healthy &&
        !backup.backupChecked) {
      backup.status = HostStatus.suspicious;
      backup.wasCompromised = true;
      _addEvent('WARN', 'BACKUP-OFFLINE expuesto por montaje temporal.');
    }

    if (finance.status == HostStatus.suspicious &&
        minute >= 8 &&
        !hashBlocked) {
      finance.status = HostStatus.encrypting;
      _addEvent('ALERT', 'FIN-ERP-02 empieza cifrado local.');
    }
  }

  bool get _allCompromisedCleaned {
    return hosts
        .where((HostNode host) => host.wasCompromised)
        .every(
          (HostNode host) =>
              host.status == HostStatus.cleaned ||
              host.status == HostStatus.restored,
        );
  }

  void _raiseDetection(int amount) {
    attackerDetection = (attackerDetection + amount).clamp(0, 100).toInt();
  }

  void _addAttackerTimeEvent() {
    if (attackerDetection >= 100) {
      _addEvent('DETECT', 'El SOC correlaciona la cadena completa.');
      return;
    }

    if (minute == 4 || minute == 6) {
      _addEvent(
        'SOC',
        'Telemetria acumulada: deteccion al $attackerDetection%.',
      );
    }
  }

  void _checkAttackerDefeat() {
    if (lives <= 0) {
      phase = Nivel11Phase.defeat;
      return;
    }

    if (phase == Nivel11Phase.attacker && attackerDetection >= 100) {
      phase = Nivel11Phase.defeat;
      _addEvent('FAIL', 'El SOC aisla la cadena antes del impacto.');
    }
  }

  void _checkDefeat() {
    if (lives <= 0) {
      phase = Nivel11Phase.defeat;
      return;
    }

    final int encrypting = hosts
        .where((HostNode host) => host.status == HostStatus.encrypting)
        .length;
    if (encrypting >= 4 || totalEncryptedFiles >= 900) {
      phase = Nivel11Phase.defeat;
      _addEvent('FAIL', 'La propagacion supera la capacidad de contencion.');
    }
  }

  void _addEvent(String severity, String message) {
    if (_events.isNotEmpty && _events.last.message == message) {
      return;
    }
    _events.add(
      IncidentEvent(minute: minute, severity: severity, message: message),
    );
  }

  PreventionMeasure _measureById(String id) {
    return preventionMeasures.firstWhere((PreventionMeasure item) {
      return item.id == id;
    });
  }

  PreventionMeasure _measureFrom(List<PreventionMeasure> measures, String id) {
    return measures.firstWhere((PreventionMeasure item) {
      return item.id == id;
    });
  }
}

extension HostStatusText on HostStatus {
  String get label {
    switch (this) {
      case HostStatus.healthy:
        return 'SANO';
      case HostStatus.suspicious:
        return 'SOSPECHOSO';
      case HostStatus.encrypting:
        return 'CIFRANDO';
      case HostStatus.isolated:
        return 'AISLADO';
      case HostStatus.cleaned:
        return 'LIMPIO';
      case HostStatus.restored:
        return 'RESTAURADO';
    }
  }
}

extension Nivel11ActionText on Nivel11Action {
  String get label {
    switch (this) {
      case Nivel11Action.inspectProcesses:
        return 'Procesos';
      case Nivel11Action.reviewLogs:
        return 'Logs';
      case Nivel11Action.isolateHost:
        return 'Aislar';
      case Nivel11Action.blockHash:
        return 'Bloquear hash';
      case Nivel11Action.cutSegment:
        return 'Cortar segmento';
      case Nivel11Action.verifyBackup:
        return 'Verificar backup';
      case Nivel11Action.cleanHost:
        return 'Limpiar';
      case Nivel11Action.restoreBackup:
        return 'Restaurar servicios';
      case Nivel11Action.notifySoc:
        return 'Notificar SOC';
    }
  }
}

extension Nivel11AttackActionText on Nivel11AttackAction {
  String get label {
    switch (this) {
      case Nivel11AttackAction.phishing:
        return 'Phishing';
      case Nivel11AttackAction.reconNetwork:
        return 'Reconocer red';
      case Nivel11AttackAction.smbJump:
        return 'Saltar por SMB';
      case Nivel11AttackAction.enumeratePermissions:
        return 'Enumerar permisos';
      case Nivel11AttackAction.searchBackup:
        return 'Buscar backup';
      case Nivel11AttackAction.prepareEncryption:
        return 'Preparar cifrado';
      case Nivel11AttackAction.executeEncryption:
        return 'Ejecutar cifrado';
      case Nivel11AttackAction.hideTrace:
        return 'Reducir ruido';
    }
  }
}
