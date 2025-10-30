class LocationData {
  final Area area;
  final Cell cell;

  const LocationData({required this.area, required this.cell});

  factory LocationData.fromApiResponse(dynamic json) {
    return LocationData(
      area: Area.fromJson(json['area']),
      cell: Cell.fromJson(json['cell']),
    );
  }
}

class Area {
  final int id;
  final String name;

  const Area({required this.id, required this.name});

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(id: json['id'] ?? 0, name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class Cell {
  final int id;
  final String geoHash;
  final List<double> location;

  const Cell({required this.id, required this.geoHash, required this.location});

  factory Cell.fromJson(Map<String, dynamic> json) {
    return Cell(
      id: json['id'] ?? 0,
      geoHash: json['geo_hash'] ?? '',
      location: List<double>.from(json['location'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'geo_hash': geoHash, 'location': location};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cell && other.geoHash == geoHash;
  }

  @override
  int get hashCode => geoHash.hashCode;
}
