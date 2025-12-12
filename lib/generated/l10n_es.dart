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
  String get rejectError => 'Error al rechazar';

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
}
