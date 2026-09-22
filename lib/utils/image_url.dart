import '../services/api_service.dart';

/// Превращает относительный путь вида "/uploads/xxx.jpg" (то, что отдаёт
/// наш собственный backend после загрузки файла через ImageUrlPickerField)
/// в полный URL с доменом API. Уже полные ссылки (http/https — вставленные
/// вручную или с внешних сервисов вроде imgur) возвращаются как есть.
///
/// Без этого Image.network()/NetworkImage() пытается загрузить относительный
/// путь относительно домена самого Flutter-приложения (а не API), получает
/// HTML-страницу вместо картинки и падает с ImageCodecException ("Failed to
/// detect image file format... File header was [0x3c 0x21 0x44 0x4f ...]" —
/// это байты "<!DOCTYPE ", то есть в ответ на запрос картинки пришла
/// HTML-страница).
String resolveImageUrl(String url) {
  if (url.isEmpty) return url;
  return url.startsWith('http') ? url : '${ApiService.baseUrl}$url';
}
