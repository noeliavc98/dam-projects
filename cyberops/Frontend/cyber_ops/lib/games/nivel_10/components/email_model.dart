class EmailModel {
  final String id;
  final String sender;
  final String subject;
  final String body;
  final String? attachment;
  final bool isPhishing;
  final String educationalTip;

  const EmailModel({
    required this.id,
    required this.sender,
    required this.subject,
    required this.body,
    this.attachment,
    required this.isPhishing,
    required this.educationalTip,
  });
}