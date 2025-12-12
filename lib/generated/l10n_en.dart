// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Habitto';

  @override
  String get loginButton => 'Login';

  @override
  String get registerButton => 'Register';

  @override
  String welcomeMessage(String name) {
    return 'Hello $name!';
  }

  @override
  String get uploadMultipleHint => 'You can upload multiple photos at once';

  @override
  String get noPhotosYet => 'No photos yet';

  @override
  String get addPhotosHint => 'Add photos of your property';

  @override
  String get propertyNotFound => 'Property not found';

  @override
  String get propertyTitleFallback => 'No title';

  @override
  String rentPerMonth(String price) {
    return 'Bs. $price/month';
  }

  @override
  String bedroomsShort(String count) {
    return '$count bed.';
  }

  @override
  String bathroomsShort(String count) {
    return '$count bath.';
  }

  @override
  String sizeShort(String size) {
    return '$size m²';
  }

  @override
  String get amenitiesLabel => 'Amenities';

  @override
  String get swipeForMatchButton => 'Swipe for Match';

  @override
  String get requestRoomieButton => 'Request Roomie';

  @override
  String get scheduleViewButton => 'Schedule View';

  @override
  String get reviewsLabel => 'Reviews';

  @override
  String get mockReviewer1 => 'Ana García';

  @override
  String get mockReview1 => 'Excellent place, very bright and safe.';

  @override
  String get mockReviewer2 => 'Carlos Ruiz';

  @override
  String get mockReview2 => 'The landlord is very kind, recommended.';

  @override
  String get amenityDefaultLabel => 'Amenity';

  @override
  String get propertyTypeHouse => 'House';

  @override
  String get propertyTypeApartment => 'Apartment';

  @override
  String get propertyTypeRoom => 'Room';

  @override
  String get propertyTypeAnticretico => 'Anticretico';

  @override
  String get amenityWifi => 'WiFi';

  @override
  String get amenityParking => 'Parking';

  @override
  String get amenityLaundry => 'Laundry';

  @override
  String get amenityGym => 'Gym';

  @override
  String get amenityPool => 'Pool';

  @override
  String get amenityGarden => 'Garden';

  @override
  String loadDataError(String error) {
    return 'Error loading data: $error';
  }

  @override
  String get userFetchError => 'Error fetching user';

  @override
  String get propertyCreatedTitle => 'Property Created';

  @override
  String get propertyCreatedMessage =>
      'The property has been created successfully.';

  @override
  String get laterButton => 'Later';

  @override
  String get addPhotosButton => 'Add photos';

  @override
  String genericError(String error) {
    return 'Error: $error';
  }

  @override
  String get enterAddressError => 'Enter an address';

  @override
  String get enterPriceError => 'Enter a price';

  @override
  String get enterGuaranteeError => 'Enter a guarantee';

  @override
  String get enterDescriptionError => 'Enter a description';

  @override
  String get enterAreaError => 'Enter the area';

  @override
  String get invalidPriceError => 'Invalid price';

  @override
  String get invalidGuaranteeError => 'Invalid guarantee';

  @override
  String get invalidAreaError => 'Invalid area';

  @override
  String get propertyDetailsTitle => 'Property Details';

  @override
  String get saveAndExit => 'Save and Exit';

  @override
  String get stepBasic => 'Basic';

  @override
  String get stepDetails => 'Details';

  @override
  String get stepLocation => 'Location';

  @override
  String get stepBasicDescription => 'Main information';

  @override
  String get bedroomsLabel => 'Bedrooms';

  @override
  String get bathroomsLabel => 'Bathrooms';

  @override
  String get areaLabel => 'Area (m²)';

  @override
  String get stepDetailsDescription => 'Features and prices';

  @override
  String get rentPriceLabel => 'Rent Price';

  @override
  String get adjustPriceLabel => 'Adjust price';

  @override
  String get guaranteeLabel => 'Guarantee';

  @override
  String get adjustGuaranteeLabel => 'Adjust guarantee';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get propertyDescriptionHint => 'Describe your property...';

  @override
  String get acceptedPaymentMethodsLabel => 'Accepted payment methods';

  @override
  String get confirmLocation => 'Confirm Location';

  @override
  String get stepLocationDescription => 'Exact location';

  @override
  String get addressLabel => 'Address';

  @override
  String get addressHint => 'Ex. Main St #123';

  @override
  String get mapLocationLabel => 'Location on map';

  @override
  String get tapToSelectLocation => 'Tap to select location';

  @override
  String get availabilityDateLabel => 'Availability Date';

  @override
  String get dateHint => 'Select date';

  @override
  String get propertyTypeLabel => 'Property Type';

  @override
  String get previousButton => 'Previous';

  @override
  String get finishButton => 'Finish';

  @override
  String get nextButton => 'Next';

  @override
  String loadPhotosError(String error) {
    return 'Error loading photos: $error';
  }

  @override
  String pickImageError(String error) {
    return 'Error selecting image: $error';
  }

  @override
  String uploadSummary(Object success, Object fail) {
    return '$success uploaded, $fail failed';
  }

  @override
  String get photosUploadedSuccess => 'Photos uploaded successfully';

  @override
  String get deletePhotoTitle => 'Delete photo';

  @override
  String get deletePhotoConfirmation =>
      'Are you sure you want to delete this photo?';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get photoDeletedSuccess => 'Photo deleted';

  @override
  String get propertyUpdatedSuccess => 'Property updated';

  @override
  String updatePropertyError(String error) {
    return 'Error updating: $error';
  }

  @override
  String get editPropertyTitle => 'Edit Property';

  @override
  String get priceLabel => 'Price';

  @override
  String get bedroomsShortLabel => 'Bed.';

  @override
  String get matchLabel => 'Match';

  @override
  String get uploadPhotosButton => 'Upload Photos';

  @override
  String get noInterestsYet => 'No interests yet';

  @override
  String matchScore(String score) {
    return 'Match: $score%';
  }

  @override
  String get matchAcceptedMessage => 'Match accepted';

  @override
  String get priceBsLabel => 'Price (Bs)';

  @override
  String get guaranteeBsLabel => 'Guarantee (Bs)';

  @override
  String get sizeLabel => 'Size (m²)';

  @override
  String get saveChangesButton => 'Save Changes';

  @override
  String get requiredField => 'Required field';

  @override
  String get uploadPhotosTitle => 'Upload Photos';

  @override
  String get cameraOption => 'Camera';

  @override
  String get galleryOption => 'Gallery';

  @override
  String get socialAreasTitle => 'Social Areas';

  @override
  String get socialAreasComingSoon => 'Coming Soon: Social Areas';

  @override
  String get onboardingTitle1 => 'Find your ideal home';

  @override
  String get onboardingSubtitle1 => 'Explore thousands of options...';

  @override
  String get onboardingTitle2 => 'Connect with landlords';

  @override
  String get onboardingSubtitle2 => 'Direct and safe chat...';

  @override
  String get onboardingTitle3 => 'Manage your properties';

  @override
  String get onboardingSubtitle3 => 'Publish and manage...';

  @override
  String get onboardingTitle4 => 'All in one place';

  @override
  String get onboardingSubtitle4 => 'The best real estate experience';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionReject => 'Reject';

  @override
  String get actionLike => 'Like';

  @override
  String get actionFavorite => 'Favorite';

  @override
  String get closeButton => 'Close';

  @override
  String get matchTitle => 'It\'s a Match!';

  @override
  String get matchPrefix => 'You like ';

  @override
  String get matchWord => 'this property';

  @override
  String get matchSuffix => '!';

  @override
  String get matchWith => 'with';

  @override
  String get thisProperty => 'this property';

  @override
  String get matchSubtitle => 'Now you can chat...';

  @override
  String get sendMessageButton => 'Send Message';

  @override
  String get searchApartmentSuggestion => 'Looking for apartment in...';

  @override
  String get searchRoomieSuggestion => 'Looking for roomie...';

  @override
  String get createProfileSuggestion => 'Create profile...';

  @override
  String aiAssistantGreeting(String name) {
    return 'Hello $name! I am your assistant...';
  }

  @override
  String get micPermissionRequired => 'Microphone permission required';

  @override
  String get micPermissionTitle => 'Microphone Permission';

  @override
  String get micPermissionContent => 'We need access to the microphone...';

  @override
  String get openSettingsButton => 'Open Settings';

  @override
  String get profileCreatedSuccess => 'Profile created successfully';

  @override
  String get aiProcessingError => 'Error processing...';

  @override
  String get aiTypingIndicator => 'Typing...';

  @override
  String get listeningIndicator => 'Listening...';

  @override
  String get aiChatPlaceholder => 'Type a message...';

  @override
  String get navExplore => 'Explore';

  @override
  String get navCandidates => 'Candidates';

  @override
  String get navLeads => 'Leads';

  @override
  String get navMap => 'Map';

  @override
  String get navProperties => 'Properties';

  @override
  String get navPortfolio => 'Portfolio';

  @override
  String get navInbox => 'Inbox';

  @override
  String get navChat => 'Chat';

  @override
  String get navProfProfile => 'Pro Profile';

  @override
  String get navProfile => 'Profile';

  @override
  String get closeMenu => 'Close menu';

  @override
  String get openMenu => 'Open menu';

  @override
  String navItemActive(String label) {
    return '$label active';
  }

  @override
  String get noImagePlaceholder => 'No image';

  @override
  String get menuMatchs => 'Matches';

  @override
  String get menuAddProperty => 'Add Property';

  @override
  String get tenantRole => 'Tenant';

  @override
  String get landlordRole => 'Landlord';

  @override
  String get agentRole => 'Agent';

  @override
  String get likeSent => 'Like sent! The landlord will be notified.';

  @override
  String get likeError => 'Error sending like';

  @override
  String get rejectError => 'Error rejecting';

  @override
  String get noMoreProperties => 'No more properties';

  @override
  String get noImageLabel => 'No image';

  @override
  String get retryButton => 'Retry';

  @override
  String get noPendingMatchRequests => 'No pending match requests';

  @override
  String get newMatchRequestsWillAppearHere => 'New requests will appear here';
}
