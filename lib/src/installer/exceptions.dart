/// {@template completion_installation_exception}
/// Describes an exception during the installation of completion scripts.
/// {@endtemplate}
class CompletionInstallationException implements Exception {
  /// {@macro completion_installation_exception}
  CompletionInstallationException({
    required this.message,
    required this.executableName,
  });

  /// The error message for this exception
  final String message;

  /// The executable name for which the installation failed.
  final String executableName;

  @override
  String toString() =>
      '''Could not install completion scripts for $executableName: $message''';
}
