# Requirements Document

## Introduction

This feature addresses critical issues in the Habitto app related to user profile data loading and user registration process. The current implementation has problems fetching and displaying user data correctly, and the registration process doesn't follow the API documentation properly.

## Glossary

- **Profile_Service**: Service responsible for fetching user profile data from the API
- **Auth_Service**: Service responsible for user authentication and registration
- **Profile_Page**: UI component that displays user profile information
- **Register_Page**: UI component for user registration
- **API_Endpoint**: Backend API endpoints as defined in the API documentation
- **User_Data**: User information including name, email, phone, and profile details

## Requirements

### Requirement 1

**User Story:** As a user, I want to see my complete profile information displayed correctly, so that I can verify my account details are accurate

#### Acceptance Criteria

1. WHEN the Profile_Page loads, THE Profile_Service SHALL fetch the current user's profile data using the correct API endpoint
2. WHEN the profile data is successfully retrieved, THE Profile_Page SHALL display the user's full name, email, phone number, and user ID
3. IF the profile data is not available, THE Profile_Page SHALL display placeholder text instead of null values
4. WHEN the user data includes a nested user object, THE Profile_Page SHALL extract and display the user information correctly
5. WHILE the profile is loading, THE Profile_Page SHALL show a loading indicator

### Requirement 2

**User Story:** As a new user, I want to register an account successfully, so that I can access the Habitto platform

#### Acceptance Criteria

1. WHEN a user submits the registration form, THE Auth_Service SHALL create a user account using the correct API endpoint sequence
2. WHEN the user creation is successful, THE Auth_Service SHALL create a profile for the user with the provided information
3. IF the user creation fails, THE Register_Page SHALL display the appropriate error message
4. WHEN the registration includes a password field, THE Auth_Service SHALL include the password in the user creation request
5. WHEN the profile creation is successful, THE Register_Page SHALL navigate to the login page

### Requirement 3

**User Story:** As a developer, I want the profile service to use the correct API endpoints, so that data is fetched according to the API documentation

#### Acceptance Criteria

1. WHEN fetching current user profile, THE Profile_Service SHALL use the profiles endpoint that returns profile data with nested user information
2. WHEN the API returns profile data, THE Profile_Service SHALL handle the nested user object structure correctly
3. IF the API endpoint doesn't exist or returns an error, THE Profile_Service SHALL provide meaningful error messages
4. WHEN the profile includes user type information, THE Profile_Service SHALL set the user mode correctly
5. WHILE handling API responses, THE Profile_Service SHALL validate the response structure before processing

### Requirement 4

**User Story:** As a user, I want my profile verification status to be displayed accurately, so that I know if my account is verified

#### Acceptance Criteria

1. WHEN the profile data includes verification status, THE Profile_Page SHALL display the verification badge correctly
2. IF the user is verified, THE Profile_Page SHALL show a "Verificado" badge
3. WHEN the user is not verified, THE Profile_Page SHALL either hide the badge or show an unverified status
4. WHEN the verification status changes, THE Profile_Page SHALL update the display accordingly
5. WHILE displaying verification status, THE Profile_Page SHALL use consistent styling and colors