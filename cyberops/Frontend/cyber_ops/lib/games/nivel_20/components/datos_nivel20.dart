import 'package:flutter/material.dart';
import 'sospechoso_nivel20.dart';
import 'evidencia_nivel20.dart';

class CasoZeroDay {
  final String sistema;
  final String descripcion;
  final List<EvidenciaZeroDay> evidencias;
  final String culpableId;
  const CasoZeroDay({
    required this.sistema,
    required this.descripcion,
    required this.evidencias,
    required this.culpableId,
  });
}

const sospechososZeroDay = <SospechosoZeroDay>[
  SospechosoZeroDay(id: 'phisher', nombre: 'EL PHISHER', rol: 'Roba credenciales por correo', imagen: 'assets/images/nivel_20/atacantes/phisher.png'),
  SospechosoZeroDay(id: 'ingeniero', nombre: 'EL INGENIERO', rol: 'Disfraza malware como software legitimo', imagen: 'assets/images/nivel_20/atacantes/ingeniero.png'),
  SospechosoZeroDay(id: 'interceptor', nombre: 'EL INTERCEPTOR', rol: 'Espia trafico de red', imagen: 'assets/images/nivel_20/atacantes/interceptor.png'),
  SospechosoZeroDay(id: 'distribuidor', nombre: 'EL DISTRIBUIDOR', rol: 'Reparte archivos infectados', imagen: 'assets/images/nivel_20/atacantes/distribuidor.png'),
  SospechosoZeroDay(id: 'explotador', nombre: 'EL EXPLOTADOR', rol: 'Aprovecha vulnerabilidades zero-day', imagen: 'assets/images/nivel_20/atacantes/explotador.png'),
  SospechosoZeroDay(id: 'fantasma', nombre: 'EL FANTASMA', rol: 'Ataca sin dejar rastro', imagen: 'assets/images/nivel_20/atacantes/fantasma.png'),
];

final casos = <CasoZeroDay>[
  CasoZeroDay(
    sistema: 'PC DEL CEO',
    descripcion: 'Equipo personal del director comprometido.',
    culpableId: 'phisher',
    evidencias: [
      EvidenciaZeroDay(titulo: 'EMAIL SOSPECHOSO', descripcion: 'Correo de soporte con enlace falso.', icono: Icons.email_outlined, pista: 'Login imitado pidiendo credenciales.', idSospechoso: 'phisher'),
      EvidenciaZeroDay(titulo: 'USB EN ESCRITORIO', descripcion: 'Memoria USB sin etiqueta encontrada.', icono: Icons.usb, pista: 'No conectada al equipo.', idSospechoso: 'distribuidor'),
      EvidenciaZeroDay(titulo: 'WI-FI DE HOTEL', descripcion: 'Conexion a red publica el dia anterior.', icono: Icons.wifi_tethering, pista: 'Sin VPN activa.', idSospechoso: 'interceptor'),
      EvidenciaZeroDay(titulo: 'CREDENCIALES FILTRADAS', descripcion: 'Acceso desde IP desconocida tras click.', icono: Icons.vpn_key_outlined, pista: 'Login valido tras email sospechoso.', idSospechoso: 'phisher'),
      EvidenciaZeroDay(titulo: 'NAVEGADOR LIMPIO', descripcion: 'Sin sitios web maliciosos visitados.', icono: Icons.public, pista: 'Historial sin anomalias.', idSospechoso: 'explotador'),
      EvidenciaZeroDay(titulo: 'SIN BACKDOOR', descripcion: 'Antivirus no detecta persistencia.', icono: Icons.security, pista: 'Acceso unico, no recurrente.', idSospechoso: 'fantasma'),
    ],
  ),
  CasoZeroDay(
    sistema: 'SERVIDOR DE LA EMPRESA',
    descripcion: 'Servidor web corporativo infectado.',
    culpableId: 'explotador',
    evidencias: [
      EvidenciaZeroDay(titulo: 'WEB COMPROMETIDA', descripcion: 'Visita a sitio externo con drive-by.', icono: Icons.public, pista: 'Exploit cargado sin interaccion.', idSospechoso: 'explotador'),
      EvidenciaZeroDay(titulo: 'CVE RECIENTE', descripcion: 'Vulnerabilidad nueva sin parchear.', icono: Icons.warning_amber_outlined, pista: 'CVE publicado hace 2 dias.', idSospechoso: 'explotador'),
      EvidenciaZeroDay(titulo: 'EMAILS NORMALES', descripcion: 'Sin correos de phishing detectados.', icono: Icons.email_outlined, pista: 'Filtro antispam OK.', idSospechoso: 'phisher'),
      EvidenciaZeroDay(titulo: 'ACTUALIZACIONES OK', descripcion: 'Sistema actualizado oficialmente.', icono: Icons.system_update_alt, pista: 'Updates legitimos.', idSospechoso: 'ingeniero'),
      EvidenciaZeroDay(titulo: 'CODIGO INYECTADO', descripcion: 'Payload en memoria sin tocar disco.', icono: Icons.bug_report_outlined, pista: 'Fileless attack en RAM.', idSospechoso: 'explotador'),
      EvidenciaZeroDay(titulo: 'RED ESTABLE', descripcion: 'Sin MITM detectado.', icono: Icons.wifi_tethering, pista: 'Conexiones SSL validas.', idSospechoso: 'interceptor'),
    ],
  ),
  CasoZeroDay(
    sistema: 'SISTEMA CRITICO BANCARIO',
    descripcion: 'Infraestructura financiera comprometida.',
    culpableId: 'fantasma',
    evidencias: [
      EvidenciaZeroDay(titulo: 'PROCESOS OCULTOS', descripcion: 'Servicios que no aparecen en logs.', icono: Icons.visibility_off_outlined, pista: 'Rootkit en kernel.', idSospechoso: 'fantasma'),
      EvidenciaZeroDay(titulo: 'ACCESO MESES ATRAS', descripcion: 'Compromiso inicial hace 6 meses.', icono: Icons.access_time, pista: 'Persistencia a largo plazo.', idSospechoso: 'fantasma'),
      EvidenciaZeroDay(titulo: 'SIN VECTOR CLARO', descripcion: 'Ningun email, web o USB sospechoso.', icono: Icons.help_outline, pista: 'No hay entrada visible.', idSospechoso: 'fantasma'),
      EvidenciaZeroDay(titulo: 'EXFILTRACION LENTA', descripcion: 'Datos saliendo poco a poco.', icono: Icons.upload_outlined, pista: 'Low and slow attack.', idSospechoso: 'fantasma'),
      EvidenciaZeroDay(titulo: 'EMAILS REVISADOS', descripcion: 'Sin phishing en historial reciente.', icono: Icons.email_outlined, pista: 'No es vector inicial.', idSospechoso: 'phisher'),
      EvidenciaZeroDay(titulo: 'UPDATES VERIFICADOS', descripcion: 'Todas las actualizaciones autenticas.', icono: Icons.verified_outlined, pista: 'Firmas digitales validas.', idSospechoso: 'ingeniero'),
    ],
  ),
];
