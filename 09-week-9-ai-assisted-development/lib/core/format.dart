/// Pure helper functions for formatting and route parsing.
/// Pure Dart — completely testable without Flutter widgets.
library;

/// Formats an announcement chip label from an [id].
String formatAnnouncementChip(String id) {
  final cleanId = id.trim().isEmpty ? '0' : id.trim();
  return 'Pengumuman #$cleanId';
}

/// Parses an announcement route path parameter, defaulting to '0' if invalid.
String parseAnnouncementId(String? rawId) {
  if (rawId == null || rawId.trim().isEmpty) {
    return '0';
  }
  return rawId.trim();
}

/// Memvalidasi format email menggunakan pola dasar.
bool isValidEmail(String email) {
  final emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$",
  );

  return emailRegex.hasMatch(email.trim());
}

/// Masks sensitive token strings for safe logging.
String maskToken(String? token) {
  if (token == null || token.isEmpty) return '(empty)';
  if (token.length <= 8) return '***';
  return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
}
