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
  String get invalidBarcode => 'Enter a valid barcode (8-13 digits).';

  @override
  String get brandLabel => 'Brand';

  @override
  String get categoryLabel => 'Category';

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
  String get itemAdded => 'Item added to pantry.';

  @override
  String get itemRemoved => 'Item removed from pantry.';

  @override
  String get saveFailed => 'Failed to save inventory item.';

  @override
  String get deleteInventoryItem => 'Delete items?';

  @override
  String deleteCountSub(Object count) {
    return 'Delete $count selected items?';
  }

  @override
  String itemsDeleted(Object count) {
    return '$count deleted.';
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
  String get nutrient => 'Nutrient';

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
  String get couldNotRenameInventory => 'Could not rename inventory.';

  @override
  String get couldNotDeleteInventory => 'Could not delete inventory.';

  @override
  String get networkError => 'Network error. Please check your connection.';

  @override
  String get productNotFound => 'Product not found in database.';

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
  String expiresTomorrow(String barcode) {
    return '$barcode expires tomorrow';
  }

  @override
  String expiresToday(String barcode) {
    return '$barcode expires today!';
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
  String get servingSizeHint => 'e.g. 100 g, 1 cookie (28 g)';

  @override
  String get nutritionInfo => 'Nutrition (per 100 g / 100 ml)';

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
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

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
  String get filterByCategory => 'Category';

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
  String get locationStats => 'Location';

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
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

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
  String get addPrice => 'Add price';

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
  String get totalValue => 'Total value';

  @override
  String get averagePrice => 'Average item price';

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
  String get pricedItems => 'Items with prices';

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
  String get invalidPriceAmount => 'Enter a valid price amount';

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
}
