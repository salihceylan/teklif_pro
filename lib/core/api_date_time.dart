DateTime parseApiDateTime(String value) {
  final trimmed = value.trim();
  final hasExplicitTimezone = trimmed.endsWith('Z') ||
      RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(trimmed);
  final normalized = hasExplicitTimezone ? trimmed : '${trimmed}Z';
  return DateTime.parse(normalized).toLocal();
}
