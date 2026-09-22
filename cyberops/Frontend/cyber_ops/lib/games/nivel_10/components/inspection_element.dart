enum ElementType { sender, url, body, attachment }

class InspectionElement {
  final ElementType type;
  final String label;       // "Remitente", "Enlace"...
  final String value;       // El valor que ve el jugador
  final String revelation;  // Lo que descubre al tocar
  final bool isSuspicious;

  const InspectionElement({
    required this.type,
    required this.label,
    required this.value,
    required this.revelation,
    required this.isSuspicious,
  });
}