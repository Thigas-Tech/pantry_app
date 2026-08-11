// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get myPantry => 'My Pantry';

  @override
  String get settings => 'Settings';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get enterBarcode => 'Enter Barcode';

  @override
  String get expired => 'Expired';

  @override
  String get expiringSoon => 'Expiring soon';

  @override
  String get good => 'Good';

  @override
  String get searchHint => 'Search by name or barcode';

  @override
  String get noItemsMatch => 'No items match your search';

  @override
  String get emptyPantryTitle => 'Your pantry is empty';

  @override
  String get emptyPantrySubtitle => 'Tap the button below to scan your first product';

  @override
  String get scanFirstProduct => 'Scan a barcode';

  @override
  String get barcodeLabel => 'Barcode';

  @override
  String get invalidBarcode => 'Enter a valid barcode number.';

  @override
  String get brandLabel => 'Brand';

  @override
  String get categoryLabel => 'Categories';

  @override
  String get servingSize => 'Serving size';

  @override
  String get energy => 'Energy';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get fiber => 'Fiber';

  @override
  String get salt => 'Salt';

  @override
  String get per100g => 'Per 100 g';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get yourInventory => 'Your inventory';

  @override
  String get noItemsInPantry => 'No items in pantry yet.';

  @override
  String get addToInventory => 'Add to Inventory';

  @override
  String get copyBarcode => 'Copy barcode';

  @override
  String get barcodeCopied => 'Barcode copied!';

  @override
  String get removedFromPantry => 'Removed from pantry.';

  @override
  String get updateItem => 'Update Item';

  @override
  String get addToPantry => 'Add to Pantry';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get unitLabel => 'Unit';

  @override
  String get locationLabel => 'Location';

  @override
  String get expiryDateOptional => 'Expiry date (optional)';

  @override
  String get pickDate => 'Pick date';

  @override
  String get notesLabel => 'Notes';

  @override
  String get theme => 'Theme';

  @override
  String get expiryNotifications => 'Expiry notifications';

  @override
  String get remindBeforeExpiry => 'Remind before food expires';

  @override
  String get dataRetention => 'Data retention';

  @override
  String get manageInventories => 'Manage Inventories';

  @override
  String get manageInventoriesSub => 'Create, rename, or delete pantries';

  @override
  String get chooseTheme => 'Choose theme';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get pantryStats => 'Pantry Stats';

  @override
  String get totalProducts => 'Total products';

  @override
  String get inventoryItems => 'Inventory items';

  @override
  String get createNewPantry => 'Create new pantry';

  @override
  String get newPantry => 'New pantry';

  @override
  String get renamePantry => 'Rename pantry';

  @override
  String get deletePantry => 'Delete pantry?';

  @override
  String deletePantryContent(String name) {
    return 'All items in \"$name\" will be permanently deleted.';
  }

  @override
  String get manualEntryTooltip => 'Enter barcode manually';

  @override
  String get cameraTooltip => 'Scan with camera';

  @override
  String get typeOrPasteBarcode => 'Type or paste a barcode';

  @override
  String get submit => 'Submit';

  @override
  String get itemUpdated => 'Item updated.';

  @override
  String get productUpdated => 'Product updated.';

  @override
  String get notAvailable => 'N/A';

  @override
  String get itemAdded => 'Item added to pantry.';

  @override
  String get itemRemoved => 'Item removed from pantry.';

  @override
  String get saveFailed => 'Failed to save inventory item.';

  @override
  String get deleteInventoryItem => 'Delete items?';

  @override
  String deleteCountSub(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count selected items?',
      one: 'Delete 1 selected item?',
    );
    return '$_temp0';
  }

  @override
  String get itemsRestored => 'Items restored.';

  @override
  String get selectItems => 'Select items';

  @override
  String get deleteFailed => 'Failed to delete item.';

  @override
  String get moveToPantry => 'Move to pantry';

  @override
  String get moveFailed => 'Failed to move items.';

  @override
  String get inventoryLoadFailed => 'Failed to load inventory.';

  @override
  String get expiryPrefix => 'Exp';

  @override
  String get switchPantry => 'Switch pantry';

  @override
  String get couldNotOpenPlayStore => 'Could not open the Play Store.';

  @override
  String get viewOnOpenFoodFacts => 'View on Open Food Facts';

  @override
  String get couldNotOpenLink => 'Could not open the link.';

  @override
  String get nutrient => 'Nutrients';

  @override
  String get deleteItemTitle => 'Delete item?';

  @override
  String get deleteItemContent => 'This cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get failedToLoadInventoryItems => 'Failed to load inventory items.';

  @override
  String get enterPositiveNumber => 'Enter a positive number';

  @override
  String get notificationsEnabled => 'Notifications enabled.';

  @override
  String get notificationsDisabled => 'Notifications disabled.';

  @override
  String get notificationPermissionTitle => 'Notification Permission Required';

  @override
  String get notificationPermissionBody => 'To receive expiry reminders, grant notification permission in your device settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String themeChanged(String theme) {
    return 'Theme: $theme';
  }

  @override
  String retentionDaysValue(int days) {
    return '$days days';
  }

  @override
  String get dataRetentionDialogTitle => 'Data retention (days)';

  @override
  String get daysLabel => 'Days';

  @override
  String retentionPeriodSet(int days) {
    return 'Retention period set to $days days.';
  }

  @override
  String get noInventories => 'No inventories.';

  @override
  String itemsCount(int count) {
    return 'Items: $count';
  }

  @override
  String get nameLabel => 'Name';

  @override
  String get create => 'Create';

  @override
  String get rename => 'Rename';

  @override
  String inventoryCreated(String name) {
    return '\"$name\" created.';
  }

  @override
  String inventoryRenamed(String name) {
    return 'Renamed to \"$name\".';
  }

  @override
  String inventoryDeleted(String name) {
    return '\"$name\" deleted.';
  }

  @override
  String get couldNotCreateInventory => 'Could not create inventory.';

  @override
  String get couldNotResolveProduct => 'Could not load product details.';

  @override
  String get couldNotRenameInventory => 'Could not rename inventory.';

  @override
  String get couldNotDeleteInventory => 'Could not delete inventory.';

  @override
  String get networkError => 'Network error. Please check your connection.';

  @override
  String get fetchProductFailed => 'Failed to fetch product. Please check your connection.';

  @override
  String get productNotFoundHint => 'This product isn\'t in the Open Food Facts database yet. You can add it manually or contribute it to the community.';

  @override
  String get addManually => 'Add manually';

  @override
  String get contributeToOpenFoodFacts => 'Contribute to Open Food Facts';

  @override
  String get retry => 'Retry';

  @override
  String get expiringSoonDays => 'Expiring soon threshold';

  @override
  String expiringSoonDaysValue(int days) {
    return '$days days';
  }

  @override
  String get expiringSoonDaysDialogTitle => 'Expiring soon threshold (days)';

  @override
  String expiringSoonDaysSet(int days) {
    return 'Expiring soon threshold set to $days days.';
  }

  @override
  String get expiringToday => 'Food expiring today';

  @override
  String expiresTomorrow(String name) {
    return '$name expires tomorrow';
  }

  @override
  String expiresToday(String name) {
    return '$name expires today!';
  }

  @override
  String get expiryChannelName => 'Expiry reminders';

  @override
  String get expiryChannelDescription => 'Warns about expiring food';

  @override
  String get itemRestored => 'Item restored.';

  @override
  String get undo => 'Undo';

  @override
  String get scanHint => 'Align the barcode inside the frame';

  @override
  String get confirmExitScanner => 'Stop scanning?';

  @override
  String get confirmExitScannerHint => 'The current scan will be discarded.';

  @override
  String get stay => 'Stay';

  @override
  String get leave => 'Leave';

  @override
  String get enterCustomUnit => 'Enter custom unit';

  @override
  String get enterCustomLocation => 'Enter custom location';

  @override
  String get enterProductDetails => 'Enter product details';

  @override
  String get productNameLabel => 'Product name';

  @override
  String get requiredField => 'This field is required';

  @override
  String get servingSizeHint => 'e.g. 100';

  @override
  String get nutritionInfo => 'Nutrition (per 100 g / 100 ml)';

  @override
  String get enterValidNumber => 'Enter a valid number';

  @override
  String get addNutrient => 'Add nutrient';

  @override
  String get removeNutrient => 'Remove nutrient';

  @override
  String get chooseNutrient => 'Choose a nutrient';

  @override
  String get nutrientSaturatedFat => 'Saturated fat';

  @override
  String get nutrientMonounsaturatedFat => 'Monounsaturated fat';

  @override
  String get nutrientPolyunsaturatedFat => 'Polyunsaturated fat';

  @override
  String get nutrientTransFat => 'Trans fat';

  @override
  String get nutrientCholesterol => 'Cholesterol';

  @override
  String get nutrientOmega3 => 'Omega-3';

  @override
  String get nutrientOmega6 => 'Omega-6';

  @override
  String get nutrientSugars => 'Sugars';

  @override
  String get nutrientAddedSugars => 'Added sugars';

  @override
  String get nutrientStarch => 'Starch';

  @override
  String get nutrientSugarAlcohol => 'Sugar alcohols';

  @override
  String get nutrientSolubleFiber => 'Soluble fiber';

  @override
  String get nutrientInsolubleFiber => 'Insoluble fiber';

  @override
  String get nutrientSodium => 'Sodium';

  @override
  String get nutrientPotassium => 'Potassium';

  @override
  String get nutrientCalcium => 'Calcium';

  @override
  String get nutrientIron => 'Iron';

  @override
  String get nutrientMagnesium => 'Magnesium';

  @override
  String get nutrientPhosphorus => 'Phosphorus';

  @override
  String get nutrientZinc => 'Zinc';

  @override
  String get nutrientCopper => 'Copper';

  @override
  String get nutrientManganese => 'Manganese';

  @override
  String get nutrientSelenium => 'Selenium';

  @override
  String get nutrientChromium => 'Chromium';

  @override
  String get nutrientMolybdenum => 'Molybdenum';

  @override
  String get nutrientFluoride => 'Fluoride';

  @override
  String get nutrientIodine => 'Iodine';

  @override
  String get nutrientChloride => 'Chloride';

  @override
  String get nutrientVitaminA => 'Vitamin A';

  @override
  String get nutrientVitaminC => 'Vitamin C';

  @override
  String get nutrientVitaminD => 'Vitamin D';

  @override
  String get nutrientVitaminE => 'Vitamin E';

  @override
  String get nutrientVitaminK => 'Vitamin K';

  @override
  String get nutrientVitaminB1 => 'Vitamin B1';

  @override
  String get nutrientVitaminB2 => 'Vitamin B2';

  @override
  String get nutrientVitaminPP => 'Vitamin PP (niacin)';

  @override
  String get nutrientVitaminB6 => 'Vitamin B6';

  @override
  String get nutrientVitaminB9 => 'Vitamin B9 (folate)';

  @override
  String get nutrientVitaminB12 => 'Vitamin B12';

  @override
  String get nutrientBiotin => 'Biotin';

  @override
  String get nutrientPantothenicAcid => 'Pantothenic acid';

  @override
  String get nutrientCholine => 'Choline';

  @override
  String get nutrientCaffeine => 'Caffeine';

  @override
  String get nutrientAlcohol => 'Alcohol';

  @override
  String get nutrientCocoa => 'Cocoa';

  @override
  String get nutrientFruitsVegetablesNuts => 'Fruits, vegetables, nuts';

  @override
  String get captureImages => 'Photos';

  @override
  String get nutritionTableImage => 'Nutrition table photo';

  @override
  String get ingredientsImage => 'Ingredients list photo';

  @override
  String get productImage => 'Product photo';

  @override
  String get saveProduct => 'Save product';

  @override
  String get saveToInventory => 'Save to inventory';

  @override
  String get submitProductToOff => 'Submit to Open Food Facts';

  @override
  String get offlineWarning => 'You are offline — adding product manually';

  @override
  String get nutriscoreExplanation => 'Nutri-Score is a nutrition label that rates products from A (best) to E (worst) based on their nutritional quality. It helps compare similar products at a glance.';

  @override
  String nutriscoreNotApplicable(Object category) {
    return 'Nutri-Score is not applicable to this product ($category).';
  }

  @override
  String get nutriscoreNotApplicableGeneric => 'Nutri-Score is not applicable to this product category.';

  @override
  String get flushCache => 'Flush cache';

  @override
  String get flushCacheSub => 'Delete cached product data and images';

  @override
  String get flushCacheConfirm => 'This will delete all cached product data and images fetched from Open Food Facts. Manually entered products and your inventory items will be preserved. Cached products will be re-fetched the next time you view them.';

  @override
  String get flushCacheSuccess => 'Cached products flushed. They will refresh automatically.';

  @override
  String get flushCacheFailed => 'Failed to flush cache. Please try again.';

  @override
  String get submissionPending => 'Pending submission to Open Food Facts';

  @override
  String get submissionSubmitted => 'Submitted to Open Food Facts';

  @override
  String get submissionFailed => 'Failed to submit product. Tap to retry.';

  @override
  String showInLanguage(String language) {
    return 'Show in $language';
  }

  @override
  String get ingredientsOriginal => 'Show original ingredients';

  @override
  String get ingredientsTranslated => 'Show translated ingredients';

  @override
  String get submissionNotSubmitted => 'Not submitted to Open Food Facts';

  @override
  String get submissionSuccess => 'Product submitted to Open Food Facts.';

  @override
  String get submissionError => 'Failed to submit product. Tap to retry.';

  @override
  String get submissionPartiallyCompleted => 'Partially submitted to Open Food Facts';

  @override
  String get submittingMetadata => 'Submitting product details to Open Food Facts…';

  @override
  String get preparingSubmission => 'Preparing submission…';

  @override
  String get submissionCredentialsError => 'Submission failed because Open Food Facts credentials are not configured.';

  @override
  String get submissionOfflineError => 'Could not reach Open Food Facts. Check your connection and retry.';

  @override
  String get submissionRateLimitedError => 'Open Food Facts rate-limited the request. Please wait and try again.';

  @override
  String get submissionRejectedError => 'Open Food Facts rejected the product data.';

  @override
  String get submissionValidationError => 'Open Food Facts rejected the product data because some fields are invalid.';

  @override
  String get submissionWrongCredentialsError => 'Open Food Facts rejected your credentials. Submission is disabled. Check the Open Food Facts credentials in the app configuration and use your username, not your email.';

  @override
  String get productAlreadyInOff => 'This product is already in Open Food Facts.';

  @override
  String get productAlreadyInOffTitle => 'Already in Open Food Facts';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navRecipes => 'Recipes';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get searchTitle => 'Search Products';

  @override
  String get searchProductsHint => 'Search for products by name or barcode';

  @override
  String get noSearchResults => 'No products found matching your search';

  @override
  String get productNotFoundSearch => 'No products found in Packaged Products.';

  @override
  String get productNotFoundBarcodeHint => 'Try scanning or entering the product’s barcode.';

  @override
  String get productNotFoundOfflineHint => 'Search requires an internet connection.';

  @override
  String get enterBarcodePrompt => 'Type or paste a barcode number';

  @override
  String get productNotInDatabase => 'This barcode is not registered with Open Food Facts.';

  @override
  String get productNotInDatabaseHint => 'You can still use this product locally.';

  @override
  String get saveLocallyAction => 'Save Locally';

  @override
  String totalItemsCount(Object count) {
    return 'Total items: $count';
  }

  @override
  String expiringSoonCount(Object count) {
    return 'Expiring soon: $count';
  }

  @override
  String addedThisWeek(Object count) {
    return 'Added this week: $count';
  }

  @override
  String get filterAll => 'All';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsDataManagement => 'Data Management';

  @override
  String get settingsMaintenance => 'Maintenance';

  @override
  String get whatsNewTitle => 'What\'s new';

  @override
  String whatsNewVersion(String version) {
    return 'Version $version';
  }

  @override
  String get whatsNewDismiss => 'Got it';

  @override
  String get settingsAbout => 'About';

  @override
  String get comingSoonDescription => 'This feature will be available soon.';

  @override
  String get priceTracking => 'Price Tracking';

  @override
  String get priceTrackingDescription => 'Record purchase prices and track how much you spend.';

  @override
  String get receiptTracking => 'NFC-e Receipts';

  @override
  String get receiptTrackingDescription => 'Scan tax receipts to add products.';

  @override
  String get photoCompletenessTitle => 'Photo Completeness';

  @override
  String get contributePhotos => 'Contribute to Open Food Facts';

  @override
  String offNeedsPhotos(Object count) {
    return 'OFF needs photos for $count products';
  }

  @override
  String get noCategories => 'No categories yet';

  @override
  String get statsEmptyTitle => 'No items to analyze';

  @override
  String get statsEmptySubtitle => 'Add products to your pantry to see statistics here.';

  @override
  String get addedThisWeekLabel => 'This week';

  @override
  String get addedThisMonthLabel => 'This month';

  @override
  String get productDataUnavailable => 'Product data unavailable — pull to refresh when online';

  @override
  String get locationStats => 'Locations';

  @override
  String get nutritionPhoto => 'Nutrition';

  @override
  String get ingredientsPhoto => 'Ingredients';

  @override
  String get productPhoto => 'Product';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get issueType => 'Issue type';

  @override
  String get bugReport => 'Bug Report';

  @override
  String get featureRequest => 'Feature Request';

  @override
  String get generalFeedback => 'General Feedback';

  @override
  String get regressionReport => 'Regression';

  @override
  String get bugReportExplanation => 'Something is broken or not working as expected.';

  @override
  String get featureRequestExplanation => 'Suggest a new feature or improvement.';

  @override
  String get generalFeedbackExplanation => 'Other comments, questions, or suggestions.';

  @override
  String get regressionReportExplanation => 'A feature that used to work but no longer does.';

  @override
  String get issueTitle => 'Title';

  @override
  String get issueTitleRequired => 'Title is required (min 5 characters)';

  @override
  String get issueDescription => 'Description';

  @override
  String get issueDescriptionRequired => 'Description is required (min 10 characters)';

  @override
  String get attachScreenshot => 'Attach screenshot';

  @override
  String get includeDeviceInfo => 'Include device info';

  @override
  String get sending => 'Sending...';

  @override
  String get issueCreate => 'Create issue';

  @override
  String get issueSubmitted => 'Thanks! Your report has been submitted.';

  @override
  String get issueQueuedOffline => 'You are offline. Your report will be submitted when you are back online.';

  @override
  String get issueSubmissionFailed => 'Failed to submit. Please try again.';

  @override
  String get viewOnGitHub => 'View on GitHub';

  @override
  String get issueDuplicate => 'You recently submitted a similar report.';

  @override
  String get removeScreenshot => 'Remove';

  @override
  String get nutriScore => 'Nutri-Score';

  @override
  String photoCoverageRatio(Object local, Object total) {
    return '$local / $total';
  }

  @override
  String offPhotosCount(Object off) {
    return 'OFF: $off';
  }

  @override
  String get couldNotAttachImage => 'Could not attach image';

  @override
  String get appVersionLabel => 'App version';

  @override
  String get osLabel => 'OS';

  @override
  String get cameraPermissionDenied => 'Camera permission denied. Grant access in Settings.';

  @override
  String get cameraPermissionDeniedTitle => 'Camera permission needed';

  @override
  String get cameraPermissionDeniedBody => 'Pantry needs camera access to take product photos.';

  @override
  String get galleryPermissionDeniedTitle => 'Gallery access needed';

  @override
  String get galleryPermissionDeniedBody => 'Pantry needs access to your photos to choose an existing photo. Open Settings to allow access.';

  @override
  String get cameraNotAvailable => 'Camera not available on this device.';

  @override
  String get scannerGenericError => 'An unexpected error occurred while starting the camera.';

  @override
  String get switchToManualEntry => 'Enter barcode manually';

  @override
  String get retryScan => 'Retry';

  @override
  String get couldNotOpenSettings => 'Could not open Settings.';

  @override
  String get toggleTorch => 'Toggle flashlight';

  @override
  String get close => 'Close';

  @override
  String get retakePhoto => 'Retake photo';

  @override
  String get replacePhoto => 'Replace photo';

  @override
  String get deletePhoto => 'Delete photo';

  @override
  String get cropPhoto => 'Crop photo';

  @override
  String get photoRemoved => 'Photo removed.';

  @override
  String get applyCrop => 'Apply';

  @override
  String get rotateLeft => 'Rotate left';

  @override
  String get rotateRight => 'Rotate right';

  @override
  String get cropFailed => 'Could not crop photo.';

  @override
  String get cropTooSmall => 'The cropped photo is too small. Crop a larger area.';

  @override
  String get choosePhotoSourceTitle => 'Choose photo source';

  @override
  String get addPhotoSlot => 'Add photo';

  @override
  String get previewPhoto => 'Preview photo';

  @override
  String get photoSourceCamera => 'Take a new photo';

  @override
  String get photoSourceGallery => 'Choose an existing photo';

  @override
  String get takePhoto => 'Take photo';

  @override
  String uploadingPhotos(int current, int total) {
    return 'Uploading photo $current of $total…';
  }

  @override
  String photoSlotAction(Object action, Object label) {
    return '$action $label';
  }

  @override
  String get inactivityReminderTitle => 'Time to restock your pantry?';

  @override
  String inactivityReminderBody(int days) {
    return 'You haven\'t added any products in $days days.';
  }

  @override
  String get inactivityReminderEnabled => 'Remind me to add products regularly';

  @override
  String get inactivityThresholdDays => 'Inactivity threshold (days)';

  @override
  String get inactivityReminderChannelName => 'Inactivity reminders';

  @override
  String get inactivityReminderChannelDescription => 'Reminds you to add products regularly';

  @override
  String get notificationDeniedWarning => 'Notifications are disabled. Expiry and inactivity reminders will only show when you open the app. Enable them in Settings at any time.';

  @override
  String inactivityThresholdSet(int days) {
    return 'Inactivity threshold set to $days days.';
  }

  @override
  String get amoledDarkMode => 'AMOLED dark mode';

  @override
  String get amoledDarkModeExplanation => 'Use pure black surfaces in dark mode to save power on AMOLED displays';

  @override
  String get amoledDarkModeEnabled => 'AMOLED dark mode enabled.';

  @override
  String get amoledDarkModeDisabled => 'AMOLED dark mode disabled.';

  @override
  String get amoledNudgeTitle => 'Switch to dark mode?';

  @override
  String get amoledNudgeBody => 'Dark mode can save battery life on your device, especially if it has an AMOLED screen. You can also enable pure-black surfaces in Settings for maximum power savings.';

  @override
  String get amoledNudgeEnable => 'Enable dark mode';

  @override
  String get amoledNudgeDismiss => 'Not now';

  @override
  String get translationReport => 'Translation Report';

  @override
  String get translationReportExplanation => 'Report an issue with a product translation or suggest a new translation.';

  @override
  String get feedbackRateLimit => 'You can only submit one report per minute and up to 5 per day. Please try again later.';

  @override
  String get couldNotOpenLinkFallback => 'URL copied to clipboard.';

  @override
  String get includeLogs => 'Include app logs';

  @override
  String get includeLogsExplanation => 'Recent warnings and errors from this session';

  @override
  String get logsPrivacyNote => 'Logs may contain product names and timestamps.';

  @override
  String get price => 'Price';

  @override
  String get prices => 'Prices';

  @override
  String get addPrice => 'Price saved';

  @override
  String get editPrice => 'Edit price';

  @override
  String get deletePrice => 'Delete price';

  @override
  String get priceAdded => 'Price added.';

  @override
  String get priceUpdated => 'Price updated.';

  @override
  String get priceDeleted => 'Price deleted.';

  @override
  String get priceHistory => 'Price history';

  @override
  String get noPrices => 'No prices recorded.';

  @override
  String get recentPrices => 'Recent prices';

  @override
  String get viewAllPrices => 'View all';

  @override
  String get noPriceTrend => 'Add at least two prices to see the trend.';

  @override
  String get totalValue => 'Total value';

  @override
  String get averagePrice => 'Average item price';

  @override
  String get showPrices => 'Show prices';

  @override
  String get hidePrices => 'Hide prices for privacy';

  @override
  String get hidePricesDescription => 'Replace price values with masked text everywhere, including the stats screen.';

  @override
  String get pricesHidden => 'Prices hidden.';

  @override
  String get pricesVisible => 'Prices visible.';

  @override
  String get priceTrackingEnabled => 'Enable price tracking';

  @override
  String get priceRetentionDays => 'Price retention';

  @override
  String priceRetentionDaysValue(int days) {
    return 'Keep prices for $days days (0 = keep forever)';
  }

  @override
  String get currency => 'Currency';

  @override
  String get baseCurrency => 'Base currency';

  @override
  String get baseCurrencyDescription => 'All prices are shown in this currency.';

  @override
  String get store => 'Store';

  @override
  String get addNewStore => 'Add new store';

  @override
  String get storeAdded => 'Store added';

  @override
  String get storeAlreadyExists => 'A store with this name already exists';

  @override
  String get storeName => 'Store name';

  @override
  String get discounted => 'Discounted';

  @override
  String get regularPrice => 'Regular price';

  @override
  String get confirmDeletePrice => 'Delete this price entry?';

  @override
  String get syncToOpenPrices => 'Share with Open Prices';

  @override
  String get syncToOpenPricesDescription => 'Contribute your price data to the community food-price database.';

  @override
  String get openPricesToken => 'Open Prices API Token';

  @override
  String get openPricesTokenDescription => 'Token generated from your Open Food Facts account.';

  @override
  String get openPricesTokenSaved => 'Token saved.';

  @override
  String get openPricesSyncStarted => 'Syncing prices...';

  @override
  String openPricesSyncComplete(int count) {
    return '$count prices synced.';
  }

  @override
  String get priceSyncStatus => 'Synced';

  @override
  String get priceSyncPending => 'Pending sync';

  @override
  String get priceSyncFailed => 'Sync failed';

  @override
  String get priceTrendUp => 'Prices are rising';

  @override
  String get priceTrendDown => 'Prices are falling';

  @override
  String get priceTrendStable => 'Prices are stable';

  @override
  String get datePurchased => 'Purchase date';

  @override
  String itemWithPriceCount(int count, int total) {
    return '$count of $total items have prices';
  }

  @override
  String get openPricesProofExplanation => 'To share with Open Prices, a photo of the receipt or shelf label is required as proof. Prices without a photo stay in your local pantry only.';

  @override
  String get openPricesConsentTitle => 'Contribute to Open Prices';

  @override
  String get openPricesConsentBody => 'Open Prices is a community database of food prices. To contribute, a photo of the receipt or shelf label is required as proof.\n\nWhen you add or edit a price, you will have the option to take a proof photo. Prices without a photo stay in your local pantry and are not shared.';

  @override
  String get iUnderstand => 'I understand';

  @override
  String get notes => 'Notes';

  @override
  String get navList => 'List';

  @override
  String get shoppingList => 'Shopping List';

  @override
  String get addShoppingItem => 'Add item';

  @override
  String get itemName => 'Item name';

  @override
  String get markPurchased => 'Mark purchased';

  @override
  String get unmarkPurchased => 'Unmark purchased';

  @override
  String get moveToInventory => 'Move to pantry';

  @override
  String get addAgain => 'Add again';

  @override
  String get emptyShoppingList => 'Your shopping list is empty';

  @override
  String get emptyShoppingListSub => 'Add items from a product or tap + to add manually';

  @override
  String get deleteItem => 'Delete item';

  @override
  String get clearPurchased => 'Clear purchased';

  @override
  String get clearPurchasedConfirm => 'Remove all purchased items?';

  @override
  String get purchasedItems => 'Purchased';

  @override
  String get pendingItems => 'To buy';

  @override
  String get quickAddHint => 'Name, e.g. Milk';

  @override
  String get undoDeleteShoppingItem => 'Item deleted';

  @override
  String get undoClearPurchased => 'Purchased items cleared';

  @override
  String get shareShoppingList => 'Share shopping list';

  @override
  String get add => 'Add';

  @override
  String get quantity => 'Quantity';

  @override
  String get addToShoppingList => 'Add to shopping list';

  @override
  String get addToShoppingListTooltip => 'Shopping list';

  @override
  String get productSearchHint => 'Search products by name';

  @override
  String get addCustomItem => 'Add custom item';

  @override
  String get noProductsFound => 'No products found. Try a custom item.';

  @override
  String get backToSearch => 'Back to search';

  @override
  String get removePrice => 'Price removed';

  @override
  String shoppingTotal(String total) {
    return 'Total: $total';
  }

  @override
  String shoppingMixedCurrency(String total) {
    return '$total';
  }

  @override
  String get addToInventoryFromList => 'Add to pantry';

  @override
  String addToInventoryConfirm(int count, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: ' $skipped items without a barcode will stay in your list.',
      one: ' 1 item without a barcode will stay in your list.',
      zero: '',
    );
    return 'Add $count items to your pantry? Prices will be saved.$_temp0';
  }

  @override
  String itemsMovedToInventory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items added to pantry',
      one: '1 item added to pantry',
    );
    return '$_temp0';
  }

  @override
  String itemsSkippedNoBarcode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items left — add a barcode or create a product to move them',
      one: '1 item left — add a barcode or create a product to move it',
    );
    return '$_temp0';
  }

  @override
  String get addToPantryAfterPrice => 'Add to your pantry?';

  @override
  String get addToPantryAfterPriceDesc => 'Record the amount you bought to track it in your inventory.';

  @override
  String get howManyBought => 'How many did you buy?';

  @override
  String get choosePantry => 'Choose a pantry';

  @override
  String get addToPantrySkipped => 'Price saved. Add from product page to track inventory.';

  @override
  String get invalidPriceAmount => 'Enter a valid price amount';

  @override
  String get apiSearchWarning => 'Could not fetch all online results. Some products may be missing.';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get priceHidden => 'Price hidden';

  @override
  String get scanFailed => 'Barcode scan failed.';

  @override
  String get testNotification => 'Send test notification';

  @override
  String get testScheduledNotification => 'Send scheduled test notification (2 min)';

  @override
  String get testNotificationScheduled => 'Test notification scheduled.';

  @override
  String get testNotificationSent => 'Test notification sent.';

  @override
  String get testNotificationFailed => 'Failed to send test notification.';

  @override
  String selectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items selected',
      one: '1 item selected',
      zero: 'No items selected',
    );
    return '$_temp0';
  }

  @override
  String get moveButton => 'Move';

  @override
  String get noOtherInventories => 'No other pantries available.';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get defaultInventoryName => 'Home';

  @override
  String get locationPantry => 'Pantry';

  @override
  String get locationFridge => 'Fridge';

  @override
  String get locationFreezer => 'Freezer';

  @override
  String get unitSingular => 'unit';

  @override
  String get unitPlural => 'units';

  @override
  String get weightModeLabel => 'Weight (g)';

  @override
  String get unitModeLabel => 'Unit';

  @override
  String get servingSmall => 'Small';

  @override
  String get servingMedium => 'Medium';

  @override
  String get servingLarge => 'Large';

  @override
  String get unitGrams => 'g';

  @override
  String get unitKg => 'kg';

  @override
  String get unitMl => 'ml';

  @override
  String get unitLiter => 'L';

  @override
  String get pricePerPiece => '/unit';

  @override
  String get pricePerHundredGrams => '/100 g';

  @override
  String get pricePerKilogram => '/kg';

  @override
  String get pricePerLiter => '/L';

  @override
  String get pricePerHundredMilliliters => '/100 ml';

  @override
  String get packageQuantity => 'Package quantity';

  @override
  String get packageUnit => 'Package unit';

  @override
  String get generalNotificationChannelName => 'General Notifications';

  @override
  String get generalNotificationChannelDescription => 'Standard app notifications';

  @override
  String get testNotificationTitle => 'Test Successful';

  @override
  String get testNotificationBody => 'Immediate notifications are working!';

  @override
  String get testScheduledTitle => 'Scheduled Test';

  @override
  String get testScheduledBody => 'This fired 5 seconds later.';

  @override
  String get retryNow => 'Retry now';

  @override
  String get bearerTokenLabel => 'Bearer token';

  @override
  String pendingFeedback(Object count) {
    return 'Pending feedback: $count';
  }

  @override
  String submissionResult(Object failed, Object submitted) {
    return 'Submitted $submitted, $failed failed';
  }

  @override
  String bytesUnit(Object bytes) {
    return '$bytes B';
  }

  @override
  String kbUnit(Object size) {
    return '$size KB';
  }

  @override
  String mbUnit(Object size) {
    return '$size MB';
  }

  @override
  String get unreleasedVersion => 'Unreleased';

  @override
  String get categoryDairy => 'Dairy';

  @override
  String get categoryMilks => 'Milks';

  @override
  String get categoryMilk => 'Milk';

  @override
  String get categoryYogurts => 'Yogurts';

  @override
  String get categoryCheeses => 'Cheeses';

  @override
  String get categoryEggsAndProducts => 'Eggs and their products';

  @override
  String get categoryMeats => 'Meats';

  @override
  String get categoryFishesAndSeafoods => 'Fishes and seafoods';

  @override
  String get categoryBeverages => 'Beverages';

  @override
  String get categoryAlcoholicBeverages => 'Alcoholic beverages';

  @override
  String get categoryBreads => 'Breads';

  @override
  String get categoryCerealsAndPotatoes => 'Cereals and potatoes';

  @override
  String get categoryFruitsAndVegetables => 'Fruits and vegetables based foods';

  @override
  String get categoryConfectioneries => 'Confectioneries';

  @override
  String get categorySugarySnacks => 'Sugary snacks';

  @override
  String get categorySaltySnacks => 'Salty snacks';

  @override
  String get categoryFats => 'Fats';

  @override
  String get categorySauces => 'Sauces';

  @override
  String get categorySoups => 'Soups';

  @override
  String get categoryPreparedMeals => 'Prepared meals';

  @override
  String get categoryFrozenFoods => 'Frozen foods';

  @override
  String get categoryDesserts => 'Desserts';

  @override
  String get categoryPastries => 'Pastries';

  @override
  String get categoryBiscuitsAndCakes => 'Biscuits and cakes';

  @override
  String get categoryPizzas => 'Pizzas';

  @override
  String get categorySandwiches => 'Sandwiches';

  @override
  String get categoryBabyFoods => 'Baby foods';

  @override
  String get categoryDietaryFoods => 'Dietary foods';

  @override
  String get categorySpicesAndHerbs => 'Spices and herbs';

  @override
  String get categoryNutsAndProducts => 'Nuts and their products';

  @override
  String get categoryPlantBasedFoods => 'Plant based foods';

  @override
  String get categoryLegumesAndProducts => 'Legumes and their products';

  @override
  String get categoryCoffees => 'Coffees';

  @override
  String get categoryTeas => 'Teas';

  @override
  String get categoryChocolateProducts => 'Chocolate products';

  @override
  String get categoryIceCreams => 'Ice creams';

  @override
  String get categoryFruitJuices => 'Fruit juices';

  @override
  String get categorySodas => 'Sodas';

  @override
  String get categoryWaters => 'Waters';

  @override
  String get categoryMeatAndProducts => 'Meat and their products';

  @override
  String get categoryBreakfasts => 'Breakfasts';

  @override
  String get categoryBread => 'Bread';

  @override
  String get categoryCakes => 'Cakes';

  @override
  String get categoryCereals => 'Cereals';

  @override
  String get categoryChocolate => 'Chocolate';

  @override
  String get categoryCondiments => 'Condiments';

  @override
  String get categoryEggs => 'Eggs';

  @override
  String get categoryFish => 'Fish';

  @override
  String get categoryFruit => 'Fruit';

  @override
  String get categoryFruits => 'Fruits';

  @override
  String get categoryGrains => 'Grains';

  @override
  String get categoryHotBeverages => 'Hot beverages';

  @override
  String get categoryLegumes => 'Legumes';

  @override
  String get categoryOils => 'Oils';

  @override
  String get categoryPasta => 'Pasta';

  @override
  String get categoryPoultry => 'Poultry';

  @override
  String get categorySeeds => 'Seeds';

  @override
  String get categorySnacks => 'Snacks';

  @override
  String get categorySpreads => 'Spreads';

  @override
  String get categorySweetSpreads => 'Sweet spreads';

  @override
  String get categoryVegetables => 'Vegetables';

  @override
  String get categoryBiscuitsAndCrackers => 'Biscuits and crackers';

  @override
  String get categoryLegumeOils => 'Legume oils';

  @override
  String get categoryUhtMilks => 'UHT milks';

  @override
  String get categoryCannedSardines => 'Canned sardines';

  @override
  String get categoryCerealFlours => 'Cereal flours';

  @override
  String get categoryCerealStarches => 'Cereal starches';

  @override
  String get categoryCerealsAndProducts => 'Cereals and their products';

  @override
  String get categoryDairies => 'Dairies';

  @override
  String get categoryInstantBeverages => 'Instant beverages';

  @override
  String get categoryMilkfat => 'Milkfat';

  @override
  String get categoryStarches => 'Starches';

  @override
  String get pluEntryTooltip => 'Enter PLU code (produce)';

  @override
  String get enterPluCode => 'Enter PLU Code';

  @override
  String get pluCodeNotFound => 'PLU code not recognized';

  @override
  String get digitLabel => 'Digit';

  @override
  String get deleteDigit => 'Delete digit';

  @override
  String get fromYourPantry => 'From your pantry';

  @override
  String get inYourPantry => 'In your pantry';

  @override
  String get monthlySpendingTitle => 'Monthly spending';

  @override
  String get storeSpendingTitle => 'Spending by store';

  @override
  String get nutriscoreByStoreTitle => 'Nutri-Score by store';

  @override
  String get noStoreData => 'No purchase data yet';

  @override
  String get noSpendingData => 'Add prices to see spending trends';

  @override
  String get monthLabel => 'Month';

  @override
  String get averageScore => 'Avg. score';

  @override
  String get produceApple => 'Apple';

  @override
  String get produceBanana => 'Banana';

  @override
  String get produceOrange => 'Orange';

  @override
  String get produceTomato => 'Tomato';

  @override
  String get producePotato => 'Potato';

  @override
  String get produceCarrot => 'Carrot';

  @override
  String get produceOnion => 'Onion';

  @override
  String get produceLettuce => 'Lettuce';

  @override
  String get exactAlarmsDeniedHint => 'Scheduled test notifications may be delayed because exact alarms are not granted. Grant it in Settings > Notifications > Schedule exact alarms.';

  @override
  String get notificationRationaleTitle => 'Notifications help you keep track';

  @override
  String get notificationRationaleBody => 'Pantry uses notifications to:\n\n- Remind you when food is about to expire\n- Nudge you to add products regularly\n- Confirm that test notifications work\n\nYou can change this anytime in Settings.';

  @override
  String get notificationRationaleAllow => 'Allow';

  @override
  String get notificationRationaleNotNow => 'Not now';

  @override
  String get addProduct => 'Add product';

  @override
  String get addProductSubtitle => 'Search by barcode or name';

  @override
  String get registerRecipe => 'Register a recipe';

  @override
  String get registerRecipeSubtitle => 'Save recipes with cost tracking';

  @override
  String get scanBarcodeSubtitle => 'Snap or type a barcode';

  @override
  String get marketTrip => 'Market trip';

  @override
  String get marketTripSubtitle => 'Scan items in sequence';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get recipes => 'Recipes';

  @override
  String get editRecipe => 'Edit recipe';

  @override
  String get recipeName => 'Recipe name';

  @override
  String get recipeNameHint => 'e.g. Chicken Sandwich';

  @override
  String get recipeNameRequired => 'Recipe name is required';

  @override
  String get recipeInstructions => 'Instructions';

  @override
  String get recipeInstructionsHint => 'Describe how to prepare...';

  @override
  String get recipeIngredients => 'Ingredients';

  @override
  String get ingredientName => 'Ingredient name';

  @override
  String get ingredientQuantity => 'Qty';

  @override
  String get ingredientUnit => 'Unit';

  @override
  String get addIngredient => 'Add ingredient';

  @override
  String get selectFromPantry => 'Select items from your pantry';

  @override
  String get addSelected => 'Add selected';

  @override
  String get servings => 'Servings';

  @override
  String get servingsHint => 'e.g. 4';

  @override
  String get setServingsHint => 'Set the number of servings in the recipe editor to see per-portion nutrition';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get costPerServing => 'Cost per serving';

  @override
  String get recipeNutritionPerServing => 'Per serving';

  @override
  String get recipeNutriScore => 'Nutri-Score';

  @override
  String get recipeNoIngredients => 'Recipe has no ingredients';

  @override
  String recipeShortage(String name, double amount) {
    return 'Not enough $name: need $amount more';
  }

  @override
  String get saveRecipe => 'Save recipe';

  @override
  String get recipeSaved => 'Recipe saved';

  @override
  String get recipeDeleted => 'Recipe deleted';

  @override
  String get noRecipes => 'No recipes yet';

  @override
  String get noRecipesSubtitle => 'Register recipes to track costs and plan meals';

  @override
  String get discardChanges => 'Discard changes?';

  @override
  String get discardChangesConfirm => 'You have unsaved changes. Discard them?';

  @override
  String get recipeCost => 'Recipe cost';

  @override
  String get recipeCostUnknown => 'Unknown';

  @override
  String get recipeAverageCost => 'Average recipe cost';

  @override
  String ingredientCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingredients',
      one: '$count ingredient',
    );
    return '$_temp0';
  }

  @override
  String get deleteRecipeConfirm => 'Delete this recipe?';

  @override
  String get madeRecipe => 'I made this';

  @override
  String get cookRecipeSuccess => 'Recipe made';

  @override
  String get recipeCookFailed => 'Failed to cook recipe';

  @override
  String get confirmDiscard => 'Discard changes?';

  @override
  String get confirmDiscardContent => 'You have unsaved changes. Are you sure you want to go back?';

  @override
  String get searchProduct => 'Search product';

  @override
  String get history => 'History';

  @override
  String get noHistory => 'No cooking history yet';

  @override
  String get onboardingPage1Title => 'Scan Barcodes';

  @override
  String get onboardingPage1Desc => 'Quickly add products to your pantry by scanning their barcodes with your camera.';

  @override
  String get onboardingPage1Cta => 'Open Scanner';

  @override
  String get onboardingPage2Title => 'Search Products';

  @override
  String get onboardingPage2Desc => 'Browse millions of products from the Open Food Facts database to find exactly what you need.';

  @override
  String get onboardingPage2Cta => 'Open Search';

  @override
  String get onboardingPage3Title => 'Fresh Produce';

  @override
  String get onboardingPage3Desc => 'Add common fruits and vegetables with a single tap. Perfect for bananas, apples, tomatoes, and more.';

  @override
  String get onboardingPage3Cta => 'Add Produce';

  @override
  String get onboardingPage4Title => 'Configure Your Pantry';

  @override
  String get onboardingPage4Desc => 'Set up price tracking, currency, and data preferences to get the most out of Pantry.';

  @override
  String get onboardingPage4Cta => 'Set Up';

  @override
  String get onboardingPage5Title => 'Track Everything';

  @override
  String get onboardingPage5Desc => 'Monitor expiry dates, track prices, create shopping lists, and reduce food waste.';

  @override
  String get onboardingPage5Cta => 'Get Started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingBack => 'Back';

  @override
  String get searchSourceLabel => 'Search in';

  @override
  String get searchSourceOff => 'Packaged Products';

  @override
  String get searchSourceUsda => 'Fresh Produce';

  @override
  String get searchSourceInventory => 'My Pantry';

  @override
  String get inPantryIndicator => 'In Pantry';

  @override
  String get inPantryFilter => 'In Pantry';

  @override
  String get inPantryEmpty => 'No products in your pantry match this search';

  @override
  String get inPantrySwipeLabel => 'Already in pantry';

  @override
  String get units => 'Units';

  @override
  String get unitSystemMetric => 'Metric';

  @override
  String get unitSystemImperial => 'Imperial';

  @override
  String get perContextOverrides => 'Per-context overrides';

  @override
  String get servingSizeContext => 'Serving size';

  @override
  String get recipeIngredientsContext => 'Recipe ingredients';

  @override
  String get inventoryContext => 'Inventory';

  @override
  String get systemDefault => 'System default';

  @override
  String get imperialPreferences => 'Imperial preferences';

  @override
  String get weightPreference => 'Weight preference';

  @override
  String get volumePreference => 'Volume preference';

  @override
  String get weightOz => 'Ounces (oz)';

  @override
  String get weightLb => 'Pounds (lb)';

  @override
  String get weightAuto => 'Auto';

  @override
  String get volumeFlOz => 'Fluid ounces';

  @override
  String get volumeCup => 'Cups';

  @override
  String get volumeTbsp => 'Tablespoons';

  @override
  String get volumeTsp => 'Teaspoons';

  @override
  String get volumeAuto => 'Auto';

  @override
  String unitSystemChanged(String system) {
    return 'Units: $system';
  }
}
