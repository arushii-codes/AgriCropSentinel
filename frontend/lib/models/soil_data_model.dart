class SoilData {
  final String source;
  final Map<String, dynamic> soilData;

  SoilData({required this.source, required this.soilData});

  factory SoilData.fromJson(Map<String, dynamic> json) {
    return SoilData(
      source: json['source'],
      soilData: Map<String, dynamic>.from(json['soil_data']),
    );
  }
}
