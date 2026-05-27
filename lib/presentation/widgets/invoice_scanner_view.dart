import 'dart:io';
// debug logging via print (visible in logcat as I/flutter)
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants.dart';
import '../../data/models/scan_result.dart';

/// Vista de cámara para escanear facturas y extraer monto + fecha.
class InvoiceScannerView extends StatefulWidget {
  final ValueChanged<ScanResult>? onInvoiceScanned;
  @Deprecated('Use onInvoiceScanned instead')
  final ValueChanged<String>? onAmountDetected;
  const InvoiceScannerView({super.key, this.onInvoiceScanned, this.onAmountDetected});

  @override
  State<InvoiceScannerView> createState() => _InvoiceScannerViewState();
}

class _InvoiceScannerViewState extends State<InvoiceScannerView>
    with TickerProviderStateMixin {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _permissionDenied = false;
  bool _permissionPermanentlyDenied = false;
  String? _statusMsg;

  // Animación de la línea de escaneo
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnim;

  static const _totalKeywords = [
    'TOTAL', 'NETO', 'A PAGAR', 'GRAN TOTAL', 'SUBTOTAL', 'MONTO', 'IMPORTE',
  ];

  static final _amountRe = RegExp(
    r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})|(?:\d+)(?:[.,]\d{1,2}))',
  );

  // Fecha: DD/MM/YYYY o DD-MM-YYYY o DD.MM.YYYY (tolera espacios OCR)
  static final _dateRe = RegExp(
    r'(\d{1,2})\s*[/\-\.\s]\s*(\d{1,2})\s*[/\-\.\s]\s*(\d{2,4})',
  );

  // Hora: HH:MM o HH:MM:SS
  static final _timeRe = RegExp(
    r'(\d{1,2})\s*:\s*(\d{2})(?:\s*:\s*(\d{2}))?',
  );

  static const _dateKeywords = ['FECHA', 'FECH', 'FCCHA', 'DATE'];

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    // 1. Verificar y solicitar permiso de cámara
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (!mounted) return;

    if (status.isPermanentlyDenied) {
      setState(() => _permissionPermanentlyDenied = true);
      return;
    }
    if (!status.isGranted) {
      setState(() => _permissionDenied = true);
      return;
    }

    // 2. Permiso concedido — inicializar cámara
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _statusMsg = 'No se encontró cámara en este dispositivo.');
        return;
      }
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _statusMsg = 'Error al iniciar cámara.');
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMsg = 'Procesando factura...';
    });

    XFile? photo;
    TextRecognizer? recognizer;

    try {
      photo = await _controller!.takePicture();
      debugPrint('[SCANNER] Foto capturada: ${photo.path}');
      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized =
          await recognizer.processImage(InputImage.fromFilePath(photo.path));
      debugPrint('[SCANNER] ═══ TEXTO OCR COMPLETO ═══');
      debugPrint(recognized.text);
      debugPrint('[SCANNER] ═══ FIN TEXTO OCR ═══ (${recognized.text.length} chars, ${recognized.blocks.length} bloques)');
      final extracted = _extractAmount(recognized.text);
      final dateInfo = _extractDate(recognized.text);
      final timeInfo = _extractTime(recognized.text);
      debugPrint('[SCANNER] Monto extraído: ${extracted ?? "NINGUNO"}');
      debugPrint('[SCANNER] Fecha extraída: ${dateInfo ?? "NINGUNA"}');
      debugPrint('[SCANNER] Hora extraída: ${timeInfo ?? "NINGUNA"}');

      if (!mounted) return;
      if (extracted != null) {
        final clean = _normalizeAmount(extracted);
        final parsed = double.tryParse(clean) ?? 0.0;
        debugPrint('[SCANNER] ✓ Enviando resultado: $parsed Bs, fecha=$dateInfo, hora=$timeInfo');

        if (widget.onInvoiceScanned != null) {
          widget.onInvoiceScanned!(ScanResult(
            amountRaw: extracted,
            amountBs: parsed,
            invoiceDate: dateInfo,
            invoiceTime: timeInfo,
          ));
        } else if (widget.onAmountDetected != null) {
          widget.onAmountDetected!(extracted);
        } else {
          Navigator.of(context).pop(extracted);
        }
      } else {
        debugPrint('[SCANNER] ✗ No se pudo extraer monto del texto');
        setState(() {
          _isProcessing = false;
          _statusMsg = 'No se detectó ningún monto.\nIntenta con mejor iluminación.';
        });
      }
    } catch (e, st) {
      debugPrint('[SCANNER] ERROR: $e\n$st');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMsg = 'Error al procesar. Intenta de nuevo.';
        });
      }
    } finally {
      recognizer?.close();
      if (photo != null) {
        try { File(photo.path).deleteSync(); } catch (_) {}
      }
    }
  }

  String? _extractAmount(String rawText) {
    if (rawText.isEmpty) return null;
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    debugPrint('[SCANNER] Líneas detectadas: ${lines.length}');
    for (int i = 0; i < lines.length; i++) {
      debugPrint('[SCANNER]   [$i] ${lines[i]}');
    }

    // 1. Líneas con palabras clave de cierre
    final priority = lines.where((line) {
      final upper = line.toUpperCase();
      return _totalKeywords.any((kw) => upper.contains(kw));
    }).toList();
    debugPrint('[SCANNER] Líneas con keywords (TOTAL/NETO/etc): ${priority.length}');
    for (final p in priority) {
      debugPrint('[SCANNER]   → "$p"');
    }

    for (final line in priority.reversed) {
      final match = _amountRe.allMatches(line).lastOrNull;
      if (match != null) {
        final result = _normalizeAmount(match.group(0)!);
        debugPrint('[SCANNER] ✓ Match por keyword en misma línea: "${match.group(0)}" → $result');
        return result;
      }
    }

    // 1b. Keyword sin monto → buscar en las siguientes 5 líneas
    for (final kwLine in priority.reversed) {
      final kwIdx = lines.indexOf(kwLine);
      if (kwIdx >= 0) {
        for (int j = kwIdx + 1; j < lines.length && j <= kwIdx + 5; j++) {
          final match = _amountRe.allMatches(lines[j]).lastOrNull;
          if (match != null) {
            final result = _normalizeAmount(match.group(0)!);
            debugPrint('[SCANNER] ✓ Match adyacente a keyword (línea +${j - kwIdx}): "${match.group(0)}" → $result');
            return result;
          }
        }
      }
    }

    // 2. Fallback: monto numéricamente mayor
    debugPrint('[SCANNER] Sin match por keyword, usando fallback (monto mayor)');
    double bestValue = 0;
    String? bestStr;
    for (final line in lines) {
      for (final match in _amountRe.allMatches(line)) {
        final raw = match.group(0)!;
        final value = _parseAmount(raw);
        if (value != null && value > bestValue) {
          bestValue = value;
          bestStr = _normalizeAmount(raw);
          debugPrint('[SCANNER]   Candidato: "$raw" → $value (mejor hasta ahora)');
        }
      }
    }
    debugPrint('[SCANNER] Fallback result: ${bestStr ?? "NINGUNO"} (valor: $bestValue)');
    return bestStr;
  }

  String _normalizeAmount(String raw) {
    if (raw.contains(',')) return raw.replaceAll('.', '').replaceAll(',', '.');
    return raw.replaceAll(',', '');
  }

  double? _parseAmount(String raw) {
    try { return double.parse(_normalizeAmount(raw)); } catch (_) { return null; }
  }

  /// Extrae fecha DD/MM/YYYY de las líneas OCR.
  /// Prioriza líneas con keyword FECHA, luego fallback a cualquier fecha válida.
  DateTime? _extractDate(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // 1. Buscar en líneas con keyword FECHA
    for (final line in lines) {
      final upper = line.toUpperCase();
      if (_dateKeywords.any((kw) => upper.contains(kw))) {
        final match = _dateRe.firstMatch(line);
        if (match != null) {
          final dt = _parseDate(match);
          if (dt != null) {
            debugPrint('[SCANNER] Fecha encontrada por keyword: $dt en "$line"');
            return dt;
          }
        }
      }
    }

    // 2. Fallback: primera fecha válida en cualquier línea
    for (final line in lines) {
      final match = _dateRe.firstMatch(line);
      if (match != null) {
        final dt = _parseDate(match);
        if (dt != null) {
          debugPrint('[SCANNER] Fecha encontrada por fallback: $dt en "$line"');
          return dt;
        }
      }
    }
    return null;
  }

  DateTime? _parseDate(RegExpMatch match) {
    try {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      var year = int.parse(match.group(3)!);
      if (year < 100) year += 2000; // 26 → 2026
      if (day < 1 || day > 31 || month < 1 || month > 12 || year < 2020 || year > 2030) {
        return null;
      }
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  /// Extrae hora HH:MM de las líneas OCR.
  /// Prioriza líneas con keyword HORA, luego fallback.
  String? _extractTime(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // 1. Líneas con keyword HORA
    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper.contains('HORA')) {
        final match = _timeRe.firstMatch(line);
        if (match != null) {
          final h = int.tryParse(match.group(1)!) ?? -1;
          final m = int.tryParse(match.group(2)!) ?? -1;
          if (h >= 0 && h <= 23 && m >= 0 && m <= 59) {
            final time = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
            debugPrint('[SCANNER] Hora encontrada: $time en "$line"');
            return time;
          }
        }
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────

  bool get _isEmbedded =>
      widget.onInvoiceScanned != null || widget.onAmountDetected != null;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWebFallback();
    if (_permissionPermanentlyDenied) return _buildPermissionScreen(permanent: true);
    if (_permissionDenied) return _buildPermissionScreen(permanent: false);

    final content = Stack(
      fit: StackFit.expand,
      children: [
        // ── Cámara ──
        if (_isInitialized && _controller != null)
          CameraPreview(_controller!)
        else
          _buildLoadingState(),

        // ── Máscara + marco + línea animada ──
        if (_isInitialized)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanLineAnim,
              builder: (_, __) => CustomPaint(
                painter: _ScanOverlayPainter(scanProgress: _scanLineAnim.value),
              ),
            ),
          ),

        // ── Header (solo en modo modal, no embebido) ──
        if (!_isEmbedded)
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _CircleBtn(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Escáner de Factura',
                            style: GoogleFonts.dmSans(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Enfoca el TOTAL de la factura',
                            style: GoogleFonts.dmSans(
                              fontSize: 12, color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isInitialized)
                      _CircleBtn(
                        icon: Icons.flash_auto_rounded,
                        onTap: () async {
                          final ctrl = _controller;
                          if (ctrl == null) return;
                          try {
                            await ctrl.setFlashMode(
                              ctrl.value.flashMode == FlashMode.off
                                  ? FlashMode.torch
                                  : FlashMode.off,
                            );
                            setState(() {});
                          } catch (_) {}
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

        // ── Controles embebidos (flash) ──
        if (_isEmbedded && _isInitialized)
          Positioned(
            top: 12, right: 16,
            child: _CircleBtn(
              icon: Icons.flash_auto_rounded,
              onTap: () async {
                final ctrl = _controller;
                if (ctrl == null) return;
                try {
                  await ctrl.setFlashMode(
                    ctrl.value.flashMode == FlashMode.off
                        ? FlashMode.torch
                        : FlashMode.off,
                  );
                  setState(() {});
                } catch (_) {}
              },
            ),
          ),

        // ── Guía para modo embebido ──
        if (_isEmbedded && _isInitialized)
          Positioned(
            top: 16, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Enfoca el TOTAL de la factura',
                  style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white70),
                ),
              ),
            ),
          ),

        // ── Etiquetas del marco ──
        if (_isInitialized)
          const Positioned.fill(child: _ScanLabels()),

        // ── Toast de estado ──
        if (_statusMsg != null)
          Positioned(
            bottom: 140,
            left: 32, right: 32,
            child: _StatusToast(message: _statusMsg!),
          ),

        // ── Botón de captura ──
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: Center(
            child: _CaptureButton(
              isProcessing: _isProcessing,
              onTap: _captureAndProcess,
            ),
          ),
        ),
      ],
    );

    // En modo embebido (tab), no envolver en Scaffold
    if (_isEmbedded) {
      return Container(color: Colors.black, child: content);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: content,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: _statusMsg != null
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                _statusMsg!,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 15, color: Colors.white70, height: 1.5),
              ),
            )
          : const CircularProgressIndicator(color: AppColors.green),
    );
  }

  Widget _buildPermissionScreen({required bool permanent}) {
    final body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.no_photography_rounded,
                    size: 36, color: AppColors.red),
              ),
              const SizedBox(height: 20),
              Text(
                'Permiso de cámara requerido',
                style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
              const SizedBox(height: 8),
              Text(
                permanent
                    ? 'Bloqueaste el permiso de cámara. Ve a Ajustes del sistema y actívalo manualmente para usar el escáner.'
                    : 'TasaVe necesita acceso a la cámara para escanear facturas y autocompletar el monto.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.text2, height: 1.5),
              ),
              const SizedBox(height: 24),
              if (permanent)
                GestureDetector(
                  onTap: () => openAppSettings(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Abrir Ajustes',
                      style: GoogleFonts.dmSans(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _permissionDenied = false;
                    });
                    _initCamera();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Permitir acceso',
                      style: GoogleFonts.dmSans(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
    );

    if (_isEmbedded) return Container(color: AppColors.bg, child: body);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Escáner de Factura',
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
      ),
      body: body,
    );
  }

  Widget _buildWebFallback() {
    final body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.no_photography_rounded,
                    size: 36, color: AppColors.text3),
              ),
              const SizedBox(height: 20),
              Text(
                'Escáner no disponible en web',
                style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
              const SizedBox(height: 8),
              Text(
                'Usa la app móvil para escanear facturas y autocompletar el monto.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.text2, height: 1.5),
              ),
            ],
          ),
        ),
    );

    if (_isEmbedded) return Container(color: AppColors.bg, child: body);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Escáner de Factura',
            style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
      ),
      body: body,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PAINTER: Máscara oscura + marco + esquinas + línea de escaneo
// ─────────────────────────────────────────────────────────────────

class _ScanOverlayPainter extends CustomPainter {
  final double scanProgress; // 0.0 → 1.0

  const _ScanOverlayPainter({required this.scanProgress});

  static const _frameW = 300.0;
  static const _frameH = 200.0;
  static const _cornerLen = 28.0;
  static const _radius = Radius.circular(12);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 20;

    final frameRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: _frameW,
      height: _frameH,
    );

    // ── Máscara oscura con recorte ──
    final maskPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55);
    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frameRect, _radius));
    maskPath.fillType = PathFillType.evenOdd;
    canvas.drawPath(maskPath, maskPaint);

    // ── Borde del marco (blanco semi-transparente) ──
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, _radius),
      borderPaint,
    );

    // ── Esquinas verdes ──
    final cornerPaint = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final l = frameRect.left, t = frameRect.top;
    final r = frameRect.right, b = frameRect.bottom;

    // TL
    canvas.drawLine(Offset(l, t + _cornerLen), Offset(l, t), cornerPaint);
    canvas.drawLine(Offset(l, t), Offset(l + _cornerLen, t), cornerPaint);
    // TR
    canvas.drawLine(Offset(r - _cornerLen, t), Offset(r, t), cornerPaint);
    canvas.drawLine(Offset(r, t), Offset(r, t + _cornerLen), cornerPaint);
    // BL
    canvas.drawLine(Offset(l, b - _cornerLen), Offset(l, b), cornerPaint);
    canvas.drawLine(Offset(l, b), Offset(l + _cornerLen, b), cornerPaint);
    // BR
    canvas.drawLine(Offset(r - _cornerLen, b), Offset(r, b), cornerPaint);
    canvas.drawLine(Offset(r, b), Offset(r, b - _cornerLen), cornerPaint);

    // ── Línea de escaneo animada ──
    final scanY = frameRect.top + frameRect.height * scanProgress;
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.green.withValues(alpha: 0),
          AppColors.green.withValues(alpha: 0.9),
          AppColors.green.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTRB(frameRect.left, scanY, frameRect.right, scanY + 1));
    canvas.drawLine(
      Offset(frameRect.left + 8, scanY),
      Offset(frameRect.right - 8, scanY),
      linePaint..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter old) =>
      old.scanProgress != scanProgress;
}

// ─────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────

class _ScanLabels extends StatelessWidget {
  const _ScanLabels();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final cy = constraints.maxHeight / 2 - 20;
      final frameTop = cy - 100.0;
      return Stack(
        children: [
          Positioned(
            top: frameTop - 32,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.green.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Busca la línea TOTAL',
                  style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.green,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _StatusToast extends StatelessWidget {
  final String message;
  const _StatusToast({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(
            fontSize: 13, color: Colors.white, height: 1.4),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onTap;
  const _CaptureButton({required this.isProcessing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anillo exterior
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isProcessing
                    ? Colors.white30
                    : AppColors.green,
                width: 3,
              ),
            ),
          ),
          // Disco interior
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: isProcessing ? 52 : 62,
            height: isProcessing ? 52 : 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isProcessing ? Colors.white24 : Colors.white,
            ),
            child: isProcessing
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      color: AppColors.green,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(Icons.camera_alt_rounded,
                    color: AppColors.text, size: 28),
          ),
        ],
      ),
    );
  }
}
