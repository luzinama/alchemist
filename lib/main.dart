import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const PixelAlchemistApp());
}

class PixelAlchemistApp extends StatelessWidget {
  const PixelAlchemistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Alchemist',
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.dark(),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
          titleLarge: TextStyle(color: Colors.amber, fontSize: 20, fontFamily: 'PressStart2P'),
        ),
      ),
      home: const GameScreen(),
    );
  }
}

// === GAME STATE ===
class GameState {
  final List<List<Tile>> grid;
  final List<String> inventory;
  final int health;
  final int level;
  final Position playerPos;
  final bool gameOver;

  GameState({
    required this.grid,
    required this.inventory,
    required this.health,
    required this.level,
    required this.playerPos,
    required this.gameOver,
  });

  static GameState newLevel() {
    final random = Random();

    // Явно объявляем тип: List<List<Tile>>
    final List<List<Tile>> grid = List.generate(
      5,
          (row) => List.generate(
        5,
            (col) => TileEmpty(),
      ),
    );

    final playerPos = Position(random.nextInt(5), random.nextInt(5));
    grid[playerPos.row][playerPos.col] = TilePlayer();

    int enemiesPlaced = 0;
    final enemyTypes = ['fire+poison', 'water+light', 'earth+dark', 'air+crystal'];
    while (enemiesPlaced < 4 && enemiesPlaced < 20) {
      final r = random.nextInt(5);
      final c = random.nextInt(5);
      if (grid[r][c] is TileEmpty) {
        grid[r][c] = TileEnemy(enemyTypes[random.nextInt(enemyTypes.length)]);
        enemiesPlaced++;
      }
    }

    final elementPool = ['fire', 'water', 'earth', 'air', 'poison', 'light', 'dark', 'crystal'];
    final inventory = List.generate(4, (_) => elementPool[random.nextInt(elementPool.length)]);

    return GameState(
      grid: grid,
      inventory: inventory,
      health: 3,
      level: 1,
      playerPos: playerPos,
      gameOver: false,
    );
  }

  String? react(String usedElement, String targetFormula) {
    final Map<String, String> reactions = {
      'fire+water': 'steam',
      'water+fire': 'steam',
      'fire+poison': 'toxic_flame',
      'poison+fire': 'toxic_flame',
      'light+dark': 'void',
      'dark+light': 'void',
      'water+light': 'healing',
      'light+water': 'healing',
      'earth+air': 'dust',
      'air+earth': 'dust',
      'poison+light': 'purified',
      'light+poison': 'purified',
      'crystal+fire': 'glass',
      'fire+crystal': 'glass',
      'dark+water': 'shadow_water',
      'water+dark': 'shadow_water',
    };

    final parts = targetFormula.split('+');
    if (parts.length != 2) return null;

    final first = parts[0];
    final second = parts[1];

    if (usedElement != first && usedElement != second) {
      return null;
    }

    final otherElement = usedElement == first ? second : first;
    final directKey = '$usedElement+$otherElement';
    final reverseKey = '$otherElement+$usedElement';

    if (reactions.containsKey(directKey)) {
      return reactions[directKey];
    }
    if (reactions.containsKey(reverseKey)) {
      return reactions[reverseKey];
    }

    return null;
  }

  GameState updateAfterAction(Position newPos, String? usedElement) {
    // ✅ ЯВНО УКАЗЫВАЕМ ТИП: List<List<Tile>>
    final List<List<Tile>> newGrid = List.generate(
      grid.length,
          (i) => List<Tile>.from(grid[i]), // ✅ Используем List<Tile>.from() — сохраняет тип!
    );

    final newInventory = [...inventory];

    if (usedElement != null) {
      newInventory.remove(usedElement);
    }

    newGrid[playerPos.row][playerPos.col] = TileEmpty();
    newGrid[newPos.row][newPos.col] = TilePlayer();

    final cell = grid[newPos.row][newPos.col];
    if (cell is TileEnemy) {
      if (usedElement != null) {
        final reaction = react(usedElement, cell.formula);
        if (reaction != null) {
          newGrid[newPos.row][newPos.col] = TileEmpty();
          final newElement = ['fire', 'water', 'earth', 'air', 'poison', 'light', 'dark', 'crystal'][Random().nextInt(8)];
          newInventory.add(newElement);
        } else {
          return GameState(
            grid: newGrid,
            inventory: newInventory,
            health: health - 1,
            level: level,
            playerPos: newPos,
            gameOver: health - 1 <= 0,
          );
        }
      } else {
        return GameState(
          grid: newGrid,
          inventory: newInventory,
          health: health - 1,
          level: level,
          playerPos: newPos,
          gameOver: health - 1 <= 0,
        );
      }
    }

    if (cell is TileTrap) {
      return GameState(
        grid: newGrid,
        inventory: newInventory,
        health: health - 1,
        level: level,
        playerPos: newPos,
        gameOver: health - 1 <= 0,
      );
    }

    return GameState(
      grid: newGrid,
      inventory: newInventory,
      health: health,
      level: level,
      playerPos: newPos,
      gameOver: false,
    );
  }

  GameState move(int dr, int dc) {
    final newRow = playerPos.row + dr;
    final newCol = playerPos.col + dc;
    if (newRow < 0 || newRow >= 5 || newCol < 0 || newCol >= 5) return this;

    return updateAfterAction(Position(newRow, newCol), null);
  }

  // 👇 использует элемент на указанной позиции (например, на враге)
  GameState useElementAt(String element, Position targetPos) {
    final cell = grid[targetPos.row][targetPos.col];

    if (cell is TileEnemy) {
      return updateAfterAction(targetPos, element); // 👈 Используем позицию врага!
    }

    return this; // Не на враге — ничего не делаем
  }
}

// === TILES ===
abstract class Tile {}

class TileEmpty extends Tile {
  TileEmpty();
}

class TilePlayer extends Tile {
  TilePlayer();
}

class TileTrap extends Tile {
  TileTrap();
}

class TileEnemy extends Tile {
  final String formula;
  TileEnemy(this.formula);
  static TileEnemy enemy(String formula) => TileEnemy(formula);
}

class Position {
  final int row, col;
  Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is Position && other.row == row && other.col == col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

// === MAIN SCREEN ===
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState state;
  String? selectedElement;
  String? feedbackMessage;   // ✅ Добавлено!
  Timer? _feedbackTimer;     // ✅ Добавлено!

  @override
  void initState() {
    super.initState();
    state = GameState.newLevel();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel(); // ✅ Очистка таймера
    super.dispose();
  }

  void onTileTap(int row, int col) {
    if (state.gameOver) return;

    // Если выбран элемент — попробуем использовать его на клетке, куда тапнули
    if (selectedElement != null) {
      final targetCell = state.grid[row][col];
      if (targetCell is TileEnemy) {
        final result = state.useElementAt(selectedElement!, Position(row, col));

        if (result == state) {
          showFeedback('Этот элемент не взаимодействует с врагом...');
        } else {
          setState(() {
            state = result;
            selectedElement = null;
          });
        }
      }
      // Если тапнул не на врага — ничего не делаем
      return;
    }

    // Обычное перемещение — только если не выбран элемент
    final dr = row - state.playerPos.row;
    final dc = col - state.playerPos.col;
    if ((dr.abs() + dc.abs()) <= 1) {
      setState(() {
        state = state.move(dr, dc);
      });
    }
  }

  void onElementTap(String element) {
    setState(() {
      selectedElement = selectedElement == element ? null : element;
    });
  }

  void showFeedback(String message) {
    setState(() {
      feedbackMessage = message;
    });

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 1500), () {
      setState(() {
        feedbackMessage = null;
      });
    });
  }

  Widget buildGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.0,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: 25,
      itemBuilder: (context, index) {
        final row = index ~/ 5;
        final col = index % 5;
        final tile = state.grid[row][col];

        bool isSelected = selectedElement != null &&
            state.playerPos.row == row &&
            state.playerPos.col == col;

        Color bgColor = const Color(0xFF0F0F0F);
        IconData icon = Icons.radio_button_unchecked;
        Color iconColor = Colors.grey;

        if (tile is TilePlayer) {
          bgColor = Colors.blue.shade900;
          icon = Icons.person;
          iconColor = Colors.white;
        } else if (tile is TileEnemy) {
          bgColor = Colors.red.shade900;
          icon = Icons.flare;
          iconColor = Colors.orange;

          return Tooltip(
            message: tile.formula.toUpperCase(),
            waitDuration: const Duration(milliseconds: 300),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontFamily: 'PressStart2P',
              fontWeight: FontWeight.bold,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: GestureDetector(
              onTap: () => onTileTap(row, col),
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: Colors.black.withOpacity(0.3), width: 0.5),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    height: 40,
                    width: 40,
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                ),
              ),
            ),
          );
        } else if (tile is TileTrap) {
          bgColor = Colors.deepOrange.shade800;
          icon = Icons.warning;
          iconColor = Colors.yellow;
        }

        return GestureDetector(
          onTap: () => onTileTap(row, col),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: Colors.black.withOpacity(0.3), width: 0.5),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: 40,
                width: 40,
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildInventory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: state.inventory.map((element) {
          final isSelected = selectedElement == element;
          return Padding(
            padding: const EdgeInsets.all(4),
            child: GestureDetector(
              onTap: () => onElementTap(element),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.amber.shade700 : Colors.blue.shade800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Text(
                  element.toUpperCase().substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'PressStart2P',
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('PIXEL ALCHEMIST', style: TextStyle(fontFamily: 'PressStart2P')),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: buildGrid(),
            ),
          ),
          buildInventory(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'HP: ${state.health}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                Text(
                  'LVL: ${state.level}',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
                if (state.gameOver)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        state = GameState.newLevel();
                        selectedElement = null;
                        feedbackMessage = null; // ✅ Сбрасываем подсказку при перезапуске
                      });
                    },
                    child: const Text('REBIRTH'),
                  ),
              ],
            ),
          ),
          if (selectedElement != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Выбрано: $selectedElement → тапни на врага!',
                style: const TextStyle(color: Colors.yellow, fontSize: 12),
              ),
            ),
          if (feedbackMessage != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red, width: 1),
                ),
                child: Text(
                  feedbackMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontFamily: 'PressStart2P',
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}