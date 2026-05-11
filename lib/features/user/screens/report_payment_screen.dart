import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../../admin/providers/local_db_provider.dart';

class ReportPaymentScreen extends StatefulWidget {
  const ReportPaymentScreen({super.key});

  @override
  State<ReportPaymentScreen> createState() => _ReportPaymentScreenState();
}

class _ReportPaymentScreenState extends State<ReportPaymentScreen> {
  bool _isAiValidating = false;

  void _submit() async {
    final provider = context.read<TicketProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final roomNumber = authProvider.roomNumber ?? '-';

    if (provider.selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lampirkan bukti transfer!')),
      );
      return;
    }

    setState(() => _isAiValidating = true);

    // AI Validation: Mengecek apakah gambar adalah struk/dokumen/screenshot
    bool isValidProof = false;
    try {
      final inputImage = InputImage.fromFile(provider.selectedImage!);
      final imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));
      final labels = await imageLabeler.processImage(inputImage);
      
      final validKeywords = ['Text', 'Document', 'Screenshot', 'Receipt', 'Font', 'Paper', 'Number', 'Mobile phone'];
      
      for (final label in labels) {
        if (validKeywords.contains(label.label)) {
          isValidProof = true;
          break;
        }
      }
      imageLabeler.close();
    } catch (e) {
      isValidProof = true; // Fallback jika ML Kit gagal inisialisasi
    }

    setState(() => _isAiValidating = false);

    if (!isValidProof) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🤖 AI: Gambar ditolak! Harap unggah struk atau screenshot pembayaran.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final success = await provider.sendPaymentReport(
      user?.uid ?? '',
      roomNumber,
    );

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bukti Pembayaran Berhasil Dikirim!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim bukti pembayaran.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lapor Pembayaran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Melaporkan dari Kamar', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'Kamar ${authProvider.roomNumber ?? "-"}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Unggah Bukti Transfer (Screenshot/Foto)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => ticketProvider.pickImage(ImageSource.gallery),
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                ),
                child: ticketProvider.selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(ticketProvider.selectedImage!, fit: BoxFit.contain),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.cloud_upload_outlined, size: 64, color: Color(0xFF64748B)),
                          SizedBox(height: 16),
                          Text('Ketuk untuk Pilih Bukti Bayar', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          Text('(Format: JPG, PNG)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ticketProvider.pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Gunakan Kamera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ticketProvider.isLoading || _isAiValidating
                ? Column(
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('AI sedang memvalidasi gambar... 🤖', style: TextStyle(color: Colors.grey)),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Kirim Bukti Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }
}
