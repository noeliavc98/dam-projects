import 'package:flutter/material.dart';

/// Representa un archivo del sistema que el jugador puede inspeccionar
class PrivilegeFile {
  final String id;
  final String nombre;
  final String ruta;
  final String descripcion;
  final String contenidoSimulado; // lo que "muestra" la terminal
  final bool tieneCredenciales;  // true = es el archivo correcto a seleccionar
  final IconData icono;            // emoji o label de tipo
 
  const PrivilegeFile({
    required this.id,
    required this.nombre,
    required this.ruta,
    required this.descripcion,
    required this.contenidoSimulado,
    required this.tieneCredenciales,
    required this.icono,
  });
}