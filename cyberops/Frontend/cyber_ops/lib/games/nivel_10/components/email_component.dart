enum ComponentType { sender, subject, manipulation, link }

class EmailComponent {
  final String id;
  final ComponentType type;
  final String value;
  final int credibility; 
  final String hackerComment;
  final bool isBlocked; // true = es el real, no se puede elegir

  const EmailComponent({
    required this.id,
    required this.type,
    required this.value,
    required this.credibility,
    required this.hackerComment,
    this.isBlocked = false,
  });
}