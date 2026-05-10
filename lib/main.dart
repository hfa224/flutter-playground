import 'package:flutter/material.dart';
import 'draggable_game.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          toolbarHeight: MediaQuery.of(context).size.width * 0.1,
          title: Align(
            alignment: Alignment.center,
            child: Text(
              'Arrange everyone in order of their Riskaware age (oldest to youngest)',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 600 ? 16 : 24,
              ),
            ),
          ),
        ),
        body: GamePage(),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

typedef TileData = ({String name, GuessType type});

class _GamePageState extends State<GamePage> {
  // This object is part of the game.dart file.
  final Game _game = Game();
  List<TileData?> board = List<TileData?>.filled(5, null);
  List<TileData>? result;

  void moveTile(TileData tile, int position) {
    setState(() {
      board[position] = tile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.width * 0.7,
        child: Column(
          spacing: 5.0,
          children: [
            Row(
              spacing: 5.0,
              children: [
                for (final person in _game.availablePeople)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2.5,
                        vertical: 2.5,
                      ),
                      child: Tile(person.name, person.type),
                    ),
                  ),
              ],
            ),
            if (result != null)
              Row(
                spacing: 5.0,
                children: [
                  for (var i = 0; i < result!.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2.5,
                          vertical: 2.5,
                        ),
                        child: TileSlot(
                          position: i,
                          tileData: result![i],
                          onTileDropped: (TileData tileData, int position) {
                            print(tileData.name);
                            //moveTile(tileData, position);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            if (result == null)
              SizedBox(
                height: MediaQuery.of(context).size.width < 600 ? 100 : 200,
                child:Row(
                spacing: 5.0,
                children: [
                  for (var i = 0; i < board.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2.5,
                          vertical: 2.5,
                        ),
                        child: TileSlot(
                          position: i,
                          tileData: board[i],
                          onTileDropped: (TileData tileData, int position) {
                            moveTile(tileData, position);
                          },
                        ),
                      ),
                    ),
                ],
              ),),
            if (result == null)
              GuessButton(
                onSubmitGuess: () {
                  setState(() {
                    // NEW
                    List<Person> guessList = [];
                    for (var i = 0; i < board.length; i++) {
                      guessList.add(
                        Person(
                          name: board[i]!.name,
                          position: i,
                          startDate: DateTime.now(),
                          type: GuessType.none,
                        ),
                      );
                    }
                    result = _game
                        .guess(guessList)
                        .map((person) => (name: person.name, type: person.type))
                        .toList();
                  });
                },
              ),
            if (result != null)
              ResetButton(
                onReset: () {
                  setState(() {
                    _game.resetGame();
                    result = null;
                    board = List<TileData?>.filled(5, null);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}

class Tile extends StatelessWidget {
  const Tile(this.name, this.guessType, {super.key})
    : imageUrl = 'assets/riskaware/$name.jpg';

  final String name;
  final GuessType guessType;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Draggable<TileData>(
      data: (name: name, type: guessType),

      // Widget shown while dragging
      feedback: Material(
        color: Colors.transparent,
        child: _buildTile(opacity: 0.8),
      ),

      // Widget shown in original spot while dragging
      childWhenDragging: _buildTile(opacity: 0.3),

      // Normal widget
      child: _buildTile(),
    );
  }

  Widget _buildTile({double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: switch (guessType) {
            GuessType.hit => Colors.green,
            GuessType.miss => Colors.red,
            _ => Colors.white,
          },
        ),
        child: Center(child: Image.asset(imageUrl)),
      ),
    );
  }
}

class TileSlot extends StatelessWidget {
  const TileSlot({
    super.key,
    required this.position,
    required this.tileData,
    required this.onTileDropped,
  });

  final int position;
  final TileData? tileData;

  final void Function(TileData tile, int newPosition) onTileDropped;

  @override
  Widget build(BuildContext context) {
    return DragTarget<TileData>(
      onAcceptWithDetails: (details) {
        onTileDropped(details.data, position);
      },

      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isHovering ? Colors.blue : Colors.grey.shade400,
              width: 2,
            ),

            color: isHovering ? Colors.blue.shade100 : Colors.grey.shade200,
          ),

          child: tileData != null
              ? Tile(tileData!.name, tileData!.type)
              : const SizedBox.expand(),
        );
      },
    );
  }
}

class GuessButton extends StatelessWidget {
  const GuessButton({super.key, required this.onSubmitGuess});

  final void Function() onSubmitGuess;

  void _onSubmit() {
    onSubmitGuess();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton(
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(Colors.amber),
            ),
            onPressed: () {
              _onSubmit();
            },
            child: Text("Submit"),
          ),
        ),
      ],
    );
  }
}

class ResetButton extends StatelessWidget {
  const ResetButton({super.key, required this.onReset});

  final void Function() onReset;

  void _onReset() {
    onReset();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton(
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(
                Colors.greenAccent,
              ),
            ),
            onPressed: () {
              _onReset();
            },
            child: Text("Reset game"),
          ),
        ),
      ],
    );
  }
}
