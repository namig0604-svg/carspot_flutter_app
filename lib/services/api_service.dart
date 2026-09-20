import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

/// Ошибка запроса к API с человеко-понятным текстом (уже без "Exception:"
/// и без "HTTP 400" — именно то, что можно сразу показать пользователю).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = 'https://pacific-analysis-production.up.railway.app';

  /// http.MultipartFile.fromBytes без явного contentType шлёт
  /// application/octet-stream — бэкенд такие файлы отклоняет как
  /// "неподдерживаемый формат". Определяем тип по расширению сами.
  static MediaType _mediaTypeForFilename(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
        return MediaType('image', 'heic');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  /// Достаёт из ответа сервера понятный текст ошибки. Бэкенд (FastAPI) почти
  /// всегда присылает JSON вида {"detail": "..."} — либо строку (обычная
  /// ошибка), либо список объектов при 422 (ошибка проверки полей формы).
  static String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        final detail = decoded['detail'];

        if (detail is String && detail.trim().isNotEmpty) {
          return detail;
        }

        if (detail is List && detail.isNotEmpty) {
          final parts = detail.map((item) {
            if (item is Map && item['msg'] != null) {
              String field = '';
              if (item['loc'] is List && (item['loc'] as List).isNotEmpty) {
                field = (item['loc'] as List).last.toString();
              }
              final msg = item['msg'].toString();
              return field.isNotEmpty ? '$field: $msg' : msg;
            }
            return item.toString();
          }).where((s) => s.trim().isNotEmpty).toSet().join('\n');
          if (parts.isNotEmpty) return parts;
        }
      }
    } catch (_) {
      // Тело ответа — не JSON или не содержит detail, используем запасной текст ниже.
    }

    switch (response.statusCode) {
      case 400:
        return 'Некорректный запрос';
      case 401:
        return 'Неверный логин или пароль';
      case 403:
        return 'Доступ запрещён';
      case 404:
        return 'Не найдено';
      case 409:
        return 'Конфликт данных';
      case 422:
        return 'Проверьте правильность заполнения полей';
      case 429:
        return 'Слишком много запросов, попробуйте чуть позже';
      case 500:
        return 'Внутренняя ошибка сервера, мы уже разбираемся';
      case 502:
      case 503:
        return 'Сервер временно недоступен, попробуйте позже';
      default:
        return 'Ошибка сервера (${response.statusCode})';
    }
  }

  /// Единая обработка сетевых сбоев (нет интернета, таймаут и т.п.) — эти
  /// ошибки не долетают даже до ответа сервера, поэтому текст отдельный.
  static Never _throwNetworkError(Object e) {
    if (e is TimeoutException) {
      throw ApiException('Сервер не отвечает. Проверьте интернет-соединение и попробуйте ещё раз.');
    }
    throw ApiException('Нет соединения с сервером. Проверьте интернет и попробуйте ещё раз.');
  }

  static dynamic _decodeOrThrow(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw ApiException(_extractErrorMessage(response), statusCode: response.statusCode);
  }

  static Future<dynamic> get(String endpoint, {String? token}) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    http.Response response;
    try {
      response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(const Duration(seconds: 30));
    } on ApiException {
      rethrow;
    } catch (e) {
      _throwNetworkError(e);
    }

    return _decodeOrThrow(response);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body, {String? token}) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    http.Response response;
    try {
      response = await http
          .post(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
    } on ApiException {
      rethrow;
    } catch (e) {
      _throwNetworkError(e);
    }

    return _decodeOrThrow(response);
  }

  static Future<dynamic> patch(String endpoint, Map<String, dynamic> body, {String? token}) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    http.Response response;
    try {
      response = await http
          .patch(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
    } on ApiException {
      rethrow;
    } catch (e) {
      _throwNetworkError(e);
    }

    return _decodeOrThrow(response);
  }

  /// Multipart-загрузка файла (для фото в чат и т.п.) — без стороннего пакета,
  /// достаточно http.MultipartRequest.
  static Future<dynamic> uploadImage(
    String endpoint,
    List<int> bytes,
    String filename, {
    String? token,
    String fieldName = 'file',
    Map<String, String>? fields,
  }) async {
    http.Response response;
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (fields != null) request.fields.addAll(fields);
      request.files.add(http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
        contentType: _mediaTypeForFilename(filename),
      ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      response = await http.Response.fromStream(streamedResponse);
    } on ApiException {
      rethrow;
    } catch (e) {
      _throwNetworkError(e);
    }

    return _decodeOrThrow(response);
  }

  static Future<dynamic> delete(String endpoint, {String? token}) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    http.Response response;
    try {
      response = await http
          .delete(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(const Duration(seconds: 30));
    } on ApiException {
      rethrow;
    } catch (e) {
      _throwNetworkError(e);
    }

    return _decodeOrThrow(response);
  }
}
