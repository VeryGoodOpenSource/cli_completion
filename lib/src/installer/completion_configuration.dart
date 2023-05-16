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
/// A configuration that stores data on how to handle command completions.
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
  /// If the file does not exist, an empty [CompletionConfiguration] is created
  /// and stored in the file.
  ///
  /// If the file is empty, an empty [CompletionConfiguration] is created.
  ///
  /// If the file is not empty, a [CompletionConfiguration] is created from the
  /// file's content. This content is assumed to be a JSON string. It doesn't
  /// throw when the content is not a valid JSON string. Instead it gracefully
  /// handles the missing or invalid values.
  factory CompletionConfiguration.fromFile(File file) {
    if (!file.existsSync()) {
      return CompletionConfiguration.empty()..writeTo(file);
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
  late final Uninstalls uninstalls;
  if (json.containsKey(CompletionConfiguration._uninstallsJsonKey)) {
    final rawUninstalls = json[CompletionConfiguration._uninstallsJsonKey];
    if (rawUninstalls is! String) {
      uninstalls = UnmodifiableMapView({});
    } else {
      final decodedUninstalls = jsonDecode(rawUninstalls);
      if (decodedUninstalls is! Map<String, dynamic>) {
        uninstalls = UnmodifiableMapView({});
      } else {
        final newUninstalls = <SystemShell, UnmodifiableSetView<String>>{};

        for (final entry in decodedUninstalls.entries) {
          if (!entry.key.canParseSystemShell()) continue;
          final systemShell = entry.key.toSystemShell();
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
        uninstalls = UnmodifiableMapView(newUninstalls);
      }
    }
  } else {
    uninstalls = UnmodifiableMapView({});
  }

  return uninstalls;
}

/// Returns a JSON representation of this [Uninstalls].
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
  Uninstalls add({required String command, required SystemShell systemShell}) {
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
  void remove({required String command, required SystemShell systemShell}) {
    final modifiable = _modifiable();

    if (modifiable.containsKey(systemShell)) {
      modifiable[systemShell]!.remove(command);
    }
  }

  Map<SystemShell, Set<String>> _modifiable() {
    return map((key, value) => MapEntry(key, value.toSet()));
  }
}

extension on String {
  /// Whether this [String] can be parsed into a [SystemShell].
  bool canParseSystemShell() {
    try {
      toSystemShell();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Parses a [SystemShell] from the [String].
  ///
  /// The value is assumed to be a string representation of a [SystemShell]
  /// derived from [SystemShell.toString].
  ///
  /// Throws an [ArgumentError] if the string cannot be parsed into a
  /// [SystemShell].
  SystemShell toSystemShell() {
    if (this == SystemShell.bash.toString()) {
      return SystemShell.bash;
    } else if (this == SystemShell.zsh.toString()) {
      return SystemShell.zsh;
    } else {
      throw ArgumentError.value(
        this,
        'value',
        '''Failed to parse $SystemShell from "$this"''',
      );
    }
  }
}
