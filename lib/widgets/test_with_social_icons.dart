import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TextWithIcons extends StatelessWidget {
  final String text;
  final bool isDark;
  final bool useBrandColor;
  final Color? isColored;

  const TextWithIcons({
    super.key,
    required this.text,
    this.isDark = false,
    this.isColored,
    this.useBrandColor = true,
  });

  IconData _detectIcon(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('instagram')) return FontAwesomeIcons.instagram;
    if (lower.contains('linkedin')) return FontAwesomeIcons.linkedin;
    if (lower.contains('facebook')) return FontAwesomeIcons.facebook;
    if (lower.contains('twitter')) return FontAwesomeIcons.twitter;
    if (lower.contains('x.com')) return FontAwesomeIcons.xTwitter;
    if (lower.contains('youtube')) return FontAwesomeIcons.youtube;
    if (lower.contains('github')) return FontAwesomeIcons.github;
    if (lower.contains('email') || lower.contains('@')) return Icons.email;
    if (lower.contains('tel') || RegExp(r'^\+?\d{6,}').hasMatch(lower))
      return Icons.phone;
    if (lower.contains('http') || lower.contains('www.')) return Icons.link;

    return Icons.info_outline;
  }

  Color? _detectIconColor(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('instagram')) return const Color(0xFFE1306C);
    if (lower.contains('linkedin')) return const Color(0xFF0077B5);
    if (lower.contains('facebook')) return const Color(0xFF1877F2);
    if (lower.contains('twitter') || lower.contains('x.com'))
      return const Color(0xFF1DA1F2);
    if (lower.contains('youtube')) return const Color(0xFFFF0000);
    if (lower.contains('github')) return Colors.black;
    if (lower.contains('email') || lower.contains('@')) return Colors.orange;
    if (lower.contains('tel') || RegExp(r'^\+?\d{6,}').hasMatch(lower))
      return Colors.green;
    if (lower.contains('http') || lower.contains('www.'))
      return Colors.blueGrey;

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          _detectIcon(text),
          color: _detectIconColor(text),
          size: 16,
          shadows: [
            Shadow(
              color: useBrandColor
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              offset: const Offset(0, 0),
              blurRadius: 0.2,
          )],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SelectableText(
            text,
            style: TextStyle(
              color: isColored ?? (isDark ? Colors.white : Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}
