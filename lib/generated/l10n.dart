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

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
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
  /// **'Error al rechazar'**
  String get rejectError;

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
