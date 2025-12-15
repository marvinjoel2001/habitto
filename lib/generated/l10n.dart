import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_en.dart';
import 'l10n_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Habitto'**
  String get appTitle;

  /// No description provided for @loginButton.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get registerButton;

  /// No description provided for @welcomeMessage.
  ///
  /// In es, this message translates to:
  /// **'¡Hola {name}!'**
  String welcomeMessage(String name);

  /// No description provided for @uploadMultipleHint.
  ///
  /// In es, this message translates to:
  /// **'Puedes subir varias fotos a la vez'**
  String get uploadMultipleHint;

  /// No description provided for @noPhotosYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay fotos'**
  String get noPhotosYet;

  /// No description provided for @addPhotosHint.
  ///
  /// In es, this message translates to:
  /// **'Agrega fotos de tu propiedad'**
  String get addPhotosHint;

  /// No description provided for @propertyNotFound.
  ///
  /// In es, this message translates to:
  /// **'Propiedad no encontrada'**
  String get propertyNotFound;

  /// No description provided for @propertyTitleFallback.
  ///
  /// In es, this message translates to:
  /// **'Sin título'**
  String get propertyTitleFallback;

  /// No description provided for @rentPerMonth.
  ///
  /// In es, this message translates to:
  /// **'Bs. {price}/mes'**
  String rentPerMonth(String price);

  /// No description provided for @bedroomsShort.
  ///
  /// In es, this message translates to:
  /// **'{count} hab.'**
  String bedroomsShort(String count);

  /// No description provided for @bathroomsShort.
  ///
  /// In es, this message translates to:
  /// **'{count} baños'**
  String bathroomsShort(String count);

  /// No description provided for @sizeShort.
  ///
  /// In es, this message translates to:
  /// **'{size} m²'**
  String sizeShort(String size);

  /// No description provided for @amenitiesLabel.
  ///
  /// In es, this message translates to:
  /// **'Comodidades'**
  String get amenitiesLabel;

  /// No description provided for @swipeForMatchButton.
  ///
  /// In es, this message translates to:
  /// **'Desliza para Match'**
  String get swipeForMatchButton;

  /// No description provided for @requestRoomieButton.
  ///
  /// In es, this message translates to:
  /// **'Solicitar Roomie'**
  String get requestRoomieButton;

  /// No description provided for @scheduleViewButton.
  ///
  /// In es, this message translates to:
  /// **'Agendar Visita'**
  String get scheduleViewButton;

  /// No description provided for @reviewsLabel.
  ///
  /// In es, this message translates to:
  /// **'Reseñas'**
  String get reviewsLabel;

  /// No description provided for @mockReviewer1.
  ///
  /// In es, this message translates to:
  /// **'Ana García'**
  String get mockReviewer1;

  /// No description provided for @mockReview1.
  ///
  /// In es, this message translates to:
  /// **'Excelente lugar, muy iluminado y seguro.'**
  String get mockReview1;

  /// No description provided for @mockReviewer2.
  ///
  /// In es, this message translates to:
  /// **'Carlos Ruiz'**
  String get mockReviewer2;

  /// No description provided for @mockReview2.
  ///
  /// In es, this message translates to:
  /// **'El propietario es muy amable, recomendado.'**
  String get mockReview2;

  /// No description provided for @amenityDefaultLabel.
  ///
  /// In es, this message translates to:
  /// **'Comodidad'**
  String get amenityDefaultLabel;

  /// No description provided for @propertyTypeHouse.
  ///
  /// In es, this message translates to:
  /// **'Casa'**
  String get propertyTypeHouse;

  /// No description provided for @propertyTypeApartment.
  ///
  /// In es, this message translates to:
  /// **'Departamento'**
  String get propertyTypeApartment;

  /// No description provided for @propertyTypeRoom.
  ///
  /// In es, this message translates to:
  /// **'Habitación'**
  String get propertyTypeRoom;

  /// No description provided for @propertyTypeAnticretico.
  ///
  /// In es, this message translates to:
  /// **'Anticrético'**
  String get propertyTypeAnticretico;

  /// No description provided for @amenityWifi.
  ///
  /// In es, this message translates to:
  /// **'WiFi'**
  String get amenityWifi;

  /// No description provided for @amenityParking.
  ///
  /// In es, this message translates to:
  /// **'Parqueo'**
  String get amenityParking;

  /// No description provided for @amenityLaundry.
  ///
  /// In es, this message translates to:
  /// **'Lavandería'**
  String get amenityLaundry;

  /// No description provided for @amenityGym.
  ///
  /// In es, this message translates to:
  /// **'Gimnasio'**
  String get amenityGym;

  /// No description provided for @amenityPool.
  ///
  /// In es, this message translates to:
  /// **'Piscina'**
  String get amenityPool;

  /// No description provided for @amenityGarden.
  ///
  /// In es, this message translates to:
  /// **'Jardín'**
  String get amenityGarden;

  /// No description provided for @loadDataError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar datos: {error}'**
  String loadDataError(String error);

  /// No description provided for @userFetchError.
  ///
  /// In es, this message translates to:
  /// **'Error al obtener usuario'**
  String get userFetchError;

  /// No description provided for @propertyCreatedTitle.
  ///
  /// In es, this message translates to:
  /// **'Propiedad Creada'**
  String get propertyCreatedTitle;

  /// No description provided for @propertyCreatedMessage.
  ///
  /// In es, this message translates to:
  /// **'La propiedad se ha creado exitosamente.'**
  String get propertyCreatedMessage;

  /// No description provided for @laterButton.
  ///
  /// In es, this message translates to:
  /// **'Más tarde'**
  String get laterButton;

  /// No description provided for @addPhotosButton.
  ///
  /// In es, this message translates to:
  /// **'Agregar fotos'**
  String get addPhotosButton;

  /// No description provided for @genericError.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String genericError(String error);

  /// No description provided for @enterAddressError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una dirección'**
  String get enterAddressError;

  /// No description provided for @enterPriceError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un precio'**
  String get enterPriceError;

  /// No description provided for @enterGuaranteeError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una garantía'**
  String get enterGuaranteeError;

  /// No description provided for @enterDescriptionError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una descripción'**
  String get enterDescriptionError;

  /// No description provided for @enterAreaError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el área'**
  String get enterAreaError;

  /// No description provided for @invalidPriceError.
  ///
  /// In es, this message translates to:
  /// **'Precio inválido'**
  String get invalidPriceError;

  /// No description provided for @invalidGuaranteeError.
  ///
  /// In es, this message translates to:
  /// **'Garantía inválida'**
  String get invalidGuaranteeError;

  /// No description provided for @invalidAreaError.
  ///
  /// In es, this message translates to:
  /// **'Área inválida'**
  String get invalidAreaError;

  /// No description provided for @propertyDetailsTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalles de la propiedad'**
  String get propertyDetailsTitle;

  /// No description provided for @saveAndExit.
  ///
  /// In es, this message translates to:
  /// **'Guardar y Salir'**
  String get saveAndExit;

  /// No description provided for @stepBasic.
  ///
  /// In es, this message translates to:
  /// **'Básico'**
  String get stepBasic;

  /// No description provided for @stepDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles'**
  String get stepDetails;

  /// No description provided for @stepLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get stepLocation;

  /// No description provided for @stepBasicDescription.
  ///
  /// In es, this message translates to:
  /// **'Información principal'**
  String get stepBasicDescription;

  /// No description provided for @bedroomsLabel.
  ///
  /// In es, this message translates to:
  /// **'Dormitorios'**
  String get bedroomsLabel;

  /// No description provided for @bathroomsLabel.
  ///
  /// In es, this message translates to:
  /// **'Baños'**
  String get bathroomsLabel;

  /// No description provided for @areaLabel.
  ///
  /// In es, this message translates to:
  /// **'Área (m²)'**
  String get areaLabel;

  /// No description provided for @stepDetailsDescription.
  ///
  /// In es, this message translates to:
  /// **'Características y precios'**
  String get stepDetailsDescription;

  /// No description provided for @rentPriceLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio de Alquiler'**
  String get rentPriceLabel;

  /// No description provided for @adjustPriceLabel.
  ///
  /// In es, this message translates to:
  /// **'Ajustar precio'**
  String get adjustPriceLabel;

  /// No description provided for @guaranteeLabel.
  ///
  /// In es, this message translates to:
  /// **'Garantía'**
  String get guaranteeLabel;

  /// No description provided for @adjustGuaranteeLabel.
  ///
  /// In es, this message translates to:
  /// **'Ajustar garantía'**
  String get adjustGuaranteeLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get descriptionLabel;

  /// No description provided for @propertyDescriptionHint.
  ///
  /// In es, this message translates to:
  /// **'Describe tu propiedad...'**
  String get propertyDescriptionHint;

  /// No description provided for @acceptedPaymentMethodsLabel.
  ///
  /// In es, this message translates to:
  /// **'Métodos de pago aceptados'**
  String get acceptedPaymentMethodsLabel;

  /// No description provided for @confirmLocation.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Ubicación'**
  String get confirmLocation;

  /// No description provided for @stepLocationDescription.
  ///
  /// In es, this message translates to:
  /// **'Ubicación exacta'**
  String get stepLocationDescription;

  /// No description provided for @addressLabel.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get addressLabel;

  /// No description provided for @addressHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Av. Principal #123'**
  String get addressHint;

  /// No description provided for @mapLocationLabel.
  ///
  /// In es, this message translates to:
  /// **'Ubicación en el mapa'**
  String get mapLocationLabel;

  /// No description provided for @tapToSelectLocation.
  ///
  /// In es, this message translates to:
  /// **'Toca para seleccionar ubicación'**
  String get tapToSelectLocation;

  /// No description provided for @availabilityDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de disponibilidad'**
  String get availabilityDateLabel;

  /// No description provided for @dateHint.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar fecha'**
  String get dateHint;

  /// No description provided for @propertyTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de Propiedad'**
  String get propertyTypeLabel;

  /// No description provided for @previousButton.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get previousButton;

  /// No description provided for @finishButton.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get finishButton;

  /// No description provided for @nextButton.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get nextButton;

  /// No description provided for @loadPhotosError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar fotos: {error}'**
  String loadPhotosError(String error);

  /// No description provided for @pickImageError.
  ///
  /// In es, this message translates to:
  /// **'Error al seleccionar imagen: {error}'**
  String pickImageError(String error);

  /// No description provided for @uploadSummary.
  ///
  /// In es, this message translates to:
  /// **'{success} subidas, {fail} fallidas'**
  String uploadSummary(Object success, Object fail);

  /// No description provided for @photosUploadedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Fotos subidas correctamente'**
  String get photosUploadedSuccess;

  /// No description provided for @deletePhotoTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar foto'**
  String get deletePhotoTitle;

  /// No description provided for @deletePhotoConfirmation.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de eliminar esta foto?'**
  String get deletePhotoConfirmation;

  /// No description provided for @cancelButton.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get deleteButton;

  /// No description provided for @photoDeletedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Foto eliminada'**
  String get photoDeletedSuccess;

  /// No description provided for @propertyUpdatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Propiedad actualizada'**
  String get propertyUpdatedSuccess;

  /// No description provided for @updatePropertyError.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar: {error}'**
  String updatePropertyError(String error);

  /// No description provided for @editPropertyTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar Propiedad'**
  String get editPropertyTitle;

  /// No description provided for @priceLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get priceLabel;

  /// No description provided for @bedroomsShortLabel.
  ///
  /// In es, this message translates to:
  /// **'Hab.'**
  String get bedroomsShortLabel;

  /// No description provided for @matchLabel.
  ///
  /// In es, this message translates to:
  /// **'Match'**
  String get matchLabel;

  /// No description provided for @uploadPhotosButton.
  ///
  /// In es, this message translates to:
  /// **'Subir Fotos'**
  String get uploadPhotosButton;

  /// No description provided for @noInterestsYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay interesados'**
  String get noInterestsYet;

  /// No description provided for @matchScore.
  ///
  /// In es, this message translates to:
  /// **'Match: {score}%'**
  String matchScore(String score);

  /// No description provided for @matchAcceptedMessage.
  ///
  /// In es, this message translates to:
  /// **'Match aceptado'**
  String get matchAcceptedMessage;

  /// No description provided for @priceBsLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio (Bs)'**
  String get priceBsLabel;

  /// No description provided for @guaranteeBsLabel.
  ///
  /// In es, this message translates to:
  /// **'Garantía (Bs)'**
  String get guaranteeBsLabel;

  /// No description provided for @sizeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tamaño (m²)'**
  String get sizeLabel;

  /// No description provided for @saveChangesButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar Cambios'**
  String get saveChangesButton;

  /// No description provided for @requiredField.
  ///
  /// In es, this message translates to:
  /// **'Campo requerido'**
  String get requiredField;

  /// No description provided for @uploadPhotosTitle.
  ///
  /// In es, this message translates to:
  /// **'Subir Fotos'**
  String get uploadPhotosTitle;

  /// No description provided for @cameraOption.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get cameraOption;

  /// No description provided for @galleryOption.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get galleryOption;

  /// No description provided for @socialAreasTitle.
  ///
  /// In es, this message translates to:
  /// **'Áreas Sociales'**
  String get socialAreasTitle;

  /// No description provided for @socialAreasComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente: Áreas Sociales'**
  String get socialAreasComingSoon;

  /// No description provided for @onboardingTitle1.
  ///
  /// In es, this message translates to:
  /// **'Encuentra tu hogar ideal'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In es, this message translates to:
  /// **'Explora miles de opciones...'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In es, this message translates to:
  /// **'Conecta con propietarios'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In es, this message translates to:
  /// **'Chat directo y seguro...'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In es, this message translates to:
  /// **'Gestiona tus propiedades'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In es, this message translates to:
  /// **'Publica y administra...'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In es, this message translates to:
  /// **'Todo en un solo lugar'**
  String get onboardingTitle4;

  /// No description provided for @onboardingSubtitle4.
  ///
  /// In es, this message translates to:
  /// **'La mejor experiencia inmobiliaria'**
  String get onboardingSubtitle4;

  /// No description provided for @actionUndo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get actionUndo;

  /// No description provided for @actionReject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get actionReject;

  /// No description provided for @actionLike.
  ///
  /// In es, this message translates to:
  /// **'Me gusta'**
  String get actionLike;

  /// No description provided for @actionFavorite.
  ///
  /// In es, this message translates to:
  /// **'Favorito'**
  String get actionFavorite;

  /// No description provided for @closeButton.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get closeButton;

  /// No description provided for @matchTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Es un Match!'**
  String get matchTitle;

  /// No description provided for @matchPrefix.
  ///
  /// In es, this message translates to:
  /// **'Te gusta '**
  String get matchPrefix;

  /// No description provided for @matchWord.
  ///
  /// In es, this message translates to:
  /// **'esta propiedad'**
  String get matchWord;

  /// No description provided for @matchSuffix.
  ///
  /// In es, this message translates to:
  /// **'!'**
  String get matchSuffix;

  /// No description provided for @matchWith.
  ///
  /// In es, this message translates to:
  /// **'con'**
  String get matchWith;

  /// No description provided for @thisProperty.
  ///
  /// In es, this message translates to:
  /// **'esta propiedad'**
  String get thisProperty;

  /// No description provided for @matchSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ahora pueden chatear...'**
  String get matchSubtitle;

  /// No description provided for @sendMessageButton.
  ///
  /// In es, this message translates to:
  /// **'Enviar Mensaje'**
  String get sendMessageButton;

  /// No description provided for @searchApartmentSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Busco departamento en...'**
  String get searchApartmentSuggestion;

  /// No description provided for @searchRoomieSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Busco roomie...'**
  String get searchRoomieSuggestion;

  /// No description provided for @createProfileSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Crear perfil...'**
  String get createProfileSuggestion;

  /// No description provided for @aiAssistantGreeting.
  ///
  /// In es, this message translates to:
  /// **'¡Hola {name}! Soy tu asistente...'**
  String aiAssistantGreeting(String name);

  /// No description provided for @micPermissionRequired.
  ///
  /// In es, this message translates to:
  /// **'Se requiere permiso de micrófono'**
  String get micPermissionRequired;

  /// No description provided for @micPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Permiso de micrófono'**
  String get micPermissionTitle;

  /// No description provided for @micPermissionContent.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos acceso al micrófono...'**
  String get micPermissionContent;

  /// No description provided for @openSettingsButton.
  ///
  /// In es, this message translates to:
  /// **'Abrir Configuración'**
  String get openSettingsButton;

  /// No description provided for @profileCreatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Perfil creado exitosamente'**
  String get profileCreatedSuccess;

  /// No description provided for @aiProcessingError.
  ///
  /// In es, this message translates to:
  /// **'Error al procesar...'**
  String get aiProcessingError;

  /// No description provided for @aiTypingIndicator.
  ///
  /// In es, this message translates to:
  /// **'Escribiendo...'**
  String get aiTypingIndicator;

  /// No description provided for @listeningIndicator.
  ///
  /// In es, this message translates to:
  /// **'Escuchando...'**
  String get listeningIndicator;

  /// No description provided for @aiChatPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get aiChatPlaceholder;

  /// No description provided for @navExplore.
  ///
  /// In es, this message translates to:
  /// **'Explorar'**
  String get navExplore;

  /// No description provided for @navCandidates.
  ///
  /// In es, this message translates to:
  /// **'Candidatos'**
  String get navCandidates;

  /// No description provided for @navLeads.
  ///
  /// In es, this message translates to:
  /// **'Prospectos'**
  String get navLeads;

  /// No description provided for @navMap.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get navMap;

  /// No description provided for @navProperties.
  ///
  /// In es, this message translates to:
  /// **'Propiedades'**
  String get navProperties;

  /// No description provided for @navPortfolio.
  ///
  /// In es, this message translates to:
  /// **'Portafolio'**
  String get navPortfolio;

  /// No description provided for @navInbox.
  ///
  /// In es, this message translates to:
  /// **'Buzón'**
  String get navInbox;

  /// No description provided for @navChat.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navProfProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil Pro'**
  String get navProfProfile;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @closeMenu.
  ///
  /// In es, this message translates to:
  /// **'Cerrar menú'**
  String get closeMenu;

  /// No description provided for @openMenu.
  ///
  /// In es, this message translates to:
  /// **'Abrir menú'**
  String get openMenu;

  /// No description provided for @navItemActive.
  ///
  /// In es, this message translates to:
  /// **'{label} activo'**
  String navItemActive(String label);

  /// No description provided for @noImagePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Sin imagen'**
  String get noImagePlaceholder;

  /// No description provided for @menuMatchs.
  ///
  /// In es, this message translates to:
  /// **'Matches'**
  String get menuMatchs;

  /// No description provided for @menuAddProperty.
  ///
  /// In es, this message translates to:
  /// **'Agregar Propiedad'**
  String get menuAddProperty;

  /// No description provided for @tenantRole.
  ///
  /// In es, this message translates to:
  /// **'Inquilino'**
  String get tenantRole;

  /// No description provided for @landlordRole.
  ///
  /// In es, this message translates to:
  /// **'Propietario'**
  String get landlordRole;

  /// No description provided for @agentRole.
  ///
  /// In es, this message translates to:
  /// **'Agente'**
  String get agentRole;

  /// No description provided for @likeSent.
  ///
  /// In es, this message translates to:
  /// **'¡Like enviado! El propietario será notificado.'**
  String get likeSent;

  /// No description provided for @likeError.
  ///
  /// In es, this message translates to:
  /// **'Error al dar like'**
  String get likeError;

  /// No description provided for @rejectError.
  ///
  /// In es, this message translates to:
  /// **'Error al rechazar: {error}'**
  String rejectError(String error);

  /// No description provided for @noMoreProperties.
  ///
  /// In es, this message translates to:
  /// **'No hay más propiedades'**
  String get noMoreProperties;

  /// No description provided for @noImageLabel.
  ///
  /// In es, this message translates to:
  /// **'Sin imagen'**
  String get noImageLabel;

  /// No description provided for @retryButton.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retryButton;

  /// No description provided for @noPendingMatchRequests.
  ///
  /// In es, this message translates to:
  /// **'No tienes solicitudes de match pendientes'**
  String get noPendingMatchRequests;

  /// No description provided for @newMatchRequestsWillAppearHere.
  ///
  /// In es, this message translates to:
  /// **'Las nuevas solicitudes aparecerán aquí'**
  String get newMatchRequestsWillAppearHere;

  /// No description provided for @searchPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar por zona, precio, tipo...'**
  String get searchPlaceholder;

  /// No description provided for @filterZone.
  ///
  /// In es, this message translates to:
  /// **'Zona'**
  String get filterZone;

  /// No description provided for @filterPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get filterPrice;

  /// No description provided for @filterType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get filterType;

  /// No description provided for @filterAmenities.
  ///
  /// In es, this message translates to:
  /// **'Comodidades'**
  String get filterAmenities;

  /// No description provided for @viewMoreDetails.
  ///
  /// In es, this message translates to:
  /// **'Ver más detalles'**
  String get viewMoreDetails;

  /// No description provided for @houseType.
  ///
  /// In es, this message translates to:
  /// **'Casa'**
  String get houseType;

  /// No description provided for @apartmentType.
  ///
  /// In es, this message translates to:
  /// **'Departamento'**
  String get apartmentType;

  /// No description provided for @roomType.
  ///
  /// In es, this message translates to:
  /// **'Habitación'**
  String get roomType;

  /// No description provided for @wifiAmenity.
  ///
  /// In es, this message translates to:
  /// **'WiFi'**
  String get wifiAmenity;

  /// No description provided for @parkingAmenity.
  ///
  /// In es, this message translates to:
  /// **'Parqueo'**
  String get parkingAmenity;

  /// No description provided for @laundryAmenity.
  ///
  /// In es, this message translates to:
  /// **'Lavandería'**
  String get laundryAmenity;

  /// No description provided for @gymAmenity.
  ///
  /// In es, this message translates to:
  /// **'Gimnasio'**
  String get gymAmenity;

  /// No description provided for @poolAmenity.
  ///
  /// In es, this message translates to:
  /// **'Piscina'**
  String get poolAmenity;

  /// No description provided for @gardenAmenity.
  ///
  /// In es, this message translates to:
  /// **'Jardín'**
  String get gardenAmenity;

  /// No description provided for @lifestyleQuiet.
  ///
  /// In es, this message translates to:
  /// **'Tranquilo'**
  String get lifestyleQuiet;

  /// No description provided for @lifestyleSocial.
  ///
  /// In es, this message translates to:
  /// **'Social'**
  String get lifestyleSocial;

  /// No description provided for @lifestyleActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get lifestyleActive;

  /// No description provided for @lifestyleReading.
  ///
  /// In es, this message translates to:
  /// **'Lectura'**
  String get lifestyleReading;

  /// No description provided for @lifestyleMusic.
  ///
  /// In es, this message translates to:
  /// **'Música'**
  String get lifestyleMusic;

  /// No description provided for @lifestyleMovies.
  ///
  /// In es, this message translates to:
  /// **'Cine'**
  String get lifestyleMovies;

  /// No description provided for @lifestyleCooking.
  ///
  /// In es, this message translates to:
  /// **'Cocina'**
  String get lifestyleCooking;

  /// No description provided for @lifestyleTravel.
  ///
  /// In es, this message translates to:
  /// **'Viajes'**
  String get lifestyleTravel;

  /// No description provided for @lifestyleTech.
  ///
  /// In es, this message translates to:
  /// **'Tecnología'**
  String get lifestyleTech;

  /// No description provided for @lifestyleArt.
  ///
  /// In es, this message translates to:
  /// **'Arte'**
  String get lifestyleArt;

  /// No description provided for @lifestyleNature.
  ///
  /// In es, this message translates to:
  /// **'Naturaleza'**
  String get lifestyleNature;

  /// No description provided for @lifestyleStudy.
  ///
  /// In es, this message translates to:
  /// **'Estudio'**
  String get lifestyleStudy;

  /// No description provided for @langSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get langSpanish;

  /// No description provided for @langEnglish.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get langEnglish;

  /// No description provided for @langPortuguese.
  ///
  /// In es, this message translates to:
  /// **'Portugués'**
  String get langPortuguese;

  /// No description provided for @langFrench.
  ///
  /// In es, this message translates to:
  /// **'Francés'**
  String get langFrench;

  /// No description provided for @langGerman.
  ///
  /// In es, this message translates to:
  /// **'Alemán'**
  String get langGerman;

  /// No description provided for @langItalian.
  ///
  /// In es, this message translates to:
  /// **'Italiano'**
  String get langItalian;

  /// No description provided for @searchProfileCreatedTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil de búsqueda creado'**
  String get searchProfileCreatedTitle;

  /// No description provided for @searchProfileCreatedMessage.
  ///
  /// In es, this message translates to:
  /// **'Hemos guardado tus preferencias.'**
  String get searchProfileCreatedMessage;

  /// No description provided for @continueButton.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueButton;

  /// No description provided for @errorCreatingSearchProfile.
  ///
  /// In es, this message translates to:
  /// **'Error al crear el perfil de búsqueda'**
  String get errorCreatingSearchProfile;

  /// No description provided for @errorMessage.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String errorMessage(String error);

  /// No description provided for @selectLocationError.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una ubicación en el mapa'**
  String get selectLocationError;

  /// No description provided for @selectPropertyTypeError.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos un tipo de propiedad'**
  String get selectPropertyTypeError;

  /// No description provided for @createSearchProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear perfil de búsqueda'**
  String get createSearchProfileTitle;

  /// No description provided for @skipButton.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get skipButton;

  /// No description provided for @locationStep.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get locationStep;

  /// No description provided for @propertyStep.
  ///
  /// In es, this message translates to:
  /// **'Propiedad'**
  String get propertyStep;

  /// No description provided for @cohabitationStep.
  ///
  /// In es, this message translates to:
  /// **'Convivencia'**
  String get cohabitationStep;

  /// No description provided for @lifestyleStep.
  ///
  /// In es, this message translates to:
  /// **'Estilo de vida'**
  String get lifestyleStep;

  /// No description provided for @step1Title.
  ///
  /// In es, this message translates to:
  /// **'Ubicación y presupuesto'**
  String get step1Title;

  /// No description provided for @budgetRangeLabel.
  ///
  /// In es, this message translates to:
  /// **'Rango de presupuesto'**
  String get budgetRangeLabel;

  /// No description provided for @dragToAdjustLabel.
  ///
  /// In es, this message translates to:
  /// **'Arrastra para ajustar'**
  String get dragToAdjustLabel;

  /// No description provided for @step2Title.
  ///
  /// In es, this message translates to:
  /// **'Tipo de propiedad'**
  String get step2Title;

  /// No description provided for @minLabel.
  ///
  /// In es, this message translates to:
  /// **'Min: {value}'**
  String minLabel(Object value);

  /// No description provided for @maxLabel.
  ///
  /// In es, this message translates to:
  /// **'Max: {value}'**
  String maxLabel(Object value);

  /// No description provided for @remoteWorkSpaceLabel.
  ///
  /// In es, this message translates to:
  /// **'Espacio para trabajo remoto'**
  String get remoteWorkSpaceLabel;

  /// No description provided for @petAllowedLabel.
  ///
  /// In es, this message translates to:
  /// **'Se permiten mascotas'**
  String get petAllowedLabel;

  /// No description provided for @step3Title.
  ///
  /// In es, this message translates to:
  /// **'Preferencias de convivencia'**
  String get step3Title;

  /// No description provided for @roommatePreferenceLabel.
  ///
  /// In es, this message translates to:
  /// **'Preferencia de roomie'**
  String get roommatePreferenceLabel;

  /// No description provided for @noRoommateOption.
  ///
  /// In es, this message translates to:
  /// **'Sin roomie'**
  String get noRoommateOption;

  /// No description provided for @openRoommateOption.
  ///
  /// In es, this message translates to:
  /// **'Abierto a roomie'**
  String get openRoommateOption;

  /// No description provided for @yesRoommateOption.
  ///
  /// In es, this message translates to:
  /// **'Deseo roomie'**
  String get yesRoommateOption;

  /// No description provided for @familySizeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tamaño de familia'**
  String get familySizeLabel;

  /// No description provided for @childrenCountLabel.
  ///
  /// In es, this message translates to:
  /// **'Número de hijos'**
  String get childrenCountLabel;

  /// No description provided for @step4Title.
  ///
  /// In es, this message translates to:
  /// **'Estilo de vida'**
  String get step4Title;

  /// No description provided for @lifestyleLabel.
  ///
  /// In es, this message translates to:
  /// **'Estilo de vida'**
  String get lifestyleLabel;

  /// No description provided for @selectTagsLabel.
  ///
  /// In es, this message translates to:
  /// **'Selecciona etiquetas ({count})'**
  String selectTagsLabel(Object count);

  /// No description provided for @smokerLabel.
  ///
  /// In es, this message translates to:
  /// **'Fumador'**
  String get smokerLabel;

  /// No description provided for @languagesLabel.
  ///
  /// In es, this message translates to:
  /// **'Idiomas'**
  String get languagesLabel;

  /// No description provided for @paymentMethodsLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar métodos de pago: {error}'**
  String paymentMethodsLoadError(String error);

  /// No description provided for @enterPaymentMethodNameError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el nombre del método de pago'**
  String get enterPaymentMethodNameError;

  /// No description provided for @paymentMethodCreatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Método de pago creado'**
  String get paymentMethodCreatedSuccess;

  /// No description provided for @paymentMethodCreateError.
  ///
  /// In es, this message translates to:
  /// **'Error al crear método de pago: {error}'**
  String paymentMethodCreateError(String error);

  /// No description provided for @createPaymentMethodTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear método de pago'**
  String get createPaymentMethodTitle;

  /// No description provided for @paymentMethodNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del método de pago'**
  String get paymentMethodNameLabel;

  /// No description provided for @paymentMethodNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Transferencia bancaria'**
  String get paymentMethodNameHint;

  /// No description provided for @createButton.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get createButton;

  /// No description provided for @paymentMethodsTitle.
  ///
  /// In es, this message translates to:
  /// **'Métodos de pago'**
  String get paymentMethodsTitle;

  /// No description provided for @noPaymentMethods.
  ///
  /// In es, this message translates to:
  /// **'No hay métodos de pago'**
  String get noPaymentMethods;

  /// No description provided for @createFirstPaymentMethodHint.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primer método de pago'**
  String get createFirstPaymentMethodHint;

  /// No description provided for @idLabel.
  ///
  /// In es, this message translates to:
  /// **'ID: {id}'**
  String idLabel(Object id);

  /// No description provided for @editFeatureComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Edición disponible próximamente'**
  String get editFeatureComingSoon;

  /// No description provided for @deleteFeatureComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Eliminación disponible próximamente'**
  String get deleteFeatureComingSoon;

  /// No description provided for @editButton.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get editButton;

  /// No description provided for @imageSelectionError.
  ///
  /// In es, this message translates to:
  /// **'Error al seleccionar imagen: {error}'**
  String imageSelectionError(String error);

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado'**
  String get profileUpdatedSuccess;

  /// No description provided for @profileUpdateError.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar perfil: {error}'**
  String profileUpdateError(String error);

  /// No description provided for @editProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get editProfileTitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Apellido'**
  String get lastNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get emailLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get phoneLabel;

  /// No description provided for @changePasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get changePasswordLabel;

  /// No description provided for @notificationsLabel.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsLabel;

  /// No description provided for @cancelButtonCaps.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelButtonCaps;

  /// No description provided for @profileLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar perfil: {error}'**
  String profileLoadError(String error);

  /// No description provided for @logoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logoutTitle;

  /// No description provided for @logoutConfirmation.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas cerrar sesión?'**
  String get logoutConfirmation;

  /// No description provided for @logoutError.
  ///
  /// In es, this message translates to:
  /// **'Error al cerrar sesión: {error}'**
  String logoutError(String error);

  /// No description provided for @profileInfoLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar información del perfil'**
  String get profileInfoLoadError;

  /// No description provided for @clientsButton.
  ///
  /// In es, this message translates to:
  /// **'Clientes'**
  String get clientsButton;

  /// No description provided for @salesButton.
  ///
  /// In es, this message translates to:
  /// **'Ventas'**
  String get salesButton;

  /// No description provided for @commissionsButton.
  ///
  /// In es, this message translates to:
  /// **'Comisiones'**
  String get commissionsButton;

  /// No description provided for @agendaButton.
  ///
  /// In es, this message translates to:
  /// **'Agenda'**
  String get agendaButton;

  /// No description provided for @myRentalsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis alquileres'**
  String get myRentalsTitle;

  /// No description provided for @assignedPropertiesTitle.
  ///
  /// In es, this message translates to:
  /// **'Propiedades asignadas'**
  String get assignedPropertiesTitle;

  /// No description provided for @profileSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración del perfil'**
  String get profileSettingsTitle;

  /// No description provided for @changeUserModeLabel.
  ///
  /// In es, this message translates to:
  /// **'Cambiar modo de usuario'**
  String get changeUserModeLabel;

  /// No description provided for @verifyProfileLabel.
  ///
  /// In es, this message translates to:
  /// **'Verificar perfil'**
  String get verifyProfileLabel;

  /// No description provided for @editProfileLabel.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get editProfileLabel;

  /// No description provided for @deleteAccountLabel.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get deleteAccountLabel;

  /// No description provided for @profileVerificationTitle.
  ///
  /// In es, this message translates to:
  /// **'Verificación de perfil'**
  String get profileVerificationTitle;

  /// No description provided for @profileVerificationMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil ha sido verificado.'**
  String get profileVerificationMessage;

  /// No description provided for @understoodButton.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get understoodButton;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que deseas eliminar tu cuenta?'**
  String get deleteAccountConfirmation;

  /// No description provided for @accountDeletionScheduled.
  ///
  /// In es, this message translates to:
  /// **'Eliminación de cuenta programada'**
  String get accountDeletionScheduled;

  /// No description provided for @deleteAccountError.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar cuenta'**
  String get deleteAccountError;

  /// No description provided for @confirmModeChange.
  ///
  /// In es, this message translates to:
  /// **'Confirmar cambio a {name}'**
  String confirmModeChange(String name);

  /// No description provided for @acceptButton.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get acceptButton;

  /// No description provided for @updatingProfile.
  ///
  /// In es, this message translates to:
  /// **'Actualizando perfil...'**
  String get updatingProfile;

  /// No description provided for @profileModeUpdated.
  ///
  /// In es, this message translates to:
  /// **'Modo de perfil actualizado a {name}'**
  String profileModeUpdated(String name);

  /// No description provided for @profileUpdateGenericError.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar el perfil'**
  String get profileUpdateGenericError;

  /// No description provided for @tenantModeDescription.
  ///
  /// In es, this message translates to:
  /// **'Explora y alquila propiedades.'**
  String get tenantModeDescription;

  /// No description provided for @landlordModeDescription.
  ///
  /// In es, this message translates to:
  /// **'Publica y gestiona tus propiedades.'**
  String get landlordModeDescription;

  /// No description provided for @agentModeDescription.
  ///
  /// In es, this message translates to:
  /// **'Administra clientes y propiedades como agente.'**
  String get agentModeDescription;

  /// No description provided for @noRegisteredProperties.
  ///
  /// In es, this message translates to:
  /// **'No tienes propiedades registradas'**
  String get noRegisteredProperties;

  /// No description provided for @propertyNoAddress.
  ///
  /// In es, this message translates to:
  /// **'Sin dirección'**
  String get propertyNoAddress;

  /// No description provided for @availableStatus.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get availableStatus;

  /// No description provided for @unavailableStatus.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get unavailableStatus;

  /// No description provided for @manageButton.
  ///
  /// In es, this message translates to:
  /// **'Administrar'**
  String get manageButton;

  /// No description provided for @noAssignedProperties.
  ///
  /// In es, this message translates to:
  /// **'No tienes propiedades asignadas'**
  String get noAssignedProperties;

  /// No description provided for @viewReviewsButton.
  ///
  /// In es, this message translates to:
  /// **'Ver reseñas'**
  String get viewReviewsButton;

  /// No description provided for @incentivesButton.
  ///
  /// In es, this message translates to:
  /// **'Incentivos'**
  String get incentivesButton;

  /// No description provided for @userLabel.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get userLabel;

  /// No description provided for @myRentalsTitleMixed.
  ///
  /// In es, this message translates to:
  /// **'Tus alquileres'**
  String get myRentalsTitleMixed;

  /// No description provided for @myPropertiesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis propiedades'**
  String get myPropertiesTitle;

  /// No description provided for @assignedPropertiesTitleMixed.
  ///
  /// In es, this message translates to:
  /// **'Asignadas'**
  String get assignedPropertiesTitleMixed;

  /// No description provided for @verifiedLabel.
  ///
  /// In es, this message translates to:
  /// **'Verificado'**
  String get verifiedLabel;

  /// No description provided for @loadPropertiesError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar propiedades'**
  String get loadPropertiesError;

  /// No description provided for @connectionError.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión: {error}'**
  String connectionError(String error);

  /// No description provided for @noPropertiesRegistered.
  ///
  /// In es, this message translates to:
  /// **'No tienes propiedades registradas'**
  String get noPropertiesRegistered;

  /// No description provided for @addFirstProperty.
  ///
  /// In es, this message translates to:
  /// **'Agrega tu primera propiedad'**
  String get addFirstProperty;

  /// No description provided for @addPropertyButton.
  ///
  /// In es, this message translates to:
  /// **'Agregar propiedad'**
  String get addPropertyButton;

  /// No description provided for @activeStatus.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get activeStatus;

  /// No description provided for @inactiveStatus.
  ///
  /// In es, this message translates to:
  /// **'Inactivo'**
  String get inactiveStatus;

  /// No description provided for @loadPhotosErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar fotos'**
  String get loadPhotosErrorGeneric;

  /// No description provided for @invalidPropertyIdError.
  ///
  /// In es, this message translates to:
  /// **'ID de propiedad inválido'**
  String get invalidPropertyIdError;

  /// No description provided for @invalidPropertyIdErrorDetail.
  ///
  /// In es, this message translates to:
  /// **'No se pudo validar el ID de la propiedad'**
  String get invalidPropertyIdErrorDetail;

  /// No description provided for @takePhotoError.
  ///
  /// In es, this message translates to:
  /// **'Error al tomar foto: {error}'**
  String takePhotoError(String error);

  /// No description provided for @uploadPhotoErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Error al subir foto'**
  String get uploadPhotoErrorGeneric;

  /// No description provided for @photosUploadedCount.
  ///
  /// In es, this message translates to:
  /// **'Fotos subidas: {count}'**
  String photosUploadedCount(Object count);

  /// No description provided for @pickImagesError.
  ///
  /// In es, this message translates to:
  /// **'Error al seleccionar imágenes: {error}'**
  String pickImagesError(String error);

  /// No description provided for @photoUploadedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Foto subida correctamente'**
  String get photoUploadedSuccess;

  /// No description provided for @deletePhotoErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar foto'**
  String get deletePhotoErrorGeneric;

  /// No description provided for @photosOfProperty.
  ///
  /// In es, this message translates to:
  /// **'Fotos de {address}'**
  String photosOfProperty(String address);

  /// No description provided for @uploadingStatus.
  ///
  /// In es, this message translates to:
  /// **'Subiendo...'**
  String get uploadingStatus;

  /// No description provided for @selectMultiplePhotos.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar múltiples fotos'**
  String get selectMultiplePhotos;

  /// No description provided for @moreOptionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get moreOptionsTitle;

  /// No description provided for @favoritePropertiesOption.
  ///
  /// In es, this message translates to:
  /// **'Propiedades favoritas'**
  String get favoritePropertiesOption;

  /// No description provided for @favoritePropertiesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Accede a tu lista de favoritos'**
  String get favoritePropertiesSubtitle;

  /// No description provided for @searchHistoryOption.
  ///
  /// In es, this message translates to:
  /// **'Historial de búsqueda'**
  String get searchHistoryOption;

  /// No description provided for @searchHistorySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ve tus búsquedas recientes'**
  String get searchHistorySubtitle;

  /// No description provided for @notificationsOption.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsOption;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Actualizaciones y alertas recientes'**
  String get notificationsSubtitle;

  /// No description provided for @helpSupportOption.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y soporte'**
  String get helpSupportOption;

  /// No description provided for @helpSupportSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Encuentra asistencia y preguntas frecuentes'**
  String get helpSupportSubtitle;

  /// No description provided for @settingsOption.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settingsOption;

  /// No description provided for @settingsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Preferencias de la aplicación'**
  String get settingsSubtitle;

  /// No description provided for @propertyLabel.
  ///
  /// In es, this message translates to:
  /// **'Propiedad'**
  String get propertyLabel;

  /// No description provided for @pricePerMonth.
  ///
  /// In es, this message translates to:
  /// **'Bs. {price}/mes'**
  String pricePerMonth(String price);

  /// No description provided for @fetchProfileError.
  ///
  /// In es, this message translates to:
  /// **'Error al obtener perfil'**
  String get fetchProfileError;

  /// No description provided for @loadFavoritesError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar favoritos'**
  String get loadFavoritesError;

  /// No description provided for @removeFavoriteError.
  ///
  /// In es, this message translates to:
  /// **'Error al quitar de favoritos'**
  String get removeFavoriteError;

  /// No description provided for @yourLikesTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus likes'**
  String get yourLikesTitle;

  /// No description provided for @yourLikesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Propiedades que te gustan'**
  String get yourLikesSubtitle;

  /// No description provided for @noLikesYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes favoritos'**
  String get noLikesYet;

  /// No description provided for @explorePropertiesHint.
  ///
  /// In es, this message translates to:
  /// **'Explora propiedades y agrega likes'**
  String get explorePropertiesHint;

  /// No description provided for @removedFromFavorites.
  ///
  /// In es, this message translates to:
  /// **'Se quitó de favoritos: {type} · {address}'**
  String removedFromFavorites(String type, String address);

  /// No description provided for @defaultUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get defaultUser;

  /// No description provided for @processingProfile.
  ///
  /// In es, this message translates to:
  /// **'Procesando perfil...'**
  String get processingProfile;

  /// No description provided for @searchProfileCreatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Perfil de búsqueda creado'**
  String get searchProfileCreatedSuccess;

  /// No description provided for @propertiesLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar propiedades'**
  String get propertiesLoadError;

  /// No description provided for @noMatchesTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin coincidencias'**
  String get noMatchesTitle;

  /// No description provided for @refreshButton.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get refreshButton;

  /// No description provided for @messagesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mensajes'**
  String get messagesTitle;

  /// No description provided for @searchConversationsPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar conversaciones...'**
  String get searchConversationsPlaceholder;

  /// No description provided for @matchRequestsTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes de match'**
  String get matchRequestsTitle;

  /// No description provided for @matchRequestsAction.
  ///
  /// In es, this message translates to:
  /// **'Revisar solicitudes de match'**
  String get matchRequestsAction;

  /// No description provided for @noMatchRequests.
  ///
  /// In es, this message translates to:
  /// **'No tienes solicitudes de match pendientes'**
  String get noMatchRequests;

  /// No description provided for @notificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsTitle;

  /// No description provided for @notificationsLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar notificaciones'**
  String get notificationsLoadError;

  /// No description provided for @notificationMarkedRead.
  ///
  /// In es, this message translates to:
  /// **'Notificación marcada como leída'**
  String get notificationMarkedRead;

  /// No description provided for @notificationDefaultTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificación'**
  String get notificationDefaultTitle;

  /// No description provided for @markAsReadButton.
  ///
  /// In es, this message translates to:
  /// **'Marcar como leído'**
  String get markAsReadButton;

  /// No description provided for @noNotifications.
  ///
  /// In es, this message translates to:
  /// **'Sin notificaciones'**
  String get noNotifications;

  /// No description provided for @userDefaultName.
  ///
  /// In es, this message translates to:
  /// **'Usuario {id}'**
  String userDefaultName(Object id);

  /// No description provided for @hoursAgo.
  ///
  /// In es, this message translates to:
  /// **'hace {count} h'**
  String hoursAgo(Object count);

  /// No description provided for @minutesAgo.
  ///
  /// In es, this message translates to:
  /// **'hace {count} min'**
  String minutesAgo(Object count);

  /// No description provided for @nowLabel.
  ///
  /// In es, this message translates to:
  /// **'Hace un momento'**
  String get nowLabel;

  /// No description provided for @selectUserTitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un usuario'**
  String get selectUserTitle;

  /// No description provided for @searchUsersPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar usuarios...'**
  String get searchUsersPlaceholder;

  /// No description provided for @noUsersAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay usuarios disponibles'**
  String get noUsersAvailable;

  /// No description provided for @noUsersFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron usuarios'**
  String get noUsersFound;

  /// No description provided for @tryRefreshList.
  ///
  /// In es, this message translates to:
  /// **'Intenta actualizar la lista'**
  String get tryRefreshList;

  /// No description provided for @tryAnotherSearch.
  ///
  /// In es, this message translates to:
  /// **'Prueba otra búsqueda'**
  String get tryAnotherSearch;

  /// No description provided for @errorGetCurrentUser.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener el usuario actual'**
  String get errorGetCurrentUser;

  /// No description provided for @wsRouteNotFound.
  ///
  /// In es, this message translates to:
  /// **'Ruta de WebSocket no encontrada'**
  String get wsRouteNotFound;

  /// No description provided for @wsError.
  ///
  /// In es, this message translates to:
  /// **'Error de WebSocket: {error}'**
  String wsError(String error);

  /// No description provided for @wsConnectionClosed.
  ///
  /// In es, this message translates to:
  /// **'Conexión de WebSocket cerrada'**
  String get wsConnectionClosed;

  /// No description provided for @chatExampleMessage1.
  ///
  /// In es, this message translates to:
  /// **'¡Hola! ¿En qué puedo ayudarte?'**
  String get chatExampleMessage1;

  /// No description provided for @chatExampleMessage2.
  ///
  /// In es, this message translates to:
  /// **'¡Hola! Me interesa tu propiedad.'**
  String get chatExampleMessage2;

  /// No description provided for @chatExampleMessage3.
  ///
  /// In es, this message translates to:
  /// **'¡Genial! ¿Tienes alguna pregunta?'**
  String get chatExampleMessage3;

  /// No description provided for @chatExampleMessage4.
  ///
  /// In es, this message translates to:
  /// **'Sí, ¿cómo es la zona?'**
  String get chatExampleMessage4;

  /// No description provided for @chatExampleMessage5.
  ///
  /// In es, this message translates to:
  /// **'Es tranquila y cerca de tiendas.'**
  String get chatExampleMessage5;

  /// No description provided for @chatExampleMessage6.
  ///
  /// In es, this message translates to:
  /// **'Perfecto, gracias.'**
  String get chatExampleMessage6;

  /// No description provided for @sendingMessage.
  ///
  /// In es, this message translates to:
  /// **'Enviando...'**
  String get sendingMessage;

  /// No description provided for @errorSendingMessage.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar'**
  String get errorSendingMessage;

  /// No description provided for @wsConnectionUnavailable.
  ///
  /// In es, this message translates to:
  /// **'WebSocket no disponible'**
  String get wsConnectionUnavailable;

  /// No description provided for @serverNoConfirmation.
  ///
  /// In es, this message translates to:
  /// **'El servidor no confirmó'**
  String get serverNoConfirmation;

  /// No description provided for @clearChatTitle.
  ///
  /// In es, this message translates to:
  /// **'Borrar conversación'**
  String get clearChatTitle;

  /// No description provided for @todayLabel.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get todayLabel;

  /// No description provided for @matchedWithUser.
  ///
  /// In es, this message translates to:
  /// **'Has hecho match con {name}'**
  String matchedWithUser(String name);

  /// No description provided for @typingPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get typingPlaceholder;

  /// No description provided for @clearChatConfirmation.
  ///
  /// In es, this message translates to:
  /// **'Esto eliminará todos los mensajes'**
  String get clearChatConfirmation;

  /// No description provided for @clearButton.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get clearButton;

  /// No description provided for @chatClearedLocally.
  ///
  /// In es, this message translates to:
  /// **'Chat borrado localmente'**
  String get chatClearedLocally;

  /// No description provided for @chatClearedForAccount.
  ///
  /// In es, this message translates to:
  /// **'Chat borrado para esta cuenta'**
  String get chatClearedForAccount;

  /// No description provided for @untitledProperty.
  ///
  /// In es, this message translates to:
  /// **'Propiedad sin título'**
  String get untitledProperty;

  /// No description provided for @unspecifiedAddress.
  ///
  /// In es, this message translates to:
  /// **'Dirección no especificada'**
  String get unspecifiedAddress;

  /// No description provided for @acceptError.
  ///
  /// In es, this message translates to:
  /// **'Error al aceptar: {error}'**
  String acceptError(String error);

  /// No description provided for @matchRequestAccepted.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de match aceptada'**
  String get matchRequestAccepted;

  /// No description provided for @matchRequestRejected.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de match rechazada'**
  String get matchRequestRejected;

  /// No description provided for @rejectButton.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get rejectButton;

  /// No description provided for @verifyingProfile.
  ///
  /// In es, this message translates to:
  /// **'Verificando perfil...'**
  String get verifyingProfile;

  /// No description provided for @socialLoginError.
  ///
  /// In es, this message translates to:
  /// **'Error en inicio social: {provider}'**
  String socialLoginError(String provider);

  /// No description provided for @loginWithEmailButton.
  ///
  /// In es, this message translates to:
  /// **'Ingresar con correo'**
  String get loginWithEmailButton;

  /// No description provided for @loginWithGoogleButton.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get loginWithGoogleButton;

  /// No description provided for @loginWithAppleButton.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get loginWithAppleButton;

  /// No description provided for @loginWithFacebookButton.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Facebook'**
  String get loginWithFacebookButton;

  /// No description provided for @tagline.
  ///
  /// In es, this message translates to:
  /// **'Encuentra, conecta y alquila — todo en un lugar'**
  String get tagline;

  /// No description provided for @takePhotoButton.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get takePhotoButton;

  /// No description provided for @galleryButton.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get galleryButton;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get passwordsDoNotMatch;

  /// No description provided for @createSearchProfileDescription.
  ///
  /// In es, this message translates to:
  /// **'Usaremos tus preferencias para personalizar resultados.'**
  String get createSearchProfileDescription;

  /// No description provided for @registrationSuccess.
  ///
  /// In es, this message translates to:
  /// **'Registro exitoso'**
  String get registrationSuccess;

  /// No description provided for @registrationSuccessLogin.
  ///
  /// In es, this message translates to:
  /// **'Registrado correctamente. Inicia sesión.'**
  String get registrationSuccessLogin;

  /// No description provided for @registrationError.
  ///
  /// In es, this message translates to:
  /// **'Error al registrarse'**
  String get registrationError;

  /// No description provided for @backButton.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get backButton;

  /// No description provided for @yourNameTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get yourNameTitle;

  /// No description provided for @firstNamePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get firstNamePlaceholder;

  /// No description provided for @lastNamePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Apellido'**
  String get lastNamePlaceholder;

  /// No description provided for @contactTitle.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get contactTitle;

  /// No description provided for @emailPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get emailPlaceholder;

  /// No description provided for @enterEmailError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo'**
  String get enterEmailError;

  /// No description provided for @enterValidEmailError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo válido'**
  String get enterValidEmailError;

  /// No description provided for @phonePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get phonePlaceholder;

  /// No description provided for @enterPhoneError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu teléfono'**
  String get enterPhoneError;

  /// No description provided for @accountTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get accountTitle;

  /// No description provided for @usernamePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get usernamePlaceholder;

  /// No description provided for @enterUsernameError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu usuario'**
  String get enterUsernameError;

  /// No description provided for @passwordPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordPlaceholder;

  /// No description provided for @enterPasswordError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña'**
  String get enterPasswordError;

  /// No description provided for @passwordLengthError.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get passwordLengthError;

  /// No description provided for @confirmPasswordPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmPasswordPlaceholder;

  /// No description provided for @confirmPasswordError.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu contraseña'**
  String get confirmPasswordError;

  /// No description provided for @authErrorDefault.
  ///
  /// In es, this message translates to:
  /// **'Error de autenticación'**
  String get authErrorDefault;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPasswordButton;

  /// No description provided for @noAccountLabel.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get noAccountLabel;

  /// No description provided for @registerLink.
  ///
  /// In es, this message translates to:
  /// **'Regístrate'**
  String get registerLink;

  /// No description provided for @welcomeToHabitto.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a Habitto'**
  String get welcomeToHabitto;

  /// No description provided for @emailOrUsernamePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Correo o Usuario'**
  String get emailOrUsernamePlaceholder;

  /// No description provided for @enterEmailOrUsernameError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo o usuario'**
  String get enterEmailOrUsernameError;

  /// No description provided for @createWithAIButton.
  ///
  /// In es, this message translates to:
  /// **'Crear con IA'**
  String get createWithAIButton;

  /// No description provided for @portfolioTitle.
  ///
  /// In es, this message translates to:
  /// **'Portafolio de Agente'**
  String get portfolioTitle;

  /// No description provided for @loadPortfolioError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar portafolio'**
  String get loadPortfolioError;

  /// No description provided for @portfolioItemSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Bs. {price} • {size} m²'**
  String portfolioItemSubtitle(String price, String size);

  /// No description provided for @requestsTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get requestsTitle;

  /// No description provided for @loadLeadsError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar prospectos'**
  String get loadLeadsError;

  /// No description provided for @noNewRequests.
  ///
  /// In es, this message translates to:
  /// **'No hay nuevas solicitudes'**
  String get noNewRequests;

  /// No description provided for @newRequestsPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Vuelve más tarde para ver nuevos prospectos'**
  String get newRequestsPlaceholder;

  /// No description provided for @scoreLabel.
  ///
  /// In es, this message translates to:
  /// **'Puntaje: {score}%'**
  String scoreLabel(String score);

  /// No description provided for @alertHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial de Alertas'**
  String get alertHistoryTitle;

  /// No description provided for @alertHistoryComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Historial de alertas próximamente'**
  String get alertHistoryComingSoon;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'es':
      return SEs();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
