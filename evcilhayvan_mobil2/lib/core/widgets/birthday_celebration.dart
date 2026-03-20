import 'dart:math';
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';

/// Check if any of the given pets has a birthday today (same month & day).
List<Pet> getBirthdayPets(List<Pet> pets) {
  final now = DateTime.now();
  return pets.where((p) {
    final bd = p.birthDate;
    if (bd == null) return false;
    return bd.month == now.month && bd.day == now.day;
  }).toList();
}

class BirthdayCelebrationDialog extends StatefulWidget {
  final List<Pet> birthdayPets;
  const BirthdayCelebrationDialog({super.key, required this.birthdayPets});

  @override
  State<BirthdayCelebrationDialog> createState() => _BirthdayCelebrationDialogState();
}

class _BirthdayCelebrationDialogState extends State<BirthdayCelebrationDialog>
    with TickerProviderStateMixin {
  late AnimationController _confettiCtrl;
  late List<_Confetti> _confettiList;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _scaleCtrl.forward();

    final rng = Random();
    _confettiList = List.generate(60, (_) => _Confetti(rng));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final names = widget.birthdayPets.map((p) => p.name).join(', ');

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎂', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 12),
                  Text(
                    'Dogum Gunu!',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$names bugün dogum gununü kutluyor! 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Minik dostunuza sürpriz bir ikram yapmayi unutmayin! 🐾',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: const Text('Kutla! 🎊', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            // Confetti overlay
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _confettiCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(_confettiList, _confettiCtrl.value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Confetti {
  final double x;
  final double speed;
  final double size;
  final Color color;
  final double rotation;
  final double phase;

  _Confetti(Random rng)
      : x = rng.nextDouble(),
        speed = 0.2 + rng.nextDouble() * 0.5,
        size = 6 + rng.nextDouble() * 8,
        color = _kColors[rng.nextInt(_kColors.length)],
        rotation = rng.nextDouble() * 2 * pi,
        phase = rng.nextDouble();

  static const _kColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6B9D),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFFF6B6B),
  ];
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confetti;
  final double progress;

  _ConfettiPainter(this.confetti, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in confetti) {
      final t = (progress * c.speed + c.phase) % 1.0;
      final x = c.x * size.width;
      final y = t * (size.height + 40) - 20;
      final paint = Paint()..color = c.color.withOpacity(0.85);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(c.rotation + progress * pi * 2);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}
