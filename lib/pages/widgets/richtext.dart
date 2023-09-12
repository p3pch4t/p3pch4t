// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class RichTextView extends StatelessWidget {
  const RichTextView({
    required this.text,
    required this.textAlign,
    required this.dateReceived,
    super.key,
  });
  final String text;
  final TextAlign textAlign;
  final DateTime dateReceived;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        right: textAlign == TextAlign.start ? 64 : 0,
        left: textAlign == TextAlign.end ? 64 : 0,
      ),
      child: MarkdownBody(
        // controller: controller,
        selectable: true,
        imageBuilder: (uri, title, alt) =>
            const Text('image tags are not supported'),
        data: '`${getDateText(dateReceived)}`: $text',
        extensionSet: md.ExtensionSet(
          md.ExtensionSet.gitHubFlavored.blockSyntaxes,
          <md.InlineSyntax>[
            md.EmojiSyntax(),
            ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
          ],
        ),
      ),
    );
  }
}

String getDateText(DateTime dateReceived) {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  if (dateReceived.isBefore(tomorrow) && dateReceived.isAfter(yesterday)) {
    return '${dateReceived.hour.toString().padLeft(2, '0')}:'
        '${dateReceived.minute.toString().padLeft(2, '0')}';
  }
  return dateReceived.toIso8601String();
}
