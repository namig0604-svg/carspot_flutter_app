import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';

/// Редактирование своего профиля: юзернейм, имя, фото, описание.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _usernameController.text = user['username'] ?? '';
      _fullNameController.text = user['full_name'] ?? '';
      _bioController.text = user['bio'] ?? '';
      _avatarUrlController.text = user['avatar_url'] ?? '';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  String? _text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    if (_usernameController.text.trim().length < 3) {
      setState(() => _errorMessage = context.t('edit_profile.username_min_length'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final body = {
      'username': _usernameController.text.trim(),
      'full_name': _text(_fullNameController),
      'bio': _text(_bioController),
      'avatar_url': _text(_avatarUrlController),
    };

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.patch('/api/users/me', body, token: authProvider.accessToken);
      await authProvider.getCurrentUser();

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('edit_profile.profile_updated'))),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = context.tArgs('edit_profile.generic_error', {'error': '$e'}));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          prefixText: prefixText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _avatarUrlController.text.trim();

    return Scaffold(
      appBar: AppBar(title: Text(context.t('edit_profile.title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 45,
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 40) : null,
              ),
            ),
            const SizedBox(height: 20),

            _field(_usernameController, context.t('edit_profile.field_username'), required: true, prefixText: '@'),
            _field(_fullNameController, context.t('edit_profile.field_full_name')),
            _field(_bioController, context.t('edit_profile.field_bio'), maxLines: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: TextField(
                controller: _avatarUrlController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: context.t('edit_profile.field_avatar_url'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.red)),
              ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? AppLoader(size: 22, color: Colors.white)
                    : Text(context.t('common.save'), style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
