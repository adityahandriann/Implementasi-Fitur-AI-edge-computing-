import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class KtpScannerScreen extends StatefulWidget {
  const KtpScannerScreen({super.key});

  @override
  State<KtpScannerScreen> createState() => _KtpScannerScreenState();
}

class _KtpScannerScreenState extends State<KtpScannerScreen> {
  File? _imageFile;
  bool _isProcessing = false;

  String _rawText = '';
  
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nikController.dispose();
    _namaController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _nikController.clear();
        _namaController.clear();
        _alamatController.clear();
        _rawText = '';
      });
      await _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;

    setState(() => _isProcessing = true);

    try {
      final inputImage = InputImage.fromFile(_imageFile!);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      textRecognizer.close();

      final fullText = recognizedText.text;
      setState(() => _rawText = fullText);

      // Parse KTP fields from OCR text
      _parseKtpData(fullText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _parseKtpData(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    String nik = '';
    String nama = '';
    String alamat = '';

    // Helper untuk mengecek apakah sebuah baris adalah label/kata kunci KTP
    bool isLabel(String s) {
      final up = s.toUpperCase();
      const keywords = [
        'PROVINSI', 'KABUPATEN', 'KOTA', 'NIK', 'NAMA', 'TEMPAT', 'LAHIR',
        'JENIS', 'KELAMIN', 'ALAMAT', 'RT', 'RW', 'KEL', 'DESA', 'KECAMATAN',
        'AGAMA', 'STATUS', 'KAWIN', 'PEKERJAAN', 'KEWARGANEGARAAN', 'BERLAKU',
        'GOL', 'DARAH', 'ISLAM', 'KATHOLIK', 'KRISTEN', 'HINDU', 'BUDHA',
        'KONGHUCU', 'CERAI', 'PELAJAR', 'MAHASISWA', 'WNI', 'WNA', 'KARTU', 'PENDUDUK'
      ];
      for (final kw in keywords) {
        if (up.contains(kw)) return true;
      }
      return false;
    }

    // 1. CARI NIK (16 DIGIT) DI MANA SAJA
    int nikIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Cari jika ada kata dengan 16 angka berurutan
      final match = RegExp(r'\b\d{16}\b').firstMatch(line.replaceAll(' ', ''));
      if (match != null) {
        nik = match.group(0)!;
        nikIndex = i;
        break;
      }
      
      // Fallback: hapus semua selain angka, jika = 16, anggap NIK
      final digitOnly = line.replaceAll(RegExp(r'\D'), '');
      if (digitOnly.length == 16) {
        nik = digitOnly;
        nikIndex = i;
        break;
      } else if (digitOnly.length > 16 && digitOnly.startsWith('3')) {
        // NIK Indonesia biasanya diawali 1-9 (paling sering 3, 1, 31, 32 dst)
        nik = digitOnly.substring(0, 16);
        nikIndex = i;
        break;
      }
    }

    // 2. CARI NAMA (Berdasarkan relasi dengan NIK atau format huruf kapital)
    if (nikIndex != -1) {
      // Cek 1-5 baris setelah NIK. Biasanya Nama ada di bawah NIK pada blok yang sama
      for (int i = nikIndex + 1; i <= nikIndex + 5 && i < lines.length; i++) {
        final line = lines[i];
        if (line == line.toUpperCase() && !RegExp(r'\d').hasMatch(line) && line.length > 3 && !isLabel(line)) {
          nama = line;
          break;
        }
      }
    }

    // Jika Nama belum ketemu, gunakan format fallback (Cari di semua baris)
    if (nama.isEmpty) {
      for (final line in lines) {
        // Jika ada baris eksplisit "Nama : XXXXX"
        if (line.toUpperCase().contains('NAMA') && line.contains(':')) {
          final splitted = line.split(':');
          if (splitted.length > 1 && splitted.last.trim().length > 3) {
            nama = splitted.last.trim();
            break;
          }
        }
        // Jika hanya baris kapital biasa
        if (line == line.toUpperCase() && !RegExp(r'\d').hasMatch(line) && line.length > 3 && !isLabel(line)) {
          nama = line;
          break; // Ambil yang pertama cocok
        }
      }
    }

    // 3. CARI ALAMAT
    for (int i = 0; i < lines.length; i++) {
      final upLine = lines[i].toUpperCase();
      if (upLine.contains('ALAMAT')) {
        if (lines[i].contains(':') && lines[i].split(':').last.trim().length > 3) {
          alamat = lines[i].split(':').last.trim();
        }
        // Kumpulkan baris RT/RW/Desa
        for (int j = i + 1; j < lines.length; j++) {
          final nextUp = lines[j].toUpperCase();
          if (nextUp.contains('RT') || nextUp.contains('RW') || nextUp.contains('KEL') || nextUp.contains('DESA') || nextUp.contains('KEC')) {
            if (lines[j].contains(':')) {
              alamat += ', ' + lines[j].split(':').last.trim();
            } else {
              alamat += ', ' + lines[j].replaceAll(RegExp(r'^(RT/RW|KEL/DESA|KECAMATAN)\b', caseSensitive: false), '').trim();
            }
          } else if (nextUp.contains('AGAMA')) {
            break;
          }
        }
        break;
      }
    }

    // Bersihkan karakter aneh jika ada
    nama = nama.replaceAll(RegExp(r"[^A-Za-z\s\.\,\']"), '').trim();

    setState(() {
      _nikController.text = nik;
      _namaController.text = nama;
      _alamatController.text = alamat;
    });
  }

  void _confirmAndReturn() {
    Navigator.pop(context, {
      'nik': _nikController.text,
      'nama': _namaController.text,
      'alamat': _alamatController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan KTP (AI OCR)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Area Gambar ---
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_imageFile!, fit: BoxFit.contain),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.credit_card, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'Ambil foto KTP untuk di-scan AI',
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // --- Tombol Ambil Gambar ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Kamera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeri'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Loading Indicator ---
            if (_isProcessing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('🤖 AI sedang membaca KTP...', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 24),
                ],
              ),

            // --- Hasil Deteksi ---
            if (!_isProcessing && _imageFile != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.smart_toy_outlined, size: 20, color: colorScheme.secondary),
                            const SizedBox(width: 8),
                            Text(
                              'Hasil Deteksi AI',
                              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.secondary),
                            ),
                          ],
                        ),
                        Text('(Bisa diedit manual)', style: TextStyle(fontSize: 10, color: colorScheme.secondary.withValues(alpha: 0.7))),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildEditableRow('NIK', _nikController, Icons.pin_outlined),
                    const SizedBox(height: 12),
                    _buildEditableRow('Nama', _namaController, Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildEditableRow('Alamat', _alamatController, Icons.map_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- Raw OCR Text (collapsible) ---
              ExpansionTile(
                title: Text(
                  'Lihat Teks Mentah OCR',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                tilePadding: EdgeInsets.zero,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _rawText.isEmpty ? '(Tidak ada teks terdeteksi)' : _rawText,
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Tombol Gunakan Hasil ---
              ElevatedButton.icon(
                onPressed: _confirmAndReturn,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Gunakan Hasil Ini'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditableRow(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: Icon(icon, size: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'Input manual jika tidak terdeteksi',
            hintStyle: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}
