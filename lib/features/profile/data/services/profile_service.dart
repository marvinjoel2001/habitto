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
      // Try to get current user profile - this should return profile data with nested user
      final response = await _apiService.get(AppConfig.currentUserEndpoint);

      if (response['success'] && response['data'] != null) {
        final data = response['data'];
        
        // Check if this is a profile response with nested user data
        if (data['user'] != null) {
          // This is a profile response with nested user data
          return {
            'success': true,
            'profile': Profile.fromJson(data),
            'user': User.fromJson(data['user']),
          };
        } else {
          // This might be just user data, try to get profile separately
          // First, let's try to find the user's profile
          try {
            final profileResponse = await _apiService.get(AppConfig.profilesEndpoint);
            if (profileResponse['success'] && profileResponse['data'] != null) {
              final results = profileResponse['data']['results'] as List?;
              if (results != null && results.isNotEmpty) {
                // Find the profile for the current user
                final userProfile = results.firstWhere(
                  (profile) => profile['user']['id'] == data['id'],
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
            'user': User.fromJson(data),
          };
        }
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
