class AttendanceCheckinRequestModel {
  final int? sessionId;
  final int? slotId;
  final String? qrToken;
  final String? otpCode;
  final String? verificationTicket;
  final String? verificationMethod;
  final String? wifiBssid;
  final String? wifiSsid;
  final String? faceSampleBase64;
  final bool livenessPassed;
  final List<String>? livenessSteps;
  final String? deviceModel;
  final int? recheckRequestId;

  const AttendanceCheckinRequestModel({
    this.sessionId,
    this.slotId,
    this.qrToken,
    this.otpCode,
    this.verificationTicket,
    this.verificationMethod,
    this.wifiBssid,
    this.wifiSsid,
    this.faceSampleBase64,
    this.livenessPassed = false,
    this.livenessSteps,
    this.deviceModel,
    this.recheckRequestId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (sessionId != null) 'sessionId': sessionId,
      if (slotId != null) 'slotId': slotId,
      if (qrToken != null) 'qrToken': qrToken,
      if (otpCode != null) 'otpCode': otpCode,
      if (verificationTicket != null) 'verificationTicket': verificationTicket,
      if (verificationMethod != null) 'verificationMethod': verificationMethod,
      if (wifiBssid != null) 'wifiBssid': wifiBssid,
      if (wifiSsid != null) 'wifiSsid': wifiSsid,
      if (faceSampleBase64 != null) 'faceSampleBase64': faceSampleBase64,
      'livenessPassed': livenessPassed,
      if (livenessSteps != null) 'livenessSteps': livenessSteps,
      if (deviceModel != null) 'deviceModel': deviceModel,
      if (recheckRequestId != null) 'recheckRequestId': recheckRequestId,
    };
  }
}
