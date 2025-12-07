import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InventoryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _products = [];
  Map<String, dynamic>? _lowStockItems;
  bool _isLoading = false;
  
  List<dynamic> get products => _products;
  Map<String, dynamic>? get lowStockItems => _lowStockItems;
  bool get isLoading => _isLoading;
  
  Future<void> fetchInventory() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _products = await _apiService.getInventory();
    } catch (e) {
      print('Error fetching inventory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchLowStockItems() async {
    try {
      _lowStockItems = await _apiService.getLowStockItems();
      notifyListeners();
    } catch (e) {
      print('Error fetching low stock: $e');
    }
  }
  
  Future<Map<String, dynamic>> processInvoice(File imageFile) async {
    try {
      final result = await _apiService.processInvoiceImage(imageFile);
      await fetchInventory();
      await fetchLowStockItems();
      return result;
    } catch (e) {
      throw Exception('Failed to process invoice: $e');
    }
  }
  
  Future<Map<String, dynamic>> getForecast(int productId) async {
    try {
      return await _apiService.getForecast(productId);
    } catch (e) {
      throw Exception('Failed to get forecast: $e');
    }
  }
  
  Future<void> addProduct({
    required String name,
    String? sku,
    double? price,
    int? quantity,
    int? minQuantity,
  }) async {
    try {
      await _apiService.addProduct(
        name: name,
        sku: sku,
        price: price,
        quantity: quantity,
        minQuantity: minQuantity,
      );
      await fetchInventory();
      await fetchLowStockItems();
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }
  
  Future<void> updateProduct({
    required int productId,
    required String name,
    String? sku,
    double? price,
    int? minQuantity,
  }) async {
    try {
      await _apiService.updateProduct(
        productId: productId,
        name: name,
        sku: sku,
        price: price,
        minQuantity: minQuantity,
      );
      await fetchInventory();
      await fetchLowStockItems();
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }
  
  Future<void> updateProductQuantity({
    required int productId,
    required int quantity,
  }) async {
    try {
      await _apiService.updateProductQuantity(
        productId: productId,
        quantity: quantity,
      );
      await fetchInventory();
      await fetchLowStockItems();
    } catch (e) {
      throw Exception('Failed to update product quantity: $e');
    }
  }
  
  Future<void> deleteProduct(int productId) async {
    try {
      await _apiService.deleteProduct(productId);
      await fetchInventory();
      await fetchLowStockItems();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}
