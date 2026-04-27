import 'package:flutter/material.dart';
import '../../data/models/card_model.dart';

class AnimatedCard extends StatefulWidget {
  final CardModel data;
  final int delay;
  const AnimatedCard({super.key, required this.data, required this.delay});

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 380), vsync: this);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(_ctrl);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _mapColor(String key) {
    switch (key) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      case 'indigo':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _mapIcon(String key) {
    switch (key) {
      case 'calculate':
        return Icons.calculate;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'picture_as_pdf':
        return Icons.picture_as_pdf;
      case 'map':
        return Icons.map;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _mapColor(widget.data.color);
    final icon = _mapIcon(widget.data.icon);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.data.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.data.subtitle, style: const TextStyle(color: Colors.white70)),
                    ]),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
