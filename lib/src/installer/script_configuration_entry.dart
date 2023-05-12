import 'dart:io';

/// {@template script_entry}
/// A script entry is a section of a file that starts with [_startComment] and
/// ends with [_endComment].
/// {@endtemplate}
class ScriptConfigurationEntry {
  /// {@macro script_entry}
  const ScriptConfigurationEntry(this.name)
      : _startComment = '## [$name]',
        _endComment = '## [/$name]';

  /// The name of the entry.
  final String name;

  /// The start comment of the entry.
  final String _startComment;

  /// The end comment of the entry.
  final String _endComment;

  /// Whether there is an entry with [name] in [file].
  ///
  /// If the [file] does not exist, this will return false.
  bool existsIn(File file) {
    if (!file.existsSync()) return false;
    final content = file.readAsStringSync();
    return content.contains(_startComment) && content.contains(_endComment);
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
      ..writeln()
      ..writeln(_startComment)
      ..writeln(content)
      ..writeln(_endComment)
      ..writeln();

    file.writeAsStringSync(
      entry.toString(),
      mode: FileMode.append,
    );
  }
}
