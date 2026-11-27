import '../../domain/entities/work_location.dart';

class WorkLocationModel extends WorkLocation {
  const WorkLocationModel({
    required super.id,
    required super.name,
    super.code,
    super.address,
    required super.latitude,
    required super.longitude,
    required super.radiusMeters,
  });

  factory WorkLocationModel.fromJson(Map<String, dynamic> json) {
    return WorkLocationModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      address: json['address']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      radiusMeters: _toInt(json['radius_meters'], fallback: 100),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
      };

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
