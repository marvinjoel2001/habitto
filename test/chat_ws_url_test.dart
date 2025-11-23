import 'package:flutter_test/flutter_test.dart';
import 'package:habitto/config/app_config.dart';

void main() {
  group('WebSocket URL builder', () {
    test('inbox URL uses correct path and port', () {
      final uri = AppConfig.buildWsUri('${AppConfig.wsInboxPath}42/', token: 'abc');
      expect(uri.scheme, AppConfig.wsScheme());
      final http = AppConfig.httpBaseUri();
      expect(uri.port, http.hasPort ? http.port : null);
      expect(uri.path, '/ws/chat/inbox/42/');
      expect(uri.queryParameters[AppConfig.wsTokenQueryName], 'abc');
    });

    test('chat room URL normal path with trailing slash', () {
      final uri = AppConfig.buildWsUri('${AppConfig.wsChatPath}5-7/', token: null);
      final http = AppConfig.httpBaseUri();
      expect(uri.port, http.hasPort ? http.port : null);
      expect(uri.path, '/ws/chat/5-7/');
      expect(uri.queryParameters.isEmpty, true);
    });
  });
}