import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../config/app_config.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/token_storage.dart';
import '../../domain/entities/profile.dart';
import '../../../auth/domain/entities/user.dart';

class ProfileService {
  final ApiService _apiService;
  final TokenStorage _tokenStorage;

  ProfileService({
    ApiService? apiService,
    TokenStorage? tokenStorage,
  })  : _apiService = apiService ?? ApiService(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  /// Get current user's profile
  Future<Map<String, dynamic>> getCurrentProfile() async {
    try {
      // Try to use the specific profile endpoint first if available
      try {
        final profileMeResponse = await _apiService.get(AppConfig.currentProfileEndpoint);
        if (profileMeResponse['success'] && profileMeResponse['data'] != null) {
          final profileData = profileMeResponse['data'];
          return {
            'success': true,
            'profile': Profile.fromJson(profileData),
            'user': User.fromJson(profileData['user']),
          };
        }
      } catch (e) {
        print('Profile /me endpoint not available, trying alternative method: $e');
      }

      // Fallback: Get current user data first
      final userResponse = await _apiService.get(AppConfig.currentUserEndpoint);

      if (userResponse['success'] && userResponse['data'] != null) {
        final userData = userResponse['data'];
        final userId = userData['id'];

        // Now try to get the user's profile from the profiles list
        try {
          final profileResponse = await _apiService.get(AppConfig.profilesEndpoint);
          if (profileResponse['success'] && profileResponse['data'] != null) {
            final results = profileResponse['data']['results'] as List?;
            if (results != null && results.isNotEmpty) {
              // Find the profile for the current user
              final userProfile = results.firstWhere(
                (profile) => profile['user']['id'] == userId,
                orElse: () => null,
              );

              if (userProfile != null) {
                return {
                  'success': true,
                  'profile': Profile.fromJson(userProfile),
                  'user': User.fromJson(userProfile['user']),
                };
              }
            }
          }
        } catch (e) {
          print('Error fetching profile list: $e');
        }

        // If we can't find a profile, return just the user data
        return {
          'success': true,
          'profile': null,
          'user': User.fromJson(userData),
        };
      } else {
        return {
          'success': false,
          'error': userResponse['error'] ?? 'Failed to get user data',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Get profile by ID
  Future<Map<String, dynamic>> getProfileById(int profileId) async {
    try {
      final response = await _apiService.get('${AppConfig.profilesEndpoint}$profileId/');

      if (response['success']) {
        return {
          'success': true,
          'profile': Profile.fromJson(response['data']),
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to get profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Update profile
  Future<Map<String, dynamic>> updateProfile(int profileId, Map<String, dynamic> profileData) async {
    try {
      final response = await _apiService.put(
        '${AppConfig.profilesEndpoint}$profileId/',
        profileData,
      );

      if (response['success']) {
        return {
          'success': true,
          'profile': Profile.fromJson(response['data']),
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Verify profile
  Future<Map<String, dynamic>> verifyProfile(int profileId) async {
    try {
      final response = await _apiService.post('${AppConfig.profilesEndpoint}$profileId/verify/', {});

      if (response['success']) {
        return {
          'success': true,
          'message': 'Profile verified successfully',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to verify profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Add property to favorites
  Future<Map<String, dynamic>> addToFavorites(int profileId, int propertyId) async {
    try {
      // First get current profile to get existing favorites
      final currentProfileResult = await getProfileById(profileId);
      if (!currentProfileResult['success']) {
        return currentProfileResult;
      }

      final Profile currentProfile = currentProfileResult['profile'];
      final List<int> favorites = List<int>.from(currentProfile.favorites ?? []);

      if (!favorites.contains(propertyId)) {
        favorites.add(propertyId);
      }

      return await updateProfile(profileId, {'favorites': favorites});
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to add to favorites: $e',
      };
    }
  }

  /// Remove property from favorites
  Future<Map<String, dynamic>> removeFromFavorites(int profileId, int propertyId) async {
    try {
      // First get current profile to get existing favorites
      final currentProfileResult = await getProfileById(profileId);
      if (!currentProfileResult['success']) {
        return currentProfileResult;
      }

      final Profile currentProfile = currentProfileResult['profile'];
      final List<int> favorites = List<int>.from(currentProfile.favorites ?? []);

      favorites.remove(propertyId);

      return await updateProfile(profileId, {'favorites': favorites});
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to remove from favorites: $e',
      };
    }
  }
}
