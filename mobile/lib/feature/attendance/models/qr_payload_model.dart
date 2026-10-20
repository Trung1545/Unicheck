import 'dart:convert';

class QrPayloadModel {
  final String raw;
  final int? sessionId;
  final int? slotId;
  final String? roomCode;
  final String? courseCode;
  final String? token;
  final DateTime timestamp;

  const QrPayloadModel({
    required this.raw,
    this.sessionId,
    this.slotId,
    this.roomCode,
    this.courseCode,
    this.token,
    required this.timestamp,
  });

  factory QrPayloadModel.parse(String raw) {
    final trimmed = raw.trim();
    final now = DateTime.now();

    // 1. Try parsing JSON
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = json.decode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return QrPayloadModel(
            raw: trimmed,
            sessionId: (decoded['sessionId'] as num?)?.toInt() ??
                (decoded['id'] as num?)?.toInt(),
            slotId: (decoded['slotId'] as num?)?.toInt(),
            roomCode: decoded['roomCode'] as String? ??
                decoded['room'] as String?,
            courseCode: decoded['courseCode'] as String?,
            token: decoded['token'] as String? ?? decoded['hash'] as String?,
            timestamp: decoded['timestamp'] != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    (decoded['timestamp'] as num).toInt() > 10000000000
                        ? (decoded['timestamp'] as num).toInt()
                        : (decoded['timestamp'] as num).toInt() * 1000,
                  )
                : now,
          );
        }
      } catch (_) {
        // Fallback to other formats
      }
    }

    // 2. Try URI format (e.g. unicheck://attendance?sessionId=101&slotId=101)
    if (trimmed.contains('://') || trimmed.startsWith('unicheck:')) {
      try {
        final uri = Uri.parse(trimmed);
        final q = uri.queryParameters;
        return QrPayloadModel(
          raw: trimmed,
          sessionId: int.tryParse(q['sessionId'] ?? q['id'] ?? ''),
          slotId: int.tryParse(q['slotId'] ?? ''),
          roomCode: q['roomCode'] ?? q['room'],
          courseCode: q['courseCode'],
          token: q['token'] ?? q['signature'],
          timestamp: now,
        );
      } catch (_) {
        // Fallback
      }
    }

    // 3. Delimited string format: UNICHECK:SESSION_ID:ROOM_CODE (e.g. UNICHECK:101:A4-501)
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length >= 2) {
        final id = int.tryParse(parts[1]);
        final room = parts.length >= 3 ? parts[2] : null;
        return QrPayloadModel(
          raw: trimmed,
          sessionId: id,
          slotId: id,
          roomCode: room,
          timestamp: now,
        );
      }
    }

    // 4. Fallback plain text / number
    final fallbackId = int.tryParse(trimmed);
    return QrPayloadModel(
      raw: trimmed,
      sessionId: fallbackId,
      slotId: fallbackId,
      timestamp: now,
    );
  }

  bool get isValid =>
      raw.isNotEmpty && (sessionId != null || slotId != null || roomCode != null);
}
