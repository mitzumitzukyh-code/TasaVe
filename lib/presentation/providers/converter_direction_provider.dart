import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConversionDirection { usdToBs, bsToUsd }

final conversionDirectionProvider = StateProvider<ConversionDirection>(
  (ref) => ConversionDirection.usdToBs,
);
