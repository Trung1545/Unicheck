class RoomWifiAccessPointModel {
  final int id;
  final int? roomId;
  final String? roomCode;
  final String? roomName;
  final int? wifiAccessPointId;
  final String? ssid;
  final String? bssid;
  final String? apName;
  final String? location;
  final String? apStatus;
  final int? signalStrength;
  final bool isPrimary;
  final String? positionNote;

  const RoomWifiAccessPointModel({
    required this.id,
    this.roomId,
    this.roomCode,
    this.roomName,
    this.wifiAccessPointId,
    this.ssid,
    this.bssid,
    this.apName,
    this.location,
    this.apStatus,
    this.signalStrength,
    this.isPrimary = false,
    this.positionNote,
  });

  factory RoomWifiAccessPointModel.fromJson(Map<String, dynamic> json) {
    return RoomWifiAccessPointModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      roomId: (json['roomId'] as num?)?.toInt(),
      roomCode: json['roomCode'] as String?,
      roomName: json['roomName'] as String?,
      wifiAccessPointId: (json['wifiAccessPointId'] as num?)?.toInt(),
      ssid: json['ssid'] as String?,
      bssid: json['bssid'] as String?,
      apName: json['apName'] as String?,
      location: json['location'] as String?,
      apStatus: json['apStatus'] as String?,
      signalStrength: (json['signalStrength'] as num?)?.toInt(),
      isPrimary: json['isPrimary'] == true,
      positionNote: json['positionNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'roomCode': roomCode,
      'roomName': roomName,
      'wifiAccessPointId': wifiAccessPointId,
      'ssid': ssid,
      'bssid': bssid,
      'apName': apName,
      'location': location,
      'apStatus': apStatus,
      'signalStrength': signalStrength,
      'isPrimary': isPrimary,
      'positionNote': positionNote,
    };
  }
}
