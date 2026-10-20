import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/room_wifi_ap_model.dart';

class WifiValidationResult {
  final bool isMatched;
  final String? connectedSsid;
  final String? connectedBssid;
  final RoomWifiAccessPointModel? matchedAp;
  final String reason;

  const WifiValidationResult({
    required this.isMatched,
    this.connectedSsid,
    this.connectedBssid,
    this.matchedAp,
    required this.reason,
  });
}

class WifiValidator {
  final NetworkInfo _networkInfo;

  WifiValidator({NetworkInfo? networkInfo})
      : _networkInfo = networkInfo ?? NetworkInfo();

  static String cleanSsid(String? raw) {
    if (raw == null) return '';
    var cleaned = raw.trim();
    if (cleaned.startsWith('"') && cleaned.endsWith('"') && cleaned.length >= 2) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    if (cleaned.startsWith("'") && cleaned.endsWith("'") && cleaned.length >= 2) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    return cleaned.trim();
  }

  static String cleanBssid(String? raw) {
    if (raw == null) return '';
    return raw.trim().toLowerCase();
  }

  Future<String?> getCurrentWifiSsid() async {
    try {
      final name = await _networkInfo.getWifiName();
      return cleanSsid(name);
    } catch (e) {
      if (kDebugMode) {
        print('WifiValidator getWifiName error: $e');
      }
      return null;
    }
  }

  Future<String?> getCurrentWifiBssid() async {
    try {
      final bssid = await _networkInfo.getWifiBSSID();
      return cleanBssid(bssid);
    } catch (e) {
      if (kDebugMode) {
        print('WifiValidator getWifiBSSID error: $e');
      }
      return null;
    }
  }

  Future<WifiValidationResult> validateRoomWifi({
    required List<RoomWifiAccessPointModel> allowedAps,
    String? expectedRoomCode,
  }) async {
    final currentSsid = await getCurrentWifiSsid();
    final currentBssid = await getCurrentWifiBssid();

    if (currentSsid == null || currentSsid.isEmpty) {
      return WifiValidationResult(
        isMatched: false,
        connectedSsid: null,
        connectedBssid: currentBssid,
        reason: 'Thiết bị chưa kết nối Wi-Fi phòng học. Vui lòng bật Wi-Fi.',
      );
    }

    if (allowedAps.isEmpty) {
      // If room has no registered APs, verify that user is at least connected to campus wifi
      final isCampus = currentSsid.toLowerCase().contains('unicheck') ||
          currentSsid.toLowerCase().contains('student') ||
          currentSsid.toLowerCase().contains('campus') ||
          currentSsid.toLowerCase().contains('hcmut');

      if (isCampus) {
        return WifiValidationResult(
          isMatched: true,
          connectedSsid: currentSsid,
          connectedBssid: currentBssid,
          reason: 'Đã kết nối mạng trường học: $currentSsid (Không có AP phòng riêng biệt)',
        );
      }

      return WifiValidationResult(
        isMatched: false,
        connectedSsid: currentSsid,
        connectedBssid: currentBssid,
        reason: 'Mạng "$currentSsid" không thuộc danh sách trạm phát trường học.',
      );
    }

    // Match by BSSID first (highest precision)
    if (currentBssid != null && currentBssid.isNotEmpty) {
      for (final ap in allowedAps) {
        if (cleanBssid(ap.bssid) == currentBssid && ap.bssid != null && ap.bssid!.isNotEmpty) {
          return WifiValidationResult(
            isMatched: true,
            connectedSsid: currentSsid,
            connectedBssid: currentBssid,
            matchedAp: ap,
            reason: "Đang kết nối trạm phát: '$currentSsid' (Khớp phòng ${expectedRoomCode ?? ap.roomCode ?? ''})",
          );
        }
      }
    }

    // Match by SSID (fallback)
    for (final ap in allowedAps) {
      if (cleanSsid(ap.ssid).toLowerCase() == currentSsid.toLowerCase()) {
        return WifiValidationResult(
          isMatched: true,
          connectedSsid: currentSsid,
          connectedBssid: currentBssid,
          matchedAp: ap,
          reason: "Đang kết nối trạm phát: '$currentSsid' (Khớp phòng ${expectedRoomCode ?? ap.roomCode ?? ''})",
        );
      }
    }

    // Not matched
    final expectedNames = allowedAps
        .map((a) => a.ssid ?? a.apName ?? a.roomCode ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');

    return WifiValidationResult(
      isMatched: false,
      connectedSsid: currentSsid,
      connectedBssid: currentBssid,
      reason: 'Đang kết nối mạng "$currentSsid". Cần kết nối trạm phát phòng học ($expectedNames).',
    );
  }
}
