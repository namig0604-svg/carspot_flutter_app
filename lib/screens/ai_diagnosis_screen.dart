import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/business_category.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';
import 'businesses_list_screen.dart';

/// ИИ-диагностика по симптомам — CarSpot Premium. Чат с нейросетью
/// (Anthropic Claude на бэкенде, см. app/api/ai_diagnosis.py): владелец
/// описывает симптомы, ИИ уточняет детали и в конце предлагает вероятную
/// причину + категорию автосервиса, куда можно сразу перейти.
///
/// Переписка хранится только в памяти этого экрана — при выходе теряется
/// (бэкенд её тоже не сохраняет), это осознанное упрощение MVP.
class AiDiagnosisScreen extends StatefulWidget {
  final String? carId;

  const AiDiagnosisScreen({Key? key, this.carId}) : super(key: key);

  @override
  State<AiDiagnosisScreen> createState() => _AiDiagnosisScreenState();
}

class _AiDiagnosisScreenState extends State<AiDiagnosisScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  String? _suggestedCategory;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isSending = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.post(
        '/api/ai-diagnosis',
        {
          'messages': _messages,
          if (widget.carId != null) 'car_id': widget.carId,
        },
        token: authProvider.accessToken,
      );
      if (response is Map<String, dynamic>) {
        final reply = response['reply'] as String? ?? '';
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
          _suggestedCategory = response['suggested_category'] as String?;
        });
      }
    } on ApiException catch (e) {
      setState(() => _messages.add({'role': 'error', 'content': e.message}));
    } catch (e) {
      if (mounted) {
        setState(() => _messages.add({'role': 'error', 'content': '$e'}));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  Widget _bubble(BuildContext context, Map<String, String> msg, bool isDark) {
    final role = msg['role'];
    final isMe = role == 'user';
    final isError = role == 'error';
    final cardSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardText = isDark ? AppColors.textOnDark : AppColors.textOnLight;

    final bg = isMe ? AppColors.blue : (isError ? AppColors.red.withOpacity(0.15) : cardSurface);
    final fg = isMe ? Colors.white : (isError ? AppColors.red : cardText);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isMe ? 14 : 2),
              bottomRight: Radius.circular(isMe ? 2 : 14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe && !isError) ...[
                const Icon(Icons.auto_awesome, size: 15, color: Colors.amber),
                const SizedBox(width: 6),
              ],
              Flexible(child: Text(msg['content'] ?? '', style: TextStyle(color: fg))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardText = isDark ? AppColors.textOnDark : AppColors.textOnLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('ai_diagnosis.title')),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Text(
              context.t('ai_diagnosis.disclaimer'),
              style: TextStyle(fontSize: 11.5, color: cardText.withOpacity(0.55)),
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        context.t('ai_diagnosis.empty_hint'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cardText.withOpacity(0.6)),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _bubble(context, _messages[index], isDark),
                  ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: AppLoader(size: 20),
            ),
          if (_suggestedCategory != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: Icon(businessCategoryIcon(_suggestedCategory), size: 18),
                  label: Text(
                    context.tArgs('ai_diagnosis.open_businesses_cta', {
                      'category': businessCategoryLabel(context, _suggestedCategory),
                    }),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BusinessesListScreen(initialCategory: _suggestedCategory),
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      enabled: !_isSending,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: context.t('ai_diagnosis.input_hint'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.blue,
                    child: _isSending
                        ? const AppLoader(size: 18, color: Colors.white)
                        : IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 20),
                            onPressed: _send,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
