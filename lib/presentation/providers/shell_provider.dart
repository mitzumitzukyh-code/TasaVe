import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the active tab index in ShellScreen
final shellTabProvider = StateProvider<int>((ref) => 0);
