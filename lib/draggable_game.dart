/// Game logic and supporting types for Draggable game,
/// a game where you drag riskaware people into their start order
///
/// Defines the [Game] state machine and the
/// [Person], and [GuessType] data model used to
/// represent guesses and their evaluation against a hidden word.
library;

import 'dart:collection';
import 'dart:math';

/// The result of evaluating a [Letter] of a guess against the hidden word.
enum GuessType {
  /// The letter hasn't yet been evaluated.
  none,

  /// The letter matches the hidden word's letter at the same position.
  hit,

  /// The letter doesn't appear in the hidden word.
  miss;

  GuessType empty() {
    return GuessType.none;
  }
}

/// A single character paired with its [HitType] against the hidden word.
class Person {
  String name;
  int position;
  DateTime startDate;
  GuessType type;

  Person({
    required this.name,
    required this.position,
    required this.startDate,
    required this.type,
  });
}

Person get emptyPerson => Person(
  name: '',
  position: -1,
  startDate: DateTime.now(),
  type: GuessType.none,
);

/// Every word that can be legally entered as a guess.
//const List<String> allLegalGuesses = [...legalWords, ...legalGuesses];

/// Words that can be chosen as the hidden word.
//const List<String> legalWords = ['aback', 'abase', 'abate', 'abbey', 'abbot'];

/// Additional words accepted as guesses beyond those in [legalWords].
final Map<String, DateTime> peopleNames = {
  'rob_g': DateTime.parse("1984-04-02"),
  'martyn_b': DateTime.parse("1984-04-02"),
  'russ_m': DateTime.parse("2001-10-29"),
  'tim_d': DateTime.parse("2004-04-19"),
  'james_e': DateTime.parse("2005-10-03"),
  'phil_w': DateTime.parse("2007-05-29"),
  'sacha_d': DateTime.parse("2009-01-12"),
  'peter_m': DateTime.parse("2011-04-04"),
  'mark_w': DateTime.parse("2011-06-13"),
  'helen_a': DateTime.parse("2013-09-16"),
  'steve_b': DateTime.parse("2013-10-01"),
  'andrej_z': DateTime.parse("2015-11-30"),
  'karin_e': DateTime.parse("2015-01-26"),
  'tim_c': DateTime.parse("2015-10-01"),
  'sian_j': DateTime.parse("2016-01-06"),
  'beth_d': DateTime.parse("2018-03-07"),
  'jenny_b': DateTime.parse("2019-11-11"),
  'ben_b': DateTime.parse("2019-11-18"),
  'fred_c': DateTime.parse("2021-10-04"),
  'harry_h': DateTime.parse("2022-01-05"),
  'tim_p': DateTime.parse("2022-02-01"),
  'emily_t': DateTime.parse("2022-06-06"),
  'agata_s': DateTime.parse("2022-11-01"),
  'james_w': DateTime.parse("2023-01-09"),
  'owain_s': DateTime.parse("2023-10-02"),
  'una_r': DateTime.parse("2025-01-06"),
  'murray_p': DateTime.parse("2025-02-01"),
};

final sorted = peopleNames.entries.toList()
  ..sort((a, b) => a.value.compareTo(b.value));
final Map<String, DateTime> dateSortedPeople = {
  for (var entry in sorted) entry.key: entry.value,
};

List<Person> _namesToPeople = List.generate(
  dateSortedPeople.length,
  (i) => Person(
    name: dateSortedPeople.keys.elementAt(i),
    position: i,
    startDate: dateSortedPeople.values.elementAt(i),
    type: GuessType.none,
  ),
);

/// Game state of a single round of Birdle,
/// a five-letter word-guessing game similar to Wordle.
///
/// Exposes the state and methods a UI needs to
/// evaluate guesses and track progress,
/// but doesn't advance play on its own.
///
/// Clients drive each round by calling [guess] to submit an attempt and
/// [resetGame] to start over.
class Game {
  /// The default maximum number of guesses allowed in a [Game].
  static const int defaultMaxGuesses = 5;

  /// Creates a new game with [maxGuesses] guesses allowed.
  ///
  /// If [seed] is provided, the hidden word is
  /// chosen deterministically from [legalWords],
  /// otherwise it is selected at random.
  Game({this.maxGuesses = defaultMaxGuesses, this.seed})
    : _options = _generateInitialPeopleGroup(),
      _guess = [];

  /// The maximum number of guesses allowed in this game.
  final int maxGuesses;

  /// The seed used to choose the hidden word,
  /// or `null` if it was selected at random.
  final int? seed;

  /// The current options, exposed publicly through [availablePeople].
  PeopleGroup _options;

  /// Backing storage for [guesses].
  ///
  /// Holds every guess slot in order,
  /// with unfilled slots represented by empty [Word]s.
  List<PeopleGroup> _guess;

  /// The word the player is trying to guess.
  PeopleGroup get availablePeople => _options;

  /// An unmodifiable view of every guess slot, including those still empty.
  PeopleGroup get currentGuess => _guess.first;

  /// The most recently submitted guess,
  /// or an empty [PeopleGroup] if no guesses have been made.
  // PeopleGroup get previousGuess {
  //   final index = _guesses.lastIndexWhere((word) => word.isNotEmpty);
  //   return index == -1 ? PeopleGroup.empty() : _guesses[index];
  // }

  /// The index of the next empty guess slot, or `-1` if every slot is full.
  //int get activeIndex => _guesses.indexWhere((word) => word.isEmpty);

  /// The number of guesses still available to the player.
  // int get guessesRemaining {
  //   if (activeIndex == -1) return 0;
  //   return maxGuesses - activeIndex;
  // }

  /// Whether the most recent guess matches the hidden word.
  bool get didWin {
    if (_guess.isEmpty) return false;

    for (final person in _guess.first) {
      if (person.type != GuessType.hit) return false;
    }

    return true;
  }

  /// Whether all allowed guesses have been used without winning.
  bool get didLose => _guess.isNotEmpty && !didWin;

  /// Picks a new hidden word and clears every submitted guess.
  void resetGame() {
    _options = _generateInitialPeopleGroup();
    _guess = [];
  }

  /// Evaluates [guess] against the actual people order,
  /// records the result in [guesses], and returns it.
  ///
  /// For finer control, use [isLegalGuess] to validate input or
  /// [matchGuessOnly] to evaluate without recording the result.
  PeopleGroup guess(List<Person> guess) {
    final result = matchGuessOnly(guess);
    submitGuess(result);
    return result;
  }

  /// Whether [guess] is a legal word to guess.
  ///
  /// UIs can call this method before [guess] to
  /// show players a message when they enter an invalid word.
  //bool isLegalGuess(List<Person> guess) => PeopleGroup.fromString(guess).isLegalGuess;

  /// Evaluates [guess] against the hidden word without advancing the game.
  PeopleGroup matchGuessOnly(List<Person> guess) =>
      PeopleGroup(guess).evaluateGuess(_options);

  /// Stores [guess] in the next empty slot of [guesses].
  void submitGuess(PeopleGroup guess) {
    if (_guess.isNotEmpty) {
      throw StateError('No guesses remaining.');
    }

    _guess.add(guess);
  }

  /// Returns the starting hidden word for a new round.
  ///
  /// Picks a random set of people either using the seed or not
  static PeopleGroup _generateInitialPeopleGroup() => PeopleGroup.random();
}

/// A five-person group made up of [Person]s, each tracking its [Position].
class PeopleGroup with IterableMixin<Person> {
  /// Creates a word backed by the specified list of [Person]s.
  PeopleGroup(this._persons);

  /// Creates a word with five blank letters of [HitType.none].
  factory PeopleGroup.empty() =>
      PeopleGroup(List<Person>.filled(5, emptyPerson));

  /// Creates a [PeopleGroup] from [guess].
  /// Each character is lowercased,
  /// every [Person] starts as [GuessType.none].
  factory PeopleGroup.fromString(List<Person> guess) {
    if (guess.length != 5) {
      throw ArgumentError.value(
        guess,
        'guess',
        'Must be exactly 5 people long.',
      );
    }
    return PeopleGroup(guess);
  }

  /// Creates a people group chosen at random from [namesToPeople].
  factory PeopleGroup.random() {
    final random = Random();
    List<Person> nextPeopleGroup = List<Person>.filled(5, emptyPerson);
    var i = 0;
    while (i < 5) {
      var randomPerson = _namesToPeople[random.nextInt(_namesToPeople.length)];
      if (!nextPeopleGroup
          .map((p) => p.name)
          .toList()
          .contains(randomPerson.name)) {
        nextPeopleGroup[i] = Person(
          name: randomPerson.name,
          position: randomPerson.position,
          startDate: randomPerson.startDate,
          type: GuessType.none,
        );
        print(
          "name: ${randomPerson.name} position ${randomPerson.position} and start date: ${randomPerson.startDate}",
        );
        i++;
      }
    }

    var sortedList = List<Person>.from(nextPeopleGroup);
    sortedList.sort((a, b) => a.position.compareTo(b.position));
    for (int i = 0; i < 5; i++) {
      for (Person person in nextPeopleGroup) {
        if (person.name == sortedList[i].name) {
          person.position = i;
          print(
            "repositioned name: ${person.name} position ${person.position} and start date: ${person.startDate}",
          );
        }
      }
    }

    return PeopleGroup.fromString(nextPeopleGroup);
  }

  /// Creates a word chosen from [legalWords] using [seed] as an index.
  // factory PeopleGroup.fromSeed(int seed) =>
  //     PeopleGroup.fromString(legalWords[seed % legalWords.length]);

  /// An unmodifiable list of [Letter]s that make up this word.
  final List<Person> _persons;

  @override
  Iterator<Person> get iterator => _persons.iterator;

  /// Whether every [Letter] in this word has no character.
  @override
  bool get isEmpty => every((person) => person.name.isEmpty);

  @override
  int get length => _persons.length;

  /// The [Person] at index [i] in people group.
  Person operator [](int i) => _persons[i];

  @override
  String toString() => _persons.map((letter) => letter.name).join().trim();

  /// Returns a multi-line string showing each [Letter] alongside its [HitType].
  ///
  /// Used to play the game from the command line.
  String toStringVerbose() => _persons
      .map((letter) => '${letter.name} - ${letter.type.name}')
      .join('\n');
}

/// Validation and guess-evaluation logic on [PeopleGroup].
extension PeopleGroupUtils on PeopleGroup {
  /// Whether this word appears in [allLegalGuesses].
  //bool get isLegalGuess => allLegalGuesses.contains(toString());

  /// Compares this [Word] against the specified [hiddenWord]
  /// and returns a new [Word] with the same letters,
  /// but where each [Letter] has new a [HitType] of
  /// [HitType.hit], [HitType.partial], or [HitType.miss].
  PeopleGroup evaluateGuess(PeopleGroup originalPeopleGroup) {
    //assert(isLegalGuess);

    final result = List<Person>.filled(length, emptyPerson);
    // Counts hidden-word letters that can still be claimed as partial matches.
    final unmatchedHiddenLetterCounts = <String, int>{};

    // Reserve exact matches before scoring partial matches.
    for (var i = 0; i < length; i++) {
      final currentPerson = this[i];

      final guessName = currentPerson.name;
      final guessPosition = currentPerson.position;
      var hiddenPosition = -1;

      for (Person person in originalPeopleGroup) {
        if (person.name == guessName) {
          hiddenPosition = person.position;
        }
      }

      print(
        "name: ${currentPerson.name}guess position $guessPosition and hidden position $hiddenPosition",
      );

      if (guessPosition == hiddenPosition) {
        result[i] = Person(
          name: guessName,
          position: -1,
          startDate: currentPerson.startDate,
          type: GuessType.hit,
        );
      } else {
        result[i] = Person(
          name: guessName,
          position: -1,
          startDate: currentPerson.startDate,
          type: GuessType.miss,
        );
      }
    }

    return PeopleGroup(result);
  }
}
