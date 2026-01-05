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
  String get createPropertySuggestion => 'List property';

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
  String get menuAiAssistant => 'AI Assistant';

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
  String rejectError(String error) {
    return 'Reject error: $error';
  }

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

  @override
  String get searchPlaceholder => 'Search by zone, price, type...';

  @override
  String get filterZone => 'Zone';

  @override
  String get filterPrice => 'Price';

  @override
  String get filterType => 'Type';

  @override
  String get filterAmenities => 'Amenities';

  @override
  String get viewMoreDetails => 'View more details';

  @override
  String get houseType => 'House';

  @override
  String get apartmentType => 'Apartment';

  @override
  String get roomType => 'Room';

  @override
  String get wifiAmenity => 'WiFi';

  @override
  String get parkingAmenity => 'Parking';

  @override
  String get laundryAmenity => 'Laundry';

  @override
  String get gymAmenity => 'Gym';

  @override
  String get poolAmenity => 'Pool';

  @override
  String get gardenAmenity => 'Garden';

  @override
  String get lifestyleQuiet => 'Quiet';

  @override
  String get lifestyleSocial => 'Social';

  @override
  String get lifestyleActive => 'Active';

  @override
  String get lifestyleReading => 'Reading';

  @override
  String get lifestyleMusic => 'Music';

  @override
  String get lifestyleMovies => 'Movies';

  @override
  String get lifestyleCooking => 'Cooking';

  @override
  String get lifestyleTravel => 'Travel';

  @override
  String get lifestyleTech => 'Tech';

  @override
  String get lifestyleArt => 'Art';

  @override
  String get lifestyleNature => 'Nature';

  @override
  String get lifestyleStudy => 'Study';

  @override
  String get langSpanish => 'Spanish';

  @override
  String get langEnglish => 'English';

  @override
  String get langPortuguese => 'Portuguese';

  @override
  String get langFrench => 'French';

  @override
  String get langGerman => 'German';

  @override
  String get langItalian => 'Italian';

  @override
  String get searchProfileCreatedTitle => 'Search profile created';

  @override
  String get searchProfileCreatedMessage => 'Your preferences have been saved.';

  @override
  String get continueButton => 'Continue';

  @override
  String get errorCreatingSearchProfile => 'Error creating search profile';

  @override
  String errorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get selectLocationError => 'Select a location on the map';

  @override
  String get selectPropertyTypeError => 'Select at least one property type';

  @override
  String get createSearchProfileTitle => 'Create search profile';

  @override
  String get skipButton => 'Skip';

  @override
  String get locationStep => 'Location';

  @override
  String get propertyStep => 'Property';

  @override
  String get cohabitationStep => 'Cohabitation';

  @override
  String get lifestyleStep => 'Lifestyle';

  @override
  String get step1Title => 'Location and budget';

  @override
  String get budgetRangeLabel => 'Budget range';

  @override
  String get dragToAdjustLabel => 'Drag to adjust';

  @override
  String get step2Title => 'Property type';

  @override
  String minLabel(Object value) {
    return 'Min: $value';
  }

  @override
  String maxLabel(Object value) {
    return 'Max: $value';
  }

  @override
  String get remoteWorkSpaceLabel => 'Remote workspace';

  @override
  String get petAllowedLabel => 'Pets allowed';

  @override
  String get step3Title => 'Cohabitation preferences';

  @override
  String get roommatePreferenceLabel => 'Roommate preference';

  @override
  String get noRoommateOption => 'No roommate';

  @override
  String get openRoommateOption => 'Open to roommate';

  @override
  String get yesRoommateOption => 'Want roommate';

  @override
  String get familySizeLabel => 'Family size';

  @override
  String get childrenCountLabel => 'Number of children';

  @override
  String get step4Title => 'Lifestyle';

  @override
  String get lifestyleLabel => 'Lifestyle';

  @override
  String selectTagsLabel(Object count) {
    return 'Select tags ($count)';
  }

  @override
  String get smokerLabel => 'Smoker';

  @override
  String get languagesLabel => 'Languages';

  @override
  String paymentMethodsLoadError(String error) {
    return 'Error loading payment methods: $error';
  }

  @override
  String get enterPaymentMethodNameError => 'Enter the payment method name';

  @override
  String get paymentMethodCreatedSuccess => 'Payment method created';

  @override
  String paymentMethodCreateError(String error) {
    return 'Error creating payment method: $error';
  }

  @override
  String get createPaymentMethodTitle => 'Create payment method';

  @override
  String get paymentMethodNameLabel => 'Payment method name';

  @override
  String get paymentMethodNameHint => 'Ex. Bank transfer';

  @override
  String get createButton => 'Create';

  @override
  String get paymentMethodsTitle => 'Payment Methods';

  @override
  String get noPaymentMethods => 'No payment methods';

  @override
  String get createFirstPaymentMethodHint => 'Create your first payment method';

  @override
  String idLabel(Object id) {
    return 'ID: $id';
  }

  @override
  String get editFeatureComingSoon => 'Edit coming soon';

  @override
  String get deleteFeatureComingSoon => 'Delete coming soon';

  @override
  String get editButton => 'Edit';

  @override
  String imageSelectionError(String error) {
    return 'Error selecting image: $error';
  }

  @override
  String get profileUpdatedSuccess => 'Profile updated';

  @override
  String profileUpdateError(String error) {
    return 'Error updating profile: $error';
  }

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get emailLabel => 'Email';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get changePasswordLabel => 'Change password';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get cancelButtonCaps => 'Cancel';

  @override
  String profileLoadError(String error) {
    return 'Error loading profile: $error';
  }

  @override
  String get logoutTitle => 'Log out';

  @override
  String get logoutConfirmation => 'Do you want to log out?';

  @override
  String logoutError(String error) {
    return 'Error logging out: $error';
  }

  @override
  String get profileInfoLoadError => 'Error loading profile info';

  @override
  String get clientsButton => 'Clients';

  @override
  String get salesButton => 'Sales';

  @override
  String get commissionsButton => 'Commissions';

  @override
  String get agendaButton => 'Agenda';

  @override
  String get myRentalsTitle => 'My rentals';

  @override
  String get assignedPropertiesTitle => 'Assigned properties';

  @override
  String get profileSettingsTitle => 'Profile settings';

  @override
  String get changeUserModeLabel => 'Change user mode';

  @override
  String get verifyProfileLabel => 'Verify profile';

  @override
  String get editProfileLabel => 'Edit profile';

  @override
  String get deleteAccountLabel => 'Delete account';

  @override
  String get profileVerificationTitle => 'Profile verification';

  @override
  String get profileVerificationMessage => 'Your profile has been verified.';

  @override
  String get understoodButton => 'Understood';

  @override
  String get deleteAccountConfirmation =>
      'Are you sure you want to delete your account?';

  @override
  String get accountDeletionScheduled => 'Account deletion scheduled';

  @override
  String get deleteAccountError => 'Error deleting account';

  @override
  String confirmModeChange(String name) {
    return 'Confirm change to $name';
  }

  @override
  String get acceptButton => 'Accept';

  @override
  String get updatingProfile => 'Updating profile...';

  @override
  String profileModeUpdated(String name) {
    return 'Profile mode updated to $name';
  }

  @override
  String get profileUpdateGenericError => 'Error updating profile';

  @override
  String get tenantModeDescription => 'Explore and rent properties.';

  @override
  String get landlordModeDescription => 'Publish and manage your properties.';

  @override
  String get agentModeDescription =>
      'Manage clients and properties as an agent.';

  @override
  String get noRegisteredProperties => 'You have no registered properties';

  @override
  String get propertyNoAddress => 'No address';

  @override
  String get availableStatus => 'Available';

  @override
  String get unavailableStatus => 'Unavailable';

  @override
  String get manageButton => 'Manage';

  @override
  String get noAssignedProperties => 'You have no assigned properties';

  @override
  String get viewReviewsButton => 'View reviews';

  @override
  String get incentivesButton => 'Incentives';

  @override
  String get userLabel => 'User';

  @override
  String get myRentalsTitleMixed => 'Your rentals';

  @override
  String get myPropertiesTitle => 'My properties';

  @override
  String get assignedPropertiesTitleMixed => 'Assigned';

  @override
  String get verifiedLabel => 'Verified';

  @override
  String get loadPropertiesError => 'Error loading properties';

  @override
  String connectionError(String error) {
    return 'Connection error: $error';
  }

  @override
  String get noPropertiesRegistered => 'You have no registered properties';

  @override
  String get addFirstProperty => 'Add your first property';

  @override
  String get addPropertyButton => 'Add property';

  @override
  String get activeStatus => 'Active';

  @override
  String get inactiveStatus => 'Inactive';

  @override
  String get loadPhotosErrorGeneric => 'Error loading photos';

  @override
  String get invalidPropertyIdError => 'Invalid property ID';

  @override
  String get invalidPropertyIdErrorDetail =>
      'Could not validate the property ID';

  @override
  String takePhotoError(String error) {
    return 'Error taking photo: $error';
  }

  @override
  String get uploadPhotoErrorGeneric => 'Error uploading photo';

  @override
  String photosUploadedCount(Object count) {
    return 'Photos uploaded: $count';
  }

  @override
  String pickImagesError(String error) {
    return 'Error selecting images: $error';
  }

  @override
  String get photoUploadedSuccess => 'Photo uploaded successfully';

  @override
  String get deletePhotoErrorGeneric => 'Error deleting photo';

  @override
  String photosOfProperty(String address) {
    return 'Photos of $address';
  }

  @override
  String get uploadingStatus => 'Uploading...';

  @override
  String get selectMultiplePhotos => 'Select multiple photos';

  @override
  String get moreOptionsTitle => 'More options';

  @override
  String get favoritePropertiesOption => 'Favorite properties';

  @override
  String get favoritePropertiesSubtitle => 'Access your favorites list';

  @override
  String get searchHistoryOption => 'Search history';

  @override
  String get searchHistorySubtitle => 'View your recent searches';

  @override
  String get notificationsOption => 'Notifications';

  @override
  String get notificationsSubtitle => 'Recent updates and alerts';

  @override
  String get helpSupportOption => 'Help & support';

  @override
  String get helpSupportSubtitle => 'Find assistance and FAQs';

  @override
  String get settingsOption => 'Settings';

  @override
  String get settingsSubtitle => 'App preferences';

  @override
  String get propertyLabel => 'Property';

  @override
  String pricePerMonth(String price) {
    return 'Bs. $price/month';
  }

  @override
  String get fetchProfileError => 'Error fetching profile';

  @override
  String get loadFavoritesError => 'Error loading favorites';

  @override
  String get removeFavoriteError => 'Error removing from favorites';

  @override
  String get yourLikesTitle => 'Your likes';

  @override
  String get yourLikesSubtitle => 'Properties you like';

  @override
  String get noLikesYet => 'You have no favorites yet';

  @override
  String get explorePropertiesHint => 'Explore properties and add likes';

  @override
  String removedFromFavorites(String type, String address) {
    return 'Removed from favorites: $type · $address';
  }

  @override
  String get defaultUser => 'User';

  @override
  String get processingProfile => 'Processing profile...';

  @override
  String get searchProfileCreatedSuccess => 'Search profile created';

  @override
  String get propertiesLoadError => 'Error loading properties';

  @override
  String get noMatchesTitle => 'No matches found';

  @override
  String get refreshButton => 'Refresh';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get searchConversationsPlaceholder => 'Search conversations...';

  @override
  String get matchRequestsTitle => 'Match Requests';

  @override
  String get matchRequestsAction => 'Review match requests';

  @override
  String get noMatchRequests => 'No pending match requests';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsLoadError => 'Error loading notifications';

  @override
  String get notificationMarkedRead => 'Notification marked as read';

  @override
  String get notificationDefaultTitle => 'Notification';

  @override
  String get markAsReadButton => 'Mark as read';

  @override
  String get noNotifications => 'No notifications';

  @override
  String userDefaultName(Object id) {
    return 'User $id';
  }

  @override
  String hoursAgo(Object count) {
    return '${count}h ago';
  }

  @override
  String minutesAgo(Object count) {
    return '${count}m ago';
  }

  @override
  String get nowLabel => 'Just now';

  @override
  String get selectUserTitle => 'Select a user';

  @override
  String get searchUsersPlaceholder => 'Search users...';

  @override
  String get noUsersAvailable => 'No users available';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get tryRefreshList => 'Try refreshing the list';

  @override
  String get tryAnotherSearch => 'Try another search';

  @override
  String get errorGetCurrentUser => 'Unable to get current user';

  @override
  String get wsRouteNotFound => 'WebSocket route not found';

  @override
  String wsError(String error) {
    return 'WebSocket error: $error';
  }

  @override
  String get wsConnectionClosed => 'WebSocket connection closed';

  @override
  String get chatExampleMessage1 => 'Hello! How can I help you?';

  @override
  String get chatExampleMessage2 => 'Hi! I\'m interested in your property.';

  @override
  String get chatExampleMessage3 => 'Great! Do you have any questions?';

  @override
  String get chatExampleMessage4 => 'Yes, what\'s the neighborhood like?';

  @override
  String get chatExampleMessage5 => 'It\'s quiet and close to shops.';

  @override
  String get chatExampleMessage6 => 'Perfect, thanks!';

  @override
  String get sendingMessage => 'Sending...';

  @override
  String get errorSendingMessage => 'Error sending';

  @override
  String get wsConnectionUnavailable => 'WebSocket not available';

  @override
  String get serverNoConfirmation => 'Server did not confirm';

  @override
  String get clearChatTitle => 'Clear conversation';

  @override
  String get todayLabel => 'Today';

  @override
  String matchedWithUser(String name) {
    return 'Matched with $name';
  }

  @override
  String get typingPlaceholder => 'Type a message...';

  @override
  String get clearChatConfirmation => 'This will remove all messages';

  @override
  String get clearButton => 'Clear';

  @override
  String get chatClearedLocally => 'Chat cleared locally';

  @override
  String get chatClearedForAccount => 'Chat cleared for this account';

  @override
  String get untitledProperty => 'Untitled property';

  @override
  String get unspecifiedAddress => 'Unspecified address';

  @override
  String acceptError(String error) {
    return 'Accept error: $error';
  }

  @override
  String get matchRequestAccepted => 'Match request accepted';

  @override
  String get matchRequestRejected => 'Match request rejected';

  @override
  String get rejectButton => 'Reject';

  @override
  String get verifyingProfile => 'Verifying profile...';

  @override
  String socialLoginError(String provider) {
    return 'Social login error: $provider';
  }

  @override
  String get loginWithEmailButton => 'Login with email';

  @override
  String get loginWithGoogleButton => 'Continue with Google';

  @override
  String get loginWithAppleButton => 'Continue with Apple';

  @override
  String get loginWithFacebookButton => 'Continue with Facebook';

  @override
  String get tagline => 'Find, connect and rent — all in one place';

  @override
  String get takePhotoButton => 'Take photo';

  @override
  String get galleryButton => 'Choose from gallery';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get createSearchProfileDescription =>
      'We will use your preferences to personalize results.';

  @override
  String get registrationSuccess => 'Registration successful';

  @override
  String get registrationSuccessLogin =>
      'Registered successfully. Please log in.';

  @override
  String get registrationError => 'Registration failed';

  @override
  String get backButton => 'Back';

  @override
  String get yourNameTitle => 'Your name';

  @override
  String get firstNamePlaceholder => 'First name';

  @override
  String get lastNamePlaceholder => 'Last name';

  @override
  String get contactTitle => 'Contact';

  @override
  String get emailPlaceholder => 'Email';

  @override
  String get enterEmailError => 'Enter your email';

  @override
  String get enterValidEmailError => 'Enter a valid email';

  @override
  String get phonePlaceholder => 'Phone';

  @override
  String get enterPhoneError => 'Enter your phone number';

  @override
  String get accountTitle => 'Account';

  @override
  String get usernamePlaceholder => 'Username';

  @override
  String get enterUsernameError => 'Enter your username';

  @override
  String get passwordPlaceholder => 'Password';

  @override
  String get enterPasswordError => 'Enter your password';

  @override
  String get passwordLengthError => 'Password must be at least 6 characters';

  @override
  String get confirmPasswordPlaceholder => 'Confirm password';

  @override
  String get confirmPasswordError => 'Confirm your password';

  @override
  String get authErrorDefault => 'Authentication error';

  @override
  String get forgotPasswordButton => 'Forgot your password?';

  @override
  String get noAccountLabel => 'Don’t have an account?';

  @override
  String get registerLink => 'Register';

  @override
  String get welcomeToHabitto => 'Welcome to Habitto';

  @override
  String get emailOrUsernamePlaceholder => 'Email or Username';

  @override
  String get enterEmailOrUsernameError => 'Enter your email or username';

  @override
  String get createWithAIButton => 'Create with AI';

  @override
  String get portfolioTitle => 'Agent Portfolio';

  @override
  String get loadPortfolioError => 'Error loading portfolio';

  @override
  String portfolioItemSubtitle(String price, String size) {
    return 'Bs. $price • $size m²';
  }

  @override
  String get requestsTitle => 'Requests';

  @override
  String get loadLeadsError => 'Error loading leads';

  @override
  String get noNewRequests => 'No new requests';

  @override
  String get newRequestsPlaceholder => 'Check back later for new leads';

  @override
  String scoreLabel(String score) {
    return 'Score: $score%';
  }

  @override
  String get alertHistoryTitle => 'Alert History';

  @override
  String get alertHistoryComingSoon => 'Alert history coming soon';
}
