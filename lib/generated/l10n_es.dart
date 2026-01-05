// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Habitto';

  @override
  String get loginButton => 'Iniciar Sesión';

  @override
  String get registerButton => 'Registrarse';

  @override
  String welcomeMessage(String name) {
    return '¡Hola $name!';
  }

  @override
  String get uploadMultipleHint => 'Puedes subir varias fotos a la vez';

  @override
  String get noPhotosYet => 'Aún no hay fotos';

  @override
  String get addPhotosHint => 'Agrega fotos de tu propiedad';

  @override
  String get propertyNotFound => 'Propiedad no encontrada';

  @override
  String get propertyTitleFallback => 'Sin título';

  @override
  String rentPerMonth(String price) {
    return 'Bs. $price/mes';
  }

  @override
  String bedroomsShort(String count) {
    return '$count hab.';
  }

  @override
  String bathroomsShort(String count) {
    return '$count baños';
  }

  @override
  String sizeShort(String size) {
    return '$size m²';
  }

  @override
  String get amenitiesLabel => 'Comodidades';

  @override
  String get swipeForMatchButton => 'Desliza para Match';

  @override
  String get requestRoomieButton => 'Solicitar Roomie';

  @override
  String get scheduleViewButton => 'Agendar Visita';

  @override
  String get reviewsLabel => 'Reseñas';

  @override
  String get mockReviewer1 => 'Ana García';

  @override
  String get mockReview1 => 'Excelente lugar, muy iluminado y seguro.';

  @override
  String get mockReviewer2 => 'Carlos Ruiz';

  @override
  String get mockReview2 => 'El propietario es muy amable, recomendado.';

  @override
  String get amenityDefaultLabel => 'Comodidad';

  @override
  String get propertyTypeHouse => 'Casa';

  @override
  String get propertyTypeApartment => 'Departamento';

  @override
  String get propertyTypeRoom => 'Habitación';

  @override
  String get propertyTypeAnticretico => 'Anticrético';

  @override
  String get amenityWifi => 'WiFi';

  @override
  String get amenityParking => 'Parqueo';

  @override
  String get amenityLaundry => 'Lavandería';

  @override
  String get amenityGym => 'Gimnasio';

  @override
  String get amenityPool => 'Piscina';

  @override
  String get amenityGarden => 'Jardín';

  @override
  String loadDataError(String error) {
    return 'Error al cargar datos: $error';
  }

  @override
  String get userFetchError => 'Error al obtener usuario';

  @override
  String get propertyCreatedTitle => 'Propiedad Creada';

  @override
  String get propertyCreatedMessage =>
      'La propiedad se ha creado exitosamente.';

  @override
  String get laterButton => 'Más tarde';

  @override
  String get addPhotosButton => 'Agregar fotos';

  @override
  String genericError(String error) {
    return 'Error: $error';
  }

  @override
  String get enterAddressError => 'Ingresa una dirección';

  @override
  String get enterPriceError => 'Ingresa un precio';

  @override
  String get enterGuaranteeError => 'Ingresa una garantía';

  @override
  String get enterDescriptionError => 'Ingresa una descripción';

  @override
  String get enterAreaError => 'Ingresa el área';

  @override
  String get invalidPriceError => 'Precio inválido';

  @override
  String get invalidGuaranteeError => 'Garantía inválida';

  @override
  String get invalidAreaError => 'Área inválida';

  @override
  String get propertyDetailsTitle => 'Detalles de la propiedad';

  @override
  String get saveAndExit => 'Guardar y Salir';

  @override
  String get stepBasic => 'Básico';

  @override
  String get stepDetails => 'Detalles';

  @override
  String get stepLocation => 'Ubicación';

  @override
  String get stepBasicDescription => 'Información principal';

  @override
  String get bedroomsLabel => 'Dormitorios';

  @override
  String get bathroomsLabel => 'Baños';

  @override
  String get areaLabel => 'Área (m²)';

  @override
  String get stepDetailsDescription => 'Características y precios';

  @override
  String get rentPriceLabel => 'Precio de Alquiler';

  @override
  String get adjustPriceLabel => 'Ajustar precio';

  @override
  String get guaranteeLabel => 'Garantía';

  @override
  String get adjustGuaranteeLabel => 'Ajustar garantía';

  @override
  String get descriptionLabel => 'Descripción';

  @override
  String get propertyDescriptionHint => 'Describe tu propiedad...';

  @override
  String get acceptedPaymentMethodsLabel => 'Métodos de pago aceptados';

  @override
  String get confirmLocation => 'Confirmar Ubicación';

  @override
  String get stepLocationDescription => 'Ubicación exacta';

  @override
  String get addressLabel => 'Dirección';

  @override
  String get addressHint => 'Ej. Av. Principal #123';

  @override
  String get mapLocationLabel => 'Ubicación en el mapa';

  @override
  String get tapToSelectLocation => 'Toca para seleccionar ubicación';

  @override
  String get availabilityDateLabel => 'Fecha de disponibilidad';

  @override
  String get dateHint => 'Seleccionar fecha';

  @override
  String get propertyTypeLabel => 'Tipo de Propiedad';

  @override
  String get previousButton => 'Anterior';

  @override
  String get finishButton => 'Finalizar';

  @override
  String get nextButton => 'Siguiente';

  @override
  String loadPhotosError(String error) {
    return 'Error al cargar fotos: $error';
  }

  @override
  String pickImageError(String error) {
    return 'Error al seleccionar imagen: $error';
  }

  @override
  String uploadSummary(Object success, Object fail) {
    return '$success subidas, $fail fallidas';
  }

  @override
  String get photosUploadedSuccess => 'Fotos subidas correctamente';

  @override
  String get deletePhotoTitle => 'Eliminar foto';

  @override
  String get deletePhotoConfirmation => '¿Estás seguro de eliminar esta foto?';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get photoDeletedSuccess => 'Foto eliminada';

  @override
  String get propertyUpdatedSuccess => 'Propiedad actualizada';

  @override
  String updatePropertyError(String error) {
    return 'Error al actualizar: $error';
  }

  @override
  String get editPropertyTitle => 'Editar Propiedad';

  @override
  String get priceLabel => 'Precio';

  @override
  String get bedroomsShortLabel => 'Hab.';

  @override
  String get matchLabel => 'Match';

  @override
  String get uploadPhotosButton => 'Subir Fotos';

  @override
  String get noInterestsYet => 'Aún no hay interesados';

  @override
  String matchScore(String score) {
    return 'Match: $score%';
  }

  @override
  String get matchAcceptedMessage => 'Match aceptado';

  @override
  String get priceBsLabel => 'Precio (Bs)';

  @override
  String get guaranteeBsLabel => 'Garantía (Bs)';

  @override
  String get sizeLabel => 'Tamaño (m²)';

  @override
  String get saveChangesButton => 'Guardar Cambios';

  @override
  String get requiredField => 'Campo requerido';

  @override
  String get uploadPhotosTitle => 'Subir Fotos';

  @override
  String get cameraOption => 'Cámara';

  @override
  String get galleryOption => 'Galería';

  @override
  String get socialAreasTitle => 'Áreas Sociales';

  @override
  String get socialAreasComingSoon => 'Próximamente: Áreas Sociales';

  @override
  String get onboardingTitle1 => 'Encuentra tu hogar ideal';

  @override
  String get onboardingSubtitle1 => 'Explora miles de opciones...';

  @override
  String get onboardingTitle2 => 'Conecta con propietarios';

  @override
  String get onboardingSubtitle2 => 'Chat directo y seguro...';

  @override
  String get onboardingTitle3 => 'Gestiona tus propiedades';

  @override
  String get onboardingSubtitle3 => 'Publica y administra...';

  @override
  String get onboardingTitle4 => 'Todo en un solo lugar';

  @override
  String get onboardingSubtitle4 => 'La mejor experiencia inmobiliaria';

  @override
  String get actionUndo => 'Deshacer';

  @override
  String get actionReject => 'Rechazar';

  @override
  String get actionLike => 'Me gusta';

  @override
  String get actionFavorite => 'Favorito';

  @override
  String get closeButton => 'Cerrar';

  @override
  String get matchTitle => '¡Es un Match!';

  @override
  String get matchPrefix => 'Te gusta ';

  @override
  String get matchWord => 'esta propiedad';

  @override
  String get matchSuffix => '!';

  @override
  String get matchWith => 'con';

  @override
  String get thisProperty => 'esta propiedad';

  @override
  String get matchSubtitle => 'Ahora pueden chatear...';

  @override
  String get sendMessageButton => 'Enviar Mensaje';

  @override
  String get searchApartmentSuggestion => 'Busco departamento en...';

  @override
  String get searchRoomieSuggestion => 'Busco roomie...';

  @override
  String get createProfileSuggestion => 'Crear perfil...';

  @override
  String get createPropertySuggestion => 'Publicar propiedad';

  @override
  String aiAssistantGreeting(String name) {
    return '¡Hola $name! Soy tu asistente...';
  }

  @override
  String get micPermissionRequired => 'Se requiere permiso de micrófono';

  @override
  String get micPermissionTitle => 'Permiso de micrófono';

  @override
  String get micPermissionContent => 'Necesitamos acceso al micrófono...';

  @override
  String get openSettingsButton => 'Abrir Configuración';

  @override
  String get profileCreatedSuccess => 'Perfil creado exitosamente';

  @override
  String get aiProcessingError => 'Error al procesar...';

  @override
  String get aiTypingIndicator => 'Escribiendo...';

  @override
  String get listeningIndicator => 'Escuchando...';

  @override
  String get aiChatPlaceholder => 'Escribe un mensaje...';

  @override
  String get navExplore => 'Explorar';

  @override
  String get navCandidates => 'Candidatos';

  @override
  String get navLeads => 'Prospectos';

  @override
  String get navMap => 'Mapa';

  @override
  String get navProperties => 'Propiedades';

  @override
  String get navPortfolio => 'Portafolio';

  @override
  String get navInbox => 'Buzón';

  @override
  String get navChat => 'Chat';

  @override
  String get navProfProfile => 'Perfil Pro';

  @override
  String get navProfile => 'Perfil';

  @override
  String get closeMenu => 'Cerrar menú';

  @override
  String get openMenu => 'Abrir menú';

  @override
  String navItemActive(String label) {
    return '$label activo';
  }

  @override
  String get noImagePlaceholder => 'Sin imagen';

  @override
  String get menuMatchs => 'Matches';

  @override
  String get menuAiAssistant => 'Asistente IA';

  @override
  String get menuAddProperty => 'Agregar Propiedad';

  @override
  String get tenantRole => 'Inquilino';

  @override
  String get landlordRole => 'Propietario';

  @override
  String get agentRole => 'Agente';

  @override
  String get likeSent => '¡Like enviado! El propietario será notificado.';

  @override
  String get likeError => 'Error al dar like';

  @override
  String rejectError(String error) {
    return 'Error al rechazar: $error';
  }

  @override
  String get noMoreProperties => 'No hay más propiedades';

  @override
  String get noImageLabel => 'Sin imagen';

  @override
  String get retryButton => 'Reintentar';

  @override
  String get noPendingMatchRequests =>
      'No tienes solicitudes de match pendientes';

  @override
  String get newMatchRequestsWillAppearHere =>
      'Las nuevas solicitudes aparecerán aquí';

  @override
  String get searchPlaceholder => 'Buscar por zona, precio, tipo...';

  @override
  String get filterZone => 'Zona';

  @override
  String get filterPrice => 'Precio';

  @override
  String get filterType => 'Tipo';

  @override
  String get filterAmenities => 'Comodidades';

  @override
  String get viewMoreDetails => 'Ver más detalles';

  @override
  String get houseType => 'Casa';

  @override
  String get apartmentType => 'Departamento';

  @override
  String get roomType => 'Habitación';

  @override
  String get wifiAmenity => 'WiFi';

  @override
  String get parkingAmenity => 'Parqueo';

  @override
  String get laundryAmenity => 'Lavandería';

  @override
  String get gymAmenity => 'Gimnasio';

  @override
  String get poolAmenity => 'Piscina';

  @override
  String get gardenAmenity => 'Jardín';

  @override
  String get lifestyleQuiet => 'Tranquilo';

  @override
  String get lifestyleSocial => 'Social';

  @override
  String get lifestyleActive => 'Activo';

  @override
  String get lifestyleReading => 'Lectura';

  @override
  String get lifestyleMusic => 'Música';

  @override
  String get lifestyleMovies => 'Cine';

  @override
  String get lifestyleCooking => 'Cocina';

  @override
  String get lifestyleTravel => 'Viajes';

  @override
  String get lifestyleTech => 'Tecnología';

  @override
  String get lifestyleArt => 'Arte';

  @override
  String get lifestyleNature => 'Naturaleza';

  @override
  String get lifestyleStudy => 'Estudio';

  @override
  String get langSpanish => 'Español';

  @override
  String get langEnglish => 'Inglés';

  @override
  String get langPortuguese => 'Portugués';

  @override
  String get langFrench => 'Francés';

  @override
  String get langGerman => 'Alemán';

  @override
  String get langItalian => 'Italiano';

  @override
  String get searchProfileCreatedTitle => 'Perfil de búsqueda creado';

  @override
  String get searchProfileCreatedMessage => 'Hemos guardado tus preferencias.';

  @override
  String get continueButton => 'Continuar';

  @override
  String get errorCreatingSearchProfile =>
      'Error al crear el perfil de búsqueda';

  @override
  String errorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get selectLocationError => 'Selecciona una ubicación en el mapa';

  @override
  String get selectPropertyTypeError =>
      'Selecciona al menos un tipo de propiedad';

  @override
  String get createSearchProfileTitle => 'Crear perfil de búsqueda';

  @override
  String get skipButton => 'Saltar';

  @override
  String get locationStep => 'Ubicación';

  @override
  String get propertyStep => 'Propiedad';

  @override
  String get cohabitationStep => 'Convivencia';

  @override
  String get lifestyleStep => 'Estilo de vida';

  @override
  String get step1Title => 'Ubicación y presupuesto';

  @override
  String get budgetRangeLabel => 'Rango de presupuesto';

  @override
  String get dragToAdjustLabel => 'Arrastra para ajustar';

  @override
  String get step2Title => 'Tipo de propiedad';

  @override
  String minLabel(Object value) {
    return 'Min: $value';
  }

  @override
  String maxLabel(Object value) {
    return 'Max: $value';
  }

  @override
  String get remoteWorkSpaceLabel => 'Espacio para trabajo remoto';

  @override
  String get petAllowedLabel => 'Se permiten mascotas';

  @override
  String get step3Title => 'Preferencias de convivencia';

  @override
  String get roommatePreferenceLabel => 'Preferencia de roomie';

  @override
  String get noRoommateOption => 'Sin roomie';

  @override
  String get openRoommateOption => 'Abierto a roomie';

  @override
  String get yesRoommateOption => 'Deseo roomie';

  @override
  String get familySizeLabel => 'Tamaño de familia';

  @override
  String get childrenCountLabel => 'Número de hijos';

  @override
  String get step4Title => 'Estilo de vida';

  @override
  String get lifestyleLabel => 'Estilo de vida';

  @override
  String selectTagsLabel(Object count) {
    return 'Selecciona etiquetas ($count)';
  }

  @override
  String get smokerLabel => 'Fumador';

  @override
  String get languagesLabel => 'Idiomas';

  @override
  String paymentMethodsLoadError(String error) {
    return 'Error al cargar métodos de pago: $error';
  }

  @override
  String get enterPaymentMethodNameError =>
      'Ingresa el nombre del método de pago';

  @override
  String get paymentMethodCreatedSuccess => 'Método de pago creado';

  @override
  String paymentMethodCreateError(String error) {
    return 'Error al crear método de pago: $error';
  }

  @override
  String get createPaymentMethodTitle => 'Crear método de pago';

  @override
  String get paymentMethodNameLabel => 'Nombre del método de pago';

  @override
  String get paymentMethodNameHint => 'Ej. Transferencia bancaria';

  @override
  String get createButton => 'Crear';

  @override
  String get paymentMethodsTitle => 'Métodos de pago';

  @override
  String get noPaymentMethods => 'No hay métodos de pago';

  @override
  String get createFirstPaymentMethodHint => 'Crea tu primer método de pago';

  @override
  String idLabel(Object id) {
    return 'ID: $id';
  }

  @override
  String get editFeatureComingSoon => 'Edición disponible próximamente';

  @override
  String get deleteFeatureComingSoon => 'Eliminación disponible próximamente';

  @override
  String get editButton => 'Editar';

  @override
  String imageSelectionError(String error) {
    return 'Error al seleccionar imagen: $error';
  }

  @override
  String get profileUpdatedSuccess => 'Perfil actualizado';

  @override
  String profileUpdateError(String error) {
    return 'Error al actualizar perfil: $error';
  }

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get firstNameLabel => 'Nombre';

  @override
  String get lastNameLabel => 'Apellido';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get phoneLabel => 'Teléfono';

  @override
  String get changePasswordLabel => 'Cambiar contraseña';

  @override
  String get notificationsLabel => 'Notificaciones';

  @override
  String get cancelButtonCaps => 'Cancelar';

  @override
  String profileLoadError(String error) {
    return 'Error al cargar perfil: $error';
  }

  @override
  String get logoutTitle => 'Cerrar sesión';

  @override
  String get logoutConfirmation => '¿Deseas cerrar sesión?';

  @override
  String logoutError(String error) {
    return 'Error al cerrar sesión: $error';
  }

  @override
  String get profileInfoLoadError => 'Error al cargar información del perfil';

  @override
  String get clientsButton => 'Clientes';

  @override
  String get salesButton => 'Ventas';

  @override
  String get commissionsButton => 'Comisiones';

  @override
  String get agendaButton => 'Agenda';

  @override
  String get myRentalsTitle => 'Mis alquileres';

  @override
  String get assignedPropertiesTitle => 'Propiedades asignadas';

  @override
  String get profileSettingsTitle => 'Configuración del perfil';

  @override
  String get changeUserModeLabel => 'Cambiar modo de usuario';

  @override
  String get verifyProfileLabel => 'Verificar perfil';

  @override
  String get editProfileLabel => 'Editar perfil';

  @override
  String get deleteAccountLabel => 'Eliminar cuenta';

  @override
  String get profileVerificationTitle => 'Verificación de perfil';

  @override
  String get profileVerificationMessage => 'Tu perfil ha sido verificado.';

  @override
  String get understoodButton => 'Entendido';

  @override
  String get deleteAccountConfirmation =>
      '¿Seguro que deseas eliminar tu cuenta?';

  @override
  String get accountDeletionScheduled => 'Eliminación de cuenta programada';

  @override
  String get deleteAccountError => 'Error al eliminar cuenta';

  @override
  String confirmModeChange(String name) {
    return 'Confirmar cambio a $name';
  }

  @override
  String get acceptButton => 'Aceptar';

  @override
  String get updatingProfile => 'Actualizando perfil...';

  @override
  String profileModeUpdated(String name) {
    return 'Modo de perfil actualizado a $name';
  }

  @override
  String get profileUpdateGenericError => 'Error al actualizar el perfil';

  @override
  String get tenantModeDescription => 'Explora y alquila propiedades.';

  @override
  String get landlordModeDescription => 'Publica y gestiona tus propiedades.';

  @override
  String get agentModeDescription =>
      'Administra clientes y propiedades como agente.';

  @override
  String get noRegisteredProperties => 'No tienes propiedades registradas';

  @override
  String get propertyNoAddress => 'Sin dirección';

  @override
  String get availableStatus => 'Disponible';

  @override
  String get unavailableStatus => 'No disponible';

  @override
  String get manageButton => 'Administrar';

  @override
  String get noAssignedProperties => 'No tienes propiedades asignadas';

  @override
  String get viewReviewsButton => 'Ver reseñas';

  @override
  String get incentivesButton => 'Incentivos';

  @override
  String get userLabel => 'Usuario';

  @override
  String get myRentalsTitleMixed => 'Tus alquileres';

  @override
  String get myPropertiesTitle => 'Mis propiedades';

  @override
  String get assignedPropertiesTitleMixed => 'Asignadas';

  @override
  String get verifiedLabel => 'Verificado';

  @override
  String get loadPropertiesError => 'Error al cargar propiedades';

  @override
  String connectionError(String error) {
    return 'Error de conexión: $error';
  }

  @override
  String get noPropertiesRegistered => 'No tienes propiedades registradas';

  @override
  String get addFirstProperty => 'Agrega tu primera propiedad';

  @override
  String get addPropertyButton => 'Agregar propiedad';

  @override
  String get activeStatus => 'Activo';

  @override
  String get inactiveStatus => 'Inactivo';

  @override
  String get loadPhotosErrorGeneric => 'Error al cargar fotos';

  @override
  String get invalidPropertyIdError => 'ID de propiedad inválido';

  @override
  String get invalidPropertyIdErrorDetail =>
      'No se pudo validar el ID de la propiedad';

  @override
  String takePhotoError(String error) {
    return 'Error al tomar foto: $error';
  }

  @override
  String get uploadPhotoErrorGeneric => 'Error al subir foto';

  @override
  String photosUploadedCount(Object count) {
    return 'Fotos subidas: $count';
  }

  @override
  String pickImagesError(String error) {
    return 'Error al seleccionar imágenes: $error';
  }

  @override
  String get photoUploadedSuccess => 'Foto subida correctamente';

  @override
  String get deletePhotoErrorGeneric => 'Error al eliminar foto';

  @override
  String photosOfProperty(String address) {
    return 'Fotos de $address';
  }

  @override
  String get uploadingStatus => 'Subiendo...';

  @override
  String get selectMultiplePhotos => 'Seleccionar múltiples fotos';

  @override
  String get moreOptionsTitle => 'Más opciones';

  @override
  String get favoritePropertiesOption => 'Propiedades favoritas';

  @override
  String get favoritePropertiesSubtitle => 'Accede a tu lista de favoritos';

  @override
  String get searchHistoryOption => 'Historial de búsqueda';

  @override
  String get searchHistorySubtitle => 'Ve tus búsquedas recientes';

  @override
  String get notificationsOption => 'Notificaciones';

  @override
  String get notificationsSubtitle => 'Actualizaciones y alertas recientes';

  @override
  String get helpSupportOption => 'Ayuda y soporte';

  @override
  String get helpSupportSubtitle =>
      'Encuentra asistencia y preguntas frecuentes';

  @override
  String get settingsOption => 'Configuración';

  @override
  String get settingsSubtitle => 'Preferencias de la aplicación';

  @override
  String get propertyLabel => 'Propiedad';

  @override
  String pricePerMonth(String price) {
    return 'Bs. $price/mes';
  }

  @override
  String get fetchProfileError => 'Error al obtener perfil';

  @override
  String get loadFavoritesError => 'Error al cargar favoritos';

  @override
  String get removeFavoriteError => 'Error al quitar de favoritos';

  @override
  String get yourLikesTitle => 'Tus likes';

  @override
  String get yourLikesSubtitle => 'Propiedades que te gustan';

  @override
  String get noLikesYet => 'Aún no tienes favoritos';

  @override
  String get explorePropertiesHint => 'Explora propiedades y agrega likes';

  @override
  String removedFromFavorites(String type, String address) {
    return 'Se quitó de favoritos: $type · $address';
  }

  @override
  String get defaultUser => 'Usuario';

  @override
  String get processingProfile => 'Procesando perfil...';

  @override
  String get searchProfileCreatedSuccess => 'Perfil de búsqueda creado';

  @override
  String get propertiesLoadError => 'Error al cargar propiedades';

  @override
  String get noMatchesTitle => 'Sin coincidencias';

  @override
  String get refreshButton => 'Actualizar';

  @override
  String get messagesTitle => 'Mensajes';

  @override
  String get searchConversationsPlaceholder => 'Buscar conversaciones...';

  @override
  String get matchRequestsTitle => 'Solicitudes de match';

  @override
  String get matchRequestsAction => 'Revisar solicitudes de match';

  @override
  String get noMatchRequests => 'No tienes solicitudes de match pendientes';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsLoadError => 'Error al cargar notificaciones';

  @override
  String get notificationMarkedRead => 'Notificación marcada como leída';

  @override
  String get notificationDefaultTitle => 'Notificación';

  @override
  String get markAsReadButton => 'Marcar como leído';

  @override
  String get noNotifications => 'Sin notificaciones';

  @override
  String userDefaultName(Object id) {
    return 'Usuario $id';
  }

  @override
  String hoursAgo(Object count) {
    return 'hace $count h';
  }

  @override
  String minutesAgo(Object count) {
    return 'hace $count min';
  }

  @override
  String get nowLabel => 'Hace un momento';

  @override
  String get selectUserTitle => 'Selecciona un usuario';

  @override
  String get searchUsersPlaceholder => 'Buscar usuarios...';

  @override
  String get noUsersAvailable => 'No hay usuarios disponibles';

  @override
  String get noUsersFound => 'No se encontraron usuarios';

  @override
  String get tryRefreshList => 'Intenta actualizar la lista';

  @override
  String get tryAnotherSearch => 'Prueba otra búsqueda';

  @override
  String get errorGetCurrentUser => 'No se pudo obtener el usuario actual';

  @override
  String get wsRouteNotFound => 'Ruta de WebSocket no encontrada';

  @override
  String wsError(String error) {
    return 'Error de WebSocket: $error';
  }

  @override
  String get wsConnectionClosed => 'Conexión de WebSocket cerrada';

  @override
  String get chatExampleMessage1 => '¡Hola! ¿En qué puedo ayudarte?';

  @override
  String get chatExampleMessage2 => '¡Hola! Me interesa tu propiedad.';

  @override
  String get chatExampleMessage3 => '¡Genial! ¿Tienes alguna pregunta?';

  @override
  String get chatExampleMessage4 => 'Sí, ¿cómo es la zona?';

  @override
  String get chatExampleMessage5 => 'Es tranquila y cerca de tiendas.';

  @override
  String get chatExampleMessage6 => 'Perfecto, gracias.';

  @override
  String get sendingMessage => 'Enviando...';

  @override
  String get errorSendingMessage => 'Error al enviar';

  @override
  String get wsConnectionUnavailable => 'WebSocket no disponible';

  @override
  String get serverNoConfirmation => 'El servidor no confirmó';

  @override
  String get clearChatTitle => 'Borrar conversación';

  @override
  String get todayLabel => 'Hoy';

  @override
  String matchedWithUser(String name) {
    return 'Has hecho match con $name';
  }

  @override
  String get typingPlaceholder => 'Escribe un mensaje...';

  @override
  String get clearChatConfirmation => 'Esto eliminará todos los mensajes';

  @override
  String get clearButton => 'Borrar';

  @override
  String get chatClearedLocally => 'Chat borrado localmente';

  @override
  String get chatClearedForAccount => 'Chat borrado para esta cuenta';

  @override
  String get untitledProperty => 'Propiedad sin título';

  @override
  String get unspecifiedAddress => 'Dirección no especificada';

  @override
  String acceptError(String error) {
    return 'Error al aceptar: $error';
  }

  @override
  String get matchRequestAccepted => 'Solicitud de match aceptada';

  @override
  String get matchRequestRejected => 'Solicitud de match rechazada';

  @override
  String get rejectButton => 'Rechazar';

  @override
  String get verifyingProfile => 'Verificando perfil...';

  @override
  String socialLoginError(String provider) {
    return 'Error en inicio social: $provider';
  }

  @override
  String get loginWithEmailButton => 'Ingresar con correo';

  @override
  String get loginWithGoogleButton => 'Continuar con Google';

  @override
  String get loginWithAppleButton => 'Continuar con Apple';

  @override
  String get loginWithFacebookButton => 'Continuar con Facebook';

  @override
  String get tagline => 'Encuentra, conecta y alquila — todo en un lugar';

  @override
  String get takePhotoButton => 'Tomar foto';

  @override
  String get galleryButton => 'Elegir de la galería';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get createSearchProfileDescription =>
      'Usaremos tus preferencias para personalizar resultados.';

  @override
  String get registrationSuccess => 'Registro exitoso';

  @override
  String get registrationSuccessLogin =>
      'Registrado correctamente. Inicia sesión.';

  @override
  String get registrationError => 'Error al registrarse';

  @override
  String get backButton => 'Atrás';

  @override
  String get yourNameTitle => 'Tu nombre';

  @override
  String get firstNamePlaceholder => 'Nombre';

  @override
  String get lastNamePlaceholder => 'Apellido';

  @override
  String get contactTitle => 'Contacto';

  @override
  String get emailPlaceholder => 'Correo electrónico';

  @override
  String get enterEmailError => 'Ingresa tu correo';

  @override
  String get enterValidEmailError => 'Ingresa un correo válido';

  @override
  String get phonePlaceholder => 'Teléfono';

  @override
  String get enterPhoneError => 'Ingresa tu teléfono';

  @override
  String get accountTitle => 'Cuenta';

  @override
  String get usernamePlaceholder => 'Usuario';

  @override
  String get enterUsernameError => 'Ingresa tu usuario';

  @override
  String get passwordPlaceholder => 'Contraseña';

  @override
  String get enterPasswordError => 'Ingresa tu contraseña';

  @override
  String get passwordLengthError =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get confirmPasswordPlaceholder => 'Confirmar contraseña';

  @override
  String get confirmPasswordError => 'Confirma tu contraseña';

  @override
  String get authErrorDefault => 'Error de autenticación';

  @override
  String get forgotPasswordButton => '¿Olvidaste tu contraseña?';

  @override
  String get noAccountLabel => '¿No tienes cuenta?';

  @override
  String get registerLink => 'Regístrate';

  @override
  String get welcomeToHabitto => 'Bienvenido a Habitto';

  @override
  String get emailOrUsernamePlaceholder => 'Correo o Usuario';

  @override
  String get enterEmailOrUsernameError => 'Ingresa tu correo o usuario';

  @override
  String get createWithAIButton => 'Crear con IA';

  @override
  String get portfolioTitle => 'Portafolio de Agente';

  @override
  String get loadPortfolioError => 'Error al cargar portafolio';

  @override
  String portfolioItemSubtitle(String price, String size) {
    return 'Bs. $price • $size m²';
  }

  @override
  String get requestsTitle => 'Solicitudes';

  @override
  String get loadLeadsError => 'Error al cargar prospectos';

  @override
  String get noNewRequests => 'No hay nuevas solicitudes';

  @override
  String get newRequestsPlaceholder =>
      'Vuelve más tarde para ver nuevos prospectos';

  @override
  String scoreLabel(String score) {
    return 'Puntaje: $score%';
  }

  @override
  String get alertHistoryTitle => 'Historial de Alertas';

  @override
  String get alertHistoryComingSoon => 'Historial de alertas próximamente';
}
