// lib/services/custom_text_editor.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/theme_provider.dart';

final Map<String, bool> defaultToolbarButtons = {
  'showDividers': true,
  'showFontFamily': true,
  'showFontSize': true,
  'showBoldButton': true,
  'showItalicButton': true,
  'showSmallButton': false,
  'showUnderLineButton': true,
  'showLineHeightButton': false,
  'showStrikeThrough': true,
  'showInlineCode': true,
  'showColorButton': true,
  'showBackgroundColorButton': true,
  'showClearFormat': true,
  'showAlignmentButtons': false,
  'showLeftAlignment': true,
  'showCenterAlignment': true,
  'showRightAlignment': true,
  'showJustifyAlignment': true,
  'showHeaderStyle': true,
  'showListNumbers': true,
  'showListBullets': true,
  'showListCheck': true,
  'showCodeBlock': true,
  'showQuote': true,
  'showIndent': true,
  'showLink': true,
  'showUndo': true,
  'showRedo': true,
  'showDirection': false,
  'showSearchButton': true,
  'showSubscript': true,
  'showSuperscript': true,
  'showClipboardCut': false,
  'showClipboardCopy': false,
  'showClipboardPaste': false,
  'showImageButton': false,
  'showVideoButton': false,
};

final Map<String, bool> minimalToolbarButtons = {
  'showBoldButton': true,
  'showItalicButton': true,
  'showUnderLineButton': true,
};

final Map<String, bool> maximalToolbarButtons = {
  for (var key in defaultToolbarButtons.keys) key: true,
};

Map<String, bool> buildCustomToolbarButtons({
  required Map<String, bool> base,
  Map<String, bool>? override,
}) {
  final merged = Map<String, bool>.from(base);
  if (override != null) merged.addAll(override);
  return merged;
}

/// =======================================
/// EDITÖR (mevcut davranış korunuyor)
/// =======================================
class QuillTextEditor extends StatefulWidget {
  final String? initialJsonDelta;
  final bool showAll;
  final void Function(String jsonDelta)? onSubmit;
  final String submitLabel;
  final Map<String, bool>? toolbarButtons;
  final double minHeight;

  const QuillTextEditor({
    super.key,
    this.initialJsonDelta,
    this.onSubmit,
    this.submitLabel = 'Save',
    this.showAll = true,
    this.toolbarButtons,
    this.minHeight = 50,
  });

  @override
  State<QuillTextEditor> createState() => QuillTextEditorState();
}

class QuillTextEditorState extends State<QuillTextEditor> {
  late final QuillController _controller;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  String getJson() {
    final delta = _controller.document.toDelta();
    return jsonEncode(delta.toJson());
  }

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic(
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          enableExternalRichPaste: true,
        ),
      ),
    );

    // (Mevcut mantık korunuyor)
    if (widget.initialJsonDelta != null &&
        widget.initialJsonDelta!.trim().startsWith('[')) {
      try {
        _controller.document =
            Document.fromJson(jsonDecode(widget.initialJsonDelta!));
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  void _submit() {
    final delta = _controller.document.toDelta();
    final json = jsonEncode(delta.toJson());
    widget.onSubmit?.call(json);
  }

  @override
  Widget build(BuildContext context) {
    bool showButton = false;
    final minHeight = widget.minHeight;
    final theme = Provider.of<ThemeProvider>(context, listen: true);
    final buttons =
        widget.showAll ? maximalToolbarButtons : widget.toolbarButtons ?? minimalToolbarButtons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.isDarkMode ? Colors.grey[900] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: QuillSimpleToolbar(
            controller: _controller,
            config: QuillSimpleToolbarConfig(
              showClipboardPaste: buttons['showClipboardPaste'] ?? false,
              showBoldButton: buttons['showBoldButton'] ?? false,
              showItalicButton: buttons['showItalicButton'] ?? false,
              showUnderLineButton: buttons['showUnderLineButton'] ?? false,
              showStrikeThrough: buttons['showStrikeThrough'] ?? false,
              showHeaderStyle: buttons['showHeaderStyle'] ?? false,
              showListNumbers: buttons['showListNumbers'] ?? false,
              showListBullets: buttons['showListBullets'] ?? false,
              showListCheck: buttons['showListCheck'] ?? false,
              showCodeBlock: buttons['showCodeBlock'] ?? false,
              showQuote: buttons['showQuote'] ?? false,
              showIndent: buttons['showIndent'] ?? false,
              showLink: buttons['showLink'] ?? false,
              showUndo: buttons['showUndo'] ?? false,
              showRedo: buttons['showRedo'] ?? false,
              showClearFormat: buttons['showClearFormat'] ?? false,
              showAlignmentButtons: buttons['showAlignmentButtons'] ?? false,
              showLeftAlignment: buttons['showLeftAlignment'] ?? false,
              showCenterAlignment: buttons['showCenterAlignment'] ?? false,
              showRightAlignment: buttons['showRightAlignment'] ?? false,
              showJustifyAlignment: buttons['showJustifyAlignment'] ?? false,
              showDirection: buttons['showDirection'] ?? false,
              showSearchButton: buttons['showSearchButton'] ?? false,
              showSubscript: buttons['showSubscript'] ?? false,
              showSuperscript: buttons['showSuperscript'] ?? false,
              showColorButton: buttons['showColorButton'] ?? false,
              showBackgroundColorButton:
                  buttons['showBackgroundColorButton'] ?? false,
              showFontFamily: buttons['showFontFamily'] ?? false,
              showFontSize: buttons['showFontSize'] ?? false,
              showSmallButton: buttons['showSmallButton'] ?? false,
              showLineHeightButton: buttons['showLineHeightButton'] ?? false,
              showInlineCode: buttons['showInlineCode'] ?? false,
              showClipboardCut: buttons['showClipboardCut'] ?? false,
              showClipboardCopy: buttons['showClipboardCopy'] ?? false,
              buttonOptions: QuillSimpleToolbarButtonOptions(
                base: QuillToolbarBaseButtonOptions(
                  afterButtonPressed: () => _editorFocusNode.requestFocus(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Provider.of<ThemeProvider>(context).isDarkMode
                ? Colors.grey[900]
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Provider.of<ThemeProvider>(context).isDarkMode
                  ? Colors.grey[600]!
                  : Colors.grey[300]!,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: QuillEditor(
            focusNode: _editorFocusNode,
            scrollController: _editorScrollController,
            controller: _controller,
            config: QuillEditorConfig(
              placeholder: 'Write here...',
              padding: EdgeInsets.zero,
              scrollable: true,
              minHeight: minHeight,
              maxHeight: 160,
              autoFocus: true,
              embedBuilders: FlutterQuillEmbeds.editorBuilders(),
            ),
          ),
        ),
        showButton
            ? ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: Text(widget.submitLabel),
              )
            : Container(),
      ],
    );
  }
}

/// =======================================================
/// YENİ: VIEWER (Quill JSON -> okumak / göstermek için)
/// =======================================================

/// Quill Delta JSON veya düz metni kartta/detayda göstermek için küçük yardımcı.
String quillDeltaToPlainText(String? raw) {
  final txt = (raw ?? '').trim();
  if (txt.isEmpty) return '';
  if (txt.startsWith('[')) {
    try {
      final doc = Document.fromJson(jsonDecode(txt));
      // Quill'in kendi düz metin çıkarımı:
      final plain = doc.toPlainText();
      // Kart özetinde daha temiz dursun:
      return plain.replaceAll(RegExp(r'\s+'), ' ').trim();
    } catch (_) {
      // JSON parse edilemediyse düz metne düş
    }
  }
  return txt.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Read-only Quill gösterici.
/// - `maxLines` verirsen kısa özet (Text ile clamp) gösterir.
/// - `maxLines` vermezsen QuillEditor ile tam render yapar.
/// - `fallbackPlainText` true ise JSON değilse düz metin gösterir.
class QuillTextViewer extends StatelessWidget {
  final String deltaJson;
  final int? maxLines;
  final bool dense;
  final bool fallbackPlainText;

  const QuillTextViewer({
    super.key,
    required this.deltaJson,
    this.maxLines,
    this.dense = false,
    this.fallbackPlainText = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Kısa özet isteniyorsa doğrudan düz metin olarak clamp et
    if (maxLines != null) {
      final preview = quillDeltaToPlainText(deltaJson);
      if (preview.isEmpty) return const SizedBox.shrink();
      return Text(
        preview,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: (dense ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium),
      );
    }

    // Tam render (read-only)
    Document? doc;
    if (deltaJson.trim().startsWith('[')) {
      try {
        doc = Document.fromJson(jsonDecode(deltaJson));
      } catch (_) {
        doc = null;
      }
    }

    // JSON parse edilemediyse fallback
    if (doc == null) {
      if (!fallbackPlainText) return const SizedBox.shrink();
      final plain = quillDeltaToPlainText(deltaJson);
      if (plain.isEmpty) return const SizedBox.shrink();
      return Text(
        plain,
        style: (dense ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium),
      );
    }

    final controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    return QuillEditor(
      controller: controller,
      focusNode: FocusNode(),
      scrollController: ScrollController(),
      config: const QuillEditorConfig(
        readOnlyMouseCursor: MouseCursor.uncontrolled,
        padding: EdgeInsets.zero,
        scrollable: false, // kart içinde kendi boyunda kalsın
        minHeight: 0,
        autoFocus: false,
        // embedBuilders: FlutterQuillEmbeds.editorBuilders(), // istersen aç
      ),
    );
  }
}
