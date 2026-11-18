class QrTokenModel {
  final int id;
  final int mealSlotId;
  final String token;

  final DateTime expiresAt;
  final DateTime serverTime;
  final int expiresIn;

  final bool isUsed;

  const QrTokenModel({
    required this.id,
    required this.mealSlotId,
    required this.token,
    required this.expiresAt,
    required this.serverTime,
    required this.expiresIn,
    required this.isUsed,
  });

  factory QrTokenModel.fromJson(Map<String, dynamic> json) {
    final tokenValue =
        json['token'] ??
        json['qr_token'] ??
        json['qr_data'] ??
        json['value'] ??
        '';

    final expiryValue =
        json['expires_at'] ??
        json['expiry_time'] ??
        json['expired_at'];

    final serverTimeValue = json['server_time'];

    final expiresAt =
        DateTime.tryParse(expiryValue?.toString() ?? '')?.toUtc() ??
        DateTime.now().toUtc();

    final serverTime =
        DateTime.tryParse(serverTimeValue?.toString() ?? '')?.toUtc() ??
        DateTime.now().toUtc();

    return QrTokenModel(
      id: _toInt(json['id']),
      mealSlotId: _toInt(json['meal_slot_id']),
      token: tokenValue.toString(),
      expiresAt: expiresAt,
      serverTime: serverTime,
      expiresIn: _toInt(json['expires_in']),
      isUsed: _toBool(json['is_used']),
    );
  }

  String get qrValue => token;
}

int _toInt(dynamic value) {
  if (value is int) return value;

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;

  final text = value?.toString().toLowerCase();

  return text == 'true' || text == '1';
}