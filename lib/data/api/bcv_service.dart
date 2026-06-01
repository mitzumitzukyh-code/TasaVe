import 'package:dio/dio.dart';
import '../models/tasa_model.dart';

/// URL base del API de TasaVe (Cloudflare Worker).
/// TODO: Configurar según entorno (producción/desarrollo)
const _apiBaseUrl = 'https://tasave-api.tusubdominio.workers.dev';

class BcvService {
  late final Dio _dio;

  BcvService() {
    _dio = Dio(BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  Future<TasaModel> fetchCurrentRate() async {
    try {
      final response = await _dio.get('/tasa');
      return TasaModel.fromJson(response.data);
    } on DioException {
      throw Exception('Error al obtener la tasa. Intenta de nuevo.');
    }
  }

  Future<List<TasaHistoryEntry>> fetchHistory({int days = 30}) async {
    try {
      final response = await _dio.get('/tasa/history', queryParameters: {'days': days});
      final list = response.data as List;
      return list.map((e) => TasaHistoryEntry.fromJson(e)).toList();
    } on DioException {
      throw Exception('Error al obtener el historial. Intenta de nuevo.');
    }
  }
}
