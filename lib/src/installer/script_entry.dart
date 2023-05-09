import 'dart:io';

/// {@template script_entry}
/// A script entry is a section of a file that is starts with [startComment]
/// and ends with [endComment].
/// {@endtemplate}
class ScriptEntry {
  /// {@macro script_entry}
  const ScriptEntry(this.name);

  /// The name of the entry.
  final String name;

  /// The start comment of the entry.
  String get startComment => '\n## [$name]';

  /// The end comment of the entry.
  String get endComment => '## [/$name]\n';

  /// Whether there is an entry with [name] in [file].
  ///
  /// If the [file] does not exist, this will return false.
  bool existsIn(File file) {
    if (!file.existsSync()) return false;
    final content = file.readAsStringSync();
    // TODO(alestiago): Refine logic with regular expressions.
    return content.contains(startComment) && content.contains(endComment);
  }

  /// Adds an entry with [name] to the end of the [file].
  ///
  /// If the [file] does not exist, it will be created.
  ///
  /// If [content] is not null, it will be added within the entry.
  void appendTo(File file, {String? content}) {
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }

    final entry = StringBuffer()
      ..writeln(startComment)
      ..writeln(content)
      ..writeln(endComment);

    file.writeAsStringSync(
      entry.toString(),
      mode: FileMode.append,
    );
  }
}
