import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';

/// Форма клуба: создание нового (club == null) или редактирование (owner/admin).
class ClubFormScreen extends StatefulWidget {
  final Map<String, dynamic>? club;

  const ClubFormScreen({Key? key, this.club}) : super(key: key);

  @override
  State<ClubFormScreen> createState() => _ClubFormScreenState();
}

class _ClubFormScreenState extends State<ClubFormScreen> {
  bool get _isEditing => widget.club != null;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _tagsController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _coverUrlController = TextEditingController();

  bool _isPublic = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final club = widget.club;
    if (club != null) {
      _nameController.text = club['name'] ?? '';
      _descriptionController.text = club['description'] ?? '';
      _countryController.text = club['country'] ?? '';
      _cityController.text = club['city'] ?? '';
      _tagsController.text = club['tags'] ?? '';
      _logoUrlController.text = club['logo_url'] ?? '';
      _coverUrlController.text = club['cover_url'] ?? '';
      _isPublic = club['is_public'] ?? true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _tagsController.dispose();
    _logoUrlController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  String? _text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    if (_nameController.text.trim().length < 3) {
      setState(() => _errorMessage = 'Название клуба — минимум 3 символа');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final body = {
      'name': _nameController.text.trim(),
      'description': _text(_descriptionController),
      'country': _text(_countryController),
      'city': _text(_cityController),
      'tags': _text(_tagsController),
      'logo_url': _text(_logoUrlController),
      'cover_url': _text(_coverUrlController),
      'is_public': _isPublic,
    };

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (_isEditing) {
        await ApiService.patch(
          '/api/clubs/${widget.club!['id']}',
          body,
          token: authProvider.accessToken,
        );
      } else {
        await ApiService.post('/api/clubs/', body, token: authProvider.accessToken);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Клуб обновлён' : 'Клуб создан 🏁')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Изменить клуб' : 'Создать клуб')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(_nameController, 'Название клуба', required: true),
            _field(_descriptionController, 'Описание', maxLines: 3),
            _field(_countryController, 'Страна'),
            _field(_cityController, 'Город'),
            _field(_tagsController, 'Тематика через запятую (JDM, Drift, Stance)'),
            _field(_logoUrlController, 'Ссылка на логотип (URL)'),
            _field(_coverUrlController, 'Ссылка на обложку (URL)'),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Открытый клуб'),
              subtitle: const Text('Вступление сразу, без одобрения'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
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
                    : Text(
                        _isEditing ? 'Сохранить' : 'Создать клуб',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
