import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:test/test.dart';
import 'package:birdle/draggable_game.dart';

void main() {
  group('Test the Game object', () {
    test('Test Game Objects', () {
      Game game = Game();

      for (Person person in game.availablePeople) {
        int position = person.position;
        final DateFormat formatter = DateFormat('yyyy-MM-dd');
        print(person.name + " $position " + formatter.format(person.startDate));
      }
    });
    test('Test evaluation hit', () {
     Game game = Game();

     List<Person> guess = List.from(game.availablePeople.toList());

     PeopleGroup result = game.guess(guess);

      for (Person person in result) {
        int position = person.position;
        final DateFormat formatter = DateFormat('yyyy-MM-dd');
        print(person.name + " $position " + formatter.format(person.startDate) + " " + person.type.toString());
      }

      assert(game.didWin);

    });

    test('Test evaluation miss', () async {
     Game game = Game();

     for (Person person in game.availablePeople) {
        int position = person.position;
        final DateFormat formatter = DateFormat('yyyy-MM-dd');
        print(person.name + " $position " + formatter.format(person.startDate) + " " + person.type.toString());
      }

     List<Person> guess = List.from(game.availablePeople.toList());

     for (var i=0; i<5; i++) {
      guess[i] = Person(name: guess[i].name, position: i, startDate: guess[i].startDate, type: GuessType.none);
     }

     PeopleGroup result = game.guess(guess);

      for (Person person in result) {
        int position = person.position;
        final DateFormat formatter = DateFormat('yyyy-MM-dd');
        print(person.name + " $position " + formatter.format(person.startDate) + " " + person.type.toString());
      }

      
      assert(game.didLose);
    });
  });
}
