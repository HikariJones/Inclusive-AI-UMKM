import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use different base URLs based on platform
<<<<<<< Updated upstream
  static const String baseUrl = 'http://127.0.0.1:8000'; // Flutter web / local desktop
=======
  // For iOS Simulator on macOS: use 'http://localhost:8000'
  // For physical device: use your MacBook's IP address (e.g., 'http://192.168.0.103:8000')
  // To find your IP: run 'ifconfig | grep "inet " | grep -v 127.0.0.1' in terminal
  // IMPORTANT: Remove trailing slash! Use 'http://localhost:8000' NOT 'http://localhost:8000/'
  // For macOS app: use 'http://localhost:8000' (same machine)
  // For iOS Simulator: use 'http://localhost:8000'
  // For physical iOS device: use 'http://192.168.0.103:8000' (your MacBook's IP)
  static const String baseUrl = 'http://localhost:8000'; // Perfect for macOS app!
>>>>>>> Stashed changes
  // Use 'http://10.0.2.2:8000' for Android emulator

  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout:
          const Duration(seconds: 30), // Increased timeout
      receiveTimeout:
          const Duration(seconds: 30), // Increased timeout
      sendTimeout:
          const Duration(seconds: 30), // Added send timeout
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // Authentication
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('Attempting login to: ${_dio.options.baseUrl}/api/auth/token');
      print('Username: $username');
      
      // Try using Dio's queryParameters with proper encoding
      final uri = Uri.parse('${_dio.options.baseUrl}/api/auth/token');
      final body = 'username=${Uri.encodeComponent(username)}&password=${Uri.encodeComponent(password)}';
      
      final response = await _dio.post(
        '/api/auth/token',
        data: body,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );
      
      print('Login response status: ${response.statusCode}');
      print('Login response data: ${response.data}');
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Login failed: ${response.data?['detail'] ?? 'Unknown error'}');
      }
    } on DioException catch (e) {
      // Better error handling for Dio exceptions
      print('DioException type: ${e.type}');
      print('DioException message: ${e.message}');
      print('Response data: ${e.response?.data}');
      print('Status code: ${e.response?.statusCode}');
      print('Request path: ${e.requestOptions.path}');
      print('Request baseUrl: ${e.requestOptions.baseUrl}');
      
      if (e.response != null) {
        throw Exception('Login failed: ${e.response?.data?['detail'] ?? e.message}');
      } else {
        throw Exception('Login failed: Connection error - ${e.message}');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, String> userData) async {
    try {
      final response = await _dio.post('/api/auth/register', data: userData);
      return response.data;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Payment APIs
  Future<Map<String, dynamic>> uploadPaymentScreenshot(File imageFile) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path),
      });

      final response =
          await _dio.post('/api/payments/validate-screenshot', data: formData);
      return response.data;
    } catch (e) {
      throw Exception('Failed to upload screenshot: $e');
    }
  }

  Future<List<dynamic>> getPendingPayments() async {
    try {
      final response = await _dio.get('/api/payments/pending');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get pending payments: $e');
    }
  }

  Future<Map<String, dynamic>> getTodayStats() async {
    try {
      final response = await _dio.get('/api/payments/stats/today');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get stats: $e');
    }
  }

  // Inventory APIs
  Future<List<dynamic>> getInventory() async {
    try {
      final response = await _dio.get('/api/inventory/products');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get inventory: $e');
    }
  }

  Future<Map<String, dynamic>> getLowStockItems() async {
    try {
      final response = await _dio.get('/api/inventory/low-stock');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get low stock items: $e');
    }
  }

  Future<Map<String, dynamic>> getForecast(int productId) async {
    try {
      final response = await _dio.get('/api/inventory/forecast/$productId');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get forecast: $e');
    }
  }

  Future<Map<String, dynamic>> processInvoiceImage(File imageFile) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path),
      });

      final response =
          await _dio.post('/api/inventory/process-invoice', data: formData);
      return response.data;
    } catch (e) {
      throw Exception('Failed to process invoice: $e');
    }
  }

  // NEW: Book Report OCR to Excel
  Future<Map<String, dynamic>> convertBookToExcel(File imageFile) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path),
      });

      final response =
          await _dio.post('/api/ocr/book-to-excel', data: formData);
      return response.data;
    } catch (e) {
      throw Exception('Failed to convert book to excel: $e');
    }
  }

  // Download Excel file
  Future<String> downloadExcel(String fileId, String savePath) async {
    try {
      await _dio.download(
        '/api/ocr/download-excel/$fileId',
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );
      return savePath;
    } catch (e) {
      throw Exception('Failed to download excel: $e');
    }
  }
  
  // CRUD Operations for Inventory
  Future<Map<String, dynamic>> addProduct({
    required String name,
    String? sku,
    double? price,
    int? quantity,
    int? minQuantity,
  }) async {
    try {
      final response = await _dio.post('/api/inventory/products', data: {
        'name': name,
        if (sku != null) 'sku': sku,
        if (price != null) 'price': price,
        if (quantity != null) 'current_stock': quantity,  // Backend uses current_stock
        if (minQuantity != null) 'min_stock': minQuantity,  // Backend uses min_stock
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }
  
  Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required String name,
    String? sku,
    double? price,
    int? minQuantity,
  }) async {
    try {
      final response = await _dio.put('/api/inventory/products/$productId', data: {
        'name': name,
        if (sku != null) 'sku': sku,
        if (price != null) 'price': price,
        if (minQuantity != null) 'min_stock': minQuantity,  // Backend uses min_stock
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }
  
  Future<Map<String, dynamic>> updateProductQuantity({
    required int productId,
    required int quantity,
  }) async {
    try {
      final response = await _dio.patch('/api/inventory/products/$productId/quantity', data: {
        'quantity': quantity,
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to update product quantity: $e');
    }
  }
  
  Future<void> deleteProduct(int productId) async {
    try {
      await _dio.delete('/api/inventory/products/$productId');
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}
