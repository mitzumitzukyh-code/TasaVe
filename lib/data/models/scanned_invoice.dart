import 'dart:convert';

class ScannedInvoice {
  final String id;
  final double amountBs;
  final String? label;
  final DateTime scannedAt;
  final DateTime? invoiceDate;
  final String? invoiceTime;

  const ScannedInvoice({
    required this.id,
    required this.amountBs,
    this.label,
    required this.scannedAt,
    this.invoiceDate,
    this.invoiceTime,
  });

  ScannedInvoice copyWith({String? label}) {
    return ScannedInvoice(
      id: id,
      amountBs: amountBs,
      label: label ?? this.label,
      scannedAt: scannedAt,
      invoiceDate: invoiceDate,
      invoiceTime: invoiceTime,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amountBs': amountBs,
    'label': label,
    'scannedAt': scannedAt.toIso8601String(),
    'invoiceDate': invoiceDate?.toIso8601String(),
    'invoiceTime': invoiceTime,
  };

  factory ScannedInvoice.fromJson(Map<String, dynamic> json) {
    return ScannedInvoice(
      id: json['id'] as String,
      amountBs: (json['amountBs'] as num).toDouble(),
      label: json['label'] as String?,
      scannedAt: DateTime.parse(json['scannedAt'] as String),
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.tryParse(json['invoiceDate'] as String)
          : null,
      invoiceTime: json['invoiceTime'] as String?,
    );
  }

  static String encodeList(List<ScannedInvoice> list) {
    return jsonEncode(list.map((e) => e.toJson()).toList());
  }

  static List<ScannedInvoice> decodeList(String raw) {
    final list = jsonDecode(raw) as List;
    return list.map((e) => ScannedInvoice.fromJson(e as Map<String, dynamic>)).toList();
  }
}
