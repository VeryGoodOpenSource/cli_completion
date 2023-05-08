class CompletionUninstallation {
  /// Uninstall all completion configuration files for in the current shell.
  ///
  /// It will remove:
  /// - All completion script files in [completionConfigDir] that is named after
  /// the commands and the current shell (e.g. `very_good.bash`).
  /// - A config file in [completionConfigDir] that is named after the current
  /// shell (e.g. `bash-config.bash`) that sources the aforementioned
  /// completion script file.
  /// - A line in the shell config file (e.g. `.bash_profile`) that sources
  /// the aforementioned config file.
  void uninstall() {}
}
