import 'package:flutter/material.dart';

// src: https://github.com/alihabbash/read_more_text/blob/master/lib/read_more_text.dart

class ReadMoreText extends StatefulWidget {
  const ReadMoreText(
    this.text, {
    required this.numLines,
    required this.readMoreText,
    required this.readLessText,
    this.readMoreAlign = AlignmentDirectional.bottomEnd,
    this.readMoreIcon,
    this.readLessIcon,
    this.readMoreTextStyle,
    this.readMoreIconColor = Colors.blue,
    this.style,
    this.locale,
    this.onReadMoreClicked,
    this.readMoreKey,
    this.textKey,
    super.key,
  })  : assert(
          (readMoreIcon != null && readLessIcon != null) ||
              readMoreIcon == null && readLessIcon == null,
          'You need to specify both read more and read less icons ',
        ),
        cursorHeight = null,
        _isSelectable = false,
        showCursor = null,
        cursorWidth = null,
        cursorColor = null,
        cursorRadius = null,
        toolbarOptions = null;

  /// Show a read more text widget with the use of [SelectableText] instead
  /// of normal [Text] widget.
  ///
  /// You can customize the look and feel of the [SelectableText] like cursor
  /// width, cursor height, cursor color, etc...
  const ReadMoreText.selectable(
    this.text, {
    required this.numLines,
    required this.readMoreText,
    required this.readLessText,
    super.key,
    this.readMoreAlign = AlignmentDirectional.bottomEnd,
    this.readMoreKey,
    this.textKey,
    this.readMoreIcon,
    this.readLessIcon,
    this.readMoreTextStyle,
    this.readMoreIconColor = Colors.blue,
    this.style,
    this.locale,
    this.onReadMoreClicked,
    this.cursorColor,
    this.cursorRadius,
    this.cursorWidth,
    this.showCursor,
    this.toolbarOptions,
    this.cursorHeight,
  }) : _isSelectable = true;

  /// The main text that needs to be shown.
  final String text;

  /// The number of lines before trim the text.
  final int numLines;

  /// The main text style.
  final TextStyle? style;

  /// The icon color next to read more/less text.
  final Color readMoreIconColor;

  /// The style of read more/less text.
  final TextStyle? readMoreTextStyle;

  /// The icon that needs to be shown when the text is collapsed.
  ///
  /// When you specify [readMoreIcon] you also need to specify [readLessIcon].
  final Widget? readMoreIcon;

  /// The icon that needs to be shown when the text is expanded.
  ///
  /// When you specify [readMoreIcon] you also need to specify [readLessIcon].
  final Widget? readLessIcon;

  /// The show more text.
  final String readMoreText;

  /// The show less text.
  final String readLessText;

  /// Called when clicked on read more.
  final VoidCallback? onReadMoreClicked;

  /// The alignment of the read more text and icon.
  /// default is [AlignmentDirectional.bottomEnd]
  final AlignmentGeometry readMoreAlign;

  /// The locale of the main text, that allows the widget calculate the
  /// number of lines accurately.
  ///
  /// It's optional and should be used when the passed text locale is different
  /// from the app locale.
  ///
  /// e.g: The app locale is `en` but you pass a german text.
  final Locale? locale;

  /// Whether to show the cursor or not.
  final bool? showCursor;

  /// The cursor width if the cursor is shown.
  final double? cursorWidth;

  /// The cursor height if the cursor is shown.
  final double? cursorHeight;

  /// The cursor color if the cursor is shown.
  final Color? cursorColor;

  /// The cursor radius if the cursor is shown.
  final Radius? cursorRadius;

  /// The toolbar options of the selection area.
  final ToolbarOptions? toolbarOptions;
  final bool _isSelectable;

  /// The key for the content text.
  final Key? textKey;

  /// The key for read more button.
  final Key? readMoreKey;

  @override
  State<ReadMoreText> createState() => _ReadMoreTextState();
}

class _ReadMoreTextState extends State<ReadMoreText> {
  final _defaultShowMoreStyle = const TextStyle(
    color: Colors.blue,
    fontWeight: FontWeight.w500,
    fontSize: 13,
  );

  var _isTextExpanded = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final locale = widget.locale ?? Localizations.maybeLocaleOf(context);
          final span = TextSpan(text: widget.text);
          final tp = TextPainter(
            text: span,
            locale: locale,
            maxLines: widget.numLines,
            textDirection: Directionality.of(context),
          );
          tp.layout(maxWidth: constraints.maxWidth);
          return Column(
            children: [
              if (widget._isSelectable)
                SelectableText(
                  widget.text,
                  key: widget.textKey,
                  maxLines: _isTextExpanded ? null : widget.numLines,
                  style: widget.style,
                  cursorColor: widget.cursorColor,
                  cursorWidth: widget.cursorWidth ?? 2,
                  cursorHeight: widget.cursorHeight,
                  cursorRadius: widget.cursorRadius,
                  showCursor: widget.showCursor ?? false,
                  toolbarOptions: widget.toolbarOptions,
                  scrollPhysics: const NeverScrollableScrollPhysics(),
                )
              else
                Text(
                  widget.text,
                  key: widget.textKey,
                  maxLines: _isTextExpanded ? null : widget.numLines,
                  style: widget.style,
                ),
              if (tp.didExceedMaxLines) const SizedBox(height: 8),
              if (tp.didExceedMaxLines)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: GestureDetector(
                    key: widget.readMoreKey,
                    onTap: _onReadMoreClicked,
                    child: Align(
                      alignment: widget.readMoreAlign,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isTextExpanded
                                ? widget.readLessText
                                : widget.readMoreText,
                            style: widget.readMoreTextStyle ??
                                _defaultShowMoreStyle,
                          ),
                          const SizedBox(width: 8),
                          if (widget.readMoreIcon != null)
                            _isTextExpanded
                                ? widget.readLessIcon!
                                : widget.readMoreIcon!,
                          if (widget.readMoreIcon == null)
                            Icon(
                              _isTextExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: widget.readMoreIconColor,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );

  void _onReadMoreClicked() {
    _isTextExpanded = !_isTextExpanded;
    setState(() {});
    widget.onReadMoreClicked?.call();
  }
}
