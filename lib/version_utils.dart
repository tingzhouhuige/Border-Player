List<int>? parseReleaseVersion(String? value) {
  if (value == null) return null;
  var normalized = value.trim();
  if (normalized.startsWith('v') || normalized.startsWith('V')) {
    normalized = normalized.substring(1);
  }
  normalized = normalized.split('+').first.split('-').first;
  if (normalized.isEmpty) return null;

  final parts = normalized.split('.');
  final result = <int>[];
  for (final part in parts) {
    final number = int.tryParse(part);
    if (number == null || number < 0) return null;
    result.add(number);
  }
  return result;
}

bool isReleaseVersionNewer(String? candidate, String current) {
  final candidateParts = parseReleaseVersion(candidate);
  final currentParts = parseReleaseVersion(current);
  if (candidateParts == null || currentParts == null) return false;

  final length = candidateParts.length > currentParts.length
      ? candidateParts.length
      : currentParts.length;
  for (var index = 0; index < length; index++) {
    final candidatePart =
        index < candidateParts.length ? candidateParts[index] : 0;
    final currentPart = index < currentParts.length ? currentParts[index] : 0;
    if (candidatePart != currentPart) return candidatePart > currentPart;
  }
  return false;
}
