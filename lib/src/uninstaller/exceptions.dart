/// {@template completion_uninstallation_exception}
/// Describes an exception during the uninstallation of completion scripts.
/// {@endtemplate}
class CompletionUninstallationException implements Exception {
  /// {@macro completion_uninstallation_exception}
  CompletionUninstallationException({
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
