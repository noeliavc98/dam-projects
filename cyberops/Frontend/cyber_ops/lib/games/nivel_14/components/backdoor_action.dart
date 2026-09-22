enum BackdoorActionType {
  contain,
  remove,
  recover,
  verify,
}

class BackdoorAction {
  final String id;
  final BackdoorActionType type;
  final String title;
  final String description;
  final bool isRequired;
  final bool isDangerous;
  final String feedback;

  const BackdoorAction({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.isRequired,
    required this.isDangerous,
    required this.feedback,
  });
}

extension BackdoorActionTypeLabel on BackdoorActionType {
  String get label {
    switch (this) {
      case BackdoorActionType.contain:
        return 'CONTENCIÓN';
      case BackdoorActionType.remove:
        return 'ELIMINACIÓN';
      case BackdoorActionType.recover:
        return 'RECUPERACIÓN';
      case BackdoorActionType.verify:
        return 'VERIFICACIÓN';
    }
  }
}