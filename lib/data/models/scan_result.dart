/// Resultado de un escaneo OCR de factura.
/// Contiene el monto en Bs y opcionalmente la fecha/hora de la factura.
class ScanResult {
  final String amountRaw;
  final double amountBs;
  final DateTime? invoiceDate;
  final String? invoiceTime;

  const ScanResult({
    required this.amountRaw,
    required this.amountBs,
    this.invoiceDate,
    this.invoiceTime,
  });
}
