import 'pregunta_nivel15.dart';

class Sospechoso {
  final String nombre;
  final String pid;
  final String estado;
  final String firma;
  final String usuario;
  final String memoria;
  final bool esRootkit;
  final List<Pregunta> preguntas;
  final String respuestaInicial;

  Sospechoso({
    required this.nombre,
    required this.pid,
    required this.estado,
    required this.firma,
    required this.usuario,
    required this.memoria,
    required this.esRootkit,
    required this.preguntas,
    required this.respuestaInicial,
  });
}
