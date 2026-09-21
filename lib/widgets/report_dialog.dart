import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../l10n/l10n_extensions.dart';

/// Причины жалобы — ключ уходит на бэкенд, подпись показывается пользователю.
const Map<String, String> reportReasonLabels = {
  'spam': 'Спам / реклама',
  'abuse': 'Оскорбления, агрессия',
  'fake_profile': 'Фейковый профиль',
  'inappropriate': 'Неприемлемый контент',
  'scam': 'Мошенничество',
  'other': 'Другое',
};

/// Ключ перевода подписи причины жалобы по её коду (см. [reportReasonLabels]).
String _reportReasonKey(String reason) => 'report_dialog.reason_$reason';

/// Открывает форму жалобы на пользователя/сходку/клуб/сервис/сообщение/фото.
/// targetType — один из: user, event, club, business, message, photo.
Future<void> showReportDialog(
  BuildContext context, {
  required String targetType,
  required String targetId,
}) async {
  String selectedReason = 'spam';
  final descriptionController = TextEditingController();
  bool isSending = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) {
      return StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('report_dialog.title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...reportReasonLabels.entries.map(
                    (e) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(context.t(_reportReasonKey(e.key))),
                      value: e.key,
                      groupValue: selectedReason,
                      onChanged: (v) => setSheetState(() => selectedReason = v!),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    maxLength: 1000,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: context.t('report_dialog.details_label'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSending
                          ? null
                          : () async {
                              setSheetState(() => isSending = true);
                              try {
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                await ApiService.post(
                                  '/api/reports/',
                                  {
                                    'target_type': targetType,
                                    'target_id': targetId,
                                    'reason': selectedReason,
                                    if (descriptionController.text.trim().isNotEmpty)
                                      'description': descriptionController.text.trim(),
                                  },
                                  token: authProvider.accessToken,
                                );
                                Navigator.pop(sheetCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(context.t('report_dialog.report_sent'))),
                                );
                              } catch (e) {
                                setSheetState(() => isSending = false);
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(content: Text(context.tArgs('report_dialog.error_message', {'error': '$e'}))),
                                );
                              }
                            },
                      child: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(context.t('report_dialog.submit_button')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
