import 'dart:math';

import 'package:code_tanks/src/common/test_socket.dart';
import 'package:code_tanks/src/server/game_server/logic/components/game_command/game_commands_component.dart';
import 'package:code_tanks/src/server/game_server/logic/game.dart';
import 'package:code_tanks/src/server/game_server/logic/systems/render_system.dart';
import 'package:test/test.dart';
import '../assets/dart/run.dart' as dart_run;

import '../assets/dart/code_tanks_api.dart';

class Custom extends BaseTank {
  @override
  void run() {
    setRadarToRotateWithGun(true);

    ahead(2);
    rotateGun(2);
    back(2);
    setRotateRadar(2);

    setRotateGun(2);
    ahead(2);
  }

  @override
  void onScanTank(ScanTankEvent e) {
    back(2);
    setRotateRadar(2);

    setRotateGun(2);
    ahead(2);
  }
}

BaseTank createTank() => Custom();

void main() {
  group('simple test', () {
    Game game;
    const gameKeys = ['0', '1', '2'];

    // final gameServerSocket = TestSocket();

    setUp(() {
      game = Game('0', gameKeys);

      for (final key in gameKeys) {
        final socket = TestSocket();
        dart_run.handleSocketAndBot(socket, Custom());
        game.addTank(key, socket);
      }
    });

    test('first test', () async {
      RenderSystem renderSystem = game.world.getSystemByType(RenderSystem);

      expect(renderSystem.frames.length, 0);

      await game.world.updateAsync();

      expect(renderSystem.frames.length, 1);

      await game.world.updateAsync();

      expect(renderSystem.frames.length, 2);

      await game.world.updateAsync();

      expect(renderSystem.frames.length, 3);
      expect(renderSystem.frames[0].renderables.length, 3);            
    });

    tearDown(() {
      //
    });
  });
}