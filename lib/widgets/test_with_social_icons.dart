import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class TextWithIcons extends StatelessWidget {
  final String text;
  final bool isDark;
  /// Marka rengi kullan (Instagram pembe, LinkedIn mavi vs.)
  final bool useBrandColor;
  /// Zorla metin rengi. null ise tema/marka rengine göre seçilir.
  final Color? isColored;
  /// Metin tıklanınca uygun uygulamayı aç (tel/mail/web)
  final bool clickable;
  /// Dilersen tıklamayı kendin yakalayabil.
  final VoidCallback? onTap;

  const TextWithIcons({
    super.key,
    required this.text,
    this.isDark = false,
    this.isColored,
    this.useBrandColor = true,
    this.clickable = true,
    this.onTap,
  });

  // --- Statik regex'ler (her seferinde yeniden yaratmayalım)
  static final RegExp _rePhone = RegExp(r'^\s*(?:\+?\d[\d\s\-().]{6,})$');
  static final RegExp _reUrl   = RegExp(r'^(https?:\/\/|www\.)', caseSensitive: false);
  static final RegExp _reMail  = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool _isPhone(String s) => _rePhone.hasMatch(s);
  static bool _isUrl(String s)   => _reUrl.hasMatch(s);
  static bool _isMail(String s)  => _reMail.hasMatch(s) || s.toLowerCase().startsWith('mailto:');
  static bool _looksLikeLink(String s) =>
      _isPhone(s) || _isMail(s) || _isUrl(s) || s.toLowerCase().startsWith('tel:');

  IconData _detectIcon(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('instagram')) return FontAwesomeIcons.instagram;
    if (lower.contains('linkedin')) return FontAwesomeIcons.linkedin;
    if (lower.contains('facebook')) return FontAwesomeIcons.facebook;
    if (lower.contains('twitter') || lower.contains('x.com')) return FontAwesomeIcons.xTwitter;
    if (lower.contains('youtube')) return FontAwesomeIcons.youtube;
    if (lower.contains('github')) return FontAwesomeIcons.github;
    if (_isMail(input)) return Icons.email;
    if (_isPhone(input)) return Icons.phone;
    if (_isUrl(input)) return Icons.link;

    return Icons.info_outline;
  }

  Color _brandOrThemeColor(BuildContext context, String input) {
    if (!useBrandColor) {
      return isColored ?? (isDark ? Colors.white : Colors.black);
    }
    final lower = input.toLowerCase();

    if (lower.contains('instagram')) return const Color(0xFFE1306C);
    if (lower.contains('linkedin')) return const Color(0xFF0077B5);
    if (lower.contains('facebook')) return const Color(0xFF1877F2);
    if (lower.contains('twitter') || lower.contains('x.com')) return const Color(0xFF1DA1F2);
    if (lower.contains('youtube')) return const Color(0xFFFF0000);
    if (lower.contains('github')) return Colors.black;
    if (_isMail(input)) return Colors.orange;
    if (_isPhone(input)) return Colors.green;
    if (_isUrl(input)) return Colors.blueGrey;

    // fallback
    return isColored ?? (isDark ? Colors.white : Colors.black87);
  }

  Future<void> _handleTap(BuildContext context) async {
    if (onTap != null) {
      onTap!();
      return;
    }
    if (!clickable || !_looksLikeLink(text)) return;

    Uri? uri;
    final t = text.trim();

    if (_isMail(t)) {
      final addr = t.toLowerCase().startsWith('mailto:') ? t : 'mailto:$t';
      uri = Uri.parse(addr);
    } else if (_isPhone(t)) {
      final tel = t.toLowerCase().startsWith('tel:') ? t : 'tel:$t';
      uri = Uri.parse(tel.replaceAll(' ', ''));
    } else if (_isUrl(t)) {
      uri = Uri.parse(t.startsWith('http') ? t : 'https://$t');
    }

    if (uri != null) {
      final can = await canLaunchUrl(uri);
      if (can) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Olmadı, panoya kopyala
    await Clipboard.setData(ClipboardData(text: t));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kopyalandı')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _brandOrThemeColor(context, text);
    final textColor = isColored ?? (isDark ? Colors.white : Colors.black87);
    final isTapTarget = clickable && _looksLikeLink(text);

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _detectIcon(text),
          color: iconColor,
          size: 16,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: SelectableText(
            text,
            style: TextStyle(color: textColor),
          ),
        ),
      ],
    );

    // Tıklanabilirse InkWell ile sar
    return Semantics(
      // Erişilebilirlik
      button: isTapTarget,
      label: text,
      child: isTapTarget
          ? InkWell(
              onTap: () => _handleTap(context),
              onLongPress: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kopyalandı')),
                  );
                }
              },
              child: row,
            )
          : row,
    );
  }
}
