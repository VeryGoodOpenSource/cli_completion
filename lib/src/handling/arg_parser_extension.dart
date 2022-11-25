import 'package:args/args.dart';

final _optionRegex = RegExp(r'^--(([a-zA-Z\-_0-9]+)(=(.*))?)?$');

/// Defines if [string] is an option.
bool isOption(String string) => _optionRegex.hasMatch(string);

final _abbrRegex = RegExp(r'^-(([a-zA-Z0-9]+)(.*))?$');

/// Defines if [string] is an option in an abbreviated form.
bool isAbbr(String string) => _abbrRegex.hasMatch(string);

/// Extends [ArgParser] with utility methods that allow parsing a completion
/// input, which in most cases only regards part of the rules.
extension ArgParserExtension on ArgParser {
  /// Parses [args] with this [ArgParser]'s command structure only, ignore
  /// option strict rules (mandatory, allowed values, non negatable flags,
  /// default values);
  ///
  /// Still breaks if an unknown option/alias is passed.
  ///
  /// Returns null if there is an error when parsing, which means the given args
  /// do not respect the known command structure.
  ArgResults? tryParseCommandsOnly(Iterable<String> args) {
    final commandsOnlyGrammar = _looseOptions();

    final filteredArgs = args.where((element) {
      return !isAbbr(element) && !isOption(element) && element.isNotEmpty;
    });

    try {
      return commandsOnlyGrammar
          .parse(filteredArgs.where((element) => element.isNotEmpty));
    } on ArgParserException {
      return null;
    }
  }

  /// Recursively copies this [ArgParser] without options.
  ArgParser _looseOptions() {
    final clonedArgParser = ArgParser(
      allowTrailingOptions: allowTrailingOptions,
    );

    for (final entry in commands.entries) {
      final parser = entry.value._looseOptions();
      clonedArgParser.addCommand(entry.key, parser);
    }

    return clonedArgParser;
  }
}
