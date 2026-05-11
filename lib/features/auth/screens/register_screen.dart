import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _waController = TextEditingController();
  String _selectedRole = 'user';
  String? _selectedKamar;
  
  List<String> _occupiedRooms = [];
  bool _isFetchingRooms = true;

  @override
  void initState() {
    super.initState();
    _fetchOccupiedRooms();
  }

  Future<void> _fetchOccupiedRooms() async {
    if (!mounted) return;
    setState(() => _isFetchingRooms = true);
    try {
      // 1. Ambil data dari User yang sedang mendaftar (Cloud Firestore)
      final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final List<String> fromUsers = userSnapshot.docs.map((doc) {
        final data = doc.data();
        return (data['roomNumber'] ?? '').toString().trim();
      }).where((room) => room.isNotEmpty).toList();

      // 2. Ambil data dari Sinkronisasi Admin (Master Status dari SQLite)
      final masterDoc = await FirebaseFirestore.instance.collection('system').doc('room_status').get();
      List<String> fromMaster = [];
      if (masterDoc.exists) {
        final data = masterDoc.data();
        fromMaster = List<String>.from(data?['occupied_list'] ?? []);
      }
      
      if (mounted) {
        setState(() {
          // Gabungkan kedua sumber data dan hilangkan duplikasi (unique set)
          _occupiedRooms = {...fromUsers, ...fromMaster}.toList();
          _isFetchingRooms = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching rooms: $e");
      if (mounted) {
        setState(() => _isFetchingRooms = false);
        
        // Jika errornya adalah masalah izin (belum diatur di Firebase Console)
        // Kita tidak tampilkan pesan teknis yang mengganggu UI registrasi, 
        // tapi kita log di console agar developer tahu.
        if (e.toString().contains('permission-denied')) {
          debugPrint("PENTING: Atur Firestore Security Rules Anda ke 'allow read: if true' untuk koleksi 'users' dan 'system'.");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status kamar tidak sinkron: $e'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  List<String> _getAllRooms() {
    List<String> rooms = [];
    for (int l = 1; l <= 3; l++) {
      for (int n = 1; n <= 10; n++) {
        rooms.add("$l.$n");
      }
    }
    return rooms;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Registrasi Akun', style: TextStyle(color: Colors.black, fontSize: 16)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buat Akun Baru',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -1),
              ),
              const SizedBox(height: 8),
              const Text('Lengkapi data di bawah untuk bergabung.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(child: _buildRoleCard('user', 'Anak Kost', Icons.person_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildRoleCard('admin', 'Admin Kost', Icons.admin_panel_settings_outlined)),
                ],
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 18)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline, size: 18)),
                obscureText: true,
              ),
              
              if (_selectedRole == 'user') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.badge_outlined, size: 18)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _waController,
                  decoration: const InputDecoration(labelText: 'Nomor WhatsApp', prefixIcon: Icon(Icons.phone_android_outlined, size: 18)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                
                const Text(
                  'Pilih Nomor Kamar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                
                _isFetchingRooms 
                  ? const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Mengecek ketersediaan kamar...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _buildLegendItem(Colors.green, 'Tersedia'),
                                const SizedBox(width: 12),
                                _buildLegendItem(Colors.red, 'Terisi'),
                              ],
                            ),
                            Text(
                              '${_getAllRooms().length - _occupiedRooms.length} Kamar Kosong',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 18),
                              onPressed: _fetchOccupiedRooms,
                              tooltip: 'Refresh Status',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1,
                          ),
                          itemCount: _getAllRooms().length,
                          itemBuilder: (context, index) {
                            final room = _getAllRooms()[index];
                            
                            // Logika Pencocokan Fleksibel: 
                            // Kamar terisi jika nomor kamar (misal '1.1') ada di dalam list terisi 
                            // (menangani jika di database tertulis 'Kamar 1.1' atau '1.1')
                            bool isOccupied = _occupiedRooms.any((occ) => 
                              occ.toString().trim() == room || 
                              occ.toString().contains(room)
                            );
                            
                            bool isSelected = _selectedKamar == room;

                            return GestureDetector(
                              onTap: isOccupied ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Kamar $room sudah ditempati!'),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } : () {
                                setState(() => _selectedKamar = room);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isOccupied 
                                      ? Colors.red.withValues(alpha: 0.15) 
                                      : (isSelected ? const Color(0xFF4F46E5) : Colors.green.withValues(alpha: 0.1)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isOccupied 
                                        ? Colors.red.withValues(alpha: 0.8) 
                                        : (isSelected ? const Color(0xFF4F46E5) : Colors.green.withValues(alpha: 0.5)),
                                    width: isSelected ? 3 : 1.5,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                                  ] : null,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          room,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isOccupied 
                                                ? Colors.red[900] 
                                                : (isSelected ? Colors.white : Colors.green[900]),
                                          ),
                                        ),
                                        if (isOccupied)
                                          const Text('FULL', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.red)),
                                      ],
                                    ),
                                    if (isSelected)
                                      const Positioned(
                                        top: 2,
                                        right: 2,
                                        child: Icon(Icons.check_circle, size: 14, color: Colors.white),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (_selectedKamar != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              '✅ Anda memilih Kamar $_selectedKamar',
                              style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                      ],
                    ),
              ],
              
              const SizedBox(height: 32),
              if (authProvider.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(authProvider.errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email dan Password wajib diisi!')));
                            return;
                          }

                          if (_selectedRole == 'user') {
                            if (_nameController.text.isEmpty || _waController.text.isEmpty || _selectedKamar == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi Nama, WA, dan Kamar!')));
                              return;
                            }
                            
                            // PROTEKSI CRASH: Gunakan Try-Catch untuk pengecekan ganda
                            try {
                              final check = await FirebaseFirestore.instance
                                  .collection('users')
                                  .where('roomNumber', isEqualTo: _selectedKamar)
                                  .get();
                              
                              if (check.docs.isNotEmpty) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maaf, kamar ini sudah terdaftar!'), backgroundColor: Colors.red));
                                return;
                              }
                            } catch (e) {
                              debugPrint("Pengecekan ganda dilewati: $e");
                            }
                          }

                          bool success = await authProvider.register(
                            email: _emailController.text,
                            password: _passwordController.text,
                            role: _selectedRole,
                            name: _nameController.text,
                            wa: _waController.text,
                            roomNumber: _selectedKamar,
                          );

                          if (!mounted) return;

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_selectedRole == 'user' ? 'Pendaftaran berhasil! Menunggu konfirmasi admin.' : 'Registrasi Berhasil!')),
                            );
                            Navigator.pop(context);
                          }
                        },
                  child: authProvider.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Daftar Akun Sekarang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildRoleCard(String role, String label, IconData icon) {
    bool isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() {
        _selectedRole = role;
        if (role == 'admin') {
          _nameController.clear();
          _waController.clear();
          _selectedKamar = null;
        }
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF64748B), size: 20),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
