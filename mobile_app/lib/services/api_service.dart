import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use different base URLs based on platform
  static const String baseUrl = 'http://192.168.1.2:8000'; // Windows/iOS
  // Use 'http://10.0.2.2:8000' for Android emulator
  // Use 'http://YOUR_IP:8000' for physical device

  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout:
          const Duration(seconds: 10), // Fast fail if server unreachable
      receiveTimeout:
          const Duration(seconds: 120), // Long wait for OCR processing
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
      // OAuth2PasswordRequestForm expects form data, not JSON
      final response = await _dio.post(
        '/api/auth/token',
        data: FormData.fromMap({
          'username': username,
          'password': password,
        }),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      return response.data;
    } catch (e) {
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
