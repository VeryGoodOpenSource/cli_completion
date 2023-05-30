import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:cli_completion/installer.dart';
import 'package:cli_completion/parser.dart';
import 'package:meta/meta.dart';

/// A map of [SystemShell]s to a list of uninstalled commands.
///
/// The map and its content are unmodifiable. This is to ensure that
/// [CompletionConfiguration]s is fully immutable.
typedef ShellCommandsMap
    = UnmodifiableMapView<SystemShell, UnmodifiableSetView<String>>;

/// {@template completion_configuration}
/// A configuration that stores information on how to handle command
/// completions.
/// {@endtemplate}
@immutable
class CompletionConfiguration {
  /// {@macro completion_configuration}
  const CompletionConfiguration._({
    required this.uninstalls,
    required this.installs,
  });

  /// Creates an empty [CompletionConfiguration].
  @visibleForTesting
  CompletionConfiguration.empty()
      : uninstalls = ShellCommandsMap({}),
        installs = ShellCommandsMap({});

  /// Creates a [CompletionConfiguration] from the given [file] content.
  ///
  /// If the file does not exist or is empty, a [CompletionConfiguration.empty]
  /// is created.
  ///
  /// If the file is not empty, a [CompletionConfiguration] is created from the
  /// file's content. This content is assumed to be a JSON string. The parsing
  /// is handled gracefully, so if the JSON is partially or fully invalid, it
  /// handles issues without throwing an [Exception].
  factory CompletionConfiguration.fromFile(File file) {
    if (!file.existsSync()) {
      return CompletionConfiguration.empty();
    }

    final json = file.readAsStringSync();
    return CompletionConfiguration._fromJson(json);
  }

  /// Creates a [CompletionConfiguration] from the given JSON string.
  factory CompletionConfiguration._fromJson(String json) {
    late final Map<String, dynamic> decodedJson;
    try {
      decodedJson = jsonDecode(json) as Map<String, dynamic>;
    } on FormatException {
      decodedJson = {};
    }

    return CompletionConfiguration._(
      uninstalls: _jsonDecodeShellCommandsMap(
        decodedJson,
        jsonKey: CompletionConfiguration.uninstallsJsonKey,
      ),
      installs: _jsonDecodeShellCommandsMap(
        decodedJson,
        jsonKey: CompletionConfiguration.installsJsonKey,
      ),
    );
  }

  /// The JSON key for the [uninstalls] field.
  @visibleForTesting
  static const String uninstallsJsonKey = 'uninstalls';

  /// The JSON key for the [installs] field.
  @visibleForTesting
  static const String installsJsonKey = 'installs';

  /// Stores those commands that have been manually uninstalled by the user.
  ///
  /// Uninstalls are specific to a given [SystemShell].
  final ShellCommandsMap uninstalls;

  /// Stores those commands that have completion installed.
  ///
  /// Installed commands are specific to a given [SystemShell].
  final ShellCommandsMap installs;

  /// Stores the [CompletionConfiguration] in the given [file].
  void writeTo(File file) {
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(_toJson());
  }

  /// Returns a JSON representation of this [CompletionConfiguration].
  String _toJson() {
    return jsonEncode({
      uninstallsJsonKey: _jsonEncodeShellCommandsMap(uninstalls),
      installsJsonKey: _jsonEncodeShellCommandsMap(installs),
    });
  }

  /// Returns a copy of this [CompletionConfiguration] with the given fields
  /// replaced.
  CompletionConfiguration copyWith({
    ShellCommandsMap? uninstalls,
    ShellCommandsMap? installs,
  }) {
    return CompletionConfiguration._(
      uninstalls: uninstalls ?? this.uninstalls,
      installs: installs ?? this.installs,
    );
  }
}

/// Decodes [ShellCommandsMap] from the given [json].
///
/// If the [json] is not partially or fully valid, it handles issues gracefully
/// without throwing an [Exception].
ShellCommandsMap _jsonDecodeShellCommandsMap(
  Map<String, dynamic> json, {
  required String jsonKey,
}) {
  if (!json.containsKey(jsonKey)) {
    return ShellCommandsMap({});
  }
  final jsonShellCommandsMap = json[jsonKey];
  if (jsonShellCommandsMap is! String) {
    return ShellCommandsMap({});
  }
  late final Map<String, dynamic> decodedShellCommandsMap;
  try {
    decodedShellCommandsMap =
        jsonDecode(jsonShellCommandsMap) as Map<String, dynamic>;
  } on FormatException {
    return ShellCommandsMap({});
  }

  final newShellCommandsMap = <SystemShell, UnmodifiableSetView<String>>{};
  for (final entry in decodedShellCommandsMap.entries) {
    final systemShell = SystemShell.tryParse(entry.key);
    if (systemShell == null) continue;
    final commandsSet = <String>{};
    if (entry.value is List) {
      for (final uninstall in entry.value as List) {
        if (uninstall is String) {
          commandsSet.add(uninstall);
        }
      }
    }
    newShellCommandsMap[systemShell] = UnmodifiableSetView(commandsSet);
  }
  return UnmodifiableMapView(newShellCommandsMap);
}

/// Returns a JSON representation of the given [ShellCommandsMap].
String _jsonEncodeShellCommandsMap(ShellCommandsMap shellCommandsMap) {
  return jsonEncode({
    for (final entry in shellCommandsMap.entries)
      entry.key.toString(): entry.value.toList(),
  });
}

/// Provides convinience methods for [ShellCommandsMap].
extension ShellCommandsMapExtension on ShellCommandsMap {
  /// Returns a new [ShellCommandsMap] with the given [command] added to
  /// [systemShell].
  ShellCommandsMap include({
    required String command,
    required SystemShell systemShell,
  }) {
    final modifiable = _modifiable();

    if (modifiable.containsKey(systemShell)) {
      modifiable[systemShell]!.add(command);
    } else {
      modifiable[systemShell] = {command};
    }

    return UnmodifiableMapView(
      modifiable.map((key, value) => MapEntry(key, UnmodifiableSetView(value))),
    );
  }

  /// Returns a new [ShellCommandsMap] with the given [command] removed from
  /// [systemShell].
  ShellCommandsMap exclude({
    required String command,
    required SystemShell systemShell,
  }) {
    final modifiable = _modifiable();

    if (modifiable.containsKey(systemShell)) {
      modifiable[systemShell]!.remove(command);
    }

    return UnmodifiableMapView(
      modifiable.map((key, value) => MapEntry(key, UnmodifiableSetView(value))),
    );
  }

  /// Whether the [command] is contained in [systemShell].
  bool contains({required String command, required SystemShell systemShell}) {
    if (containsKey(systemShell)) {
      return this[systemShell]!.contains(command);
    }
    return false;
  }

  Map<SystemShell, Set<String>> _modifiable() {
    return map((key, value) => MapEntry(key, value.toSet()));
  }
}
