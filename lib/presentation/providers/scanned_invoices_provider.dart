import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/scanned_invoice.dart';
import 'tasa_provider.dart';

class ScannedInvoicesNotifier extends StateNotifier<List<ScannedInvoice>> {
  final Ref _ref;

  ScannedInvoicesNotifier(this._ref) : super([]) {
    _load();
  }

  static const _key = 'scanned_invoices';

  void _load() {
    final storage = _ref.read(localStorageProvider);
    final raw = storage.prefs.getString(_key);
    if (raw != null) {
      try {
        state = ScannedInvoice.decodeList(raw);
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final storage = _ref.read(localStorageProvider);
    await storage.prefs.setString(_key, ScannedInvoice.encodeList(state));
  }

  void add(ScannedInvoice invoice) {
    state = [invoice, ...state];
    _save();
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _save();
  }

  void updateLabel(String id, String label) {
    state = state.map((e) => e.id == id ? e.copyWith(label: label) : e).toList();
    _save();
  }

  void clearAll() {
    state = [];
    _save();
  }

  double get totalBs => state.fold(0.0, (sum, e) => sum + e.amountBs);
}

final scannedInvoicesProvider =
    StateNotifierProvider<ScannedInvoicesNotifier, List<ScannedInvoice>>(
  (ref) => ScannedInvoicesNotifier(ref),
);
