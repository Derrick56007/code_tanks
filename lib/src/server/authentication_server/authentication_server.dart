import 'dart:async';
import 'dart:io';

import '../../../code_tanks_server_common.dart';
import '../authentication_server/authentication_database.dart';

class AuthenticationServer {
  final String address;
  final int port;
  final List<String> gameServerAddresses;
  final List<String> buildServerAddresses;

  HttpServer server;
  StreamSubscription<HttpRequest> sub;

  final gameServerSockets = <String, ServerWebSocket>{};
  final buildServerSockets = <String, ServerWebSocket>{};

  final authenticationDatabase = AuthenticationDatabase();

  AuthenticationServer(
      this.address, this.port, this.gameServerAddresses, this.buildServerAddresses) {
    print('game server urls: $gameServerAddresses');
    print('build server urls: $buildServerAddresses');
  }

  void init() async {
    server = await HttpServer.bind(address, port);
    server.idleTimeout = null;

    sub = server.listen(onRequest);

    print('auth server started at $address:$port');

    await authenticationDatabase.init();
  }

  void onRequest(HttpRequest req) async {
    // handle websocket connection
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      final socket = ServerWebSocket.upgradeRequest(req);

      await socket.start();

      handleSocketStart(req, socket);

      await socket.done;

      handleSocketDone(socket);
    }
  }

  void handleSocketStart(HttpRequest req, ServerWebSocket socket) {
    socket
      ..on('game_server_handshake', () {
        final address = req.connectionInfo.remoteAddress.address;

        print('handshake from game server $address');

        if (!gameServerAddresses.contains(address)) {
          print('address is not a valid game server $address');
          return;
        }

        if (gameServerSockets.containsKey(address)) {
          print('game server already connected: $address');
          return;
        }

        gameServerSockets[address] = socket;
        print('game server handshake success');
      })
      ..on('build_server_handshake', () {
        final address = req.connectionInfo.remoteAddress.address;

        print('handshake from build server $address');

        if (!buildServerAddresses.contains(address)) {
          print('address is not a valid build server $address');
          return;
        }
        if (buildServerSockets.containsKey(address)) {
          print('build server already connected: $address');
          return;
        }

        buildServerSockets[address] = socket;
        print('build server handshake success');
      })
      ..on('register', (data) => onRegister(socket, data))
      ..on('login', (data) => onLogin(socket, data))
      ..on('logout', () => onLogout(socket));
  }

  void handleSocketDone(ServerWebSocket socket) {
    if (gameServerSockets.containsValue(socket)) {
      gameServerSockets.remove(socket);
    }

    if (buildServerSockets.containsValue(socket)) {
      buildServerSockets.remove(socket);
    }
  }

  Future close() async {
    await sub.cancel();

    print('authentication server closed at $address:$port');
  }

  Future<void> onRegister(ServerWebSocket socket, data) async {
    await onLogout(socket);


    if (!(data is Map)) {
      print('incorrect data type for registering');
      return;
    }

    final username = '${data["username"]}';
    final password = '${data["password"]}';

    if (username == null || 
        username.trim().isEmpty ||
        username.toLowerCase() == 'null') {
      print('invalid username/password');
      return;
    }

    // search for username
    await authenticationDatabase.send_object(['HGET', 'users', username]);

    if (password == null ||
        password.trim().isEmpty ||
        password.toLowerCase() == 'null') {
          print('invalid username/password');
          return;
        }
  }

  Future<void> onLogin(ServerWebSocket socket, data) async {

  }

  Future<void> onLogout(ServerWebSocket socket) async {
  }
}
