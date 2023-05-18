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
typedef Uninstalls
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
  });

  /// Creates an empty [CompletionConfiguration].
  @visibleForTesting
  CompletionConfiguration.empty() : uninstalls = UnmodifiableMapView({});

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
      uninstalls: _jsonDecodeUninstalls(decodedJson),
    );
  }

  /// The JSON key for the [uninstalls] field.
  static const String _uninstallsJsonKey = 'uninstalls';

  /// Stores those commands that have been manually uninstalled by the user.
  ///
  /// Uninstalls are specific to a given [SystemShell].
  final Uninstalls uninstalls;

  /// Stores the [CompletionConfiguration] in the given [file].
  void writeTo(File file) {
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(_toJson());
  }

  /// Returns a copy of this [CompletionConfiguration] with the given fields
  /// replaced.
  CompletionConfiguration copyWith({
    Uninstalls? uninstalls,
  }) {
    return CompletionConfiguration._(
      uninstalls: uninstalls ?? this.uninstalls,
    );
  }

  /// Returns a JSON representation of this [CompletionConfiguration].
  String _toJson() {
    return jsonEncode({
      _uninstallsJsonKey: _jsonEncodeUninstalls(uninstalls),
    });
  }
}

/// Decodes [Uninstalls] from the given [json].
///
/// If the [json] is not partially or fully valid, it handles issues gracefully
/// without throwing an [Exception].
Uninstalls _jsonDecodeUninstalls(Map<String, dynamic> json) {
  if (!json.containsKey(CompletionConfiguration._uninstallsJsonKey)) {
    return UnmodifiableMapView({});
  }
  final jsonUninstalls = json[CompletionConfiguration._uninstallsJsonKey];
  if (jsonUninstalls is! String) {
    return UnmodifiableMapView({});
  }
  late final Map<String, dynamic> decodedUninstalls;
  try {
    decodedUninstalls = jsonDecode(jsonUninstalls) as Map<String, dynamic>;
  } on FormatException {
    return UnmodifiableMapView({});
  }

  final newUninstalls = <SystemShell, UnmodifiableSetView<String>>{};
  for (final entry in decodedUninstalls.entries) {
    final systemShell = SystemShell.tryParse(entry.key);
    if (systemShell == null) continue;
    final uninstallSet = <String>{};
    if (entry.value is List) {
      for (final uninstall in entry.value as List) {
        if (uninstall is String) {
          uninstallSet.add(uninstall);
        }
      }
    }
    newUninstalls[systemShell] = UnmodifiableSetView(uninstallSet);
  }
  return UnmodifiableMapView(newUninstalls);
}

/// Returns a JSON representation of the given [Uninstalls].
String _jsonEncodeUninstalls(Uninstalls uninstalls) {
  return jsonEncode({
    for (final entry in uninstalls.entries)
      entry.key.toString(): entry.value.toList(),
  });
}

/// Provides convinience methods for [Uninstalls].
extension UninstallsExtension on Uninstalls {
  /// Returns a new [Uninstalls] with the given [command] added to
  /// [systemShell].
  Uninstalls include(
      {required String command, required SystemShell systemShell}) {
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

  /// Returns a new [Uninstalls] with the given [command] removed from
  /// [systemShell].
  Uninstalls exclude({
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
