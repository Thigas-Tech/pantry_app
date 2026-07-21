import 'dart:io';

void main(List<String> args) {
  final files = args.toList();
  if (files.isEmpty) {
    stderr.writeln(
      'Usage: dart run tools/strip_backticks.dart <file1.dart> [file2.dart ...]',
    );
    exit(1);
  }

  for (final filePath in files) {
    final file = File(filePath);
    if (!file.existsSync()) {
      stderr.writeln('File not found: $filePath');
      continue;
    }

    var modified = false;
    final lines = file.readAsLinesSync();
    final out = <String>[];

    for (final line in lines) {
      var trimmed = line.trimLeft();
      if (trimmed.startsWith('///')) {
        var docSection = line;
        // Strip backticks — do NOT create brackets for null/true/false
        // because they aren't valid cross-references in dartdoc.
        // Strip remaining backtick pairs (but not triple backticks ```)
        // Use a regex to match `content` where content doesn't contain backticks
        docSection = docSection.replaceAllMapped(
          RegExp(r'`([^`]+)`'),
          (m) {
            final content = m.group(1)!;
            // If the content is a valid-looking identifier (alphanumeric/underscore/dot),
            // it might be a cross-reference candidate. But to be safe, we just return
            // the content without backticks.
            return content;
          },
        );
        if (docSection != line) {
          modified = true;
        }
        out.add(docSection);
      } else {
        out.add(line);
      }
    }

    if (modified) {
      file.writeAsStringSync('${out.join('\n')}\n');
      print('Modified: $filePath');
    }
  }
}
