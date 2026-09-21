import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';

/// Полноэкранный просмотр историй — как в Instagram: свайп по горизонтали
/// между людьми (PageView), тап слева/справа внутри — назад/вперёд по
/// историям одного человека, авто-переход по таймеру с прогресс-баром.
class StoryViewerScreen extends StatefulWidget {
  final List<dynamic> rings; // фид: [{user, stories_count, has_unseen, latest_created_at}, ...]
  final int initialIndex;

  const StoryViewerScreen({Key? key, required this.rings, required this.initialIndex}) : super(key: key);

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late final PageController _pageController;
  late int _userIndex;

  @override
  void initState() {
    super.initState();
    _userIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _userIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToUser(int index) {
    if (index < 0 || index >= widget.rings.length) {
      Navigator.pop(context);
      return;
    }
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.rings.length,
        onPageChanged: (i) => setState(() => _userIndex = i),
        itemBuilder: (context, index) {
          final ring = widget.rings[index] as Map<String, dynamic>;
          final user = ring['user'] as Map<String, dynamic>?;
          return _UserStoriesPage(
            key: ValueKey(user?['id']),
            userId: (user?['id'] ?? '').toString(),
            username: (user?['username'] as String?) ?? '?',
            avatarUrl: user?['avatar_url'] as String?,
            isActive: index == _userIndex,
            onFinished: () => _goToUser(index + 1),
            onPrevUser: () => _goToUser(index - 1),
          );
        },
      ),
    );
  }
}

class _UserStoriesPage extends StatefulWidget {
  final String userId;
  final String username;
  final String? avatarUrl;
  final bool isActive;
  final VoidCallback onFinished;
  final VoidCallback onPrevUser;

  const _UserStoriesPage({
    Key? key,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.isActive,
    required this.onFinished,
    required this.onPrevUser,
  }) : super(key: key);

  @override
  State<_UserStoriesPage> createState() => _UserStoriesPageState();
}

class _UserStoriesPageState extends State<_UserStoriesPage> with SingleTickerProviderStateMixin {
  static const Duration _storyDuration = Duration(seconds: 5);

  List<dynamic> _stories = [];
  bool _isLoading = true;
  int _index = 0;
  AnimationController? _controller;

  String? get _token => Provider.of<AuthProvider>(context, listen: false).accessToken;
  String? get _myId => Provider.of<AuthProvider>(context, listen: false).user?['id'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _UserStoriesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller?.forward(from: _controller!.value);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.stop();
    }
  }

  Future<void> _load() async {
    try {
      final response = await ApiService.get('/api/stories/user/${widget.userId}', token: _token);
      final items = response is List ? response : [];
      if (!mounted) return;
      setState(() {
        _stories = items;
        _isLoading = false;
      });
      if (_stories.isNotEmpty) {
        _startTimer();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFinished());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFinished());
    }
  }

  void _startTimer() {
    _controller?.dispose();
    final controller = AnimationController(vsync: this, duration: _storyDuration);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _next();
    });
    _controller = controller;
    if (widget.isActive) controller.forward();
    setState(() {});
  }

  void _next() {
    if (_index < _stories.length - 1) {
      setState(() => _index += 1);
      _startTimer();
    } else {
      widget.onFinished();
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() => _index -= 1);
      _startTimer();
    } else {
      widget.onPrevUser();
    }
  }

  Future<void> _delete() async {
    final story = _stories[_index] as Map<String, dynamic>;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('story_viewer.delete_title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('common.cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.t('common.delete'))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.delete('/api/stories/${story['id']}', token: _token);
      if (!mounted) return;
      setState(() => _stories.removeAt(_index));
      if (_stories.isEmpty) {
        widget.onFinished();
      } else {
        if (_index >= _stories.length) _index = _stories.length - 1;
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('story_viewer.delete_failed', {'error': '$e'}))));
      }
    }
  }

  Widget _buildSegment(int i) {
    double filled;
    if (i < _index) {
      filled = 1.0;
    } else if (i > _index) {
      filled = 0.0;
    } else {
      filled = _controller?.value ?? 0.0;
    }
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: filled,
            heightFactor: 1,
            child: Container(color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: AppLoader(color: Colors.white));
    }
    if (_stories.isEmpty) {
      return const SizedBox.shrink();
    }

    final story = _stories[_index] as Map<String, dynamic>;
    final isMine = story['is_mine'] == true || story['user_id'] == _myId;
    final imageUrl = (story['image_url'] ?? '').toString();
    final fullImageUrl = imageUrl.startsWith('http')
        ? imageUrl
        : 'https://pacific-analysis-production.up.railway.app$imageUrl';

    return GestureDetector(
      onTapUp: (details) {
        final width = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < width / 3) {
          _prev();
        } else {
          _next();
        }
      },
      onLongPressStart: (_) => _controller?.stop(),
      onLongPressEnd: (_) {
        if (widget.isActive) _controller?.forward();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(fullImageUrl, fit: BoxFit.cover),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: AnimatedBuilder(
                      animation: _controller ?? const AlwaysStoppedAnimation(0.0),
                      builder: (context, _) => Row(
                        children: List.generate(_stories.length, _buildSegment),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white24,
                          backgroundImage: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                              ? NetworkImage(widget.avatarUrl!)
                              : null,
                          child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                              ? Text(
                                  widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.username,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isMine)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white),
                            onPressed: _delete,
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if ((story['caption'] ?? '').toString().isNotEmpty)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: Text(
                story['caption'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (isMine)
            Positioned(
              bottom: 8,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text('${story['views_count'] ?? 0}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
