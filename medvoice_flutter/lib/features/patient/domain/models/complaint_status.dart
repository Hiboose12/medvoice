enum ComplaintStatus {
  newComplaint('new', 'New'),
  review('review', 'Under Review'),
  responded('responded', 'Responded'),
  resolved('resolved', 'Resolved'),
  escalated('escalated', 'Escalated');

  const ComplaintStatus(this.value, this.label);
  final String value;
  final String label;

  static ComplaintStatus fromValue(String value) => ComplaintStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => ComplaintStatus.newComplaint,
      );
}

enum ComplaintSeverity {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High');

  const ComplaintSeverity(this.value, this.label);
  final String value;
  final String label;
}
