import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../../../data/storage_keys.dart';
import '../../auth/providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static Future<bool> checkAndShow(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(StorageKeys.hasSeenOnboarding) ?? false;
    if (hasSeen) return false;

    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
          fullscreenDialog: true,
        ),
      );
      await prefs.setBool(StorageKeys.hasSeenOnboarding, true);
      return true;
    }
    return false;
  }

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      assetName: 'welcome',
      title: 'Smart Naam Jap',
      subtitle: 'नाम जप',
      description:
          'A distraction-free counter for your daily naam jap. '
          'Tap to count, watch your malas grow, and deepen your practice.',
    ),
    _OnboardingPage(
      assetName: 'focus',
      title: 'Focus on the Divine',
      subtitle: 'Center Image',
      description:
          'Place your beloved deity image — Radha-Krishna, Ram, Hanuman, '
          'or any ishta — at the center of the mala beads. Stay connected while you chant.',
    ),
    _OnboardingPage(
      assetName: 'cloud',
      title: 'Cloud Sync',
      subtitle: 'Never Lose Progress',
      description:
          'Sign in with Google to automatically back up your counts '
          'and streaks. Switch devices seamlessly — your data follows you.',
    ),
    _OnboardingPage(
      assetName: 'leaderboard',
      title: 'Global Leaderboard',
      subtitle: 'Coming Soon',
      description:
          'Connect with the community. See how your practice grows '
          'alongside others and stay motivated together.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish() async {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }
    await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _skip() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, right: 16),
              child: Align(
                alignment: Alignment.topRight,
                child: _currentPage < _pages.length - 1
                    ? TextButton(
                        onPressed: _skip,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.outfit(
                            color: AppColors.textMuted,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _PageContent(page: _pages[index]);
                },
              ),
            ),
            _BottomBar(
              pageCount: _pages.length,
              currentPage: _currentPage,
              onNext: _nextPage,
              onFinish: _finish,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;

  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (page.assetName == 'welcome')
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 120,
                height: 120,
              ),
            )
          else if (page.assetName == 'focus')
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'lib/features/onboarding/assets/focus_preview.png',
                  height: 280,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            _PageIllustration(assetName: page.assetName),
          SizedBox(height: page.assetName == 'focus' ? 24 : 48),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIllustration extends StatelessWidget {
  final String assetName;

  const _PageIllustration({required this.assetName});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: CustomPaint(
        painter: _IllustrationPainter(assetName: assetName),
        size: const Size(double.infinity, 220),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  final String assetName;

  _IllustrationPainter({required this.assetName});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final themePalette = ThemeColorPalette.forTheme(AppColors.currentTheme);
    final primary = themePalette.primary;

    switch (assetName) {
      case 'focus':
        _drawMalaWithDeity(canvas, center, primary, size);
      case 'cloud':
        _drawCloud(canvas, center, primary, size);
      case 'leaderboard':
        _drawLeaderboard(canvas, center, primary, size);
    }
  }

  void _drawMalaWithDeity(Canvas canvas, Offset center, Color primary, Size size) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [primary.withValues(alpha: 0.2), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: 100));

    canvas.drawCircle(center, 100, glowPaint);

    for (int i = 0; i < 108; i++) {
      final angle = (i / 108) * math.pi * 2 - math.pi / 2;
      final radius = 80.0;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      final isMeru = i == 0;
      canvas.drawCircle(
        Offset(x, y),
        isMeru ? 5 : 3,
        Paint()..color = isMeru ? primary : primary.withValues(alpha: 0.45),
      );
    }

    final innerCircle = Paint()
      ..color = AppColors.cardBackground
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 32, innerCircle);
    canvas.drawCircle(center, 32, Paint()
      ..color = primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    final deityPaint = Paint()
      ..color = primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 24, deityPaint);

    final petalPaint = Paint()..color = primary.withValues(alpha: 0.4);
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2;
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * 16,
          center.dy + math.sin(angle) * 16,
        ),
        5,
        petalPaint,
      );
    }

    canvas.drawCircle(center, 6, Paint()..color = primary);
  }

  void _drawCloud(Canvas canvas, Offset center, Color primary, Size size) {
    canvas.drawCircle(
      center,
      100,
      Paint()
        ..shader = RadialGradient(
          colors: [primary.withValues(alpha: 0.15), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: 100)),
    );

    final cloudPaint = Paint()
      ..color = primary.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(center.dx - 25, center.dy), radius: 28))
      ..addOval(Rect.fromCircle(center: Offset(center.dx + 25, center.dy), radius: 28))
      ..addOval(Rect.fromCircle(center: Offset(center.dx, center.dy - 18), radius: 32))
      ..addOval(Rect.fromCircle(center: Offset(center.dx, center.dy + 5), radius: 24));
    canvas.drawPath(path, cloudPaint);

    final arrowPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - 50, center.dy - 55), Offset(center.dx - 50, center.dy - 80), arrowPaint);
    canvas.drawLine(Offset(center.dx - 50, center.dy - 80), Offset(center.dx - 40, center.dy - 72), arrowPaint);
    canvas.drawLine(Offset(center.dx - 50, center.dy - 80), Offset(center.dx - 60, center.dy - 72), arrowPaint);

    final devicePaint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + 55, center.dy - 60), width: 24, height: 36),
        const Radius.circular(4),
      ),
      devicePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + 55, center.dy - 60), width: 18, height: 28),
        const Radius.circular(2),
      ),
      Paint()..color = primary.withValues(alpha: 0.3),
    );
  }

  void _drawLeaderboard(Canvas canvas, Offset center, Color primary, Size size) {
    canvas.drawCircle(
      center,
      100,
      Paint()
        ..shader = RadialGradient(
          colors: [primary.withValues(alpha: 0.15), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: 100)),
    );

    final positions = [
      (Offset(center.dx, center.dy + 25), 50.0, primary.withValues(alpha: 0.9)),
      (Offset(center.dx - 35, center.dy + 45), 35.0, primary.withValues(alpha: 0.5)),
      (Offset(center.dx + 35, center.dy + 45), 35.0, primary.withValues(alpha: 0.5)),
    ];
    for (final (pos, width, color) in positions) {
      final podiumPath = Path()
        ..moveTo(pos.dx - width / 2, pos.dy)
        ..lineTo(pos.dx + width / 2, pos.dy)
        ..lineTo(pos.dx + width / 2 - 5, pos.dy + 40)
        ..lineTo(pos.dx - width / 2 + 5, pos.dy + 40)
        ..close();
      canvas.drawPath(podiumPath, Paint()..color = color);
    }

    final crownPath = Path()
      ..moveTo(center.dx - 12, center.dy - 5)
      ..lineTo(center.dx - 8, center.dy - 22)
      ..lineTo(center.dx - 3, center.dy - 12)
      ..lineTo(center.dx, center.dy - 25)
      ..lineTo(center.dx + 3, center.dy - 12)
      ..lineTo(center.dx + 8, center.dy - 22)
      ..lineTo(center.dx + 12, center.dy - 5)
      ..close();
    canvas.drawPath(crownPath, Paint()
      ..color = primary
      ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter oldDelegate) {
    return oldDelegate.assetName != assetName;
  }
}

class _BottomBar extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  const _BottomBar({
    required this.pageCount,
    required this.currentPage,
    required this.onNext,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            pageCount,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: currentPage == index
                    ? AppColors.primary
                    : AppColors.textMuted.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: currentPage == pageCount - 1 ? onFinish : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                currentPage == pageCount - 1
                    ? 'Sign in & Get Started'
                    : 'Continue',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        if (currentPage == pageCount - 1) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue Offline',
              style: GoogleFonts.outfit(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OnboardingPage {
  final String assetName;
  final String title;
  final String subtitle;
  final String description;

  const _OnboardingPage({
    required this.assetName,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}
