import 'components/backdoor_action.dart';
import 'components/backdoor_evidence.dart';
import 'data/backdoor_data.dart';

class Nivel14Game {
  static const int maxAnalysisAttempts = 2;
  static const int maxVerificationAttempts = 2;

  int xp = 0;
  int integrity = 100;
  int analysisAttempts = 0;
  int verificationAttempts = 0;

  bool analysisDone = false;
  bool containmentUnlocked = false;
  bool completed = false;
  bool failed = false;

  final Set<String> selectedEvidenceIds = {};
  final Set<String> selectedActionIds = {};

  List<BackdoorEvidence> get evidences => BackdoorData.evidences;
  List<BackdoorAction> get actions => BackdoorData.actions;

  List<BackdoorEvidence> get selectedEvidences {
    return evidences
        .where((evidence) => selectedEvidenceIds.contains(evidence.id))
        .toList();
  }

  List<BackdoorAction> get selectedActions {
    return actions
        .where((action) => selectedActionIds.contains(action.id))
        .toList();
  }

  Set<String> get requiredEvidenceIds {
    return evidences
        .where((evidence) => evidence.isBackdoorSignal)
        .map((evidence) => evidence.id)
        .toSet();
  }

  Set<String> get falseEvidenceIds {
    return evidences
        .where((evidence) => !evidence.isBackdoorSignal)
        .map((evidence) => evidence.id)
        .toSet();
  }

  Set<String> get requiredActionIds {
    return actions
        .where((action) => action.isRequired)
        .map((action) => action.id)
        .toSet();
  }

  Set<String> get dangerousActionIds {
    return actions
        .where((action) => action.isDangerous)
        .map((action) => action.id)
        .toSet();
  }

  void toggleEvidence(BackdoorEvidence evidence) {
    if (analysisDone || completed || failed) return;

    if (selectedEvidenceIds.contains(evidence.id)) {
      selectedEvidenceIds.remove(evidence.id);
    } else {
      selectedEvidenceIds.add(evidence.id);
    }
  }

  String analyzeBackdoor() {
    if (completed || failed) return 'La misión ya ha terminado.';
    if (analysisDone) return 'La backdoor ya ha sido identificada.';

    final selectedRequired = selectedEvidenceIds.intersection(
      requiredEvidenceIds,
    );
    final selectedFalse = selectedEvidenceIds.intersection(falseEvidenceIds);

    final missingCount = requiredEvidenceIds.length - selectedRequired.length;
    final falseCount = selectedFalse.length;

    if (missingCount == 0 && falseCount == 0) {
      analysisDone = true;
      containmentUnlocked = true;
      xp += 500;

      return 'Backdoor identificada: acceso remoto, cuenta oculta, binario camuflado, canal de mando y persistencia al reinicio.';
    }

    analysisAttempts++;
    integrity -= (missingCount * 14) + (falseCount * 10);
    if (analysisAttempts >= maxAnalysisAttempts) {
      integrity = 0;
      failed = true;
      return 'Se agotaron los intentos de análisis. El atacante usó la demora para recuperar acceso.';
    }

    if (integrity <= 0) {
      integrity = 0;
      failed = true;
      return 'Integridad agotada. El atacante ha recuperado acceso.';
    }

    final attemptsLeft = maxAnalysisAttempts - analysisAttempts;
    return 'Análisis incompleto: faltan $missingCount evidencias reales y hay $falseCount falsos positivos. Intentos de análisis restantes: $attemptsLeft.';
  }

  void toggleAction(BackdoorAction action) {
    if (!containmentUnlocked || completed || failed) return;

    if (selectedActionIds.contains(action.id)) {
      selectedActionIds.remove(action.id);
    } else {
      selectedActionIds.add(action.id);
    }
  }

  String verifySystem() {
    if (!containmentUnlocked) {
      return 'Primero debes identificar la backdoor.';
    }

    if (completed || failed) return 'La misión ya ha terminado.';

    final selectedRequired = selectedActionIds.intersection(requiredActionIds);
    final selectedDangerous = selectedActionIds.intersection(
      dangerousActionIds,
    );

    final missingCount = requiredActionIds.length - selectedRequired.length;
    final dangerousCount = selectedDangerous.length;

    if (missingCount == 0 && dangerousCount == 0) {
      completed = true;
      xp += 500;

      return 'Backdoor neutralizada. El acceso remoto, la persistencia, el binario y las credenciales han sido corregidos.';
    }

    verificationAttempts++;
    integrity -= (missingCount * 18) + (dangerousCount * 24);
    if (verificationAttempts >= maxVerificationAttempts) {
      integrity = 0;
      failed = true;
      return 'Se agotaron los intentos de verificación. La respuesta dejó una vía activa.';
    }

    if (integrity <= 0) {
      integrity = 0;
      failed = true;
      return 'Reconexión detectada. La respuesta fue incompleta o dañó el sistema.';
    }

    final attemptsLeft = maxVerificationAttempts - verificationAttempts;
    return 'Respuesta incompleta: quedan $missingCount acciones clave sin aplicar y $dangerousCount acciones peligrosas seleccionadas. Verificaciones restantes: $attemptsLeft.';
  }
}
