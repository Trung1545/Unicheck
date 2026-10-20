class AttendanceCheckinRequestModel {
  final int? sessionId;
  final int? slotId;
  final String? qrToken;
  final String? wifiBssid;
  final String? wifiSsid;
  final String? faceSampleBase64;
  final bool livenessPassed;
  final List<String>? livenessSteps;
  final String? deviceModel;

  const AttendanceCheckinRequestModel({
    this.sessionId,
    this.slotId,
    this.qrToken,
    this.wifiBssid,
    this.wifiSsid,
    this.faceSampleBase64,
    this.livenessPassed = false,
    this.livenessSteps,
    this.deviceModel,
  });

  Map<String, dynamic> toJson() {
    return {
      if (sessionId != null) 'sessionId': sessionId,
      if (slotId != null) 'slotId': slotId,
      if (qrToken != null) 'qrToken': qrToken,
      if (wifiBssid != null) 'wifiBssid': wifiBssid,
      if (wifiSsid != null) 'wifiSsid': wifiSsid,
      if (faceSampleBase64 != null) 'faceSampleBase64': faceSampleBase64,
      'livenessPassed': livenessPassed,
      if (livenessSteps != null) 'livenessSteps': livenessSteps,
      if (deviceModel != null) 'deviceModel': deviceModel,
    };
  }
}
