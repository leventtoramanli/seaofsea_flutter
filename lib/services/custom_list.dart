import 'package:flutter/material.dart';

/// Desteklenen liste türleri
enum ListStyle {
  bullet,         // • işaretli
  decimal,        // 1. 2. 3.
  lowerAlpha,     // a. b. c.
  upperAlpha,     // A. B. C.
  upperRoman,     // I. II. III.
  lowerRoman,     // i. ii. iii.
}

class CustomListItem {
  final String text;
  final List<CustomListItem> children;
  final TextAlign? align;
  final bool underline;
  final bool overline;
  final FontWeight? weight;
  final Color? color;
  final bool italic;

  CustomListItem(
    this.text, {
    this.children = const [],
    this.align,
    this.underline = false,
    this.overline = false,
    this.weight,
    this.color,
    this.italic = false,
  });
}

class CustomList extends StatelessWidget {
  final List<CustomListItem> items;
  final ListStyle style;
  final TextStyle? textStyle;
  final double spacing;

  const CustomList({
    Key? key,
    required this.items,
    this.style = ListStyle.bullet,
    this.textStyle,
    this.spacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodyMedium;
    return _buildList(context, items, 0, defaultStyle);
  }

  Widget _buildList(BuildContext context, List<CustomListItem> items, int depth, TextStyle? styleText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(items.length, (index) {
        final item = items[index];
        final prefix = _getListPrefix(index, _getStyleForDepth(depth));

        return Padding(
          padding: EdgeInsets.only(left: depth * 16.0, bottom: spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$prefix ', style: _buildTextStyle(item, textStyle ?? styleText!)),
                  Expanded(
                    child: Align(
                      alignment: _getAlignment(item.align),
                      child: Text(
                        item.text,
                        style: _buildTextStyle(item, textStyle ?? styleText!),
                        textAlign: item.align ?? TextAlign.left,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.children.isNotEmpty)
                _buildList(context, item.children, depth + 1, styleText),
            ],
          ),
        );
      }),
    );
  }

  ListStyle _getStyleForDepth(int depth) {
    switch (style) {
      case ListStyle.decimal:
        return [ListStyle.decimal, ListStyle.lowerAlpha, ListStyle.lowerRoman, ListStyle.bullet][depth % 4];
      case ListStyle.upperAlpha:
        return [ListStyle.upperAlpha, ListStyle.lowerAlpha, ListStyle.bullet, ListStyle.bullet][depth % 4];
      case ListStyle.upperRoman:
        return [ListStyle.upperRoman, ListStyle.lowerRoman, ListStyle.bullet, ListStyle.bullet][depth % 4];
      default:
        return ListStyle.bullet;
    }
  }

  String _getListPrefix(int index, ListStyle style) {
    switch (style) {
      case ListStyle.bullet:
        return '•';
      case ListStyle.decimal:
        return '${index + 1}.';
      case ListStyle.lowerAlpha:
        return '${String.fromCharCode(97 + index)}.';
      case ListStyle.upperAlpha:
        return '${String.fromCharCode(65 + index)}.';
      case ListStyle.upperRoman:
        return '${_toRoman(index + 1).toUpperCase()}.';
      case ListStyle.lowerRoman:
        return '${_toRoman(index + 1).toLowerCase()}.';
    }
  }

  TextStyle _buildTextStyle(CustomListItem item, TextStyle base) {
    TextDecoration? decoration;
    if (item.underline) decoration = TextDecoration.underline;
    if (item.overline) decoration = TextDecoration.overline;

    return base.copyWith(
      fontWeight: item.weight,
      color: item.color,
      fontStyle: item.italic ? FontStyle.italic : null,
      decoration: decoration,
    );
  }

  Alignment _getAlignment(TextAlign? align) {
    switch (align) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      case TextAlign.left:
      default:
        return Alignment.centerLeft;
    }
  }

  String _toRoman(int number) {
    final Map<int, String> romanNumerals = {
      1000: 'M',
      900: 'CM',
      500: 'D',
      400: 'CD',
      100: 'C',
      90: 'XC',
      50: 'L',
      40: 'XL',
      10: 'X',
      9: 'IX',
      5: 'V',
      4: 'IV',
      1: 'I',
    };

    String result = '';
    romanNumerals.forEach((int value, String numeral) {
      while (number >= value) {
        result += numeral;
        number -= value;
      }
    });
    return result;
  }
}