import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? _base64Image;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 25);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  void _showMoveRoomDialog(String currentRoom) async {
    final snapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').get();
    final occupied = snapshot.docs.map((doc) {
      final data = doc.data();
      return (data['roomNumber'] ?? '').toString();
    }).where((room) => room.isNotEmpty).toList();
    
    List<String> allRooms = [];
    for (int l = 1; l <= 3; l++) {
      for (int n = 1; n <= 10; n++) {
        allRooms.add("$l.$n");
      }
    }

    String? selectedNewRoom;
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Minta Pindah Kamar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Kamar saat ini: $currentRoom', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                hint: const Text('Pilih Kamar Baru'),
                items: allRooms.map((r) {
                  bool isOccupied = occupied.contains(r);
                  return DropdownMenuItem(
                    value: r, 
                    child: Text(
                      isOccupied ? 'Kamar $r (Terisi)' : 'Kamar $r',
                      style: TextStyle(
                        color: isOccupied ? Colors.grey : Colors.black,
                        fontStyle: isOccupied ? FontStyle.italic : null,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null && occupied.contains(val)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kamar ini sudah terisi!'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  setDialogState(() => selectedNewRoom = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (selectedNewRoom == null) return;
                final user = FirebaseAuth.instance.currentUser;
                await FirebaseFirestore.instance.collection('room_move_requests').add({
                  'uid': user?.uid,
                  'name': _nameController.text,
                  'fromRoom': currentRoom,
                  'toRoom': selectedNewRoom,
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permintaan pindah terkirim!')));
              },
              child: const Text('Kirim Permintaan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Akun')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          _nameController.text = userData['name'] ?? '';
          String? profileImg = _base64Image ?? userData['profileImage'];
          String roomNumber = userData['roomNumber'] ?? '-';
          String role = userData['role'] ?? 'user';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surfaceContainerHighest,
                        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2), width: 4),
                        image: profileImg != null
                            ? DecorationImage(image: MemoryImage(base64Decode(profileImg)), fit: BoxFit.cover)
                            : null,
                      ),
                      child: profileImg == null ? Icon(Icons.person_outline, size: 60, color: colorScheme.onSurfaceVariant) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                          child: Icon(Icons.camera_alt_outlined, color: colorScheme.onPrimary, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(userData['email'] ?? '', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14)),
                const SizedBox(height: 8),
                if (role == 'user')
                  Chip(
                    label: Text('Kamar $roomNumber', style: TextStyle(color: colorScheme.onSecondaryContainer)),
                    backgroundColor: colorScheme.secondaryContainer,
                    avatar: Icon(Icons.meeting_room_outlined, size: 16, color: colorScheme.onSecondaryContainer),
                  ),
                const SizedBox(height: 24),
                
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPasswordController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Ganti Password (Opsional)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                
                if (role == 'user') ...[
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('room_move_requests')
                        .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, moveSnapshot) {
                      final hasRequest = moveSnapshot.hasData && moveSnapshot.data!.docs.isNotEmpty;
                      
                      return Material(
                        color: hasRequest 
                            ? Colors.orange.withValues(alpha: 0.1) 
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: Icon(
                            hasRequest ? Icons.hourglass_empty : Icons.meeting_room_outlined,
                            color: hasRequest ? Colors.orange : colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            hasRequest ? 'Permintaan Pindah Sedang Diproses' : 'Manajemen Kamar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: hasRequest ? Colors.orange[900] : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          subtitle: Text(
                            hasRequest 
                                ? 'Menunggu persetujuan admin ke Kamar ${moveSnapshot.data!.docs.first['toRoom']}'
                                : 'Ajukan permohonan pindah kamar',
                            style: TextStyle(
                              color: hasRequest 
                                  ? Colors.orange[800]?.withValues(alpha: 0.8) 
                                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                          ),
                          trailing: hasRequest 
                              ? IconButton(
                                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                  onPressed: () => moveSnapshot.data!.docs.first.reference.delete(),
                                  tooltip: 'Batalkan Permintaan',
                                )
                              : Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onTap: hasRequest ? null : () => _showMoveRoomDialog(roomNumber),
                        ),
                      );
                    },
                  ),
                ],
                
                const SizedBox(height: 40),
                
                if (authProvider.isLoading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        bool success = await authProvider.updateProfile(_nameController.text, profileImg);
                        if (_newPasswordController.text.isNotEmpty) {
                          try {
                            await FirebaseAuth.instance.currentUser?.updatePassword(_newPasswordController.text);
                            _newPasswordController.clear();
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil diperbarui!')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: const Text('Simpan Perubahan'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
