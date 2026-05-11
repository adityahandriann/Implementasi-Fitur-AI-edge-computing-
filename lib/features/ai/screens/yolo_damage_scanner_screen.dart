import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

/// Layar Scanner YOLO untuk deteksi kerusakan.
/// Mengembalikan [String] deskripsi dari objek yang terdeteksi
/// saat pengguna menekan tombol "Gunakan Hasil Ini".
class YoloDamageScannerScreen extends StatefulWidget {
  const YoloDamageScannerScreen({super.key});

  @override
  State<YoloDamageScannerScreen> createState() =>
      _YoloDamageScannerScreenState();
}

class _YoloDamageScannerScreenState extends State<YoloDamageScannerScreen> {
  List<YOLOResult> _detections = [];
  double _fps = 0;

  /// Ambil label unik dari hasil deteksi, batasi 5 objek teratas
  List<String> get _uniqueLabels {
    final seen = <String>{};
    final result = <String>[];
    for (final d in _detections) {
      final label = d.className;
      if (seen.add(label) && result.length < 5) {
        result.add(label);
      }
    }
    return result;
  }

  /// Buat kalimat deskripsi yang siap dipakai di form laporan
  String get _generatedDescription {
    final labels = _uniqueLabels;
    if (labels.isEmpty) return '';
    final joined = labels.join(', ');
    return 'Kerusakan terdeteksi pada: $joined. Mohon segera ditangani.';
  }

  void _confirmAndReturn() {
    if (_uniqueLabels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada objek terdeteksi. Arahkan kamera ke area kerusakan.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // Kembalikan deskripsi ke layar sebelumnya
    Navigator.pop(context, _generatedDescription);
  }

  @override
  Widget build(BuildContext context) {
    final labels = _uniqueLabels;

    return Scaffold(
      backgroundColor: Colors.black,
      // ── App Bar ──────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          '🤖 AI Damage Scanner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                '${_fps.toStringAsFixed(1)} FPS',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Body: YOLO Camera + Overlay Info ─────────────────────
      body: Stack(
        children: [
          // 1. Live YOLO Camera View
          YOLOView(
            modelPath: 'assets/models/yolo11n_int8.tflite',
            task: YOLOTask.detect,
            confidenceThreshold: 0.5,
            iouThreshold: 0.45,
            lensFacing: LensFacing.back,
            showOverlays: true,
            onResult: (results) {
              setState(() => _detections = results);
            },
            onPerformanceMetrics: (metrics) {
              setState(() => _fps = metrics.fps);
            },
          ),

          // 2. Panel deteksi di bawah layar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.92),
                    Colors.black.withOpacity(0.0),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Jumlah objek terdeteksi
                  Row(
                    children: [
                      const Icon(Icons.radar, color: Colors.greenAccent, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${_detections.length} objek terdeteksi',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Chip label objek yang terdeteksi
                  if (labels.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: labels.map((label) {
                        return Chip(
                          label: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Arahkan kamera ke objek yang rusak…',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  ],

                  // Tombol konfirmasi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: labels.isNotEmpty ? _confirmAndReturn : null,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'Gunakan Hasil Ini',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade800,
                        disabledForegroundColor: Colors.white38,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Petunjuk kecil di atas
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Arahkan kamera ke area yang rusak',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
