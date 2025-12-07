import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PaymentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _pendingPayments = [];
  Map<String, dynamic>? _todayStats;
  bool _isLoading = false;
  
  List<dynamic> get pendingPayments => _pendingPayments;
  Map<String, dynamic>? get todayStats => _todayStats;
  bool get isLoading => _isLoading;
  
  Future<void> fetchPendingPayments() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _pendingPayments = await _apiService.getPendingPayments();
    } catch (e) {
      print('Error fetching pending payments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchTodayStats() async {
    try {
      _todayStats = await _apiService.getTodayStats();
      notifyListeners();
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }
  
  Future<Map<String, dynamic>> uploadPaymentScreenshot(File imageFile) async {
    try {
      final result = await _apiService.uploadPaymentScreenshot(imageFile);
      await fetchPendingPayments();
      await fetchTodayStats();
      return result;
    } catch (e) {
      throw Exception('Failed to upload payment: $e');
    }
  }
}
