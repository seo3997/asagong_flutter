enum ServerType { local, dev, prod }

class Constants {
  /// Toggle this enum between ServerType.local, ServerType.dev, ServerType.prod
  /// to switch base environments.
  static const ServerType currentServer = ServerType.prod;

  static String get baseUrl {
    switch (currentServer) {
      case ServerType.local:
        return 'http://10.69.122.25:9000';
      case ServerType.dev:
        return 'http://www.kycarrots.com:9000';
      case ServerType.prod:
        return 'http://www.asagong.com';
    }
  }

  static String get baseChatUrl {
    switch (currentServer) {
      case ServerType.local:
        return 'ws://10.69.122.25:9000/chat-ws?userId=';
      case ServerType.dev:
        return 'ws://www.kycarrots.com:9000/chat-ws?userId=';
      case ServerType.prod:
        return 'ws://www.asagong.com/chat-ws?userId=';
    }
  }

  static const int systemType = 2; // 1: 직거래, 2: 중간센터

  static const String roleAdmin = 'ROLE_ADMIN';
  static const String rolePub = 'ROLE_PUB';
  static const String roleSell = 'ROLE_SELL';
  static const String roleProj = 'ROLE_PROJ';

  static const String centerBranchId = '2';
  static const String appTestYn = 'Y';
}
