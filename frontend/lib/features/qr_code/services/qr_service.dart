import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/qr_token_model.dart';

class QrService {
  const QrService();

  Future<QrTokenModel> generateQr({required int mealSlotId}) async {
    try {
      final token = await SecureStorageService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Your session has expired. Please log in again.',
        );
      }

      final response = await ApiClient.dio.post(
        '/qr-codes/generate',
        data: {'meal_slot_id': mealSlotId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception('The server returned an invalid QR response.');
      }

      final data = Map<String, dynamic>.from(responseData);

      // Agar backend response {"data": {...}} format me ho.
      final nestedData = data['data'];

      if (nestedData is Map) {
        return QrTokenModel.fromJson(Map<String, dynamic>.from(nestedData));
      }

      return QrTokenModel.fromJson(data);
    } on DioException catch (error) {
      throw Exception(_getErrorMessage(error));
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');

      throw Exception(message);
    }
  }

  String _getErrorMessage(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final detail =
          responseData['detail'] ??
          responseData['message'] ??
          responseData['error'];

      if (detail is String && detail.isNotEmpty) {
        return detail;
      }

      if (detail is List && detail.isNotEmpty) {
        return detail.first.toString();
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The server is not responding. Please check the server.';
}

if (error.type == DioExceptionType.connectionError) {
  return 'Unable to connect to the server.';
}

return 'Could not generate the QR code.';
  }
}
