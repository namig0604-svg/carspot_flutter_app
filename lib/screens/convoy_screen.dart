import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/location_helper.dart';
import '../utils/map_config.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';

/// Конвой-режим: временная группа для совместной поездки с live-локацией
/// участников на общей карте (GET /api/convoy/mine, POST /api/convoy,
/// /join, /leave, /end, /{id}/destination). Пока экран открыт и
/// пользователь состоит в активном конвое, своя позиция периодически
/// шлётся на сервер (POST /api/location/update) — это и делает трансляцию
/// внутри конвоя рабочей независимо от обычной настройки приватности
/// геолокации (см. app/api/location.py:_visible_to на бэкенде).
class ConvoyScreen extends StatefulWidget {
  const ConvoyScreen({Key? key}) : super(key: key);

  @override
  State<ConvoyScreen> createState() => _ConvoyScreenState();
}

class _ConvoyScreenState extends State<ConvoyScreen> {
  Map<String, dynamic>? _convoy;
  bool _isLoading = true;
  bool _isBusy = false;

  Timer? _refreshTimer;
  Timer? _selfPositionTimer;

  static const _refreshInterval = Duration(seconds: 8);
  static const _selfPositionInterval = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _selfPositionTimer?.cancel();
    super.dispose();
  }

  String? get _token => Provider.of<AuthProvider>(context, listen: false).accessToken;

  void _startTimers() {
    _refreshTimer?.cancel();
    _selfPositionTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _refresh(showLoader: false));
    _selfPositionTimer = Timer.periodic(_selfPositionInterval, (_) => _pushSelfPosition());
    unawaited(_pushSelfPosition());
  }

  void _stopTimers() {
    _refreshTimer?.cancel();
    _selfPositionTimer?.cancel();
  }

  Future<void> _pushSelfPosition() async {
    final position = await determineCurrentPosition();
    if (position == null || !mounted) return;
    try {
      await ApiService.post(
        '/api/location/update',
        {'lat': position.latitude, 'lng': position.longitude},
        token: _token,
      );
    } catch (_) {
      // Тихо — карта конвоя работает и без своей метки, попробуем на следующем тике.
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await _refresh(showLoader: false);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refresh({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/api/convoy/mine', token: _token);
      final convoy = response is Map<String, dynamic> ? response : null;
      if (!mounted) return;
      setState(() => _convoy = convoy);
      if (convoy != null) {
        _startTimers();
      } else {
        _stopTimers();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    } finally {
      if (showLoader && mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createConvoy() async {
    final nameController = TextEditingController();
    final destinationController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t('convoy.create_dialog_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: dialogContext.t('convoy.name_label'), hintText: dialogContext.t('convoy.name_hint')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: destinationController,
              decoration: InputDecoration(labelText: dialogContext.t('convoy.destination_label_field')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(dialogContext.t('common.cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: Text(dialogContext.t('convoy.create_submit')),
          ),
        ],
      ),
    );
    if (submitted != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('convoy.name_required_hint'))));
      return;
    }
    try {
      await ApiService.post(
        '/api/convoy',
        {
          'name': name,
          if (destinationController.text.trim().isNotEmpty) 'destination_label': destinationController.text.trim(),
        },
        token: _token,
      );
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    }
  }

  Future<void> _joinConvoy() async {
    final codeController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t('convoy.join_dialog_title')),
        content: TextField(
          controller: codeController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: dialogContext.t('convoy.code_label')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(dialogContext.t('common.cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: Text(dialogContext.t('convoy.join_submit')),
          ),
        ],
      ),
    );
    if (submitted != true) return;
    final code = codeController.text.trim();
    if (code.isEmpty) return;
    try {
      await ApiService.post('/api/convoy/join', {'invite_code': code}, token: _token);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    }
  }

  Future<void> _leave() async {
    final convoyId = _convoy?['id'] as String?;
    if (convoyId == null || _isBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t('convoy.leave_confirm_title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(dialogContext.t('common.cancel'))),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(dialogContext.t('convoy.leave_button'))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isBusy = true);
    try {
      await ApiService.post('/api/convoy/$convoyId/leave', {}, token: _token);
      _stopTimers();
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _end() async {
    final convoyId = _convoy?['id'] as String?;
    if (convoyId == null || _isBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t('convoy.end_confirm_title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(dialogContext.t('common.cancel'))),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(dialogContext.t('convoy.end_button'))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isBusy = true);
    try {
      await ApiService.post('/api/convoy/$convoyId/end', {}, token: _token);
      _stopTimers();
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _editDestination() async {
    final convoyId = _convoy?['id'] as String?;
    if (convoyId == null) return;
    final controller = TextEditingController(text: (_convoy?['destination_label'] as String?) ?? '');
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t('convoy.edit_destination')),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: dialogContext.t('convoy.destination_title'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(dialogContext.t('common.cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: Text(dialogContext.t('common.save')),
          ),
        ],
      ),
    );
    if (submitted != true) return;
    try {
      await ApiService.post(
        '/api/convoy/$convoyId/destination',
        {'destination_label': controller.text.trim().isEmpty ? null : controller.text.trim()},
        token: _token,
      );
      _refresh(showLoader: false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('carpool.error', {'error': '$e'}))));
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('convoy.code_copied'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('convoy.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
      ),
      backgroundColor: AppColors.scaffoldBg(context),
      body: _isLoading
          ? const Center(child: AppLoader())
          : RefreshIndicator(
              color: Colors.deepPurple,
              backgroundColor: AppColors.surface(context),
              onRefresh: () => _refresh(showLoader: false),
              child: _convoy == null ? _buildEmptyState(context) : _buildActiveConvoy(context, _convoy!),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        Icon(Icons.route, size: 64, color: AppColors.textMuted(context)),
        const SizedBox(height: 16),
        Text(
          context.t('convoy.empty_title'),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.onSurface(context), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          context.t('convoy.empty_description'),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _createConvoy,
            icon: const Icon(Icons.add),
            label: Text(context.t('convoy.create_button')),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _joinConvoy,
            icon: const Icon(Icons.qr_code),
            label: Text(context.t('convoy.join_button')),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveConvoy(BuildContext context, Map<String, dynamic> convoy) {
    final members = (convoy['members'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final isCreator = members.any((m) => m['is_me'] == true && m['is_creator'] == true);
    final code = (convoy['invite_code'] as String?) ?? '';
    final destinationLabel = convoy['destination_label'] as String?;
    final destLat = (convoy['destination_lat'] as num?)?.toDouble();
    final destLng = (convoy['destination_lng'] as num?)?.toDouble();

    final positioned = members.where((m) => m['lat'] != null && m['lng'] != null).toList();
    LatLng center = defaultMapCenter;
    if (positioned.isNotEmpty) {
      final m = positioned.first;
      center = LatLng((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble());
    } else if (destLat != null && destLng != null) {
      center = LatLng(destLat, destLng);
    }

    return ListView(
      children: [
        SizedBox(
          height: 260,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(initialCenter: center, initialZoom: defaultMapZoom),
                children: [
                  TileLayer(
                    urlTemplate: activeTileUrlTemplate,
                    subdomains: tileSubdomains,
                    userAgentPackageName: mapUserAgentPackageName,
                  ),
                  MarkerLayer(
                    markers: [
                      if (destLat != null && destLng != null)
                        Marker(
                          point: LatLng(destLat, destLng),
                          width: 34,
                          height: 34,
                          child: const Icon(Icons.flag, color: Colors.amber, size: 30),
                        ),
                      ...positioned.map((m) {
                        final isMe = m['is_me'] == true;
                        return Marker(
                          point: LatLng((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble()),
                          width: 96,
                          height: 56,
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                constraints: const BoxConstraints(maxWidth: 90),
                                child: Text(
                                  isMe ? context.t('convoy.you_label') : (m['username'] ?? ''),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isMe ? AppColors.blue : Colors.deepPurple,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.directions_car, color: Colors.white, size: 14),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (convoy['name'] as String?) ?? '',
                style: TextStyle(color: AppColors.onSurface(context), fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.t('convoy.invite_code_title'), style: TextStyle(fontSize: 11, color: AppColors.textMuted(context))),
                          const SizedBox(height: 2),
                          Text(code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 3, color: Colors.deepPurple)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.copy), onPressed: () => _copyCode(code)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: isCreator ? _editDestination : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, color: AppColors.textMuted(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          (destinationLabel != null && destinationLabel.isNotEmpty) ? destinationLabel : context.t('convoy.no_destination'),
                          style: TextStyle(color: AppColors.onSurface(context)),
                        ),
                      ),
                      if (isCreator) Icon(Icons.edit, size: 16, color: AppColors.textMuted(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tArgs('convoy.members_title', {'count': '${members.length}'}),
                style: TextStyle(color: AppColors.onSurface(context), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...members.map((m) => _buildMemberTile(context, m)),
              const SizedBox(height: 20),
              if (isCreator)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isBusy ? null : _end,
                    icon: Icon(Icons.stop_circle_outlined, color: AppColors.red),
                    label: Text(context.t('convoy.end_button'), style: TextStyle(color: AppColors.red)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.red)),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isBusy ? null : _leave,
                  icon: Icon(Icons.exit_to_app, color: AppColors.textMuted(context)),
                  label: Text(context.t('convoy.leave_button'), style: TextStyle(color: AppColors.textMuted(context))),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberTile(BuildContext context, Map<String, dynamic> member) {
    final isMe = member['is_me'] == true;
    final isCreator = member['is_creator'] == true;
    final hasPosition = member['lat'] != null && member['lng'] != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isMe ? AppColors.blue : Colors.deepPurple,
            backgroundImage: (member['avatar_url'] != null && (member['avatar_url'] as String).isNotEmpty)
                ? NetworkImage(member['avatar_url'] as String)
                : null,
            child: (member['avatar_url'] == null || (member['avatar_url'] as String).isEmpty)
                ? Text((member['username'] ?? '?').toString().substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '${member['full_name'] ?? member['username'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.onSurface(context), fontWeight: FontWeight.w600),
                  ),
                ),
                if (isMe) Padding(padding: const EdgeInsets.only(left: 4), child: Text(context.t('convoy.you_label'), style: TextStyle(color: AppColors.textMuted(context), fontSize: 12))),
              ],
            ),
          ),
          if (isCreator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(context.t('convoy.creator_badge'), style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w700)),
            )
          else
            Icon(
              hasPosition ? Icons.location_on : Icons.location_searching,
              size: 16,
              color: hasPosition ? Colors.deepPurple : AppColors.textMuted(context),
            ),
        ],
      ),
    );
  }
}
