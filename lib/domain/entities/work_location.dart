class WorkLocation {
  final int id;
  final String name;
  final String? code;
  final String? address;
  final double latitude;
  final double longitude;
  final int radiusMeters;

  const WorkLocation({
    required this.id,
    required this.name,
    this.code,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });
}
