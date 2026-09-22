import 'data/privilege_data.dart';
import 'components/privilege_file.dart';
import 'components/privilege_binary.dart';
import 'components/privilege_cronjob.dart';
 
/// Estados de acceso — representan los nodos del árbol de privilegios
enum AccessLevel { guest, user, admin, root }
 
/// Fases del nivel
enum Fase24 { files, suid, cronjob, completed, failed }
 
class Nivel24Game {
  // ── CONSTANTES ────────────────────────────────────────────────────────────
  static const int maxIntentosPorFase = 2;
  static const int xpPorFaseCorrecta = 400;
  static const int xpPenalizacion = 100;
  static const int xpBonus = 200; // bonus si se completa sin fallos
  static const int cronjobDuracionSegundos = 45;
 
  // ── ESTADO GENERAL ────────────────────────────────────────────────────────
  int xp = 0;
  AccessLevel nivelAcceso = AccessLevel.guest;
  Fase24 faseActual = Fase24.files;
  bool completed = false;
  bool failed = false;
  String mensajeSistema = PrivilegeData.mensajeInicial;
 
  // ── FASE 1 — Archivos ─────────────────────────────────────────────────────
  int intentosFase1 = 0;
  bool fase1Completada = false;
  final Set<String> archivosSeleccionados = {};
 
  // ── FASE 2 — SUID ─────────────────────────────────────────────────────────
  int intentosFase2 = 0;
  bool fase2Completada = false;
  String? binarioSeleccionado;
 
  // ── FASE 3 — Cronjob ──────────────────────────────────────────────────────
  int intentosFase3 = 0;
  bool fase3Completada = false;
  String? comandoInyectado;
  int segundosRestantes = cronjobDuracionSegundos;
  bool cronjobActivo = false;
  double _timerAcumulado = 0;
  void Function()? onCronjobTick; // callback para refrescar UI
 
  // ── DATOS ─────────────────────────────────────────────────────────────────
  List<PrivilegeFile> get archivos => PrivilegeData.archivos;
  List<PrivilegeBinary> get binarios => PrivilegeData.binarios;
  List<PrivilegeCronjob> get cronjobs => PrivilegeData.cronjobs;
  List<String> get comandosDisponibles => PrivilegeData.comandosDisponibles;
 
  // ── HELPERS ───────────────────────────────────────────────────────────────
 
  bool get fase2Desbloqueada => fase1Completada;
  bool get fase3Desbloqueada => fase2Completada;
 
  int get fallosTotales =>
      intentosFase1 + intentosFase2 + intentosFase3;
 
  String get rangoFinal {
    if (fallosTotales == 0) return 'ROOT SILENCIOSO';
    if (fallosTotales <= 2) return 'ESCALADOR HÁBIL';
    return 'ACCESO FORZADO';
  }
 
  // ── FASE 1 — Lógica de archivos ───────────────────────────────────────────
 
  void toggleArchivo(String id) {
    if (fase1Completada || failed) return;
    if (archivosSeleccionados.contains(id)) {
      archivosSeleccionados.remove(id);
    } else {
      archivosSeleccionados.add(id);
    }
  }
 
  /// Devuelve mensaje de resultado
  String confirmarArchivos() {
    if (fase1Completada || failed) return mensajeSistema;
 
    final correctos = archivos
        .where((f) => f.tieneCredenciales)
        .map((f) => f.id)
        .toSet();
    final falsos = archivos
        .where((f) => !f.tieneCredenciales)
        .map((f) => f.id)
        .toSet();
 
    final aciertos = archivosSeleccionados.intersection(correctos);
    final falsosPositivos = archivosSeleccionados.intersection(falsos);
    final faltantes = correctos.length - aciertos.length;
 
    if (aciertos.length == correctos.length && falsosPositivos.isEmpty) {
      fase1Completada = true;
      nivelAcceso = AccessLevel.user;
      faseActual = Fase24.suid;
      xp += xpPorFaseCorrecta;
      mensajeSistema =
          '[✓] Credenciales encontradas. Acceso elevado a USER. Busca binarios con permisos SUID mal configurados.';
      return mensajeSistema;
    }
 
    intentosFase1++;
    xp = (xp - xpPenalizacion).clamp(0, 99999);
 
    if (intentosFase1 >= maxIntentosPorFase) {
      failed = true;
      faseActual = Fase24.failed;
      mensajeSistema =
          '[✗] Intentos agotados. El sistema ha registrado actividad sospechosa y bloqueado tu cuenta.';
      return mensajeSistema;
    }
 
    final restantes = maxIntentosPorFase - intentosFase1;
    mensajeSistema =
        '[!] Selección incorrecta: $faltantes archivo(s) con credenciales sin marcar, ${falsosPositivos.length} falso(s) positivo(s). Intentos restantes: $restantes.';
    return mensajeSistema;
  }
 
  // ── FASE 2 — Lógica SUID ─────────────────────────────────────────────────
 
  void seleccionarBinario(String id) {
    if (fase2Completada || failed || !fase2Desbloqueada) return;
    binarioSeleccionado = id;
  }
 
  String confirmarBinario() {
    if (!fase2Desbloqueada || fase2Completada || failed) return mensajeSistema;
    if (binarioSeleccionado == null) {
      return '[!] Selecciona un binario antes de confirmar.';
    }
 
    final correcto = binarios.firstWhere((b) => b.esSuidVulnerable);
 
    if (binarioSeleccionado == correcto.id) {
      fase2Completada = true;
      nivelAcceso = AccessLevel.admin;
      faseActual = Fase24.cronjob;
      xp += xpPorFaseCorrecta;
      cronjobActivo = true;
      mensajeSistema =
          '[✓] Binario SUID explotado. Privilegios elevados a ADMIN. Tienes ${cronjobDuracionSegundos}s para inyectar un comando en el cronjob de root antes de que se ejecute.';
      return mensajeSistema;
    }
 
    intentosFase2++;
    xp = (xp - xpPenalizacion).clamp(0, 99999);
 
    if (intentosFase2 >= maxIntentosPorFase) {
      failed = true;
      faseActual = Fase24.failed;
      mensajeSistema =
          '[✗] Binario incorrecto. El sistema de auditoría ha detectado el intento y bloqueado el acceso.';
      return mensajeSistema;
    }
 
    final restantes = maxIntentosPorFase - intentosFase2;
    mensajeSistema =
        '[!] Ese binario no tiene permisos SUID vulnerables. Analiza los flags con más cuidado. Intentos restantes: $restantes.';
    return mensajeSistema;
  }
 
  // ── FASE 3 — Lógica Cronjob ───────────────────────────────────────────────
 
  void seleccionarComando(String comando) {
    if (fase3Completada || failed || !fase3Desbloqueada) return;
    comandoInyectado = comando;
  }
 
  String confirmarComando() {
    if (!fase3Desbloqueada || fase3Completada || failed) return mensajeSistema;
    if (comandoInyectado == null) {
      return '[!] Selecciona un comando para inyectar.';
    }
 
    if (comandoInyectado == PrivilegeData.comandoCorrecto) {
      _completarNivel();
      return mensajeSistema;
    }
 
    intentosFase3++;
    xp = (xp - xpPenalizacion).clamp(0, 99999);
 
    if (intentosFase3 >= maxIntentosPorFase) {
      failed = true;
      cronjobActivo = false;
      faseActual = Fase24.failed;
      mensajeSistema =
          '[✗] Comando incorrecto. El cronjob ejecutó un payload inválido y el administrador fue alertado.';
      return mensajeSistema;
    }
 
    final restantes = maxIntentosPorFase - intentosFase3;
    mensajeSistema =
        '[!] Ese comando no escala privilegios correctamente. Piensa en qué necesita ejecutar root para darte acceso. Intentos restantes: $restantes.';
    return mensajeSistema;
  }
 
  void _completarNivel() {
    fase3Completada = true;
    completed = true;
    cronjobActivo = false;
    faseActual = Fase24.completed;
    nivelAcceso = AccessLevel.root;
    xp += xpPorFaseCorrecta;
    if (fallosTotales == 0) xp += xpBonus;
    mensajeSistema =
        '[✓] Comando inyectado. El cronjob se ejecutó como root. Acceso total al sistema conseguido.';
  }
 
  // ── TIMER del cronjob ─────────────────────────────────────────────────────
 
  /// Llamar desde el widget en cada frame (o con un Timer.periodic)
  void tickCronjob(double dt) {
    if (!cronjobActivo || fase3Completada || failed) return;
 
    _timerAcumulado += dt;
    if (_timerAcumulado >= 1.0) {
      _timerAcumulado = 0;
      segundosRestantes--;
      onCronjobTick?.call();
 
      if (segundosRestantes <= 0) {
        cronjobActivo = false;
        failed = true;
        faseActual = Fase24.failed;
        mensajeSistema =
            '[✗] Tiempo agotado. El cronjob se ejecutó sin tu payload. Acceso denegado.';
        onCronjobTick?.call();
      }
    }
  }
}
 