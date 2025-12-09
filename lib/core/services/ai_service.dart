import 'package:dio/dio.dart';
import 'package:habitto/config/app_config.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.deepseekBaseUrl,
    headers: {
      'Authorization': 'Bearer ${AppConfig.deepseekApiKey}',
      'Content-Type': 'application/json',
    },
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Sends a chat message to the Deepseek API
  Future<String?> chatCompletion({
    required List<Map<String, String>> history,
    String? systemPrompt,
  }) async {
    try {
      final messages = [
        if (systemPrompt != null) {'role': 'system', 'content': systemPrompt},
        ...history,
      ];

      final response = await _dio.post('/chat/completions', data: {
        'model': 'deepseek-chat', // Assuming 'deepseek-chat' is the model name
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1000,
      });

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'];
      }
      return null;
    } catch (e) {
      print('AI Service Error: $e');
      // In a real app, handle errors more gracefully (e.g., return error message)
      return null;
    }
  }

  /// System prompt for profile creation
  static const String profileCreationSystemPrompt = '''
You are a helpful AI assistant for a real estate app called "Habitto".
Your goal is to help the user create a "Search Profile" to find their ideal home or roommate.
You need to gather the following information through a natural conversation (ask 1-2 questions at a time):
1. Budget range (min and max).
2. Property type (Casa, Departamento, Habitación).
3. Number of bedrooms (min and max).
4. Amenities (WiFi, Parking, Laundry, Gym, Pool, Garden, etc.).
5. Remote work needs (Work space required?).
6. Pet policy (Pets allowed?).
7. Roommate preference (No, Open, Yes).
8. Family size and children count.
9. Lifestyle (Tranquilo, Social, Deportista, etc.) and smoking habits.
10. Preferred languages.
11. Approximate location (City/Area).

Language: communicate in the same language as the user (default to Spanish).

Output Format:
When you have gathered sufficient information (or if the user asks to finish), output a JSON block at the end of your message.
The JSON MUST be wrapped in a root object with a single key "PROFILE_DATA".
Example:
{
  "PROFILE_DATA": {
    "budget_min": 1000,
    "budget_max": 2000,
    "property_types": ["Departamento"],
    "bedrooms_min": 1,
    "bedrooms_max": 2,
    "amenities": ["WiFi", "Gym"],
    "remote_work_space": true,
    "pet_allowed": false,
    "roommate_preference": "open",
    "family_size": 1,
    "children_count": 0,
    "lifestyle_tags": ["Tranquilo"],
    "smoker": false,
    "languages": ["Español"],
    "location_description": "Zona Sur, La Paz"
  }
}

If you don't have enough info, just ask the next question.
Start by greeting the user and asking what they are looking for today.
''';
}
