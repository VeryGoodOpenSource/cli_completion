/// {@template completion_installation_exception}
/// Describes an exception during the installation of completion scripts.
/// {@endtemplate}
class CompletionInstallationException implements Exception {
  /// {@macro completion_installation_exception}
  CompletionInstallationException({
    required this.message,
    required this.rootCommand,
  });

  /// The error message for this exception
  final String message;

  /// The command for which the installation failed.
  final String rootCommand;

  @override
  String toString() => 'Could not install completion scripts for $rootCommand: '
      '$message';
}

/// {@template completion_unistallation_exception}
/// Describes an exception during the uninstallation of completion scripts.
/// {@endtemplate}
class CompletionUnistallationException implements Exception {
  /// {@macro completion_unistallation_exception}
  CompletionUnistallationException({
    required this.message,
    required this.rootCommand,
  });

  /// The error message for this exception
  final String message;

  /// The command for which the installation failed.
  final String rootCommand;

  @override
  String toString() =>
      '''Could not uninstall completion scripts for $rootCommand: $message''';
}
