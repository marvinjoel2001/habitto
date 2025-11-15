import 'package:flutter_test/flutter_test.dart';
import 'package:habitto/features/chat/data/services/message_service.dart';
import 'package:habitto/features/chat/data/models/message_model.dart';

void main() {
  test('parse conversations envelope returns counterpart and last_message', () {
    final svc = MessageService();
    final envelope = {
      'results': [
        {
          'counterpart': {'id': 7, 'username': 'propietario'},
          'last_message': {
            'id': 123,
            'content': '¿Te gustaría visitarla?',
            'created_at': '2025-11-14T13:00:00Z',
            'sender': 7,
            'receiver': 5,
          }
        }
      ]
    };

    final convs = svc.parseConversationsEnvelope(envelope);
    expect(convs.length, 1);
    final c = convs.first;
    expect(c['counterpart_id'], 7);
    expect(c['counterpart_username'], 'propietario');
    final msg = c['last_message'] as MessageModel;
    expect(msg.id, 123);
    expect(msg.content, '¿Te gustaría visitarla?');
    expect(msg.sender, 7);
    expect(msg.receiver, 5);
  });
}