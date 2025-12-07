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
}
