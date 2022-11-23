import 'package:args/args.dart';

/// Matches commandline option args
final optionRegex = RegExp(r'^--(([a-zA-Z\-_0-9]+)(=(.*))?)?$');

/// Matches commandline option args in abbreviated form
final abbrRegex = RegExp(r'^-(([a-zA-Z0-9]+)(.*))?$');

///Extends [ArgParser] with utility methods that allow parsing a completion
///input, which in most cases only regards part of the rules.
extension ArgParserExtension on ArgParser {
  /// Parses [args] with this [ArgParser]'s command structure only, ignore
  /// option from the input and option rules from the parser.
  ///
  /// Returns null if there is an error when parsing, which means the given args
  /// do not respect the known command structure.
  ArgResults? tryParseCommandsOnly(Iterable<String> args) {
    final commandsOnlyGrammar = cloneOnlyCommandMapping();

    // remove any eventual option from args
    final filteredArgs = args.where((element) {
      return !abbrRegex.hasMatch(element) &&
          !optionRegex.hasMatch(element) &&
          element.isNotEmpty;
    });

    try {
      return commandsOnlyGrammar.parse(filteredArgs);
    } on ArgParserException {
      return null;
    }
  }

  /// Recursively copies this [ArgParser] with all options and flags removed.
  ArgParser cloneOnlyCommandMapping() {
    final clonedArgParser = ArgParser(
      allowTrailingOptions: allowTrailingOptions,
    );

    for (final entry in commands.entries) {
      final parser = entry.value.cloneOnlyCommandMapping();
      clonedArgParser.addCommand(entry.key, parser);
    }

    return clonedArgParser;
  }
}
