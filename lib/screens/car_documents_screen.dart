import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_picker_field.dart';
import '../widgets/image_url_picker.dart' show ImageUrlPickerField;
import '../l10n/l10n_extensions.dart';

// Значения — ключи переводов, переводятся через context.t() в местах
// использования (эта карта — не готовый текст для отображения, и также
// служит текстом по умолчанию для titleController — там перевод
// подставляется через dialogContext.t() в момент установки значения).
const Map<String, String> _docTypeLabels = {
  'registration': 'car_documents.type_registration',
  'insurance_osago': 'car_documents.type_osago',
  'insurance_kasko': 'car_documents.type_kasko',
  'inspection': 'car_documents.type_inspection',
  'license': 'car_documents.type_license',
  'other': 'hazards.type_other',
};

/// Электронный бардачок: фото документов машины + срок действия для напоминаний.
/// GET/POST/DELETE /api/car-documents.
class CarDocumentsScreen extends StatefulWidget {
  const CarDocumentsScreen({Key? key}) : super(key: key);

  @override
  State<CarDocumentsScreen> createState() => _CarDocumentsScreenState();
}

class _CarDocumentsScreenState extends State<CarDocumentsScreen> {
  Map<String, dynamic>? _selectedCar;
  List<dynamic> _documents = [];
  bool _isLoading = false;

  Future<void> _onCarSelected(Map<String, dynamic> car) async {
    setState(() => _selectedCar = car);
    await _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final car = _selectedCar;
    if (car == null) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/car-documents/car/${car['id']}', token: authProvider.accessToken);
      final items = response is Map && response['items'] is List ? response['items'] as List : [];
      setState(() => _documents = items);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addDocument() async {
    final car = _selectedCar;
    if (car == null) return;

    String type = 'registration';
    final titleController = TextEditingController(text: context.t(_docTypeLabels[type]!));
    final photoUrlController = TextEditingController();
    final authProviderForPicker = Provider.of<AuthProvider>(context, listen: false);
    DateTime? expiresAt;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(dialogContext.t('car_documents.new_document_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: InputDecoration(labelText: dialogContext.t('car_documents.doc_type_label')),
                  items: _docTypeLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(dialogContext.t(e.value)))).toList(),
                  onChanged: (v) => setDialogState(() {
                    type = v ?? 'registration';
                    if (titleController.text.isEmpty || _docTypeLabels.values.map((k) => dialogContext.t(k)).contains(titleController.text)) {
                      titleController.text = _docTypeLabels[type] == null ? '' : dialogContext.t(_docTypeLabels[type]!);
                    }
                  }),
                ),
                TextField(controller: titleController, decoration: InputDecoration(labelText: dialogContext.t('car_documents.name_label'))),
                const SizedBox(height: 10),
                ImageUrlPickerField(
                  controller: photoUrlController,
                  token: authProviderForPicker.accessToken,
                  galleryLabel: dialogContext.t('part_listing_form.gallery_label'),
                  cameraLabel: dialogContext.t('hazards.type_camera'),
                  errorTextBuilder: (e) => dialogContext.tArgs('part_listing_form.upload_error', {'error': '$e'}),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(expiresAt == null
                      ? dialogContext.t('car_documents.expiry_not_set')
                      : dialogContext.tArgs('car_documents.expiry_set', {'date': '${expiresAt!.day}.${expiresAt!.month}.${expiresAt!.year}'})),
                  trailing: const Icon(Icons.event, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setDialogState(() => expiresAt = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(dialogContext.t('carpool.cancel'))),
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(dialogContext.t('car_expenses.save'))),
          ],
        ),
      ),
    );

    if (saved != true || titleController.text.trim().isEmpty) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post(
        '/api/car-documents',
        {
          'car_id': car['id'],
          'type': type,
          'title': titleController.text.trim(),
          if (photoUrlController.text.trim().isNotEmpty) 'photo_url': photoUrlController.text.trim(),
          if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
        },
        token: authProvider.accessToken,
      );
      _loadDocuments();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _delete(String id) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete('/api/car-documents/$id', token: authProvider.accessToken);
      _loadDocuments();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  bool _isExpiringSoon(String? iso) {
    if (iso == null) return false;
    try {
      final dt = DateTime.parse(iso);
      return dt.difference(DateTime.now()).inDays <= 30;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('car_documents.title')), backgroundColor: AppColors.black),
      floatingActionButton: _selectedCar == null
          ? null
          : FloatingActionButton(onPressed: _addDocument, backgroundColor: AppColors.blue, child: const Icon(Icons.add)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CarPickerField(onSelected: _onCarSelected),
            const SizedBox(height: 16),
            if (_isLoading) const Expanded(child: Center(child: AppLoader()))
            else if (_documents.isEmpty)
              Expanded(
                child: Center(child: Text(context.t('car_documents.empty'), style: const TextStyle(color: AppColors.textMutedDark))),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final d = _documents[index] as Map<String, dynamic>;
                    final expiringSoon = _isExpiringSoon(d['expires_at'] as String?);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDarkAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: expiringSoon ? Colors.amber : AppColors.steel),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.description, color: expiringSoon ? Colors.amber : AppColors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                                if (d['expires_at'] != null)
                                  Text(
                                    context.tArgs('car_documents.expires_until', {'date': _formatDate(d['expires_at'] as String?)}) +
                                        (expiringSoon ? context.t('car_documents.expiring_soon_suffix') : ''),
                                    style: TextStyle(fontSize: 12, color: expiringSoon ? Colors.amber : AppColors.textMutedDark),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
                            onPressed: () => _delete(d['id'] as String),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
