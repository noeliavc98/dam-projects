enum BackdoorEvidenceCategory {
  logs,
  processes,
  users,
  network,
  persistence,
}

enum BackdoorEvidenceSeverity {
  low,
  medium,
  high,
  critical,
}

class BackdoorEvidence {
  final String id;
  final BackdoorEvidenceCategory category;
  final BackdoorEvidenceSeverity severity;
  final String title;
  final String subtitle;
  final String description;
  final bool isBackdoorSignal;
  final String explanation;

  const BackdoorEvidence({
    required this.id,
    required this.category,
    required this.severity,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isBackdoorSignal,
    required this.explanation,
  });
}

extension BackdoorEvidenceCategoryLabel on BackdoorEvidenceCategory {
  String get label {
    switch (this) {
      case BackdoorEvidenceCategory.logs:
        return 'LOGS';
      case BackdoorEvidenceCategory.processes:
        return 'PROCESOS';
      case BackdoorEvidenceCategory.users:
        return 'USUARIOS';
      case BackdoorEvidenceCategory.network:
        return 'RED';
      case BackdoorEvidenceCategory.persistence:
        return 'PERSISTENCIA';
    }
  }
}

extension BackdoorEvidenceSeverityLabel on BackdoorEvidenceSeverity {
  String get label {
    switch (this) {
      case BackdoorEvidenceSeverity.low:
        return 'BAJA';
      case BackdoorEvidenceSeverity.medium:
        return 'MEDIA';
      case BackdoorEvidenceSeverity.high:
        return 'ALTA';
      case BackdoorEvidenceSeverity.critical:
        return 'CRÍTICA';
    }
  }
}