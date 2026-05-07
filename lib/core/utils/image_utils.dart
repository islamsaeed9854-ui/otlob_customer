import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageUtils {
  static String formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    
    var baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';
    
    // Remove trailing slash from baseUrl
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    // Ensure path starts with /
    final path = url.startsWith('/') ? url : '/$url';
    
    return '$baseUrl$path';
  }
}
