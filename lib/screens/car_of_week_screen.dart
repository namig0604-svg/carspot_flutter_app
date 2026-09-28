import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';
import '../widgets/car_picker_field.dart';
import '../utils/image_url.dart';
import '../l10n/l10n_extensions.dart';

/// Голосование «Машина недели»: список заявок текущей ISO-недели
/// (GET /api/car-of-week/entries, отсортирован сервером по votes_count),
/// голосование (POST .../vote — повторный вызов снимает голос), своя
/// заявка (POST /api/car-of-week/entries) и баннер победителя прошлой
/// недели (GET /api/car-of-week/winner).
class CarOfWeekScreen extends StatefulWidget {
  const CarOfWeekScreen({Key? key}) : super(key: key);

  @override
  State<CarOfWeekScreen> createState() => _CarOfWeekScreenState();
}

class _CarOfWeekScreenState extends State<CarOfWeekScreen> {
  List<dynamic> _items = [];
  Map<String, dynamic>? _winner;
  bool _isLoading = false;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final results = await Future.wait([
        ApiService.get('/api/car-of-week/entries', token: authProvider.accessToken),
        ApiService.get('/api/car-of-week/winner', token: authProvider.accessToken),
      ]);
      final entriesResponse = results[0];
      final winnerResponse = results[1];
      setState(() {
        _items = (entriesResponse is Map && entriesResponse['items'] is List) ? entriesResponse['items'] : [];
        _winner = winnerResponse is Map<String, dynamic> ? winnerResponse : null;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _vote(String entryId) async {
    if (_isVoting) return;
    setState(() => _isVoting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.post('/api/car-of-week/entries/$entryId/vote', {}, token: authProvider.accessToken);
      if (response is Map<String, dynamic>) {
        setState(() {
          final idx = _items.indexWhere((e) => e['id'] == entryId);
          if (idx != -1) _items[idx] = response;
          _items.sort((a, b) => ((b['votes_count'] as num?) ?? 0).compareTo((a['votes_count'] as num?) ?? 0));
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }

  Future<void> _delete(String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t('car_of_week.delete_confirm_title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(dialogContext.t('common.cancel'))),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(dialogContext.t('common.delete'))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.delete('/api/car-of-week/entries/$entryId', token: authProvider.accessToken);
      if (mounted) setState(() => _items.removeWhere((e) => e['id'] == entryId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    }
  }

  bool get _alreadyNominated {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myId = authProvider.user?['id'];
    return _items.any((e) => e['user_id'] == myId);
  }

  Future<void> _openNominateDialog() async {
    String? selectedCarId;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dialogContext.t('car_of_week.nominate_dialog_title')),
          content: SizedBox(
            width: double.maxFinite,
            child: CarPickerField(onSelected: (car) => selectedCarId = car['id'] as String?),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(dialogContext.t('common.cancel'))),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: Text(dialogContext.t('car_of_week.nominate_submit')),
            ),
          ],
        );
      },
    );
    if (submitted != true || selectedCarId == null) return;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.post('/api/car-of-week/entries', {'car_id': selectedCarId}, token: authProvider.accessToken);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('car_of_week.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
      ),
      backgroundColor: AppColors.scaffoldBg(context),
      floatingActionButton: _alreadyNominated
          ? null
          : FloatingActionButton.extended(
              onPressed: _openNominateDialog,
              backgroundColor: Colors.deepPurple,
              icon: const Icon(Icons.add),
              label: Text(context.t('car_of_week.nominate_button')),
            ),
      body: _isLoading
          ? const Center(child: AppFullLoader())
          : RefreshIndicator(
              color: Colors.deepPurple,
              backgroundColor: AppColors.surface(context),
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_winner != null) _buildWinnerBanner(context, _winner!),
                  if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          context.t('car_of_week.empty'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted(context)),
                        ),
                      ),
                    )
                  else
                    ..._items.asMap().entries.map(
                          (entry) => _buildEntryCard(context, entry.value as Map<String, dynamic>, entry.key),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildWinnerBanner(BuildContext context, Map<String, dynamic> winner) {
    final car = winner['car'] as Map<String, dynamic>?;
    final owner = winner['owner'] as Map<String, dynamic>?;
    final photoUrl = car?['photo_url'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.amber, Colors.deepOrange]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('car_of_week.winner_banner_title'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '${car?['make'] ?? ''} ${car?['model'] ?? ''}'.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                if (owner != null)
                  Text(
                    owner['full_name'] ?? owner['username'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (photoUrl != null && photoUrl.isNotEmpty)
                ? Image.network(resolveImageUrl(photoUrl), width: 52, height: 52, fit: BoxFit.cover)
                : Container(
                    width: 52,
                    height: 52,
                    color: Colors.white24,
                    child: const Icon(Icons.directions_car, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, Map<String, dynamic> item, int index) {
    final car = item['car'] as Map<String, dynamic>?;
    final owner = item['owner'] as Map<String, dynamic>?;
    final photoUrl = car?['photo_url'] as String?;
    final isMine = item['is_mine'] == true;
    final myVoted = item['my_voted'] == true;
    final votesCount = (item['votes_count'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: index == 0 ? Colors.amber : AppColors.border(context),
          width: index == 0 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '#${index + 1}',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted(context), fontWeight: FontWeight.bold),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (photoUrl != null && photoUrl.isNotEmpty)
                ? Image.network(resolveImageUrl(photoUrl), width: 56, height: 56, fit: BoxFit.cover)
                : Container(
                    width: 56,
                    height: 56,
                    color: AppColors.surfaceAlt(context),
                    child: Icon(Icons.directions_car, color: AppColors.textMuted(context)),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${car?['make'] ?? ''} ${car?['model'] ?? ''}'.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.onSurface(context), fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  isMine ? context.t('car_of_week.self_entry_label') : (owner?['full_name'] ?? owner?['username'] ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tArgs('car_of_week.votes_label', {'count': '$votesCount'}),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.deepPurple),
                ),
              ],
            ),
          ),
          if (isMine)
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.red),
              onPressed: () => _delete(item['id'] as String),
            )
          else
            IconButton(
              icon: Icon(
                myVoted ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                color: myVoted ? Colors.deepPurple : AppColors.textMuted(context),
              ),
              onPressed: _isVoting ? null : () => _vote(item['id'] as String),
            ),
        ],
      ),
    );
  }
}
