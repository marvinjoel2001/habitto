# Design Document

## Overview

This design addresses the critical issues in profile data loading and user registration by implementing proper API endpoint usage, correct data handling, and robust error management. The solution ensures that user profile information is displayed correctly and the registration process follows the API documentation.

## Architecture

### Current Issues Analysis

1. **Profile Service Issues:**
   - Uses `/api/auth/user/` endpoint which may not return profile data
   - Doesn't handle nested user object structure properly
   - Missing proper error handling for empty/null data

2. **Registration Issues:**
   - Missing password field in user creation
   - Incorrect API endpoint sequence
   - Profile creation may not be linked to user properly

3. **Profile Page Issues:**
   - `_currentUser` is never populated from profile data
   - No fallback handling for missing data
   - Verification status not properly displayed

### Proposed Solution Architecture

```
Profile Loading Flow:
User opens Profile Page → Profile Service calls correct API → Parse nested user data → Update UI with complete information

Registration Flow:
User submits form → Create User with password → Get user ID → Create Profile with user ID → Navigate to login
```

## Components and Interfaces

### 1. ProfileService Updates

**Current Method:**
```dart
Future<Map<String, dynamic>> getCurrentProfile() async {
  final response = await _apiService.get(AppConfig.currentUserEndpoint); // Wrong endpoint
  // Missing user data extraction
}
```

**New Method:**
```dart
Future<Map<String, dynamic>> getCurrentProfile() async {
  // Try profile endpoint first, fallback to user endpoint if needed
  final response = await _apiService.get('/api/profiles/me/');
  if (response['success'] && response['data'] != null) {
    final profileData = response['data'];
    return {
      'success': true,
      'profile': Profile.fromJson(profileData),
      'user': User.fromJson(profileData['user']), // Extract nested user
    };
  }
  // Fallback logic for different API responses
}
```

### 2. AuthService Registration Fix

**Current Method:**
```dart
Future<Map<String, dynamic>> register(User user, Profile profile) async {
  final userResponse = await _apiService.post(AppConfig.usersEndpoint, user.toCreateJson());
  // Missing password field
}
```

**New Method:**
```dart
Future<Map<String, dynamic>> register(User user, Profile profile, String password) async {
  final userData = user.toCreateJson();
  userData['password'] = password; // Add password field
  
  final userResponse = await _apiService.post(AppConfig.usersEndpoint, userData);
  
  if (userResponse['success']) {
    final userId = userResponse['data']['id'];
    final profileData = profile.toCreateJson();
    // Don't set user field, let backend handle it or use correct field name
    
    final profileResponse = await _apiService.post(AppConfig.profilesEndpoint, profileData);
    return {
      'success': true,
      'user': userResponse['data'],
      'profile': profileResponse['data'],
    };
  }
}
```

### 3. Profile Page State Management

**Current State:**
```dart
Profile? _currentProfile;
User? _currentUser; // Never populated
```

**New State Management:**
```dart
Profile? _currentProfile;
User? _currentUser;

Future<void> _loadCurrentProfile() async {
  final response = await _profileService.getCurrentProfile();
  if (response['success']) {
    _currentProfile = response['profile'];
    _currentUser = response['user']; // Now properly populated
  }
}
```

## Data Models

### Profile Response Structure

According to API documentation, the profile endpoint returns:
```json
{
  "id": 1,
  "user": {
    "id": 1,
    "username": "usuario1",
    "email": "usuario1@example.com",
    "first_name": "Juan",
    "last_name": "Pérez",
    "date_joined": "2025-10-22T10:00:00Z"
  },
  "user_type": "inquilino",
  "phone": "+59112345678",
  "is_verified": false,
  "created_at": "2025-10-22T10:00:00Z",
  "updated_at": "2025-10-22T10:00:00Z",
  "favorites": [1, 3, 5]
}
```

### User Creation Request Structure

```json
{
  "username": "nuevo_usuario",
  "email": "usuario@example.com",
  "password": "tu_password_segura",
  "first_name": "Nombre",
  "last_name": "Apellido"
}
```

## Error Handling

### Profile Loading Error Scenarios

1. **Network Error:** Display "Error de conexión" message
2. **Invalid Token:** Redirect to login page
3. **Profile Not Found:** Show "Perfil no encontrado" message
4. **Malformed Response:** Log error and show generic error message

### Registration Error Scenarios

1. **Username Taken:** Display "Nombre de usuario ya existe"
2. **Email Taken:** Display "Email ya registrado"
3. **Validation Errors:** Display specific field errors
4. **Network Error:** Display "Error de conexión, intenta nuevamente"

### Fallback Data Display

When profile data is missing or null:
- Name: "Usuario" (instead of null)
- Email: "email@ejemplo.com" (instead of null)
- Phone: "+591 --------" (instead of null)
- ID: "ID: ---" (instead of null)

## Testing Strategy

### Unit Tests

1. **ProfileService Tests:**
   - Test successful profile loading with nested user data
   - Test error handling for various API responses
   - Test fallback mechanisms

2. **AuthService Tests:**
   - Test successful registration with password
   - Test error handling for registration failures
   - Test profile creation after user creation

3. **Profile Page Tests:**
   - Test UI updates with complete profile data
   - Test fallback display for missing data
   - Test loading states and error states

### Integration Tests

1. **End-to-End Registration Flow:**
   - Complete registration process from form to login
   - Verify user and profile creation in backend
   - Test error scenarios and recovery

2. **Profile Loading Flow:**
   - Load profile page and verify all data displays
   - Test with different user types and verification statuses
   - Test offline/network error scenarios

### API Endpoint Testing

1. **Profile Endpoints:**
   - Test `/api/profiles/me/` endpoint response structure
   - Verify nested user data is included
   - Test authentication requirements

2. **Registration Endpoints:**
   - Test user creation with password field
   - Test profile creation after user creation
   - Verify proper error responses

## Implementation Approach

### Phase 1: Fix Profile Service
1. Update `getCurrentProfile()` method to use correct endpoint
2. Add proper user data extraction from nested response
3. Implement robust error handling and fallbacks

### Phase 2: Fix Registration Process
1. Update `register()` method to include password field
2. Fix profile creation to properly link to user
3. Add comprehensive error handling

### Phase 3: Update Profile Page
1. Ensure `_currentUser` is populated from profile response
2. Add fallback display logic for missing data
3. Update verification status display logic

### Phase 4: Testing and Validation
1. Test all scenarios with real API responses
2. Verify error handling works correctly
3. Ensure UI displays data properly in all cases

## API Integration Details

### Correct Endpoint Usage

Based on API documentation:
- **Current User Profile:** `GET /api/profiles/me/` (if available) or handle user extraction from profile data
- **User Registration:** `POST /api/users/` with password field
- **Profile Creation:** `POST /api/profiles/` after user creation

### Authentication Headers

All API calls must include:
```
Authorization: Bearer <access_token>
```

### Response Validation

Before processing API responses, validate:
1. Response has `success` field
2. Data field exists and is not null
3. Required nested objects are present
4. Data structure matches expected format