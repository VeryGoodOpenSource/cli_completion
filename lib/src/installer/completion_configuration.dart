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
  if (!json.containsKey(CompletionConfiguration._uninstallsJsonKey)) {
    return UnmodifiableMapView({});
  }
  final jsonUninstalls = json[CompletionConfiguration._uninstallsJsonKey];
  if (jsonUninstalls is! String) {
    return UnmodifiableMapView({});
  }
  final decodedUninstalls = jsonDecode(jsonUninstalls);
  if (decodedUninstalls is! Map<String, dynamic>) {
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

/// Returns a JSON representation of this [Uninstalls].
String _jsonEncodeUninstalls(Uninstalls uninstalls) {
  return jsonEncode({
    for (final entry in uninstalls.entries)
      entry.key.toString(): entry.value.toList(),
  });
}