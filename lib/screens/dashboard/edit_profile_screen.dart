import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final supabase = Supabase.instance.client;
  final picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _avatarUrl = '';
  String _role = 'client';
  bool _isAdmin = false;
  bool _loading = true;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    if (response != null) {
      _nameController.text = response['name'] ?? '';
      _avatarUrl = response['avatar_url'] ?? '';
      _bioController.text = response['bio'] ?? '';
      _locationController.text = response['location'] ?? '';
      _role = response['role'] ?? 'client';
      _isAdmin = _role == 'admin';
    }

    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<String?> _uploadAvatar(File file) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final filename = "${userId}_${const Uuid().v4()}.jpg";
    final bytes = await file.readAsBytes();

    // 🗑 Step 1: delete old file if exists
    if (_avatarUrl.isNotEmpty) {
      final uri = Uri.parse(_avatarUrl);
      final segments = uri.pathSegments;
      final index = segments.indexOf('avatars');
      if (index != -1 && index + 1 < segments.length) {
        final path = segments.sublist(index + 1).join('/');
        await supabase.storage.from('avatars').remove([path]);
      }
    }

    // 💾 Step 2: upload new avatar
    final response = await supabase.storage
        .from('avatars')
        .uploadBinary(
      filename,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        metadata: {'owner': userId},
      ),
    );

    final publicUrl =
    supabase.storage.from('avatars').getPublicUrl(filename);
    return publicUrl;
  }


  Future<void> _saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    String finalAvatarUrl = _avatarUrl;

    if (_pickedImage != null) {
      final uploaded = await _uploadAvatar(_pickedImage!);
      if (uploaded != null) {
        finalAvatarUrl = uploaded;
      }
    }

    final updates = {
      'name': _nameController.text.trim(),
      'avatar_url': finalAvatarUrl,
      'bio': _bioController.text.trim(),
      'location': _locationController.text.trim(),
    };

    if (_isAdmin) {
      updates['role'] = _role;
    }

    await supabase.from('profiles').update(updates).eq('id', user.id);

    Navigator.pop(context, true);
  }

  Widget _avatarPreview() {
    if (_pickedImage != null) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: FileImage(_pickedImage!),
      );
    } else if (_avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: NetworkImage(_avatarUrl),
      );
    } else {
      return const CircleAvatar(
        radius: 40,
        child: Icon(Icons.person, size: 40),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _avatarPreview(),
            ),
            const SizedBox(height: 12),
            const Text("Tap image to change avatar"),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Your Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: "Bio",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: "Location",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _role,
              items: const [
                DropdownMenuItem(value: 'client', child: Text('Client')),
                DropdownMenuItem(value: 'coach', child: Text('Coach')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: _isAdmin
                  ? (val) => setState(() => _role = val!)
                  : null,
              decoration: const InputDecoration(
                labelText: "Role",
                border: OutlineInputBorder(),
              ),
            ),
            if (!_isAdmin)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  "Only admins can change roles.",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
              label: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
