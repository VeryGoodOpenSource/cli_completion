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

    final stringBuffer = StringBuffer()
      ..writeln()
      ..writeln(_startComment);
    if (content != null) stringBuffer.writeln(content);
    stringBuffer
      ..writeln(_endComment)
      ..writeln();

    file.writeAsStringSync(
      stringBuffer.toString(),
      mode: FileMode.append,
    );
  }

  /// Removes the entry with [name] from the [file].
  ///
  /// If the [file] does not exist, this will do nothing.
  ///
  /// If a file has multiple entries with the same [name], all of them will be
  /// removed.
  ///
  /// If [shouldDelete] is true, the [file] will be deleted if it is empty after
  /// removing the entry. Otherwise, the [file] will be left empty.
  void removeFrom(File file, {bool shouldDelete = true}) {
    if (!file.existsSync()) return;

    final content = file.readAsStringSync();
    final stringPattern = '\n$_startComment.*$_endComment\n\n'
        .replaceAll('[', r'\[')
        .replaceAll(']', r'\]');
    final pattern = RegExp(
      stringPattern,
      multiLine: true,
      dotAll: true,
    );
    final newContent = content.replaceAllMapped(pattern, (_) => '');
    file.writeAsStringSync(newContent);

    if (shouldDelete && newContent.trim().isEmpty) {
      file.deleteSync();
    }
  }
}
