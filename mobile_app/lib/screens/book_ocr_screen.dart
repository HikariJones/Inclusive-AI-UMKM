import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../services/api_service.dart';

class BookOcrScreen extends StatefulWidget {
  const BookOcrScreen({super.key});

  @override
  State<BookOcrScreen> createState() => _BookOcrScreenState();
}

class _BookOcrScreenState extends State<BookOcrScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;
  Map<String, dynamic>? _ocrResult;
  
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _ocrResult = null;
      });
    }
  }

  Future<void> _processBookReport() async {
    if (_imageFile == null) {
      _showSnackBar('Pilih gambar terlebih dahulu', Colors.red);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await _apiService.convertBookToExcel(_imageFile!);
      
      setState(() {
        _ocrResult = result;
      });
      
      _showSnackBar('Berhasil mengekstrak data!', Colors.green);
    } catch (e) {
      _showSnackBar('Gagal: $e', Colors.red);
    } finally {
      setState(() => _isProcessing = false);
    }
  }
  
  Future<void> _downloadExcel() async {
    if (_ocrResult == null || _ocrResult!['file_id'] == null) {
      _showSnackBar('Tidak ada file untuk didownload', Colors.red);
      return;
    }
    
    try {
      setState(() => _isProcessing = true);
      
      final directory = await getApplicationDocumentsDirectory();
      final savePath = '${directory.path}/laporan_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      await _apiService.downloadExcel(_ocrResult!['file_id'], savePath);
      
      _showSnackBar('File berhasil didownload!', Colors.green);
      
      // Open the file
      await OpenFile.open(savePath);
    } catch (e) {
      _showSnackBar('Gagal download: $e', Colors.red);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konversi Buku ke Excel'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📖 Cara Penggunaan:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('1. Ambil foto halaman buku laporan'),
                    Text('2. Pastikan tulisan jelas dan pencahayaan baik'),
                    Text('3. Klik "Proses OCR"'),
                    Text('4. Download hasil dalam format Excel'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Image Preview
            if (_imageFile != null)
              Card(
                elevation: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _imageFile!,
                    height: 300,
                    fit: BoxFit.cover,
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
                    label: const Text('Ambil Foto'),
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
                    label: const Text('Dari Galeri'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Process Button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _processBookReport,
              icon: _isProcessing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isProcessing ? 'Memproses...' : 'Proses OCR'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            
            // Results Section
            if (_ocrResult != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Hasil Ekstraksi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('Baris ditemukan: ${_ocrResult!['rows_extracted'] ?? 0}'),
                      Text('Kolom ditemukan: ${_ocrResult!['columns_detected'] ?? 0}'),
                      if (_ocrResult!['preview'] != null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Preview Data:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _ocrResult!['preview'],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Download Button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _downloadExcel,
                icon: const Icon(Icons.download),
                label: const Text('Download Excel'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
