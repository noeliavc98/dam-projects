import 'package:flutter/material.dart';

import '../components/privilege_file.dart';
import '../components/privilege_binary.dart';
import '../components/privilege_cronjob.dart';
 
class PrivilegeData {
  // ── MENSAJE INICIAL ───────────────────────────────────────────────────────
  static const String mensajeInicial =
      'Conectado como GUEST. Explora el sistema de archivos y localiza credenciales expuestas para elevar tu acceso.';
 
  // ── FASE 1 — Archivos ─────────────────────────────────────────────────────
  static const List<PrivilegeFile> archivos = [
    PrivilegeFile(
      id: 'readme',
      nombre: 'README.txt',
      ruta: '/home/guest/README.txt',
      descripcion: 'Documento de bienvenida del sistema.',
      contenidoSimulado: 'Bienvenido al servidor de MegaCorp.\nPara soporte contacta con it@megacorp.internal.',
      tieneCredenciales: false,
      icono: Icons.description_rounded,
    ),
    PrivilegeFile(
      id: 'bashrc',
      nombre: '.bashrc',
      ruta: '/home/guest/.bashrc',
      descripcion: 'Configuración del shell de usuario.',
      contenidoSimulado: 'export PATH=\$PATH:/usr/local/bin\nalias ll="ls -la"',
      tieneCredenciales: false,
      icono: Icons.settings_rounded,
    ),
    PrivilegeFile(
      id: 'backup_config',
      nombre: 'backup.conf',
      ruta: '/opt/scripts/backup.conf',
      descripcion: 'Archivo de configuración del servicio de backup.',
      contenidoSimulado: '# Backup config\nDB_HOST=localhost\nDB_USER=admin\nDB_PASS=Adm1n\$ecure2024\nDB_NAME=megacorp_db',
      tieneCredenciales: true,
      icono: Icons.key_rounded,
    ),
    PrivilegeFile(
      id: 'logs',
      nombre: 'access.log',
      ruta: '/var/log/nginx/access.log',
      descripcion: 'Registro de accesos HTTP del servidor web.',
      contenidoSimulado: '192.168.1.10 - - [01/Jun/2024] "GET /index.html HTTP/1.1" 200\n192.168.1.22 - - [01/Jun/2024] "POST /login HTTP/1.1" 401',
      tieneCredenciales: false,
      icono: Icons.list_alt_rounded,
    ),
    PrivilegeFile(
      id: 'deploy_sh',
      nombre: 'deploy.sh',
      ruta: '/opt/scripts/deploy.sh',
      descripcion: 'Script de despliegue automático de la aplicación.',
      contenidoSimulado: '#!/bin/bash\n# Deploy script\necho "Deploying..."\ngit pull origin main\nnpm install && npm run build',
      tieneCredenciales: false,
      icono: Icons.terminal_rounded,
    ),
    PrivilegeFile(
      id: 'env_file',
      nombre: '.env',
      ruta: '/var/www/app/.env',
      descripcion: 'Variables de entorno de la aplicación web.',
      contenidoSimulado: 'APP_ENV=production\nSECRET_KEY=\nDB_CONNECTION=mysql\nSYSTEM_USER=sysadmin\nSYSTEM_PASS=sysAdm1n!corp',
      tieneCredenciales: true,
      icono: Icons.password_rounded,
    ),
    PrivilegeFile(
      id: 'crontab_log',
      nombre: 'cron.log',
      ruta: '/var/log/cron.log',
      descripcion: 'Log de ejecuciones del servicio cron.',
      contenidoSimulado: 'Jun 1 02:00:01 CRON[1234]: (root) CMD (/opt/maintenance/cleanup.sh)\nJun 1 03:00:01 CRON[1235]: (root) CMD (/opt/maintenance/cleanup.sh)',
      tieneCredenciales: false,
      icono: Icons.event_note_rounded,
    ),
  ];
 
  // ── FASE 2 — Binarios SUID ────────────────────────────────────────────────
  static const List<PrivilegeBinary> binarios = [
    PrivilegeBinary(
      id: 'passwd',
      nombre: '/usr/bin/passwd',
      permisos: '-rwsr-xr-x',
      propietario: 'root',
      descripcion: 'Utilidad para cambiar contraseñas. SUID necesario por diseño del sistema.',
      esSuidVulnerable: false,
    ),
    PrivilegeBinary(
      id: 'ping',
      nombre: '/usr/bin/ping',
      permisos: '-rwsr-xr-x',
      propietario: 'root',
      descripcion: 'Herramienta de diagnóstico de red. SUID estándar en la mayoría de sistemas.',
      esSuidVulnerable: false,
    ),
    PrivilegeBinary(
      id: 'find',
      nombre: '/usr/bin/find',
      permisos: '-rwsr-xr-x',
      propietario: 'root',
      descripcion: 'Comando de búsqueda de archivos con SUID activado. Permite ejecutar comandos arbitrarios como root usando -exec.',
      esSuidVulnerable: true,
    ),
    PrivilegeBinary(
      id: 'ls',
      nombre: '/usr/bin/ls',
      permisos: '-rwxr-xr-x',
      propietario: 'root',
      descripcion: 'Listado de directorios. Sin bit SUID, se ejecuta con los privilegios del usuario actual.',
      esSuidVulnerable: false,
    ),
    PrivilegeBinary(
      id: 'python3',
      nombre: '/usr/bin/python3',
      permisos: '-rwxr-xr-x',
      propietario: 'root',
      descripcion: 'Intérprete Python. Sin SUID activo en este sistema.',
      esSuidVulnerable: false,
    ),
    PrivilegeBinary(
      id: 'vim',
      nombre: '/usr/bin/vim',
      permisos: '-rwxr-xr-x',
      propietario: 'root',
      descripcion: 'Editor de texto. Sin bit SUID. No permite escalada de privilegios directamente.',
      esSuidVulnerable: false,
    ),
  ];
 
  // ── FASE 3 — Cronjobs ─────────────────────────────────────────────────────
  static const List<PrivilegeCronjob> cronjobs = [
    PrivilegeCronjob(
      id: 'backup',
      schedule: '0 2 * * *',
      usuario: 'backup',
      rutaScript: '/opt/backup/run.sh',
      descripcion: 'Ejecuta el backup diario. Pertenece al usuario backup, no root.',
      esVulnerable: false,
    ),
    PrivilegeCronjob(
      id: 'cleanup',
      schedule: '*/1 * * * *',
      usuario: 'root',
      rutaScript: '/opt/maintenance/cleanup.sh',
      descripcion: 'Limpieza de temporales cada minuto. Ejecutado por root. La carpeta /opt/maintenance/ tiene permisos de escritura para todos los usuarios.',
      esVulnerable: true,
    ),
    PrivilegeCronjob(
      id: 'monitor',
      schedule: '*/5 * * * *',
      usuario: 'www-data',
      rutaScript: '/var/www/monitor.sh',
      descripcion: 'Monitor de salud de la aplicación web. Usuario www-data, sin privilegios elevados.',
      esVulnerable: false,
    ),
  ];
 
  // ── FASE 3 — Comandos disponibles para inyectar ───────────────────────────
  static const List<String> comandosDisponibles = [
    'cp /bin/bash /tmp/rootbash && chmod +s /tmp/rootbash',
    'echo "guest ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers',
    'rm -rf /tmp/*',
    'cat /etc/passwd > /tmp/out.txt',
    'chmod 777 /etc/shadow',
  ];
 
  /// El único comando correcto para completar la fase
  static const String comandoCorrecto =
      'cp /bin/bash /tmp/rootbash && chmod +s /tmp/rootbash';
}