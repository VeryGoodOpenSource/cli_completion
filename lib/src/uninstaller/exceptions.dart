/// {@template completion_uninstallation_exception}
/// Describes an exception during the uninstallation of completion scripts.
/// {@endtemplate}
class CompletionUninstallationException implements Exception {
  /// {@macro completion_uninstallation_exception}
  CompletionUninstallationException({
    required this.message,
  });

  /// The error message for this exception
  final String message;

  @override
  String toString() => 'Could not uninstall completion scripts: '
      '$message';
}
