import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// ============================================================
///  LOTTIE ANIMATION GALLERY
///  Halaman untuk menampilkan & memutar semua animasi JSON Lottie
/// ============================================================

class LottieAnimationGallery extends StatefulWidget {
  const LottieAnimationGallery({super.key});

  static const List<LottieAnimationItem> animations = [
    LottieAnimationItem(
      name: 'Splash Animation',
      description: 'Animasi pembuka aplikasi',
      assetPath: 'assets/animations/splash_animation.json',
      category: 'Splash',
      primaryColor: Color(0xFF1976D2),
    ),
    LottieAnimationItem(
      name: 'Loading',
      description: 'Indikator loading',
      assetPath: 'assets/animations/loading.json',
      category: 'Loading',
      primaryColor: Color(0xFFFF9800),
    ),
    LottieAnimationItem(
      name: 'Error 404',
      description: 'Halaman tidak ditemukan',
      assetPath: 'assets/animations/Error 404.json',
      category: 'Error',
      primaryColor: Color(0xFFE53935),
    ),
    LottieAnimationItem(
      name: 'Game Controller',
      description: 'Animasi game controller',
      assetPath: 'assets/animations/Game Controller.json',
      category: 'Gaming',
      primaryColor: Color(0xFF8E24AA),
    ),
    LottieAnimationItem(
      name: 'Gaming',
      description: 'Animasi gaming',
      assetPath: 'assets/animations/gaming.json',
      category: 'Gaming',
      primaryColor: Color(0xFF00897B),
    ),
    LottieAnimationItem(
      name: 'AI Animation Flow 1',
      description: 'Alur animasi AI',
      assetPath: 'assets/animations/ai animation Flow 1.json',
      category: 'AI',
      primaryColor: Color(0xFF3949AB),
    ),
  ];

  @override
  State<LottieAnimationGallery> createState() => _LottieAnimationGalleryState();
}

class _LottieAnimationGalleryState extends State<LottieAnimationGallery> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  List<String> get _categories {
    final cats = <String>{'Semua'};
    for (final a in LottieAnimationGallery.animations) {
      cats.add(a.category);
    }
    return cats.toList();
  }

  List<LottieAnimationItem> get _filteredAnimations {
    return LottieAnimationGallery.animations.where((a) {
      final matchCategory =
          _selectedCategory == 'Semua' || a.category == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  void _openFullScreen(LottieAnimationItem item) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _LottieFullScreenViewer(item: item),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lottie Gallery',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D47A1),
                Color(0xFF1565C0),
                Color(0xFF1976D2),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE3E9F2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Cari animasi...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF1976D2)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFF1976D2), width: 1.5),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                        selectedColor: const Color(0xFF1976D2),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF1976D2)
                              : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: _filteredAnimations.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: _filteredAnimations.length,
                        itemBuilder: (context, index) {
                          final item = _filteredAnimations[index];
                          return _AnimationCard(
                            item: item,
                            onTap: () => _openFullScreen(item),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: Colors.white.withValues(alpha: 0.6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.movie_filter_rounded,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Total: ${LottieAnimationGallery.animations.length} animasi • Lottie',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Animasi tidak ditemukan',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba kata kunci atau kategori lain',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimationCard extends StatefulWidget {
  final LottieAnimationItem item;
  final VoidCallback onTap;

  const _AnimationCard({required this.item, required this.onTap});

  @override
  State<_AnimationCard> createState() => _AnimationCardState();
}

class _AnimationCardState extends State<_AnimationCard>
    with AutomaticKeepAliveClientMixin {
  LottieComposition? _composition;
  bool _loaded = false;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadComposition();
  }

  Future<void> _loadComposition() async {
    try {
      final composition =
          await AssetLottie(widget.item.assetPath).load();
      if (!mounted) return;
      setState(() {
        _composition = composition;
        _loaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.item.primaryColor.withValues(alpha: 0.12),
                          widget.item.primaryColor.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: _hasError
                              ? Icon(
                                  Icons.broken_image_rounded,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                )
                              : !_loaded
                                  ? SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: widget.item.primaryColor,
                                      ),
                                    )
                                  : Lottie(
                                      composition: _composition,
                                      repeat: true,
                                      fit: BoxFit.contain,
                                      renderCache:
                                          RenderCache.drawingCommands,
                                    ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: widget.item.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.item.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.fullscreen_rounded,
                              size: 14,
                              color: widget.item.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LottieFullScreenViewer extends StatefulWidget {
  final LottieAnimationItem item;

  const _LottieFullScreenViewer({required this.item});

  @override
  State<_LottieFullScreenViewer> createState() =>
      _LottieFullScreenViewerState();
}

class _LottieFullScreenViewerState extends State<_LottieFullScreenViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  LottieComposition? _composition;
  bool _loaded = false;
  bool _hasError = false;
  bool _isPlaying = true;
  bool _repeat = true;
  double _speed = 1.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _loadComposition();
  }

  Future<void> _loadComposition() async {
    try {
      final composition =
          await AssetLottie(widget.item.assetPath).load();
      if (!mounted) return;
      setState(() {
        _composition = composition;
        _loaded = true;
      });
      _controller.duration = composition.duration * (1 / _speed);
      if (_repeat) {
        _controller.repeat();
      } else {
        _controller.forward();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.isAnimating) {
        _controller.stop();
        _isPlaying = false;
      } else {
        if (_controller.isCompleted) {
          _controller.reset();
        }
        if (_repeat) {
          _controller.repeat();
        } else {
          _controller.forward();
        }
        _isPlaying = true;
      }
    });
  }

  void _toggleRepeat() {
    setState(() {
      _repeat = !_repeat;
      if (_isPlaying) {
        _controller.stop();
        _controller.reset();
        if (_repeat) {
          _controller.repeat();
        } else {
          _controller.forward();
        }
      }
    });
  }

  void _changeSpeed(double newSpeed) {
    setState(() {
      _speed = newSpeed;
      _controller.duration = _composition!.duration * (1 / _speed);
    });
  }

  void _restart() {
    _controller.reset();
    if (_repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
    setState(() => _isPlaying = true);
  }

  String _formatDuration(Duration d) {
    final seconds = d.inMilliseconds / 1000;
    return '${seconds.toStringAsFixed(1)}s';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.item.primaryColor.withValues(alpha: 0.9),
              widget.item.primaryColor.withValues(alpha: 0.6),
              const Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.item.assetPath,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _restart,
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                      tooltip: 'Restart',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: _hasError
                      ? _buildErrorView()
                      : !_loaded
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            )
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: Lottie(
                                composition: _composition,
                                controller: _controller,
                                fit: BoxFit.contain,
                                renderCache: RenderCache.drawingCommands,
                              ),
                            ),
                ),
              ),
              if (_loaded && _composition != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        '0.0s',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              return SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape:
                                      const RoundSliderThumbShape(
                                          enabledThumbRadius: 6),
                                  overlayShape:
                                      const RoundSliderOverlayShape(
                                          overlayRadius: 12),
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor:
                                      Colors.white.withValues(alpha: 0.3),
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: _controller.value.clamp(0.0, 1.0),
                                  onChanged: (v) {
                                    _controller.value = v;
                                  },
                                  onChangeEnd: (v) {
                                    if (_isPlaying) {
                                      if (_repeat) {
                                        _controller.repeat();
                                      } else {
                                        _controller.forward();
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(_composition!.duration),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ControlButton(
                        icon: _repeat
                            ? Icons.repeat_rounded
                            : Icons.repeat_one_rounded,
                        label: _repeat ? 'Loop' : 'Once',
                        isActive: _repeat,
                        onPressed: _toggleRepeat,
                      ),
                      GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: widget.item.primaryColor,
                            size: 36,
                          ),
                        ),
                      ),
                      PopupMenuButton<double>(
                        onSelected: _changeSpeed,
                        itemBuilder: (_) => [
                          _speedMenuItem(0.5),
                          _speedMenuItem(0.75),
                          _speedMenuItem(1.0),
                          _speedMenuItem(1.5),
                          _speedMenuItem(2.0),
                        ],
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: _ControlButton(
                          icon: Icons.speed_rounded,
                          label: '${_speed}x',
                          isActive: false,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _infoRow('Kategori', widget.item.category),
                      const SizedBox(height: 8),
                      _infoRow('Deskripsi', widget.item.description),
                      const SizedBox(height: 8),
                      _infoRow(
                        'Durasi',
                        _formatDuration(_composition!.duration),
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        'Status',
                        _isPlaying ? 'Memutar' : 'Dijeda',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<double> _speedMenuItem(double speed) {
    return PopupMenuItem<double>(
      value: speed,
      child: Row(
        children: [
          Icon(
            _speed == speed
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 18,
            color: _speed == speed
                ? widget.item.primaryColor
                : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            '${speed}x',
            style: TextStyle(
              fontWeight:
                  _speed == speed ? FontWeight.w700 : FontWeight.w500,
              color: _speed == speed
                  ? widget.item.primaryColor
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // PERBAIKAN ERROR DI SINI (Menutup kurung Text dengan benar)
  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        Flexible(
          flex: 2,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat animasi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class LottieAnimationItem {
  final String name;
  final String description;
  final String assetPath;
  final String category;
  final Color primaryColor;

  const LottieAnimationItem({
    required this.name,
    required this.description,
    required this.assetPath,
    required this.category,
    required this.primaryColor,
  });
}