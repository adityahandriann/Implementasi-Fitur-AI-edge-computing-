import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../auth/providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../../admin/providers/local_db_provider.dart';
import '../../ai/screens/yolo_damage_scanner_screen.dart';

class ReportDamageScreen extends StatefulWidget {
  const ReportDamageScreen({super.key});

  @override
  State<ReportDamageScreen> createState() => _ReportDamageScreenState();
}

class _ReportDamageScreenState extends State<ReportDamageScreen> {
  final _deskripsiController = TextEditingController();
  bool _usedAiScanner = false;

  void _submit() async {
    final provider = context.read<TicketProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final roomNumber = authProvider.roomNumber ?? '-';

    if (_deskripsiController.text.isEmpty || (provider.selectedImage == null && !_usedAiScanner)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi deskripsi dan ambil foto (opsional jika via AI)!')),
      );
      return;
    }

    final success = await provider.sendDamageReport(
      user?.uid ?? '',
      roomNumber,
      _deskripsiController.text,
    );

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan Kerusakan Berhasil Dikirim!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim laporan. Cek koneksi Anda.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lapor Kerusakan')),
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
            const SizedBox(height: 20),
            const Text('Deskripsi Kerusakan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _deskripsiController,
              decoration: InputDecoration(
                hintText: 'Misal: Kran air bocor, lampu mati...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Hapus teks',
                  onPressed: () => _deskripsiController.clear(),
                ),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 10),

            // ── Tombol AI Scanner ─────────────────────────────
            OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const YoloDamageScannerScreen(),
                  ),
                );
                // Jika user sudah konfirmasi hasil, isi otomatis
                if (result != null && result.isNotEmpty) {
                  setState(() {
                    _deskripsiController.text = result;
                    _usedAiScanner = true;
                  });
                }
              },
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Scan Kerusakan dengan AI'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFF4F46E5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Bukti Foto', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => ticketProvider.pickImage(ImageSource.camera),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                ),
                child: ticketProvider.selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(ticketProvider.selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Ketuk untuk Ambil Foto', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => ticketProvider.pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pilih dari Galeri'),
              ),
            ),
            const SizedBox(height: 32),
            ticketProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Kirim Laporan Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }
}
