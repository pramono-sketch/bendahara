// lib/helpers/scroll_reveal.dart
import 'package:flutter/material.dart';

/// Reusable scroll reveal animation.
///
/// Widget akan muncul ketika masuk ke viewport dengan kombinasi:
/// - Fade
/// - Slide dari bawah
/// - Scale
///
/// Animasi hanya dijalankan satu kali per widget.
class ScrollReveal extends StatefulWidget {
  final Widget child;

  /// Jeda sebelum animasi dimulai setelah widget terlihat.
  final Duration delay;

  /// Durasi animasi.
  final Duration duration;

  /// Curve yang digunakan untuk animasi.
  final Curve curve;

  /// Posisi awal slide.
  ///
  /// Contoh:
  /// Offset(0, 0.12) = bergerak dari bawah.
  /// Offset(0.12, 0) = bergerak dari kanan.
  final Offset beginOffset;

  /// Scale awal sebelum animasi.
  final double beginScale;

  /// Batas atas area yang dianggap visible.
  final double topVisibility;

  /// Persentase tinggi layar sebagai batas bawah visibility.
  final double bottomVisibility;

  const ScrollReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 650),
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(0, 0.12),
    this.beginScale = 0.96,
    this.topVisibility = 70,
    this.bottomVisibility = 0.92,
  });

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  late final Animation<double> _scale;

  final GlobalKey _key = GlobalKey();

  ScrollPosition? _scrollPosition;

  bool _hasAnimated = false;
  bool _isScheduled = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    // ---------------------------------------------------------
    // FADE
    // ---------------------------------------------------------

    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(curvedAnimation);

    // ---------------------------------------------------------
    // SLIDE
    // ---------------------------------------------------------

    _offset = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(curvedAnimation);

    // ---------------------------------------------------------
    // SCALE
    // ---------------------------------------------------------

    _scale = Tween<double>(
      begin: widget.beginScale,
      end: 1,
    ).animate(curvedAnimation);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _attachScrollListener();
  }

  // =========================================================
  // HUBUNGKAN KE SCROLLABLE
  // =========================================================

  void _attachScrollListener() {
    try {
      final position = Scrollable.of(context).position;

      if (_scrollPosition == position) {
        return;
      }

      _scrollPosition?.removeListener(_onScroll);

      _scrollPosition = position;

      _scrollPosition?.addListener(_onScroll);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkVisibility();
      });
    } catch (_) {
      // Scrollable belum tersedia.
      //
      // Tidak perlu melakukan apa-apa.
      // Lifecycle berikutnya akan mencoba kembali.
    }
  }

  // =========================================================
  // SCROLL LISTENER
  // =========================================================

  void _onScroll() {
    _checkVisibility();
  }

  // =========================================================
  // CEK VISIBILITY
  // =========================================================

  void _checkVisibility() {
    if (!mounted || _hasAnimated || _isScheduled) {
      return;
    }

    final context = _key.currentContext;

    if (context == null) {
      return;
    }

    final renderObject = context.findRenderObject();

    if (renderObject is! RenderBox || !renderObject.attached) {
      return;
    }

    final position = renderObject.localToGlobal(Offset.zero);

    final size = renderObject.size;

    final screenHeight = MediaQuery.of(context).size.height;

    final top = position.dy;

    final bottom = position.dy + size.height;

    final isVisible =
        bottom > widget.topVisibility &&
        top < screenHeight * widget.bottomVisibility;

    if (!isVisible) {
      return;
    }

    _hasAnimated = true;
    _isScheduled = true;

    Future.delayed(widget.delay, () {
      if (!mounted) {
        return;
      }

      _controller.forward();
    });
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);

    _controller.dispose();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          child: ScaleTransition(
            scale: _scale,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
