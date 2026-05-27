import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
import '../../core/constants/app_constants.dart';
import '../state/qr_pay_provider.dart';

class QrPayScreen extends ConsumerStatefulWidget {
  const QrPayScreen({super.key});

  @override
  ConsumerState<QrPayScreen> createState() => _QrPayScreenState();
}

class _QrPayScreenState extends ConsumerState<QrPayScreen> {
  bool _editing = false;

  // Controladores del formulario
  final _cedulaCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  String _bancoCodigo = '0134';
  String _prefijoCedula = 'V';
  final _formKey = GlobalKey<FormState>();

  static const _shadow = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 10,
    offset: Offset(0, 4),
  );

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _startEditing(QrPayState state) {
    _bancoCodigo = state.bancoCodigo;
    _prefijoCedula = state.prefijoCedula;
    _cedulaCtrl.text = state.cedula;
    _telefonoCtrl.text = state.telefonoDisplay;
    setState(() => _editing = true);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(qrPayProvider.notifier).save(
          bancoCodigo: _bancoCodigo,
          cedula: _cedulaCtrl.text.trim(),
          prefijoCedula: _prefijoCedula,
          rawTelefono: _telefonoCtrl.text.trim(),
        );
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final qrState = ref.watch(qrPayProvider);

    if (!qrState.isLoaded) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Pago Móvil QR',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        actions: [
          if (qrState.isComplete && !_editing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: TextButton(
                onPressed: () => _startEditing(qrState),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(
                  'Editar',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!qrState.isComplete || _editing)
                _buildForm(qrState)
              else
                _buildQrView(qrState),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FORMULARIO
  // ─────────────────────────────────────────────
  Widget _buildForm(QrPayState state) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instrucción
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_rounded,
                    color: AppColors.green, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Configura tus datos para generar tu QR de Pago Móvil.',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: AppColors.green, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Banco ──
          _FieldLabel('Banco'),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [_shadow],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _bancoCodigo,
                isExpanded: true,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.text,
                    fontWeight: FontWeight.w500),
                items: AppConstants.venezuelanBanks.map((b) {
                  return DropdownMenuItem(
                    value: b.code,
                    child: Text('${b.name}  (${b.code})'),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => _bancoCodigo = v ?? _bancoCodigo),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Cédula ──
          _FieldLabel('Cédula / RIF'),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prefijo
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [_shadow],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _prefijoCedula,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.text2),
                    items: ['V', 'E', 'J'].map((p) {
                      return DropdownMenuItem(
                          value: p, child: Text('$p-'));
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _prefijoCedula = v ?? _prefijoCedula),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StyledField(
                  controller: _cedulaCtrl,
                  hint: 'Ej: 12345678',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (v.length < 6) return 'Mínimo 6 dígitos';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Teléfono ──
          _FieldLabel('Teléfono (ej: 04121234567 o 4121234567)'),
          const SizedBox(height: 5),
          _StyledField(
            controller: _telefonoCtrl,
            hint: 'Ej: 04121234567',
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              final digits = v.trim().replaceAll(RegExp(r'\D'), '');
              final normalized = digits.startsWith('58') && digits.length >= 12
                  ? digits.substring(2)
                  : digits.startsWith('0') && digits.length >= 10
                      ? digits.substring(1)
                      : digits;
              if (normalized.length < 9 || normalized.length > 10) {
                return 'Formato inválido (ej: 04121234567)';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // ── Botón Guardar ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
              label: Text(
                'GENERAR QR',
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _guardar,
            ),
          ),

          if (_editing) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => setState(() => _editing = false),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.text3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // VISTA QR
  // ─────────────────────────────────────────────
  Widget _buildQrView(QrPayState state) {
    final banco = AppConstants.venezuelanBanks
        .firstWhere((b) => b.code == state.bancoCodigo,
            orElse: () =>
                const VenezuelanBank(code: '', name: 'Banco'))
        .name;

    return Column(
      children: [
        // ── QR Card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [_shadow],
          ),
          child: Column(
            children: [
              Text(
                'Escanear para pagar',
                style: GoogleFonts.dmSans(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    color: AppColors.text3),
              ),
              const SizedBox(height: 14),
              QrImageView(
                data: state.qrPayload,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Theme.of(context).colorScheme.surface,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.text,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 14),
              // Datos debajo del QR
              _DataRow(icon: Icons.account_balance_rounded, label: banco,
                  sub: state.bancoCodigo),
              const SizedBox(height: 6),
              _DataRow(icon: Icons.badge_rounded,
                  label: '${state.prefijoCedula}-${state.cedula}',
                  sub: 'Cédula / RIF'),
              const SizedBox(height: 6),
              _DataRow(icon: Icons.phone_android_rounded,
                  label: state.telefonoDisplay,
                  sub: 'Teléfono'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Payload técnico (solo lectura) ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [_shadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CADENA QR',
                style: GoogleFonts.dmSans(
                    fontSize: 11, letterSpacing: 1.5, color: AppColors.text3),
              ),
              const SizedBox(height: 6),
              Text(
                state.qrPayload,
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.text2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Botones de acción ──
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                icon: Icons.copy_rounded,
                label: 'COPIAR',
                color: AppColors.green,
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: state.textoCompartir));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Copiado al portapapeles',
                        style: GoogleFonts.dmSans(fontSize: 12)),
                    backgroundColor: AppColors.green,
                    duration: const Duration(seconds: 2),
                  ));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionBtn(
                icon: Icons.share_rounded,
                label: 'WHATSAPP',
                color: const Color(0xFF25D366),
                onTap: () => Share.share(state.textoCompartir,
                    subject: 'Mi Pago Móvil'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Borrar datos ──
        TextButton.icon(
          icon: const Icon(Icons.delete_outline_rounded,
              size: 14, color: AppColors.red),
          label: Text('Borrar mis datos',
              style:
                  GoogleFonts.dmSans(fontSize: 12, color: AppColors.red)),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: Theme.of(ctx).colorScheme.surface,
                title: Text('¿Borrar datos?',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                content: Text(
                    'Se eliminarán tu banco, cédula y teléfono guardados.',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: AppColors.text2)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancelar',
                        style: GoogleFonts.dmSans(
                            color: AppColors.text3)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Borrar',
                        style: GoogleFonts.dmSans(
                            color: AppColors.red,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              ref.read(qrPayProvider.notifier).clear();
            }
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
          fontSize: 11, letterSpacing: 1.2, color: AppColors.text3),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(
              fontSize: 12, color: AppColors.text3),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.green, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.red)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.red, width: 1.5)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  const _DataRow(
      {required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppColors.green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              Text(sub,
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.text3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}
