import 'dart:math';

class MazeCell {
  final int x;
  final int y;
  final CellType type;

  MazeCell({required this.x, required this.y, required this.type});
}

enum CellType {
  wall,
  floor,
  enemy,
}

class Room {
  final int x;
  final int y;
  final int width;
  final int height;

  Room({required this.x, required this.y, required this.width, required this.height});

  Point<int> get center => Point<int>(x + width ~/ 2, y + height ~/ 2);
}

class MazeGenerator {
  final int width;
  final int height;
  final int roomCount;
  final Random _random = Random();

  late List<List<CellType>> grid;
  List<Room> rooms = [];
  List<Point<int>> enemies = [];

  MazeGenerator({required this.width, required this.height, required this.roomCount}) {
    _initializeGrid();
  }

  void _initializeGrid() {
    grid = List.generate(height, (_) => List.filled(width, CellType.wall));
  }

  Room _generateRoom({int minSize = 3, int maxSize = 8}) {
    final roomWidth = minSize + _random.nextInt(maxSize - minSize + 1);
    final roomHeight = minSize + _random.nextInt(maxSize - minSize + 1);
    final x = 1 + _random.nextInt(width - roomWidth - 2);
    final y = 1 + _random.nextInt(height - roomHeight - 2);

    return Room(x: x, y: y, width: roomWidth, height: roomHeight);
  }

  bool _canPlaceRoom(Room room, {int minDistance = 2}) {
    // check walls
    if (room.x <= 0 ||
        room.y <= 0 ||
        room.x + room.width >= width - 1 ||
        room.y + room.height >= height - 1) {
      return false;
    }

    // check other rooms
    for (final existingRoom in rooms) {
      if (!(room.x + room.width + minDistance <= existingRoom.x ||
          existingRoom.x + existingRoom.width + minDistance <= room.x ||
          room.y + room.height + minDistance <= existingRoom.y ||
          existingRoom.y + existingRoom.height + minDistance <= room.y)) {
        return false;
      }
    }

    return true;
  }

  void _createRoom(Room room) {
    for (var y = room.y; y < room.y + room.height; y++) {
      for (var x = room.x; x < room.x + room.width; x++) {
        if (y >= 0 && y < height && x >= 0 && x < width) {
          grid[y][x] = CellType.floor;
        }
      }
    }
  }

  void _createCorridor(Point<int> start, Point<int> end) {
    // horizontal corridor
    final startX = min(start.x, end.x);
    final endX = max(start.x, end.x);

    for (var x = startX; x <= endX; x++) {
      if (x >= 0 && x < width && start.y >= 0 && start.y < height) {
        if (grid[start.y][x] == CellType.wall) {
          grid[start.y][x] = CellType.floor;
        }
      }
    }

    // vertical corridor
    final startY = min(start.y, end.y);
    final endY = max(start.y, end.y);

    for (var y = startY; y <= endY; y++) {
      if (y >= 0 && y < height && end.x >= 0 && end.x < width) {
        if (grid[y][end.x] == CellType.wall) {
          grid[y][end.x] = CellType.floor;
        }
      }
    }
  }

  void _placeEnemies({int enemyCount = 5}) {
    for (var i = 0; i < enemyCount; i++) {
      if (rooms.isEmpty) break;

      final room = rooms[_random.nextInt(rooms.length)];

      // 10 attempts to find empty place
      for (var attempt = 0; attempt < 10; attempt++) {
        final enemyX = room.x + 1 + _random.nextInt(room.width - 2);
        final enemyY = room.y + 1 + _random.nextInt(room.height - 2);

        if (enemyY >= 0 &&
            enemyY < height &&
            enemyX >= 0 &&
            enemyX < width &&
            grid[enemyY][enemyX] == CellType.floor) {
          grid[enemyY][enemyX] = CellType.enemy;
          enemies.add(Point<int>(enemyX, enemyY));
          break;
        }
      }
    }
  }

  List<List<CellType>> generate({int maxAttempts = 1000, int enemyCount = 5}) {
    _initializeGrid();
    rooms.clear();
    enemies.clear();

    // generate rooms
    var attempts = 0;
    while (rooms.length < roomCount && attempts < maxAttempts) {
      final room = _generateRoom();
      if (_canPlaceRoom(room)) {
        rooms.add(room);
        _createRoom(room);
      }
      attempts++;
    }

    if (rooms.length > 1) {
      // sort rooms by X
      rooms.sort((a, b) => a.x.compareTo(b.x));

      for (var i = 0; i < rooms.length - 1; i++) {
        _createCorridor(rooms[i].center, rooms[i + 1].center);
      }
    }

    // place enemies
    _placeEnemies(enemyCount: enemyCount);

    return grid;
  }

  List<MazeCell> getCells() {
    final cells = <MazeCell>[];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        cells.add(MazeCell(x: x, y: y, type: grid[y][x]));
      }
    }
    return cells;
  }

  void printMaze() {
    final symbols = {
      CellType.wall: '#',
      CellType.floor: '.',
      CellType.enemy: 'E',
    };

    for (var y = 0; y < height; y++) {
      var row = '';
      for (var x = 0; x < width; x++) {
        row += symbols[grid[y][x]]!;
      }
      print(row);
    }
  }

  CellType getCellType(int x, int y) {
    if (y >= 0 && y < height && x >= 0 && x < width) {
      return grid[y][x];
    }
    return CellType.wall;
  }
}
