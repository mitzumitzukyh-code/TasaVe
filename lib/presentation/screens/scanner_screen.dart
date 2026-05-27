import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
import '../../data/models/scanned_invoice.dart';
import '../../data/models/tasa_model.dart';
import '../../utils/formatters.dart';
import '../../core/constants/subscription_constants.dart';
import '../providers/subscription_provider.dart';
import '../providers/tasa_provider.dart';
import '../providers/history_provider.dart';
import '../providers/scanned_invoices_provider.dart';
import '../providers/shell_provider.dart';
import '../state/calculator_provider.dart';
import '../widgets/invoice_scanner_view.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _isScanning = false;

  /// Busca la tasa BCV para una fecha específica en el historial.
  /// Si no encuentra la fecha exacta, usa la más cercana anterior.
  double _rateForDate(DateTime? date, List<TasaHistoryEntry> history, double currentRate) {
    if (date == null || history.isEmpty) return currentRate;
    final target = DateTime(date.year, date.month, date.day);
    TasaHistoryEntry? best;
    for (final entry in history) {
      final entryDay = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDay == target) return entry.bcvUsd;
      if (entryDay.isBefore(target)) {
        if (best == null || entryDay.isAfter(DateTime(best.date.year, best.date.month, best.date.day))) {
          best = entry;
        }
      }
    }
    return best?.bcvUsd ?? currentRate;
  }

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(scannedInvoicesProvider);
    final tasa = ref.watch(tasaProvider).valueOrNull;
    final bcvRate = tasa?.bcvUsd ?? 0;
    final historyAsync = ref.watch(historyProvider(90));
    final history = historyAsync.valueOrNull ?? [];
    final notifier = ref.read(scannedInvoicesProvider.notifier);
    final totalBs = notifier.totalBs;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Escáner de Factura',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        actions: [
          if (invoices.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white70),
              tooltip: 'Compartir',
              onPressed: () => _shareAllInvoices(invoices, totalBs, bcvRate, history),
            ),
          if (invoices.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white70),
              tooltip: 'Borrar todas',
              onPressed: () => _confirmClearAll(context, notifier),
            ),
        ],
      ),
      body: _isScanning
          ? _buildScannerView()
          : _buildInvoiceList(invoices, totalBs, bcvRate, history),
      floatingActionButton: !_isScanning
          ? FloatingActionButton.extended(
              heroTag: 'scanner_fab',
              onPressed: () => _startScan(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
              label: Text(
                'Escanear',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  void _startScan(BuildContext context) {
    final isPremium = ref.read(isPremiumProvider);
    final storage = ref.read(localStorageProvider);
    if (!isPremium &&
        storage.dailyScanCount >= SubscriptionConstants.freeScannerDailyLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Límite gratis: ${SubscriptionConstants.freeScannerDailyLimit} escaneos/día. Pásate a Pro.',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      ref.read(shellTabProvider.notifier).state = 3;
      return;
    }
    setState(() => _isScanning = true);
  }

  // ── Scanner Camera View ──────────────────────────────────────

  Widget _buildScannerView() {
    return Column(
      children: [
        Expanded(
          child: InvoiceScannerView(
            onInvoiceScanned: (result) async {
              if (result.amountBs > 0) {
                final invoice = ScannedInvoice(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  amountBs: result.amountBs,
                  scannedAt: DateTime.now(),
                  invoiceDate: result.invoiceDate,
                  invoiceTime: result.invoiceTime,
                );
                ref.read(scannedInvoicesProvider.notifier).add(invoice);
                if (!ref.read(isPremiumProvider)) {
                  await ref.read(localStorageProvider).incrementDailyScanCount();
                }
              }
              setState(() => _isScanning = false);
            },
          ),
        ),
        // Cancel bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _isScanning = false),
                icon: const Icon(Icons.close_rounded),
                label: Text(
                  'CANCELAR',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Invoice List View ────────────────────────────────────────

  Widget _buildInvoiceList(
    List<ScannedInvoice> invoices,
    double totalBs,
    double bcvRate,
    List<TasaHistoryEntry> history,
  ) {
    if (invoices.isEmpty) return _buildEmptyState();

    final totalUsd = bcvRate > 0 ? totalBs / bcvRate : 0.0;

    return Column(
      children: [
        // ── Summary card ──
        _SummaryCard(
          totalBs: totalBs,
          totalUsd: totalUsd,
          count: invoices.length,
          bcvRate: bcvRate,
          onSendToCalc: () {
            final clean = totalBs.toStringAsFixed(2);
            ref.read(calculatorProvider.notifier).setInput(clean);
            ref.read(shellTabProvider.notifier).state = 0;
          },
        ),

        // ── List ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: invoices.length,
            itemBuilder: (_, i) {
              final inv = invoices[i];
              final rateAtDate = _rateForDate(inv.invoiceDate, history, bcvRate);
              final usd = rateAtDate > 0 ? inv.amountBs / rateAtDate : 0.0;
              return _InvoiceTile(
                invoice: inv,
                usdEquiv: usd,
                rateAtDate: rateAtDate,
                onDelete: () =>
                    ref.read(scannedInvoicesProvider.notifier).remove(inv.id),
                onRename: () => _showRenameDialog(inv),
                onSendToCalc: () {
                  ref
                      .read(calculatorProvider.notifier)
                      .setInput(inv.amountBs.toStringAsFixed(2));
                  ref.read(shellTabProvider.notifier).state = 0;
                },
                onShare: () => _shareInvoice(inv, usd, rateAtDate),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isPremium = ref.watch(isPremiumProvider);
    final storage = ref.read(localStorageProvider);
    final scansUsedToday = storage.dailyScanCount;
    final dailyLimit = SubscriptionConstants.freeScannerDailyLimit;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.document_scanner_outlined,
                  size: 42, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Calcula facturas al instante!',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Apunta la cámara a cualquier factura en Bs y TasaVe te dice cuántos dólares son en menos de 1 segundo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.text2,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (!isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(AppColors.r1),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Escaneos hoy: $scansUsedToday / $dailyLimit  ·  Ilimitados con Pro',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.text3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────

  void _confirmClearAll(BuildContext ctx, ScannedInvoicesNotifier notifier) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Borrar todas las facturas',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, color: AppColors.text)),
        content: Text('¿Estás seguro de que quieres borrar todas las facturas escaneadas?',
            style: GoogleFonts.dmSans(color: AppColors.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.dmSans(color: AppColors.text2)),
          ),
          TextButton(
            onPressed: () {
              notifier.clearAll();
              Navigator.pop(ctx);
            },
            child: Text('Borrar',
                style: GoogleFonts.dmSans(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(ScannedInvoice invoice) {
    final controller = TextEditingController(text: invoice.label ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Etiquetar factura',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, color: AppColors.text)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.dmSans(color: AppColors.text),
          decoration: InputDecoration(
            hintText: 'Ej: Supermercado, Farmacia...',
            hintStyle: GoogleFonts.dmSans(color: AppColors.text3),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.dmSans(color: AppColors.text2)),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(scannedInvoicesProvider.notifier)
                  .updateLabel(invoice.id, controller.text.trim());
              Navigator.pop(ctx);
            },
            child: Text('Guardar',
                style: GoogleFonts.dmSans(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Share ──────────────────────────────────────────────────────

  void _shareAllInvoices(
    List<ScannedInvoice> invoices,
    double totalBs,
    double bcvRate,
    List<TasaHistoryEntry> history,
  ) {
    final buf = StringBuffer('🧾 *Resumen de Facturas*\n\n');
    for (int i = 0; i < invoices.length; i++) {
      final inv = invoices[i];
      final rate = _rateForDate(inv.invoiceDate, history, bcvRate);
      final usd = rate > 0 ? inv.amountBs / rate : 0.0;
      final label = inv.label ?? 'Factura ${i + 1}';
      final dateStr = inv.invoiceDate != null
          ? '${inv.invoiceDate!.day.toString().padLeft(2, '0')}/${inv.invoiceDate!.month.toString().padLeft(2, '0')}/${inv.invoiceDate!.year}'
          : Formatters.timeAgo(inv.scannedAt);
      buf.writeln('📄 *$label*');
      buf.writeln('   💰 ${Formatters.formatCurrency(inv.amountBs)} Bs');
      if (usd > 0) buf.writeln('   💵 ≈ ${Formatters.formatCurrency(usd)} USD (${Formatters.formatRate(rate)} Bs/\$)');
      buf.writeln('   📅 $dateStr${inv.invoiceTime != null ? ' ${inv.invoiceTime}' : ''}');
      buf.writeln('');
    }
    buf.writeln('━━━━━━━━━━━━━━━━━━');
    buf.writeln('📊 *Total: ${Formatters.formatCurrency(totalBs)} Bs*');
    if (bcvRate > 0) {
      buf.writeln('💵 ≈ ${Formatters.formatCurrency(totalBs / bcvRate)} USD (tasa actual)');
    }
    buf.writeln('\n— Enviado desde *TasaVe* 🇻🇪');
    Share.share(buf.toString(), subject: 'Resumen de Facturas - TasaVe');
  }

  void _shareInvoice(ScannedInvoice inv, double usd, double rate) {
    final label = inv.label ?? 'Factura';
    final dateStr = inv.invoiceDate != null
        ? '${inv.invoiceDate!.day.toString().padLeft(2, '0')}/${inv.invoiceDate!.month.toString().padLeft(2, '0')}/${inv.invoiceDate!.year}'
        : Formatters.timeAgo(inv.scannedAt);
    final buf = StringBuffer('🧾 *$label*\n\n');
    buf.writeln('💰 Monto: ${Formatters.formatCurrency(inv.amountBs)} Bs');
    if (usd > 0) buf.writeln('💵 ≈ ${Formatters.formatCurrency(usd)} USD');
    if (rate > 0) buf.writeln('📈 Tasa: ${Formatters.formatRate(rate)} Bs/\$');
    buf.writeln('📅 $dateStr${inv.invoiceTime != null ? ' ${inv.invoiceTime}' : ''}');
    buf.writeln('\n— Enviado desde *TasaVe* 🇻🇪');
    Share.share(buf.toString(), subject: '$label - TasaVe');
  }
}

// ─────────────────────────────────────────────────────────────────
// SUMMARY CARD
// ─────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double totalBs;
  final double totalUsd;
  final int count;
  final double bcvRate;
  final VoidCallback onSendToCalc;

  const _SummaryCard({
    required this.totalBs,
    required this.totalUsd,
    required this.count,
    required this.bcvRate,
    required this.onSendToCalc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL ($count ${count == 1 ? "factura" : "facturas"})',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: AppColors.text2,
                ),
              ),
              if (bcvRate > 0)
                Text(
                  'Tasa BCV: ${Formatters.formatRate(bcvRate)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: AppColors.text3,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${Formatters.formatCurrency(totalBs)} Bs',
                      style: GoogleFonts.dmSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        height: 1,
                      ),
                    ),
                    if (bcvRate > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '≈ ${Formatters.formatCurrency(totalUsd)} USD (BCV)',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: onSendToCalc,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calculate_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Calcular',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// INVOICE TILE
// ─────────────────────────────────────────────────────────────────

class _InvoiceTile extends StatelessWidget {
  final ScannedInvoice invoice;
  final double usdEquiv;
  final double rateAtDate;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onSendToCalc;
  final VoidCallback onShare;

  const _InvoiceTile({
    required this.invoice,
    required this.usdEquiv,
    required this.rateAtDate,
    required this.onDelete,
    required this.onRename,
    required this.onSendToCalc,
    required this.onShare,
  });

  String get _dateLabel {
    if (invoice.invoiceDate != null) {
      final d = invoice.invoiceDate!;
      final date = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      if (invoice.invoiceTime != null) {
        return '$date ${invoice.invoiceTime}';
      }
      return date;
    }
    return Formatters.timeAgo(invoice.scannedAt);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(invoice.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.red),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_rounded,
                  size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.label ?? 'Factura',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (invoice.invoiceDate != null)
                        const Icon(Icons.calendar_today_rounded,
                            size: 10, color: AppColors.text3),
                      if (invoice.invoiceDate != null)
                        const SizedBox(width: 3),
                      Text(
                        _dateLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.text3,
                        ),
                      ),
                    ],
                  ),
                  if (rateAtDate > 0) ...[
                    const SizedBox(height: 1),
                    Text(
                      'Tasa: ${Formatters.formatRate(rateAtDate)} Bs/\$',
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        color: AppColors.text3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${Formatters.formatCurrency(invoice.amountBs)} Bs',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                if (usdEquiv > 0)
                  Text(
                    '≈ ${Formatters.formatCurrency(usdEquiv)} USD',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: AppColors.green,
                    ),
                  ),
              ],
            ),
            // Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  size: 18, color: AppColors.text3),
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                switch (val) {
                  case 'rename':
                    onRename();
                    break;
                  case 'calc':
                    onSendToCalc();
                    break;
                  case 'share':
                    onShare();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_rounded, size: 18, color: AppColors.text2),
                      const SizedBox(width: 8),
                      Text('Etiquetar', style: GoogleFonts.dmSans(color: AppColors.text)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'calc',
                  child: Row(
                    children: [
                      const Icon(Icons.calculate_rounded, size: 18, color: AppColors.text2),
                      const SizedBox(width: 8),
                      Text('Enviar a calculadora', style: GoogleFonts.dmSans(color: AppColors.text)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      const Icon(Icons.share_rounded, size: 18, color: AppColors.text2),
                      const SizedBox(width: 8),
                      Text('Compartir', style: GoogleFonts.dmSans(color: AppColors.text)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_rounded, size: 18, color: AppColors.red),
                      const SizedBox(width: 8),
                      Text('Eliminar', style: GoogleFonts.dmSans(color: AppColors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
