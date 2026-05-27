class TasaModel {
  final double bcvUsd;
  final double usdtP2P;
  final double? yadioRate;
  final double? bcvEur;
  final double? bcvCop;
  final double? bcvBrl;
  final DateTime timestamp;
  final bool isFromCache;
  final String? nextUpdateMessage;

  const TasaModel({
    required this.bcvUsd,
    required this.usdtP2P,
    this.yadioRate,
    this.bcvEur,
    this.bcvCop,
    this.bcvBrl,
    required this.timestamp,
    this.isFromCache = false,
    this.nextUpdateMessage,
  });

  TasaModel copyWith({
    double? bcvUsd,
    double? usdtP2P,
    double? yadioRate,
    double? bcvEur,
    double? bcvCop,
    double? bcvBrl,
    DateTime? timestamp,
    bool? isFromCache,
    String? nextUpdateMessage,
  }) {
    return TasaModel(
      bcvUsd: bcvUsd ?? this.bcvUsd,
      usdtP2P: usdtP2P ?? this.usdtP2P,
      yadioRate: yadioRate ?? this.yadioRate,
      bcvEur: bcvEur ?? this.bcvEur,
      bcvCop: bcvCop ?? this.bcvCop,
      bcvBrl: bcvBrl ?? this.bcvBrl,
      timestamp: timestamp ?? this.timestamp,
      isFromCache: isFromCache ?? this.isFromCache,
      nextUpdateMessage: nextUpdateMessage ?? this.nextUpdateMessage,
    );
  }

  factory TasaModel.fromJson(Map<String, dynamic> json) {
    final nextUpdate = json['nextUpdate'];
    String? message;
    if (nextUpdate is Map) {
      message = nextUpdate['message'] as String?;
    }

    return TasaModel(
      bcvUsd: (json['bcvUsd'] as num).toDouble(),
      usdtP2P: json['usdtP2P'] != null ? (json['usdtP2P'] as num).toDouble() : 0.0,
      yadioRate: _optionalDouble(json['yadioRate']),
      bcvEur: _optionalDouble(json['bcvEur']),
      bcvCop: _optionalDouble(json['bcvCop']),
      bcvBrl: _optionalDouble(json['bcvBrl']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFromCache: false,
      nextUpdateMessage: message,
    );
  }

  static double? _optionalDouble(dynamic value) {
    if (value == null) return null;
    if (value is num && value > 0) return value.toDouble();
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'bcvUsd': bcvUsd,
      'usdtP2P': usdtP2P,
      if (yadioRate != null) 'yadioRate': yadioRate,
      if (bcvEur != null) 'bcvEur': bcvEur,
      if (bcvCop != null) 'bcvCop': bcvCop,
      if (bcvBrl != null) 'bcvBrl': bcvBrl,
      'timestamp': timestamp.toIso8601String(),
      if (nextUpdateMessage != null) 'nextUpdateMessage': nextUpdateMessage,
    };
  }
}

class TasaHistoryEntry {
  final DateTime date;
  final double bcvUsd;
  final double variation;     // diferencia absoluta en Bs (legacy)
  final double? variationPct; // % pre-calculado por el backend (opcional)

  const TasaHistoryEntry({
    required this.date,
    required this.bcvUsd,
    required this.variation,
    this.variationPct,
  });

  /// Devuelve el % de variación diaria.
  /// Usa [variationPct] pre-calculado si existe; si no, lo calcula desde [previousBcvUsd].
  double getVariationPct(double? previousBcvUsd) {
    if (variationPct != null) return variationPct!;
    if (previousBcvUsd != null && previousBcvUsd > 0) {
      return (variation / previousBcvUsd) * 100;
    }
    return 0.0;
  }

  factory TasaHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TasaHistoryEntry(
      date: DateTime.parse(json['date'] as String),
      bcvUsd: (json['bcvUsd'] as num).toDouble(),
      variation: (json['variation'] as num).toDouble(),
      variationPct: json['variationPct'] != null
          ? (json['variationPct'] as num).toDouble()
          : null,
    );
  }
}
