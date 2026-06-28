String formatRelativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} minutes';
  if (diff.inHours < 24) return '${diff.inHours} hours';
  if (diff.inDays < 7) return '${diff.inDays} days';
  if (diff.inDays < 30) return '${diff.inDays ~/ 7} weeks';
  return '${diff.inDays ~/ 30} months';
}

String formatFeedDate(DateTime dateTime) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} · '
      '$hour:$minute $period';
}
