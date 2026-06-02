import 'dart:convert';

enum AlertType { up, down, daily }

class AlertModel {
  final String id;
  final AlertType type;
  final double? threshold;
  final bool isActive;
  final String label;

  const AlertModel({
    required this.id,
    required this.type,
    this.threshold,
    this.isActive = true,
    required this.label,
  });

  AlertModel copyWith({
    String? id,
    AlertType? type,
    double? threshold,
    bool? isActive,
    String? label,
  }) {
    return AlertModel(
      id: id ?? this.id,
      type: type ?? this.type,
      threshold: threshold ?? this.threshold,
      isActive: isActive ?? this.isActive,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'threshold': threshold,
      'isActive': isActive,
      'label': label,
    };
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      type: AlertType.values.firstWhere((e) => e.name == json['type']),
      threshold: json['threshold'] != null
          ? (json['threshold'] as num).toDouble()
          : null,
      isActive: json['isActive'] as bool? ?? true,
      label: json['label'] as String,
    );
  }

  static String encodeList(List<AlertModel> alerts) {
    return jsonEncode(alerts.map((a) => a.toJson()).toList());
  }

  static List<AlertModel> decodeList(String json) {
    final list = jsonDecode(json) as List;
    return list.map((e) => AlertModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
