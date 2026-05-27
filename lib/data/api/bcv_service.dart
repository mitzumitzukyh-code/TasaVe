import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../models/tasa_model.dart';

class BcvService {
  late final Dio _dio;

  BcvService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.API_BASE_URL,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        handler.reject(error);
      },
    ));
  }

  Future<TasaModel> fetchCurrentRate() async {
    try {
      final response = await _dio.get('/tasa');
      return TasaModel.fromJson(response.data);
    } on DioException {
      throw Exception(AppStrings.ERROR_API);
    }
  }

  Future<List<TasaHistoryEntry>> fetchHistory({int days = 30}) async {
    try {
      final response = await _dio.get('/tasa/history', queryParameters: {'days': days});
      final list = response.data as List;
      return list.map((e) => TasaHistoryEntry.fromJson(e)).toList();
    } on DioException {
      throw Exception(AppStrings.ERROR_API);
    }
  }
}
