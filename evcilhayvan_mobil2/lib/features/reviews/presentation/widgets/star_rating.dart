// lib/features/reviews/presentation/widgets/star_rating.dart

import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color color;
  final Color emptyColor;
  final bool allowHalf;

  const StarRating({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 20,
    this.color = Colors.amber,
    this.emptyColor = Colors.grey,
    this.allowHalf = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        final starValue = index + 1;
        IconData icon;

        if (allowHalf) {
          if (rating >= starValue) {
            icon = Icons.star;
          } else if (rating >= starValue - 0.5) {
            icon = Icons.star_half;
          } else {
            icon = Icons.star_border;
          }
        } else {
          icon = rating >= starValue ? Icons.star : Icons.star_border;
        }

        return Icon(
          icon,
          size: size,
          color: rating >= starValue - 0.5 ? color : emptyColor,
        );
      }),
    );
  }
}

class InteractiveStarRating extends StatefulWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final int starCount;
  final double size;
  final Color color;
  final Color emptyColor;

  const InteractiveStarRating({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.starCount = 5,
    this.size = 32,
    this.color = Colors.amber,
    this.emptyColor = Colors.grey,
  });

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  int _hoverRating = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.starCount, (index) {
        final starValue = index + 1;
        final isActive = (_hoverRating > 0 ? _hoverRating : widget.rating) >= starValue;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoverRating = starValue),
          onExit: (_) => setState(() => _hoverRating = 0),
          child: GestureDetector(
            onTap: () => widget.onRatingChanged(starValue),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                isActive ? Icons.star : Icons.star_border,
                size: widget.size,
                color: isActive ? widget.color : widget.emptyColor,
              ),
            ),
          ),
        );
      }),
    );
  }
}
