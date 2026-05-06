import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageUtils {
  static String formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    
    // Ensure URL starts with /
    final path = url.startsWith('/') ? url : '/$url';
    
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';
    return '$baseUrl$path';
  }
}
