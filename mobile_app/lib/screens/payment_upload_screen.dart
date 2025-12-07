import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';

class PaymentUploadScreen extends StatefulWidget {
  const PaymentUploadScreen({super.key});

  @override
  State<PaymentUploadScreen> createState() => _PaymentUploadScreenState();
}

class _PaymentUploadScreenState extends State<PaymentUploadScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  Map<String, dynamic>? _result;
  String? _validationStatus; // VALID, INVALID, or ERROR

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _result = null;
          _validationStatus = null;
        });

        // Auto-validate QRIS after image selection
        _validateQRIS();
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', Colors.orange);
    }
  }

  Future<void> _validateQRIS() async {
    if (_imageFile == null) return;

    setState(() => _isProcessing = true);

    try {
      final paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      final result = await paymentProvider.uploadPaymentScreenshot(_imageFile!);

      if (mounted) {
        setState(() {
          _result = result;
          _validationStatus = result['is_valid'] == true ? 'VALID' : 'INVALID';
        });

        // Show validation result
        final isValid = result['is_valid'] == true;
        _showSnackBar(
          isValid ? '✅ Pembayaran Valid!' : '❌ Pembayaran Invalid',
          isValid ? Colors.green : Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _validationStatus = 'ERROR');
        _showSnackBar('Validation error: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _uploadPayment() async {
    if (_imageFile == null) {
      _showSnackBar('Pilih gambar terlebih dahulu', Colors.red);
      return;
    }

    // Already validated automatically, confirm and reset
    if (_result != null && _validationStatus == 'VALID') {
      _showSnackBar('✅ Pembayaran berhasil disimpan!', Colors.green);

      // Refresh pending payments list
      final paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      await paymentProvider.fetchPendingPayments();

      // Reset UI to initial state
      setState(() {
        _imageFile = null;
        _result = null;
        _validationStatus = null;
      });
    } else if (_validationStatus == 'INVALID') {
      _showSnackBar(
          '❌ Pembayaran tidak valid, tidak bisa disimpan', Colors.red);
    } else {
      _showSnackBar('Tunggu validasi selesai...', Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instructions
          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📸 Upload Screenshot Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text('1. Ambil screenshot dari notifikasi bank/e-wallet'),
                  Text('2. Pastikan nominal dan waktu terlihat jelas'),
                  Text('3. Upload untuk validasi otomatis'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Image Preview (mobile only - Image.file not supported on web)
          if (_imageFile != null && !kIsWeb)
            Card(
              elevation: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _imageFile!,
                  height: 400,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else if (_imageFile != null && kIsWeb)
            Card(
              elevation: 4,
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '✅ Image selected: ${_imageFile!.path.split('/').last}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Belum ada gambar dipilih'),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Image Source Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeri'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Validation Status Indicator
          if (_validationStatus != null)
            Card(
              color: _validationStatus == 'VALID'
                  ? Colors.green.shade50
                  : _validationStatus == 'INVALID'
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      _validationStatus == 'VALID'
                          ? Icons.check_circle
                          : _validationStatus == 'INVALID'
                              ? Icons.cancel
                              : Icons.error,
                      color: _validationStatus == 'VALID'
                          ? Colors.green
                          : _validationStatus == 'INVALID'
                              ? Colors.red
                              : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _validationStatus == 'VALID'
                            ? 'Pembayaran Valid ✅'
                            : _validationStatus == 'INVALID'
                                ? 'Pembayaran Tidak Valid ❌'
                                : 'Error pada validasi ⚠️',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _validationStatus == 'VALID'
                              ? Colors.green
                              : _validationStatus == 'INVALID'
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Upload Button
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _uploadPayment,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check),
            label: Text(_isProcessing ? 'Memproses...' : 'Konfirmasi & Simpan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor:
                  _validationStatus == 'VALID' ? Colors.green : Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),

          // Results
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              color: _result!['status'] == 'matched'
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _result!['status'] == 'matched'
                              ? Icons.check_circle
                              : Icons.pending,
                          color: _result!['status'] == 'matched'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _result!['status'] == 'matched'
                              ? 'Pembayaran Cocok!'
                              : 'Pending Validasi',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_result!['extracted_data'] != null) ...[
                      _InfoRow('Nominal',
                          'Rp ${_result!['extracted_data']['amount']}'),
                      _InfoRow('Waktu',
                          _result!['extracted_data']['timestamp'] ?? '-'),
                      _InfoRow('Referensi',
                          _result!['extracted_data']['reference'] ?? '-'),
                      if (_result!['confidence'] != null)
                        _InfoRow('Confidence',
                            '${(_result!['confidence'] * 100).toStringAsFixed(1)}%'),
                    ],
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Pending Payments List
          const Text(
            'Pembayaran Pending',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Consumer<PaymentProvider>(
            builder: (context, paymentProvider, child) {
              if (paymentProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (paymentProvider.pendingPayments.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 12),
                        Text('Tidak ada pembayaran pending'),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paymentProvider.pendingPayments.length,
                itemBuilder: (context, index) {
                  final payment = paymentProvider.pendingPayments[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.pending_actions,
                          color: Colors.orange),
                      title: Text('Rp ${payment['amount']}'),
                      subtitle: Text(
                          payment['timestamp'] ?? 'Tanggal tidak diketahui'),
                      trailing: Chip(
                        label: Text('${payment['confidence_score']}%'),
                        backgroundColor: Colors.orange.shade100,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
