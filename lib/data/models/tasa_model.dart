class TasaModel {
  final double bcvUsd;
  final double bcvEur;
  final double? usdtP2P;
  final double? yadioRate;
  // Tasas adicionales BCV
  final double? bcvCop; // Peso colombiano
  final double? bcvBrl; // Real brasileño
  final double? bcvCny; // Yuan chino
  final double? bcvTry; // Lira turca
  final double? bcvRub; // Rublo ruso
  final DateTime timestamp;
  final bool isFromCache;
  final String? bcvStatus;

  const TasaModel({
    required this.bcvUsd,
    required this.bcvEur,
    this.usdtP2P,
    this.yadioRate,
    this.bcvCop,
    this.bcvBrl,
    this.bcvCny,
    this.bcvTry,
    this.bcvRub,
    required this.timestamp,
    this.isFromCache = false,
    this.bcvStatus,
  });

  /// Spread porcentual: (P2P - BCV) / BCV * 100
  double get spreadPercent {
    if (usdtP2P == null || bcvUsd == 0) return 0;
    return ((usdtP2P! - bcvUsd) / bcvUsd) * 100;
  }

  /// Mapa de todas las tasas disponibles: código → valor en Bs
  Map<String, double?> get allRates => {
    'USD': bcvUsd,
    'EUR': bcvEur,
    'COP': bcvCop,
    'BRL': bcvBrl,
    'CNY': bcvCny,
    'TRY': bcvTry,
    'RUB': bcvRub,
    'USDT': usdtP2P,
    'YADIO': yadioRate,
  };

  TasaModel copyWith({
    double? bcvUsd,
    double? bcvEur,
    double? usdtP2P,
    double? yadioRate,
    double? bcvCop,
    double? bcvBrl,
    double? bcvCny,
    double? bcvTry,
    double? bcvRub,
    DateTime? timestamp,
    bool? isFromCache,
    String? bcvStatus,
  }) {
    return TasaModel(
      bcvUsd: bcvUsd ?? this.bcvUsd,
      bcvEur: bcvEur ?? this.bcvEur,
      usdtP2P: usdtP2P ?? this.usdtP2P,
      yadioRate: yadioRate ?? this.yadioRate,
      bcvCop: bcvCop ?? this.bcvCop,
      bcvBrl: bcvBrl ?? this.bcvBrl,
      bcvCny: bcvCny ?? this.bcvCny,
      bcvTry: bcvTry ?? this.bcvTry,
      bcvRub: bcvRub ?? this.bcvRub,
      timestamp: timestamp ?? this.timestamp,
      isFromCache: isFromCache ?? this.isFromCache,
      bcvStatus: bcvStatus ?? this.bcvStatus,
    );
  }

  factory TasaModel.fromJson(Map<String, dynamic> json) {
    String? status;
    if (json['nextUpdate'] != null && json['nextUpdate'] is Map) {
      status = json['nextUpdate']['message'] as String?;
    }
    return TasaModel(
      bcvUsd: (json['bcvUsd'] as num).toDouble(),
      bcvEur: (json['bcvEur'] as num).toDouble(),
      usdtP2P: json['usdtP2P'] != null ? (json['usdtP2P'] as num).toDouble() : null,
      yadioRate: json['yadioRate'] != null ? (json['yadioRate'] as num).toDouble() : null,
      bcvCop: json['bcvCop'] != null ? (json['bcvCop'] as num).toDouble() : null,
      bcvBrl: json['bcvBrl'] != null ? (json['bcvBrl'] as num).toDouble() : null,
      bcvCny: json['bcvCny'] != null ? (json['bcvCny'] as num).toDouble() : null,
      bcvTry: json['bcvTry'] != null ? (json['bcvTry'] as num).toDouble() : null,
      bcvRub: json['bcvRub'] != null ? (json['bcvRub'] as num).toDouble() : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFromCache: false,
      bcvStatus: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bcvUsd': bcvUsd,
      'bcvEur': bcvEur,
      'usdtP2P': usdtP2P,
      'yadioRate': yadioRate,
      'bcvCop': bcvCop,
      'bcvBrl': bcvBrl,
      'bcvCny': bcvCny,
      'bcvTry': bcvTry,
      'bcvRub': bcvRub,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class TasaHistoryEntry {
  final DateTime date;
  final double bcvUsd;
  final double bcvEur;
  final double variation;

  const TasaHistoryEntry({
    required this.date,
    required this.bcvUsd,
    required this.bcvEur,
    required this.variation,
  });

  factory TasaHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TasaHistoryEntry(
      date: DateTime.parse(json['date'] as String),
      bcvUsd: (json['bcvUsd'] as num).toDouble(),
      bcvEur: (json['bcvEur'] as num).toDouble(),
      variation: (json['variation'] as num).toDouble(),
    );
  }
}
