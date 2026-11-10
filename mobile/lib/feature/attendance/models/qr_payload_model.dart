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
            token: decoded['token'] as String? ??
                decoded['qrToken'] as String? ??
                decoded['hash'] as String?,
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

    // 2. Static Test QR format: STQR:<sessionId>:<hexToken> or STQR-<sessionId>-<hexToken>
    if (trimmed.startsWith('STQR:') || trimmed.startsWith('stqr:')) {
      final parts = trimmed.split(':');
      if (parts.length >= 3) {
        final sId = int.tryParse(parts[1]);
        if (sId != null) {
          return QrPayloadModel(
            raw: trimmed,
            sessionId: sId,
            slotId: sId,
            token: trimmed,
            timestamp: now,
          );
        }
      }
    }
    if (trimmed.startsWith('STQR-') || trimmed.startsWith('stqr-')) {
      final parts = trimmed.split('-');
      if (parts.length >= 3) {
        final sId = int.tryParse(parts[1]);
        if (sId != null) {
          return QrPayloadModel(
            raw: trimmed,
            sessionId: sId,
            slotId: sId,
            token: trimmed,
            timestamp: now,
          );
        }
      }
    }

    // 3. Compact JWT format (Dynamic QR: eyJhbGciOi...)
    final jwtParts = trimmed.split('.');
    if (jwtParts.length == 3) {
      final claims = _tryDecodeJwtClaims(jwtParts[1]);
      if (claims != null) {
        final sId = (claims['sessionId'] as num?)?.toInt();
        DateTime ts = now;
        if (claims['iat'] != null) {
          final iat = (claims['iat'] as num).toInt();
          ts = DateTime.fromMillisecondsSinceEpoch(
            iat > 10000000000 ? iat : iat * 1000,
          );
        }
        return QrPayloadModel(
          raw: trimmed,
          sessionId: sId,
          slotId: sId,
          token: trimmed,
          timestamp: ts,
        );
      }
    }

    // 4. Try URI format (e.g. unicheck://attendance?sessionId=101&slotId=101)
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
          token: q['token'] ?? q['signature'] ?? q['qrToken'],
          timestamp: now,
        );
      } catch (_) {
        // Fallback
      }
    }

    // 5. Delimited string format: UNICHECK:SESSION_ID:ROOM_CODE (e.g. UNICHECK:101:A4-501)
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
          token: trimmed,
          timestamp: now,
        );
      }
    }

    // 6. Fallback plain text / number
    final fallbackId = int.tryParse(trimmed);
    return QrPayloadModel(
      raw: trimmed,
      sessionId: fallbackId,
      slotId: fallbackId,
      timestamp: now,
    );
  }

  static Map<String, dynamic>? _tryDecodeJwtClaims(String payloadBase64) {
    try {
      String normalized = payloadBase64;
      switch (normalized.length % 4) {
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
        case 0:
          break;
        default:
          return null;
      }
      final decodedBytes = base64Url.decode(normalized);
      final jsonStr = utf8.decode(decodedBytes);
      final decoded = json.decode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  bool get isValid =>
      raw.isNotEmpty &&
      (sessionId != null || slotId != null || roomCode != null || (token != null && token!.isNotEmpty));
}
