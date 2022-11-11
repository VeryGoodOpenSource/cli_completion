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

  /// The command in which its installation went wrong.
  final String rootCommand;

  @override
  String toString() => 'Could not install completion scripts for $rootCommand: '
      '$message';
}
