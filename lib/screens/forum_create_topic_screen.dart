import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/forum_category.dart';
import '../widgets/country_city_picker.dart';
import '../widgets/app_loader.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';

/// Forma novoy temy foruma: kategoriya zadana zaranee (ekran otkryvaetsya iz
/// forum_topics_screen.dart), strana - opcionalno (CountryPickerField, no
/// pustoe znachenie dopustimo - togda tema obshchaya, vidna vo vseh stranah).
class ForumCreateTopicScreen extends StatefulWidget {
  final String category;

  const ForumCreateTopicScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<ForumCreateTopicScreen> createState() => _ForumCreateTopicScreenState();
}

class _ForumCreateTopicScreenState extends State<ForumCreateTopicScreen> {
  final _countryController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _countryController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().length < 3) {
      setState(() => _errorMessage = context.t('forum.title_too_short'));
      return;
    }
    if (_bodyController.text.trim().isEmpty) {
      setState(() => _errorMessage = context.t('forum.body_empty'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final body = {
        'category': widget.category,
        'country': _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
      };
      await ApiService.post('/api/forum/topics', body, token: authProvider.accessToken);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _errorMessage = context.tArgs('forum.error_message', {'error': '$e'}));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = forumCategoryByValue(widget.category);
    return Scaffold(
      appBar: AppBar(title: Text(context.t('forum.new_topic_title'), overflow: TextOverflow.ellipsis, maxLines: 1)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(style.icon, color: style.color),
                const SizedBox(width: 8),
                Text(forumCategoryLabel(context, widget.category), style: TextStyle(color: style.color, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            CountryPickerField(
              controller: _countryController,
              label: context.t('forum.country_optional_label'),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: context.t('forum.title_label'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _bodyController,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: context.t('forum.body_label'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
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
                  backgroundColor: style.color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const AppLoader(size: 22, color: Colors.white)
                    : Text(context.t('forum.publish_button'), style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
