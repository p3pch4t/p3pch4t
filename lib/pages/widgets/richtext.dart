import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class RichTextView extends StatelessWidget {
  const RichTextView({
    required this.text,
    required this.textAlign,
    super.key,
  });
  final String text;
  final TextAlign textAlign;

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
        data: text,
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
