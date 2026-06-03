import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:torch_light/torch_light.dart';
import '../providers/tasa_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ScannerScreen — entry point (detecta plataforma)
// ─────────────────────────────────────────────────────────────────────────────

class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) return const _ScannerWebFallback();
    return const _ScannerMobile();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Pantalla de descarga para Web
// ─────────────────────────────────────────────────────────────────────────────

class _ScannerWebFallback extends StatelessWidget {
  const _ScannerWebFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE53935).withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.camera_alt_outlined, size: 44,
                            color: Color(0xFFE53935)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Escáner de precios',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text(
                      'Apunta la cámara a cualquier etiqueta\nde precio en Bs o \$ y convertimos\nal instante a USD, EUR y USDT.',
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(Icons.smartphone,
                                  size: 20, color: Color(0xFFE53935)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Disponible en la app móvil',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface)),
                                const SizedBox(height: 2),
                                Text(
                                  'Descarga TasaVe en iOS o Android\npara usar el escáner con cámara.',
                                  style: TextStyle(
                                      fontSize: 11,
                                      height: 1.5,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StoreButton(
                            icon: Icons.apple,
                            label: 'App Store',
                            sublabel: 'iOS',
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StoreButton(
                            icon: Icons.android,
                            label: 'Google Play',
                            sublabel: 'Android',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Escáner Móvil Real
// ─────────────────────────────────────────────────────────────────────────────

class _ScannerMobile extends ConsumerStatefulWidget {
  const _ScannerMobile();

  @override
  ConsumerState<_ScannerMobile> createState() => _ScannerMobileState();
}

class _ScannerMobileState extends ConsumerState<_ScannerMobile>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _cameraReady = false;
  bool _torchOn = false;
  bool _torchAvailable = false;
  bool _isProcessing = false;

  // Resultado del OCR
  double? _detectedValue;   // número detectado
  String? _detectedMode;    // 'bs' o 'usd'

  // Formato
  String _formatBs(double v) {
    final rounded = (v * 100).round();
    final intPart = rounded ~/ 100;
    final decPart = (rounded % 100).toString().padLeft(2, '0');
    final s = intPart.toString();
    final buf = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (c > 0 && c % 3 == 0) buf.write('.');
      buf.write(s[i]);
      c++;
    }
    return '${buf.toString().split('').reversed.join()},$decPart';
  }

  String _formatUsd(double v) {
    final rounded = (v * 100).round();
    final intPart = rounded ~/ 100;
    final decPart = (rounded % 100).toString().padLeft(2, '0');
    return '$intPart,$decPart';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _checkTorch();
  }

  Future<void> _checkTorch() async {
    try {
      final available = await TorchLight.isTorchAvailable();
      if (mounted) setState(() => _torchAvailable = available);
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Preferir cámara trasera
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      if (mounted) setState(() => _cameraReady = true);

      // Iniciar stream de imágenes para OCR
      await _controller!.startImageStream(_processFrame);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  final TextRecognizer _recognizer = TextRecognizer();
  DateTime _lastProcess = DateTime.now();

  Future<void> _processFrame(CameraImage image) async {
    // Throttle: máximo 1 frame por segundo
    final now = DateTime.now();
    if (now.difference(_lastProcess).inMilliseconds < 1000) return;
    if (_isProcessing) return;
    _lastProcess = now;
    _isProcessing = true;

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final recognized = await _recognizer.processImage(inputImage);
      _parseOcrResult(recognized.text);
    } catch (e) {
      debugPrint('OCR error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    final camera = _controller?.description;
    if (camera == null) return null;

    final rotation = InputImageRotationValue.fromRawValue(
            camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // ── Detección de precios ────────────────────────────────────────────────────
  // Patrones soportados:
  //   Bs: "Bs 12.345,67" | "12.345,67 Bs" | "Bs. 1000" | solo número grande
  //   USD: "$ 12,34" | "12,34 $" | "USD 12" | "12 USD"
  void _parseOcrResult(String text) {
    if (text.trim().isEmpty) return;

    // Intentar detección de Bs
    final bsPattern = RegExp(
      r'(?:Bs\.?\s*)([\d.,]+)|'
      r'([\d.,]+)\s*(?:Bs\.?)',
      caseSensitive: false,
    );
    final usdPattern = RegExp(
      r'(?:\$\s*)([\d.,]+)|'
      r'([\d.,]+)\s*(?:\$)|'
      r'(?:USD\s*)([\d.,]+)|'
      r'([\d.,]+)\s*(?:USD)',
      caseSensitive: false,
    );

    double? value;
    String? mode;

    // Buscar Bs primero
    final bsMatch = bsPattern.firstMatch(text);
    if (bsMatch != null) {
      final raw = (bsMatch.group(1) ?? bsMatch.group(2) ?? '').trim();
      value = _parseLocalNumber(raw);
      mode = 'bs';
    }

    // Si no encontró Bs, buscar USD
    if (value == null) {
      final usdMatch = usdPattern.firstMatch(text);
      if (usdMatch != null) {
        final raw = (usdMatch.group(1) ??
                usdMatch.group(2) ??
                usdMatch.group(3) ??
                usdMatch.group(4) ??
                '')
            .trim();
        value = _parseLocalNumber(raw);
        mode = 'usd';
      }
    }

    if (value != null && value > 0 && mounted) {
      setState(() {
        _detectedValue = value;
        _detectedMode = mode;
      });
    }
  }

  // Parsea números venezolanos: "27.898,50" → 27898.50, "12,34" → 12.34
  double? _parseLocalNumber(String raw) {
    if (raw.isEmpty) return null;
    // Si tiene punto Y coma → punto=miles, coma=decimal
    if (raw.contains('.') && raw.contains(',')) {
      return double.tryParse(raw.replaceAll('.', '').replaceAll(',', '.'));
    }
    // Solo coma → decimal
    if (raw.contains(',') && !raw.contains('.')) {
      return double.tryParse(raw.replaceAll(',', '.'));
    }
    // Solo punto
    if (raw.contains('.')) {
      // Si el punto separa 3 dígitos al final y no hay más → miles
      final parts = raw.split('.');
      if (parts.length == 2 && parts[1].length == 3) {
        return double.tryParse(raw.replaceAll('.', ''));
      }
      return double.tryParse(raw);
    }
    return double.tryParse(raw);
  }

  Future<void> _toggleTorch() async {
    if (!_torchAvailable) return;
    try {
      if (_torchOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      setState(() => _torchOn = !_torchOn);
    } catch (e) {
      debugPrint('Torch error: $e');
    }
  }

  void _resetScan() {
    setState(() {
      _detectedValue = null;
      _detectedMode = null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _recognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasaAsync = ref.watch(tasaProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Preview de cámara ──────────────────────────────────────────
            if (_cameraReady && _controller != null)
              Positioned.fill(
                child: CameraPreview(_controller!),
              )
            else
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                            color: Color(0xFFE53935)),
                        const SizedBox(height: 16),
                        Text('Iniciando cámara...',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Overlay oscuro superior ──────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Header ────────────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('tasave',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.5,
                            color: Color(0xFFE53935))),
                    Row(
                      children: [
                        const Text('Escáner',
                            style: TextStyle(
                                fontSize: 10, color: Colors.white54)),
                        if (_torchAvailable) ...[
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _toggleTorch,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _torchOn
                                    ? const Color(0xFFE53935)
                                    : Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _torchOn
                                    ? Icons.flashlight_on
                                    : Icons.flashlight_off,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Marco de escaneo (viewfinder) ────────────────────────────
            if (_detectedValue == null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ScanFrame(),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Apunta a una etiqueta de precio (Bs o \$)',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Resultado del OCR ────────────────────────────────────────
            if (_detectedValue != null)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _ResultPanel(
                  value: _detectedValue!,
                  mode: _detectedMode ?? 'bs',
                  tasaAsync: tasaAsync,
                  formatBs: _formatBs,
                  formatUsd: _formatUsd,
                  onReset: _resetScan,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Marco de escaneo animado
// ─────────────────────────────────────────────────────────────────────────────

class _ScanFrame extends StatefulWidget {
  @override
  State<_ScanFrame> createState() => _ScanFrameState();
}

class _ScanFrameState extends State<_ScanFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scan;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _scan = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scan,
      builder: (_, __) {
        return SizedBox(
          width: 260,
          height: 160,
          child: CustomPaint(
            painter: _FramePainter(scanProgress: _scan.value),
          ),
        );
      },
    );
  }
}

class _FramePainter extends CustomPainter {
  final double scanProgress;
  _FramePainter({required this.scanProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final cornerPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const corner = 24.0;

    // Esquinas
    final corners = [
      // TL
      [Offset(0, corner), Offset(0, 0), Offset(corner, 0)],
      // TR
      [
        Offset(size.width - corner, 0),
        Offset(size.width, 0),
        Offset(size.width, corner)
      ],
      // BL
      [
        Offset(0, size.height - corner),
        Offset(0, size.height),
        Offset(corner, size.height)
      ],
      // BR
      [
        Offset(size.width - corner, size.height),
        Offset(size.width, size.height),
        Offset(size.width, size.height - corner)
      ],
    ];

    for (final pts in corners) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, cornerPaint);
    }

    // Línea de escaneo
    final scanY = size.height * scanProgress;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFE53935).withValues(alpha: 0.8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 1, size.width, 2));
    canvas.drawLine(
        Offset(8, scanY), Offset(size.width - 8, scanY), scanPaint..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.scanProgress != scanProgress;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Panel de resultados
// ─────────────────────────────────────────────────────────────────────────────

class _ResultPanel extends StatelessWidget {
  final double value;
  final String mode; // 'bs' o 'usd'
  final AsyncValue tasaAsync;
  final String Function(double) formatBs;
  final String Function(double) formatUsd;
  final VoidCallback onReset;

  const _ResultPanel({
    required this.value,
    required this.mode,
    required this.tasaAsync,
    required this.formatBs,
    required this.formatUsd,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE53935).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: tasaAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFE53935))),
        error: (e, _) => Text('Error al cargar tasa',
            style: const TextStyle(color: Colors.white54)),
        data: (tasa) {
          final rate = (tasa.usd as num?)?.toDouble() ?? 0.0;
          final eurRate = (tasa.eur as num?)?.toDouble() ?? 0.0;

          // Calcular conversiones según el modo detectado
          late final double bsAmount;
          late final double usdAmount;
          late final double eurAmount;
          late final double usdtAmount;

          if (mode == 'bs') {
            bsAmount = value;
            usdAmount = rate > 0 ? value / rate : 0;
            eurAmount = eurRate > 0 ? value / eurRate : 0;
            usdtAmount = usdAmount; // USDT ≈ USD
          } else {
            // mode == 'usd'
            usdAmount = value;
            bsAmount = value * rate;
            eurAmount = rate > 0 && eurRate > 0 ? value * rate / eurRate : 0;
            usdtAmount = value;
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Precio detectado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFE53935).withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      mode == 'bs'
                          ? 'Bs ${formatBs(value)}'
                          : '\$ ${formatUsd(value)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('detectado',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.4))),
                  const Spacer(),
                  GestureDetector(
                    onTap: onReset,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.refresh,
                          size: 16, color: Colors.white70),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Cards de conversión
              Row(
                children: [
                  if (mode == 'bs') ...[
                    _ConvCard(
                        flag: '🇺🇸',
                        label: 'USD',
                        value: '\$ ${formatUsd(usdAmount)}'),
                    const SizedBox(width: 8),
                    _ConvCard(
                        flag: '🇪🇺',
                        label: 'EUR',
                        value: '€ ${formatUsd(eurAmount)}'),
                    const SizedBox(width: 8),
                    _ConvCard(
                        flag: '⚡',
                        label: 'USDT',
                        value: '\$ ${formatUsd(usdtAmount)}'),
                  ] else ...[
                    _ConvCard(
                        flag: '🇻🇪',
                        label: 'Bs',
                        value: 'Bs ${formatBs(bsAmount)}'),
                    const SizedBox(width: 8),
                    _ConvCard(
                        flag: '🇪🇺',
                        label: 'EUR',
                        value: '€ ${formatUsd(eurAmount)}'),
                    const SizedBox(width: 8),
                    _ConvCard(
                        flag: '⚡',
                        label: 'USDT',
                        value: '\$ ${formatUsd(usdtAmount)}'),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Tasa usada
              Text(
                'Tasa BCV: Bs ${formatBs(rate)} / USD',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.3)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConvCard extends StatelessWidget {
  final String flag;
  final String label;
  final String value;

  const _ConvCard(
      {required this.flag, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.5))),
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Widgets compartidos
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('tasave',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5,
                  color: theme.colorScheme.primary)),
          Text('Escáner',
              style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}

class _StoreButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _StoreButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurface),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sublabel,
                    style: TextStyle(
                        fontSize: 9,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4))),
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
