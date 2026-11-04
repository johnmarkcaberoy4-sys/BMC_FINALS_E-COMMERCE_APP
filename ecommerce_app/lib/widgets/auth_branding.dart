import 'package:flutter/material.dart';

class AuthBackdrop extends StatelessWidget {
  final Widget child;

  const AuthBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF10091C), Color(0xFF08060D), Color(0xFF130A20)],
            ),
          ),
        ),
        const Positioned(
          top: -150,
          right: -100,
          child: _GlowOrb(size: 330, color: Color(0x557C3AED)),
        ),
        const Positioned(
          bottom: -180,
          left: -140,
          child: _GlowOrb(size: 380, color: Color(0x334C1D95)),
        ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withAlpha(0)],
          ),
        ),
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D8B5CF6),
                blurRadius: 46,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Image.asset(
            'asset/image/aetherix_logo.png',
            height: 124,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Shop smarter. Live Aetherix.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Find something you’ll love.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFC9BED8),
              ),
        ),
      ],
    );
  }
}
