import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../providers/tasa_provider.dart';
import '../../utils/formatters.dart';

// ── Provider ──────────────────────────────────────────────

class PaymentProfile {
  final String id;
  final String name;
  final String bank;
  final String accountNumber;
  final String cedula;
  final String phone;
  final String zelle;
  final String notes;

  const PaymentProfile({
    required this.id,
    required this.name,
    this.bank = '',
    this.accountNumber = '',
    this.cedula = '',
    this.phone = '',
    this.zelle = '',
    this.notes = '',
  });

  PaymentProfile copyWith({
    String? name,
    String? bank,
    String? accountNumber,
    String? cedula,
    String? phone,
    String? zelle,
    String? notes,
  }) => PaymentProfile(
    id: id,
    name: name ?? this.name,
    bank: bank ?? this.bank,
    accountNumber: accountNumber ?? this.accountNumber,
    cedula: cedula ?? this.cedula,
    phone: phone ?? this.phone,
    zelle: zelle ?? this.zelle,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'bank': bank,
    'accountNumber': accountNumber, 'cedula': cedula,
    'phone': phone, 'zelle': zelle, 'notes': notes,
  };

  factory PaymentProfile.fromJson(Map<String, dynamic> j) => PaymentProfile(
    id: j['id'] as String,
    name: j['name'] as String,
    bank: j['bank'] as String? ?? '',
    accountNumber: j['accountNumber'] as String? ?? '',
    cedula: j['cedula'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    zelle: j['zelle'] as String? ?? '',
    notes: j['notes'] as String? ?? '',
  );

  /// Genera el texto compartible para WhatsApp
  String toShareText({double? bcvRate, double? amount}) {
    final lines = <String>[];
    lines.add('💳 *$name*');
    if (bank.isNotEmpty) lines.add('🏦 Banco: $bank');
    if (accountNumber.isNotEmpty) lines.add('📋 Cuenta: $accountNumber');
    if (cedula.isNotEmpty) lines.add('🪪 Cédula: $cedula');
    if (phone.isNotEmpty) lines.add('📱 Pago móvil: $phone');
    if (zelle.isNotEmpty) lines.add('💵 Zelle: $zelle');
    if (bcvRate != null && amount != null && amount > 0) {
      final bs = amount * bcvRate;
      lines.add('');
      lines.add('💱 Cálculo: \$${amount.toStringAsFixed(2)} × ${Formatters.formatRate(bcvRate)} = *${Formatters.formatCurrency(bs)} Bs*');
    }
    if (notes.isNotEmpty) lines.add('📝 $notes');
    lines.add('');
    lines.add('_Enviado desde CalculaYa • calculaya-app.pages.dev_');
    return lines.join('\n');
  }
}

class PerfilesNotifier extends StateNotifier<List<PaymentProfile>> {
  static const _key = 'payment_profiles';

  PerfilesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      state = list.map((e) => PaymentProfile.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.map((p) => p.toJson()).toList()));
  }

  Future<void> add(PaymentProfile profile) async {
    state = [...state, profile];
    await _save();
  }

  Future<void> update(PaymentProfile profile) async {
    state = state.map((p) => p.id == profile.id ? profile : p).toList();
    await _save();
  }

  Future<void> delete(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _save();
  }
}

final perfilesProvider = StateNotifierProvider<PerfilesNotifier, List<PaymentProfile>>((ref) {
  return PerfilesNotifier();
});

// ── Screen ────────────────────────────────────────────────

class PerfilesScreen extends ConsumerWidget {
  const PerfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(perfilesProvider);
    final tasaAsync = ref.watch(tasaProvider);
    final bcvRate = tasaAsync.valueOrNull?.bcvUsd ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.bebasNeue(fontSize: 24, letterSpacing: 2),
                      children: const [
                        TextSpan(text: 'PERFILES', style: TextStyle(color: AppColors.text)),
                        TextSpan(text: ' DE PAGO', style: TextStyle(color: AppColors.green)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showEditSheet(context, ref, null, bcvRate),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+ NUEVO',
                        style: GoogleFonts.spaceMono(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: const Color(0xFF050505),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Lista o empty state ──
            Expanded(
              child: profiles.isEmpty
                  ? _EmptyState(onTap: () => _showEditSheet(context, ref, null, bcvRate))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
                      itemCount: profiles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ProfileCard(
                        profile: profiles[i],
                        bcvRate: bcvRate,
                        onEdit: () => _showEditSheet(context, ref, profiles[i], bcvRate),
                        onDelete: () => ref.read(perfilesProvider.notifier).delete(profiles[i].id),
                        onShare: () => _shareProfile(context, profiles[i], bcvRate),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareProfile(BuildContext context, PaymentProfile profile, double bcvRate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.s2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ShareSheet(profile: profile, bcvRate: bcvRate),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, PaymentProfile? existing, double bcvRate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.s2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditSheet(
        existing: existing,
        onSave: (profile) {
          if (existing == null) {
            ref.read(perfilesProvider.notifier).add(profile);
          } else {
            ref.read(perfilesProvider.notifier).update(profile);
          }
        },
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final PaymentProfile profile;
  final double bcvRate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _ProfileCard({
    required this.profile,
    required this.bcvRate,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.s2,
        borderRadius: BorderRadius.circular(AppColors.r2),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // ── Title row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.greenDim,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.credit_card_rounded, color: AppColors.green, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    profile.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.text3),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.red),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          // ── Fields ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              children: [
                if (profile.bank.isNotEmpty) _FieldRow(icon: Icons.account_balance_rounded, label: 'Banco', value: profile.bank),
                if (profile.accountNumber.isNotEmpty) _FieldRow(icon: Icons.numbers_rounded, label: 'Cuenta', value: profile.accountNumber),
                if (profile.cedula.isNotEmpty) _FieldRow(icon: Icons.badge_outlined, label: 'Cédula', value: profile.cedula),
                if (profile.phone.isNotEmpty) _FieldRow(icon: Icons.phone_android_rounded, label: 'Pago móvil', value: profile.phone),
                if (profile.zelle.isNotEmpty) _FieldRow(icon: Icons.attach_money_rounded, label: 'Zelle', value: profile.zelle),
                if (profile.notes.isNotEmpty) _FieldRow(icon: Icons.notes_rounded, label: 'Nota', value: profile.notes),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          // ── Share button ──
          GestureDetector(
            onTap: onShare,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.share_rounded, size: 14, color: AppColors.whatsappGreen),
                  const SizedBox(width: 6),
                  Text(
                    'COMPARTIR POR WHATSAPP',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: AppColors.whatsappGreen, letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _FieldRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.text3),
          const SizedBox(width: 8),
          Text('$label: ', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text3)),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.text2),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: value)),
            child: const Icon(Icons.copy_rounded, size: 12, color: AppColors.text3),
          ),
        ],
      ),
    );
  }
}

// ── Share Sheet ───────────────────────────────────────────

class _ShareSheet extends StatefulWidget {
  final PaymentProfile profile;
  final double bcvRate;

  const _ShareSheet({required this.profile, required this.bcvRate});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _amountCtrl = TextEditingController();
  double _amount = 0;

  @override
  Widget build(BuildContext context) {
    final text = widget.profile.toShareText(
      bcvRate: widget.bcvRate > 0 ? widget.bcvRate : null,
      amount: _amount > 0 ? _amount : null,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Text('COMPARTIR PERFIL', style: GoogleFonts.spaceMono(fontSize: 9, letterSpacing: 2, color: AppColors.text3)),
          const SizedBox(height: 12),
          // Monto opcional
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.bebasNeue(fontSize: 22, color: AppColors.text),
            decoration: InputDecoration(
              hintText: 'Monto en \$ (opcional)',
              hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text3),
              prefixText: '\$ ',
              prefixStyle: GoogleFonts.spaceMono(color: AppColors.green),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.green)),
            ),
            onChanged: (v) => setState(() => _amount = double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 14),
          // Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.s3,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(text, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text2, height: 1.5)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: Text('COPIAR', style: GoogleFonts.spaceMono(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.border2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copiado al portapapeles', style: GoogleFonts.dmSans(fontSize: 12)),
                        backgroundColor: AppColors.s3,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share_rounded, size: 15),
                  label: Text('WHATSAPP', style: GoogleFonts.spaceMono(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whatsappGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Texto copiado — ábrelo en WhatsApp', style: GoogleFonts.dmSans(fontSize: 12)),
                        backgroundColor: AppColors.whatsappGreen,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Edit Sheet ────────────────────────────────────────────

class _EditSheet extends StatefulWidget {
  final PaymentProfile? existing;
  final ValueChanged<PaymentProfile> onSave;

  const _EditSheet({this.existing, required this.onSave});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _name, _bank, _account, _cedula, _phone, _zelle, _notes;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _bank = TextEditingController(text: p?.bank ?? '');
    _account = TextEditingController(text: p?.accountNumber ?? '');
    _cedula = TextEditingController(text: p?.cedula ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
    _zelle = TextEditingController(text: p?.zelle ?? '');
    _notes = TextEditingController(text: p?.notes ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _bank, _account, _cedula, _phone, _zelle, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.existing == null ? 'NUEVO PERFIL' : 'EDITAR PERFIL',
            style: GoogleFonts.spaceMono(fontSize: 9, letterSpacing: 2, color: AppColors.text3),
          ),
          const SizedBox(height: 14),
          _Field('Nombre del perfil *', _name, hint: 'Ej: Mi cuenta BDV'),
          _Field('Banco', _bank, hint: 'Ej: Banco de Venezuela'),
          _Field('Número de cuenta', _account, hint: '0102-XXXX-XXXX'),
          _Field('Cédula', _cedula, hint: 'V-12345678'),
          _Field('Pago móvil', _phone, hint: '0414-XXXXXXX', keyboardType: TextInputType.phone),
          _Field('Zelle (email o teléfono)', _zelle, hint: 'correo@email.com'),
          _Field('Nota adicional', _notes, hint: 'Opcional'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: const Color(0xFF050505),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                if (_name.text.trim().isEmpty) return;
                final profile = PaymentProfile(
                  id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _name.text.trim(),
                  bank: _bank.text.trim(),
                  accountNumber: _account.text.trim(),
                  cedula: _cedula.text.trim(),
                  phone: _phone.text.trim(),
                  zelle: _zelle.text.trim(),
                  notes: _notes.text.trim(),
                );
                widget.onSave(profile);
                Navigator.pop(context);
              },
              child: Text('GUARDAR', style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _Field(String label, TextEditingController ctrl, {String hint = '', TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text3),
          hintStyle: GoogleFonts.dmSans(fontSize: 12, color: AppColors.text3),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.green)),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.s2, shape: BoxShape.circle),
            child: const Icon(Icons.credit_card_rounded, color: AppColors.green, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Sin perfiles de pago', style: GoogleFonts.bebasNeue(fontSize: 20, color: AppColors.text, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text('Crea perfiles para compartir\ntus datos bancarios rápidamente',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.text3, height: 1.5)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('CREAR PRIMER PERFIL',
                style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF050505))),
            ),
          ),
        ],
      ),
    );
  }
}
