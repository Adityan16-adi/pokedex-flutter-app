import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide theme, colors, typography, and reusable glassmorphism widgets.
class AppTheme {
  // Brand colors taken from the logo and Pokédex identity
  static const Color primaryRed = Color(0xFFC8283A);
  static const Color darkRed = Color(0xFF881420);
  static const Color charcoal = Color(0xFF1F1F1F);
  static const Color darkCharcoal = Color(0xFF121214);
  static const Color lightGray = Color(0xFFF6F7F9);

  /// Light theme definition
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        brightness: Brightness.light,
        primary: primaryRed,
        surface: lightGray,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
    );
  }

  /// Dark theme definition
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        brightness: Brightness.dark,
        primary: primaryRed,
        surface: darkCharcoal,
      ),
      scaffoldBackgroundColor: darkCharcoal,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
    );
  }
}

/// A reusable glassmorphic container widget featuring BackdropFilter blur,
/// semi-transparent fill, subtle borders, and soft shadows.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 12,
    this.color,
    this.border,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Semi-transparent fills tailored for light & dark modes
    final defaultBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.70);

    final defaultBorder = Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.white.withValues(alpha: 0.50),
      width: 1.0,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: color ?? defaultBg,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: border ?? defaultBorder,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dynamic ambient gradient background with soft blurred color blobs
/// placed underneath the glass surfaces.
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base charcoal-to-dark-red gradient background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xFF131316),
                        Color(0xFF1B1619),
                        Color(0xFF2B0F15),
                      ]
                    : const [
                        Color(0xFFF7F8FA),
                        Color(0xFFFDF0F2),
                        Color(0xFFFAECEE),
                      ],
              ),
            ),
          ),
        ),

        // Blurred color blob 1 - Top right red accent
        Positioned(
          top: -40,
          right: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryRed.withValues(
                alpha: isDark ? 0.28 : 0.16,
              ),
            ),
          ),
        ),

        // Blurred color blob 2 - Middle left subtle cyan/blue accent
        Positioned(
          top: 260,
          left: -70,
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A90E2).withValues(
                alpha: isDark ? 0.16 : 0.09,
              ),
            ),
          ),
        ),

        // Blurred color blob 3 - Bottom right warm amber accent
        Positioned(
          bottom: -50,
          right: 10,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE2843A).withValues(
                alpha: isDark ? 0.18 : 0.10,
              ),
            ),
          ),
        ),

        // Soft atmospheric blur over background blobs
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
            child: const SizedBox.expand(),
          ),
        ),

        // Foreground screen content
        child,
      ],
    );
  }
}
