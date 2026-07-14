import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
    Locale('pt', 'BR')
  ];

  /// No description provided for @myPantry.
  ///
  /// In en, this message translates to:
  /// **'My Pantry'**
  String get myPantry;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @enterBarcode.
  ///
  /// In en, this message translates to:
  /// **'Enter Barcode'**
  String get enterBarcode;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @expiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get expiringSoon;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or barcode'**
  String get searchHint;

  /// No description provided for @noItemsMatch.
  ///
  /// In en, this message translates to:
  /// **'No items match your search'**
  String get noItemsMatch;

  /// No description provided for @emptyPantryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your pantry is empty'**
  String get emptyPantryTitle;

  /// No description provided for @emptyPantrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to scan your first product'**
  String get emptyPantrySubtitle;

  /// No description provided for @scanFirstProduct.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode'**
  String get scanFirstProduct;

  /// No description provided for @barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeLabel;

  /// No description provided for @invalidBarcode.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid barcode (8-13 digits).'**
  String get invalidBarcode;

  /// No description provided for @brandLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brandLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoryLabel;

  /// No description provided for @servingSize.
  ///
  /// In en, this message translates to:
  /// **'Serving size'**
  String get servingSize;

  /// No description provided for @energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energy;

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fat;

  /// No description provided for @fiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get fiber;

  /// No description provided for @salt.
  ///
  /// In en, this message translates to:
  /// **'Salt'**
  String get salt;

  /// No description provided for @per100g.
  ///
  /// In en, this message translates to:
  /// **'Per 100 g'**
  String get per100g;

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @yourInventory.
  ///
  /// In en, this message translates to:
  /// **'Your inventory'**
  String get yourInventory;

  /// No description provided for @noItemsInPantry.
  ///
  /// In en, this message translates to:
  /// **'No items in pantry yet.'**
  String get noItemsInPantry;

  /// No description provided for @addToInventory.
  ///
  /// In en, this message translates to:
  /// **'Add to Inventory'**
  String get addToInventory;

  /// No description provided for @copyBarcode.
  ///
  /// In en, this message translates to:
  /// **'Copy barcode'**
  String get copyBarcode;

  /// No description provided for @barcodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Barcode copied!'**
  String get barcodeCopied;

  /// No description provided for @removedFromPantry.
  ///
  /// In en, this message translates to:
  /// **'Removed from pantry.'**
  String get removedFromPantry;

  /// No description provided for @updateItem.
  ///
  /// In en, this message translates to:
  /// **'Update Item'**
  String get updateItem;

  /// No description provided for @addToPantry.
  ///
  /// In en, this message translates to:
  /// **'Add to Pantry'**
  String get addToPantry;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @expiryDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Expiry date (optional)'**
  String get expiryDateOptional;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDate;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @expiryNotifications.
  ///
  /// In en, this message translates to:
  /// **'Expiry notifications'**
  String get expiryNotifications;

  /// No description provided for @remindBeforeExpiry.
  ///
  /// In en, this message translates to:
  /// **'Remind before food expires'**
  String get remindBeforeExpiry;

  /// No description provided for @dataRetention.
  ///
  /// In en, this message translates to:
  /// **'Data retention'**
  String get dataRetention;

  /// No description provided for @manageInventories.
  ///
  /// In en, this message translates to:
  /// **'Manage Inventories'**
  String get manageInventories;

  /// No description provided for @manageInventoriesSub.
  ///
  /// In en, this message translates to:
  /// **'Create, rename, or delete pantries'**
  String get manageInventoriesSub;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose theme'**
  String get chooseTheme;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @pantryStats.
  ///
  /// In en, this message translates to:
  /// **'Pantry Stats'**
  String get pantryStats;

  /// No description provided for @totalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total products'**
  String get totalProducts;

  /// No description provided for @inventoryItems.
  ///
  /// In en, this message translates to:
  /// **'Inventory items'**
  String get inventoryItems;

  /// No description provided for @createNewPantry.
  ///
  /// In en, this message translates to:
  /// **'Create new pantry'**
  String get createNewPantry;

  /// No description provided for @newPantry.
  ///
  /// In en, this message translates to:
  /// **'New pantry'**
  String get newPantry;

  /// No description provided for @renamePantry.
  ///
  /// In en, this message translates to:
  /// **'Rename pantry'**
  String get renamePantry;

  /// No description provided for @deletePantry.
  ///
  /// In en, this message translates to:
  /// **'Delete pantry?'**
  String get deletePantry;

  /// No description provided for @deletePantryContent.
  ///
  /// In en, this message translates to:
  /// **'All items in \"{name}\" will be permanently deleted.'**
  String deletePantryContent(String name);

  /// No description provided for @manualEntryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Enter barcode manually'**
  String get manualEntryTooltip;

  /// No description provided for @cameraTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scan with camera'**
  String get cameraTooltip;

  /// No description provided for @typeOrPasteBarcode.
  ///
  /// In en, this message translates to:
  /// **'Type or paste a barcode'**
  String get typeOrPasteBarcode;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @itemUpdated.
  ///
  /// In en, this message translates to:
  /// **'Item updated.'**
  String get itemUpdated;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product updated.'**
  String get productUpdated;

  /// No description provided for @itemAdded.
  ///
  /// In en, this message translates to:
  /// **'Item added to pantry.'**
  String get itemAdded;

  /// No description provided for @itemRemoved.
  ///
  /// In en, this message translates to:
  /// **'Item removed from pantry.'**
  String get itemRemoved;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save inventory item.'**
  String get saveFailed;

  /// No description provided for @deleteInventoryItem.
  ///
  /// In en, this message translates to:
  /// **'Delete items?'**
  String get deleteInventoryItem;

  /// No description provided for @deleteCountSub.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 selected item?} other{Delete {count} selected items?}}'**
  String deleteCountSub(num count);

  /// No description provided for @itemsRestored.
  ///
  /// In en, this message translates to:
  /// **'Items restored.'**
  String get itemsRestored;

  /// No description provided for @selectItems.
  ///
  /// In en, this message translates to:
  /// **'Select items'**
  String get selectItems;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete item.'**
  String get deleteFailed;

  /// No description provided for @moveToPantry.
  ///
  /// In en, this message translates to:
  /// **'Move to pantry'**
  String get moveToPantry;

  /// No description provided for @moveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to move items.'**
  String get moveFailed;

  /// No description provided for @inventoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load inventory.'**
  String get inventoryLoadFailed;

  /// No description provided for @expiryPrefix.
  ///
  /// In en, this message translates to:
  /// **'Exp'**
  String get expiryPrefix;

  /// No description provided for @switchPantry.
  ///
  /// In en, this message translates to:
  /// **'Switch pantry'**
  String get switchPantry;

  /// No description provided for @couldNotOpenPlayStore.
  ///
  /// In en, this message translates to:
  /// **'Could not open the Play Store.'**
  String get couldNotOpenPlayStore;

  /// No description provided for @viewOnOpenFoodFacts.
  ///
  /// In en, this message translates to:
  /// **'View on Open Food Facts'**
  String get viewOnOpenFoodFacts;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get couldNotOpenLink;

  /// No description provided for @nutrient.
  ///
  /// In en, this message translates to:
  /// **'Nutrients'**
  String get nutrient;

  /// No description provided for @deleteItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete item?'**
  String get deleteItemTitle;

  /// No description provided for @deleteItemContent.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteItemContent;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @failedToLoadInventoryItems.
  ///
  /// In en, this message translates to:
  /// **'Failed to load inventory items.'**
  String get failedToLoadInventoryItems;

  /// No description provided for @enterPositiveNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive number'**
  String get enterPositiveNumber;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled.'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled.'**
  String get notificationsDisabled;

  /// No description provided for @notificationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission Required'**
  String get notificationPermissionTitle;

  /// No description provided for @notificationPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'To receive expiry reminders, grant notification permission in your device settings.'**
  String get notificationPermissionBody;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @themeChanged.
  ///
  /// In en, this message translates to:
  /// **'Theme: {theme}'**
  String themeChanged(String theme);

  /// No description provided for @retentionDaysValue.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String retentionDaysValue(int days);

  /// No description provided for @dataRetentionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Data retention (days)'**
  String get dataRetentionDialogTitle;

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get daysLabel;

  /// No description provided for @retentionPeriodSet.
  ///
  /// In en, this message translates to:
  /// **'Retention period set to {days} days.'**
  String retentionPeriodSet(int days);

  /// No description provided for @noInventories.
  ///
  /// In en, this message translates to:
  /// **'No inventories.'**
  String get noInventories;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'Items: {count}'**
  String itemsCount(int count);

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @inventoryCreated.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" created.'**
  String inventoryCreated(String name);

  /// No description provided for @inventoryRenamed.
  ///
  /// In en, this message translates to:
  /// **'Renamed to \"{name}\".'**
  String inventoryRenamed(String name);

  /// No description provided for @inventoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" deleted.'**
  String inventoryDeleted(String name);

  /// No description provided for @couldNotCreateInventory.
  ///
  /// In en, this message translates to:
  /// **'Could not create inventory.'**
  String get couldNotCreateInventory;

  /// No description provided for @couldNotRenameInventory.
  ///
  /// In en, this message translates to:
  /// **'Could not rename inventory.'**
  String get couldNotRenameInventory;

  /// No description provided for @couldNotDeleteInventory.
  ///
  /// In en, this message translates to:
  /// **'Could not delete inventory.'**
  String get couldNotDeleteInventory;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkError;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found in database.'**
  String get productNotFound;

  /// No description provided for @productNotFoundHint.
  ///
  /// In en, this message translates to:
  /// **'This product isn\'t in the Open Food Facts database yet. You can add it manually or contribute it to the community.'**
  String get productNotFoundHint;

  /// No description provided for @addManually.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get addManually;

  /// No description provided for @contributeToOpenFoodFacts.
  ///
  /// In en, this message translates to:
  /// **'Contribute to Open Food Facts'**
  String get contributeToOpenFoodFacts;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @expiringSoonDays.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon threshold'**
  String get expiringSoonDays;

  /// No description provided for @expiringSoonDaysValue.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String expiringSoonDaysValue(int days);

  /// No description provided for @expiringSoonDaysDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon threshold (days)'**
  String get expiringSoonDaysDialogTitle;

  /// No description provided for @expiringSoonDaysSet.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon threshold set to {days} days.'**
  String expiringSoonDaysSet(int days);

  /// No description provided for @expiringToday.
  ///
  /// In en, this message translates to:
  /// **'Food expiring today'**
  String get expiringToday;

  /// No description provided for @expiresTomorrow.
  ///
  /// In en, this message translates to:
  /// **'{barcode} expires tomorrow'**
  String expiresTomorrow(String barcode);

  /// No description provided for @expiresToday.
  ///
  /// In en, this message translates to:
  /// **'{barcode} expires today!'**
  String expiresToday(String barcode);

  /// No description provided for @expiryChannelName.
  ///
  /// In en, this message translates to:
  /// **'Expiry reminders'**
  String get expiryChannelName;

  /// No description provided for @expiryChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Warns about expiring food'**
  String get expiryChannelDescription;

  /// No description provided for @itemRestored.
  ///
  /// In en, this message translates to:
  /// **'Item restored.'**
  String get itemRestored;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Align the barcode inside the frame'**
  String get scanHint;

  /// No description provided for @confirmExitScanner.
  ///
  /// In en, this message translates to:
  /// **'Stop scanning?'**
  String get confirmExitScanner;

  /// No description provided for @confirmExitScannerHint.
  ///
  /// In en, this message translates to:
  /// **'The current scan will be discarded.'**
  String get confirmExitScannerHint;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @enterCustomUnit.
  ///
  /// In en, this message translates to:
  /// **'Enter custom unit'**
  String get enterCustomUnit;

  /// No description provided for @enterCustomLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter custom location'**
  String get enterCustomLocation;

  /// No description provided for @enterProductDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter product details'**
  String get enterProductDetails;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productNameLabel;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @servingSizeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 100 g, 1 cookie (28 g)'**
  String get servingSizeHint;

  /// No description provided for @nutritionInfo.
  ///
  /// In en, this message translates to:
  /// **'Nutrition (per 100 g / 100 ml)'**
  String get nutritionInfo;

  /// No description provided for @captureImages.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get captureImages;

  /// No description provided for @nutritionTableImage.
  ///
  /// In en, this message translates to:
  /// **'Nutrition table photo'**
  String get nutritionTableImage;

  /// No description provided for @ingredientsImage.
  ///
  /// In en, this message translates to:
  /// **'Ingredients list photo'**
  String get ingredientsImage;

  /// No description provided for @productImage.
  ///
  /// In en, this message translates to:
  /// **'Product photo'**
  String get productImage;

  /// No description provided for @saveProduct.
  ///
  /// In en, this message translates to:
  /// **'Save product'**
  String get saveProduct;

  /// No description provided for @offlineWarning.
  ///
  /// In en, this message translates to:
  /// **'You are offline — adding product manually'**
  String get offlineWarning;

  /// No description provided for @nutriscoreExplanation.
  ///
  /// In en, this message translates to:
  /// **'Nutri-Score is a nutrition label that rates products from A (best) to E (worst) based on their nutritional quality. It helps compare similar products at a glance.'**
  String get nutriscoreExplanation;

  /// No description provided for @nutriscoreNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Nutri-Score is not applicable to this product ({category}).'**
  String nutriscoreNotApplicable(Object category);

  /// No description provided for @nutriscoreNotApplicableGeneric.
  ///
  /// In en, this message translates to:
  /// **'Nutri-Score is not applicable to this product category.'**
  String get nutriscoreNotApplicableGeneric;

  /// No description provided for @flushCache.
  ///
  /// In en, this message translates to:
  /// **'Flush cache'**
  String get flushCache;

  /// No description provided for @flushCacheSub.
  ///
  /// In en, this message translates to:
  /// **'Delete cached product data and images'**
  String get flushCacheSub;

  /// No description provided for @flushCacheConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will delete all cached product data and images fetched from Open Food Facts. Manually entered products and your inventory items will be preserved. Cached products will be re-fetched the next time you view them.'**
  String get flushCacheConfirm;

  /// No description provided for @flushCacheSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cached products flushed. They will refresh automatically.'**
  String get flushCacheSuccess;

  /// No description provided for @flushCacheFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to flush cache. Please try again.'**
  String get flushCacheFailed;

  /// No description provided for @submissionPending.
  ///
  /// In en, this message translates to:
  /// **'Pending submission to Open Food Facts'**
  String get submissionPending;

  /// No description provided for @submissionSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted to Open Food Facts'**
  String get submissionSubmitted;

  /// No description provided for @submissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit product. Tap to retry.'**
  String get submissionFailed;

  /// Label for a chip that allows the user to re-fetch the product in a different language
  ///
  /// In en, this message translates to:
  /// **'Show in {language}'**
  String showInLanguage(String language);

  /// No description provided for @ingredientsOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show original ingredients'**
  String get ingredientsOriginal;

  /// No description provided for @ingredientsTranslated.
  ///
  /// In en, this message translates to:
  /// **'Show translated ingredients'**
  String get ingredientsTranslated;

  /// No description provided for @submissionNotSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Not submitted to Open Food Facts'**
  String get submissionNotSubmitted;

  /// No description provided for @submissionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product submitted to Open Food Facts.'**
  String get submissionSuccess;

  /// No description provided for @submissionError.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit product. Tap to retry.'**
  String get submissionError;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Products'**
  String get searchTitle;

  /// No description provided for @searchProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Search for products by name or barcode'**
  String get searchProductsHint;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No products found matching your search'**
  String get noSearchResults;

  /// No description provided for @totalItemsCount.
  ///
  /// In en, this message translates to:
  /// **'Total items: {count}'**
  String totalItemsCount(Object count);

  /// No description provided for @expiringSoonCount.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon: {count}'**
  String expiringSoonCount(Object count);

  /// No description provided for @addedThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Added this week: {count}'**
  String addedThisWeek(Object count);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get settingsDataManagement;

  /// No description provided for @settingsMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get settingsMaintenance;

  /// No description provided for @whatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNewTitle;

  /// No description provided for @whatsNewVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String whatsNewVersion(String version);

  /// No description provided for @whatsNewDismiss.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get whatsNewDismiss;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @comingSoonDescription.
  ///
  /// In en, this message translates to:
  /// **'This feature will be available soon.'**
  String get comingSoonDescription;

  /// No description provided for @priceTracking.
  ///
  /// In en, this message translates to:
  /// **'Price Tracking'**
  String get priceTracking;

  /// No description provided for @priceTrackingDescription.
  ///
  /// In en, this message translates to:
  /// **'Record purchase prices and track how much you spend.'**
  String get priceTrackingDescription;

  /// No description provided for @receiptTracking.
  ///
  /// In en, this message translates to:
  /// **'NFC-e Receipts'**
  String get receiptTracking;

  /// No description provided for @receiptTrackingDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan tax receipts to add products.'**
  String get receiptTrackingDescription;

  /// No description provided for @photoCompletenessTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo Completeness'**
  String get photoCompletenessTitle;

  /// No description provided for @contributePhotos.
  ///
  /// In en, this message translates to:
  /// **'Contribute to Open Food Facts'**
  String get contributePhotos;

  /// No description provided for @offNeedsPhotos.
  ///
  /// In en, this message translates to:
  /// **'OFF needs photos for {count} products'**
  String offNeedsPhotos(Object count);

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategories;

  /// No description provided for @statsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No items to analyze'**
  String get statsEmptyTitle;

  /// No description provided for @statsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add products to your pantry to see statistics here.'**
  String get statsEmptySubtitle;

  /// No description provided for @addedThisWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get addedThisWeekLabel;

  /// No description provided for @addedThisMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get addedThisMonthLabel;

  /// No description provided for @productDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Product data unavailable — pull to refresh when online'**
  String get productDataUnavailable;

  /// No description provided for @locationStats.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get locationStats;

  /// No description provided for @nutritionPhoto.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutritionPhoto;

  /// No description provided for @ingredientsPhoto.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientsPhoto;

  /// No description provided for @productPhoto.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get productPhoto;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @issueType.
  ///
  /// In en, this message translates to:
  /// **'Issue type'**
  String get issueType;

  /// No description provided for @bugReport.
  ///
  /// In en, this message translates to:
  /// **'Bug Report'**
  String get bugReport;

  /// No description provided for @featureRequest.
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get featureRequest;

  /// No description provided for @generalFeedback.
  ///
  /// In en, this message translates to:
  /// **'General Feedback'**
  String get generalFeedback;

  /// No description provided for @regressionReport.
  ///
  /// In en, this message translates to:
  /// **'Regression'**
  String get regressionReport;

  /// No description provided for @bugReportExplanation.
  ///
  /// In en, this message translates to:
  /// **'Something is broken or not working as expected.'**
  String get bugReportExplanation;

  /// No description provided for @featureRequestExplanation.
  ///
  /// In en, this message translates to:
  /// **'Suggest a new feature or improvement.'**
  String get featureRequestExplanation;

  /// No description provided for @generalFeedbackExplanation.
  ///
  /// In en, this message translates to:
  /// **'Other comments, questions, or suggestions.'**
  String get generalFeedbackExplanation;

  /// No description provided for @regressionReportExplanation.
  ///
  /// In en, this message translates to:
  /// **'A feature that used to work but no longer does.'**
  String get regressionReportExplanation;

  /// No description provided for @issueTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get issueTitle;

  /// No description provided for @issueTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required (min 5 characters)'**
  String get issueTitleRequired;

  /// No description provided for @issueDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get issueDescription;

  /// No description provided for @issueDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required (min 10 characters)'**
  String get issueDescriptionRequired;

  /// No description provided for @attachScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Attach screenshot'**
  String get attachScreenshot;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @includeDeviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Include device info'**
  String get includeDeviceInfo;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @issueCreate.
  ///
  /// In en, this message translates to:
  /// **'Create issue'**
  String get issueCreate;

  /// No description provided for @issueSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Your report has been submitted.'**
  String get issueSubmitted;

  /// No description provided for @issueQueuedOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Your report will be submitted when you are back online.'**
  String get issueQueuedOffline;

  /// No description provided for @issueSubmissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit. Please try again.'**
  String get issueSubmissionFailed;

  /// No description provided for @viewOnGitHub.
  ///
  /// In en, this message translates to:
  /// **'View on GitHub'**
  String get viewOnGitHub;

  /// No description provided for @issueDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You recently submitted a similar report.'**
  String get issueDuplicate;

  /// No description provided for @removeScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeScreenshot;

  /// No description provided for @nutriScore.
  ///
  /// In en, this message translates to:
  /// **'Nutri-Score'**
  String get nutriScore;

  /// No description provided for @photoCoverageRatio.
  ///
  /// In en, this message translates to:
  /// **'{local} / {total}'**
  String photoCoverageRatio(Object local, Object total);

  /// No description provided for @offPhotosCount.
  ///
  /// In en, this message translates to:
  /// **'OFF: {off}'**
  String offPhotosCount(Object off);

  /// No description provided for @couldNotAttachImage.
  ///
  /// In en, this message translates to:
  /// **'Could not attach image'**
  String get couldNotAttachImage;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersionLabel;

  /// No description provided for @osLabel.
  ///
  /// In en, this message translates to:
  /// **'OS'**
  String get osLabel;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied. Grant access in Settings.'**
  String get cameraPermissionDenied;

  /// No description provided for @cameraNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Camera not available on this device.'**
  String get cameraNotAvailable;

  /// No description provided for @scannerGenericError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while starting the camera.'**
  String get scannerGenericError;

  /// No description provided for @switchToManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Enter barcode manually'**
  String get switchToManualEntry;

  /// No description provided for @retryScan.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryScan;

  /// No description provided for @couldNotOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Could not open Settings.'**
  String get couldNotOpenSettings;

  /// No description provided for @toggleTorch.
  ///
  /// In en, this message translates to:
  /// **'Toggle flashlight'**
  String get toggleTorch;

  /// No description provided for @inactivityReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to restock your pantry?'**
  String get inactivityReminderTitle;

  /// No description provided for @inactivityReminderBody.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any products in {days} days.'**
  String inactivityReminderBody(int days);

  /// No description provided for @inactivityReminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Remind me to add products regularly'**
  String get inactivityReminderEnabled;

  /// No description provided for @inactivityThresholdDays.
  ///
  /// In en, this message translates to:
  /// **'Inactivity threshold (days)'**
  String get inactivityThresholdDays;

  /// No description provided for @inactivityReminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Inactivity reminders'**
  String get inactivityReminderChannelName;

  /// No description provided for @inactivityReminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminds you to add products regularly'**
  String get inactivityReminderChannelDescription;

  /// No description provided for @notificationDeniedWarning.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled. Expiry and inactivity reminders will only show when you open the app. Enable them in Settings at any time.'**
  String get notificationDeniedWarning;

  /// No description provided for @inactivityThresholdSet.
  ///
  /// In en, this message translates to:
  /// **'Inactivity threshold set to {days} days.'**
  String inactivityThresholdSet(int days);

  /// No description provided for @amoledDarkMode.
  ///
  /// In en, this message translates to:
  /// **'AMOLED dark mode'**
  String get amoledDarkMode;

  /// No description provided for @amoledDarkModeExplanation.
  ///
  /// In en, this message translates to:
  /// **'Use pure black surfaces in dark mode to save power on AMOLED displays'**
  String get amoledDarkModeExplanation;

  /// No description provided for @amoledDarkModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'AMOLED dark mode enabled.'**
  String get amoledDarkModeEnabled;

  /// No description provided for @amoledDarkModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'AMOLED dark mode disabled.'**
  String get amoledDarkModeDisabled;

  /// No description provided for @amoledNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode?'**
  String get amoledNudgeTitle;

  /// No description provided for @amoledNudgeBody.
  ///
  /// In en, this message translates to:
  /// **'Dark mode can save battery life on your device, especially if it has an AMOLED screen. You can also enable pure-black surfaces in Settings for maximum power savings.'**
  String get amoledNudgeBody;

  /// No description provided for @amoledNudgeEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable dark mode'**
  String get amoledNudgeEnable;

  /// No description provided for @amoledNudgeDismiss.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get amoledNudgeDismiss;

  /// No description provided for @translationReport.
  ///
  /// In en, this message translates to:
  /// **'Translation Report'**
  String get translationReport;

  /// No description provided for @translationReportExplanation.
  ///
  /// In en, this message translates to:
  /// **'Report an issue with a product translation or suggest a new translation.'**
  String get translationReportExplanation;

  /// No description provided for @feedbackRateLimit.
  ///
  /// In en, this message translates to:
  /// **'You can only submit one report per minute and up to 5 per day. Please try again later.'**
  String get feedbackRateLimit;

  /// No description provided for @couldNotOpenLinkFallback.
  ///
  /// In en, this message translates to:
  /// **'URL copied to clipboard.'**
  String get couldNotOpenLinkFallback;

  /// No description provided for @includeLogs.
  ///
  /// In en, this message translates to:
  /// **'Include app logs'**
  String get includeLogs;

  /// No description provided for @includeLogsExplanation.
  ///
  /// In en, this message translates to:
  /// **'Recent warnings and errors from this session'**
  String get includeLogsExplanation;

  /// No description provided for @logsPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Logs may contain product names and timestamps.'**
  String get logsPrivacyNote;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @prices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get prices;

  /// No description provided for @addPrice.
  ///
  /// In en, this message translates to:
  /// **'Price saved'**
  String get addPrice;

  /// No description provided for @editPrice.
  ///
  /// In en, this message translates to:
  /// **'Edit price'**
  String get editPrice;

  /// No description provided for @deletePrice.
  ///
  /// In en, this message translates to:
  /// **'Delete price'**
  String get deletePrice;

  /// No description provided for @priceAdded.
  ///
  /// In en, this message translates to:
  /// **'Price added.'**
  String get priceAdded;

  /// No description provided for @priceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Price updated.'**
  String get priceUpdated;

  /// No description provided for @priceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Price deleted.'**
  String get priceDeleted;

  /// No description provided for @priceHistory.
  ///
  /// In en, this message translates to:
  /// **'Price history'**
  String get priceHistory;

  /// No description provided for @noPrices.
  ///
  /// In en, this message translates to:
  /// **'No prices recorded.'**
  String get noPrices;

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total value'**
  String get totalValue;

  /// No description provided for @averagePrice.
  ///
  /// In en, this message translates to:
  /// **'Average item price'**
  String get averagePrice;

  /// No description provided for @showPrices.
  ///
  /// In en, this message translates to:
  /// **'Show prices'**
  String get showPrices;

  /// No description provided for @hidePrices.
  ///
  /// In en, this message translates to:
  /// **'Hide prices for privacy'**
  String get hidePrices;

  /// No description provided for @hidePricesDescription.
  ///
  /// In en, this message translates to:
  /// **'Replace price values with masked text everywhere, including the stats screen.'**
  String get hidePricesDescription;

  /// No description provided for @pricesHidden.
  ///
  /// In en, this message translates to:
  /// **'Prices hidden.'**
  String get pricesHidden;

  /// No description provided for @pricesVisible.
  ///
  /// In en, this message translates to:
  /// **'Prices visible.'**
  String get pricesVisible;

  /// No description provided for @priceTrackingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable price tracking'**
  String get priceTrackingEnabled;

  /// No description provided for @priceRetentionDays.
  ///
  /// In en, this message translates to:
  /// **'Price retention'**
  String get priceRetentionDays;

  /// No description provided for @priceRetentionDaysValue.
  ///
  /// In en, this message translates to:
  /// **'Keep prices for {days} days (0 = keep forever)'**
  String priceRetentionDaysValue(int days);

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @baseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base currency'**
  String get baseCurrency;

  /// No description provided for @baseCurrencyDescription.
  ///
  /// In en, this message translates to:
  /// **'All prices are shown in this currency.'**
  String get baseCurrencyDescription;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @addNewStore.
  ///
  /// In en, this message translates to:
  /// **'Add new store'**
  String get addNewStore;

  /// No description provided for @storeAdded.
  ///
  /// In en, this message translates to:
  /// **'Store added'**
  String get storeAdded;

  /// No description provided for @storeAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A store with this name already exists'**
  String get storeAlreadyExists;

  /// No description provided for @storeName.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get storeName;

  /// No description provided for @discounted.
  ///
  /// In en, this message translates to:
  /// **'Discounted'**
  String get discounted;

  /// No description provided for @regularPrice.
  ///
  /// In en, this message translates to:
  /// **'Regular price'**
  String get regularPrice;

  /// No description provided for @confirmDeletePrice.
  ///
  /// In en, this message translates to:
  /// **'Delete this price entry?'**
  String get confirmDeletePrice;

  /// No description provided for @syncToOpenPrices.
  ///
  /// In en, this message translates to:
  /// **'Share with Open Prices'**
  String get syncToOpenPrices;

  /// No description provided for @syncToOpenPricesDescription.
  ///
  /// In en, this message translates to:
  /// **'Contribute your price data to the community food-price database.'**
  String get syncToOpenPricesDescription;

  /// No description provided for @openPricesToken.
  ///
  /// In en, this message translates to:
  /// **'Open Prices API Token'**
  String get openPricesToken;

  /// No description provided for @openPricesTokenDescription.
  ///
  /// In en, this message translates to:
  /// **'Token generated from your Open Food Facts account.'**
  String get openPricesTokenDescription;

  /// No description provided for @openPricesTokenSaved.
  ///
  /// In en, this message translates to:
  /// **'Token saved.'**
  String get openPricesTokenSaved;

  /// No description provided for @openPricesSyncStarted.
  ///
  /// In en, this message translates to:
  /// **'Syncing prices...'**
  String get openPricesSyncStarted;

  /// No description provided for @openPricesSyncComplete.
  ///
  /// In en, this message translates to:
  /// **'{count} prices synced.'**
  String openPricesSyncComplete(int count);

  /// No description provided for @priceSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get priceSyncStatus;

  /// No description provided for @priceSyncPending.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get priceSyncPending;

  /// No description provided for @priceSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get priceSyncFailed;

  /// No description provided for @priceTrendUp.
  ///
  /// In en, this message translates to:
  /// **'Prices are rising'**
  String get priceTrendUp;

  /// No description provided for @priceTrendDown.
  ///
  /// In en, this message translates to:
  /// **'Prices are falling'**
  String get priceTrendDown;

  /// No description provided for @priceTrendStable.
  ///
  /// In en, this message translates to:
  /// **'Prices are stable'**
  String get priceTrendStable;

  /// No description provided for @datePurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get datePurchased;

  /// No description provided for @itemWithPriceCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} items have prices'**
  String itemWithPriceCount(int count, int total);

  /// No description provided for @openPricesProofExplanation.
  ///
  /// In en, this message translates to:
  /// **'To share with Open Prices, a photo of the receipt or shelf label is required as proof. Prices without a photo stay in your local pantry only.'**
  String get openPricesProofExplanation;

  /// No description provided for @openPricesConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Contribute to Open Prices'**
  String get openPricesConsentTitle;

  /// No description provided for @openPricesConsentBody.
  ///
  /// In en, this message translates to:
  /// **'Open Prices is a community database of food prices. To contribute, a photo of the receipt or shelf label is required as proof.\n\nWhen you add or edit a price, you will have the option to take a proof photo. Prices without a photo stay in your local pantry and are not shared.'**
  String get openPricesConsentBody;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get iUnderstand;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @navList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get navList;

  /// No description provided for @shoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get shoppingList;

  /// No description provided for @addShoppingItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addShoppingItem;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get itemName;

  /// No description provided for @markPurchased.
  ///
  /// In en, this message translates to:
  /// **'Mark purchased'**
  String get markPurchased;

  /// No description provided for @unmarkPurchased.
  ///
  /// In en, this message translates to:
  /// **'Unmark purchased'**
  String get unmarkPurchased;

  /// No description provided for @moveToInventory.
  ///
  /// In en, this message translates to:
  /// **'Move to pantry'**
  String get moveToInventory;

  /// No description provided for @addAgain.
  ///
  /// In en, this message translates to:
  /// **'Add again'**
  String get addAgain;

  /// No description provided for @emptyShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Your shopping list is empty'**
  String get emptyShoppingList;

  /// No description provided for @emptyShoppingListSub.
  ///
  /// In en, this message translates to:
  /// **'Add items from a product or tap + to add manually'**
  String get emptyShoppingListSub;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get deleteItem;

  /// No description provided for @clearPurchased.
  ///
  /// In en, this message translates to:
  /// **'Clear purchased'**
  String get clearPurchased;

  /// No description provided for @clearPurchasedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove all purchased items?'**
  String get clearPurchasedConfirm;

  /// No description provided for @purchasedItems.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get purchasedItems;

  /// No description provided for @pendingItems.
  ///
  /// In en, this message translates to:
  /// **'To buy'**
  String get pendingItems;

  /// No description provided for @quickAddHint.
  ///
  /// In en, this message translates to:
  /// **'Name, e.g. Milk'**
  String get quickAddHint;

  /// No description provided for @undoDeleteShoppingItem.
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get undoDeleteShoppingItem;

  /// No description provided for @undoClearPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased items cleared'**
  String get undoClearPurchased;

  /// No description provided for @shareShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Share shopping list'**
  String get shareShoppingList;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @addToShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Add to shopping list'**
  String get addToShoppingList;

  /// No description provided for @addToShoppingListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get addToShoppingListTooltip;

  /// No description provided for @productSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products by name'**
  String get productSearchHint;

  /// No description provided for @addCustomItem.
  ///
  /// In en, this message translates to:
  /// **'Add custom item'**
  String get addCustomItem;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found. Try a custom item.'**
  String get noProductsFound;

  /// No description provided for @backToSearch.
  ///
  /// In en, this message translates to:
  /// **'Back to search'**
  String get backToSearch;

  /// No description provided for @removePrice.
  ///
  /// In en, this message translates to:
  /// **'Price removed'**
  String get removePrice;

  /// No description provided for @shoppingTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}'**
  String shoppingTotal(String total);

  /// No description provided for @shoppingMixedCurrency.
  ///
  /// In en, this message translates to:
  /// **'{total}'**
  String shoppingMixedCurrency(String total);

  /// No description provided for @addToInventoryFromList.
  ///
  /// In en, this message translates to:
  /// **'Add to pantry'**
  String get addToInventoryFromList;

  /// No description provided for @addToInventoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add {count} items to your pantry? Prices will be saved.{skipped, plural, =0{} =1{ 1 item without a barcode will stay in your list.} other{ {skipped} items without a barcode will stay in your list.}}'**
  String addToInventoryConfirm(int count, int skipped);

  /// No description provided for @itemsMovedToInventory.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item added to pantry} other{{count} items added to pantry}}'**
  String itemsMovedToInventory(int count);

  /// No description provided for @itemsSkippedNoBarcode.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item left — add a barcode or create a product to move it} other{{count} items left — add a barcode or create a product to move them}}'**
  String itemsSkippedNoBarcode(int count);

  /// No description provided for @addToPantryAfterPrice.
  ///
  /// In en, this message translates to:
  /// **'Add to your pantry?'**
  String get addToPantryAfterPrice;

  /// No description provided for @addToPantryAfterPriceDesc.
  ///
  /// In en, this message translates to:
  /// **'Record the amount you bought to track it in your inventory.'**
  String get addToPantryAfterPriceDesc;

  /// No description provided for @howManyBought.
  ///
  /// In en, this message translates to:
  /// **'How many did you buy?'**
  String get howManyBought;

  /// No description provided for @choosePantry.
  ///
  /// In en, this message translates to:
  /// **'Choose a pantry'**
  String get choosePantry;

  /// No description provided for @addToPantrySkipped.
  ///
  /// In en, this message translates to:
  /// **'Price saved. Add from product page to track inventory.'**
  String get addToPantrySkipped;

  /// No description provided for @invalidPriceAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price amount'**
  String get invalidPriceAmount;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @priceHidden.
  ///
  /// In en, this message translates to:
  /// **'Price hidden'**
  String get priceHidden;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Barcode scan failed.'**
  String get scanFailed;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Send test notification'**
  String get testNotification;

  /// No description provided for @testScheduledNotification.
  ///
  /// In en, this message translates to:
  /// **'Send scheduled test notification (2 min)'**
  String get testScheduledNotification;

  /// No description provided for @testNotificationScheduled.
  ///
  /// In en, this message translates to:
  /// **'Test notification scheduled.'**
  String get testNotificationScheduled;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent.'**
  String get testNotificationSent;

  /// No description provided for @testNotificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send test notification.'**
  String get testNotificationFailed;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items selected} =1{1 item selected} other{{count} items selected}}'**
  String selectedCount(num count);

  /// No description provided for @moveButton.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get moveButton;

  /// No description provided for @noOtherInventories.
  ///
  /// In en, this message translates to:
  /// **'No other pantries available.'**
  String get noOtherInventories;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @defaultInventoryName.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get defaultInventoryName;

  /// No description provided for @locationPantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get locationPantry;

  /// No description provided for @locationFridge.
  ///
  /// In en, this message translates to:
  /// **'Fridge'**
  String get locationFridge;

  /// No description provided for @locationFreezer.
  ///
  /// In en, this message translates to:
  /// **'Freezer'**
  String get locationFreezer;

  /// No description provided for @unitSingular.
  ///
  /// In en, this message translates to:
  /// **'unit'**
  String get unitSingular;

  /// No description provided for @unitPlural.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get unitPlural;

  /// No description provided for @weightModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (g)'**
  String get weightModeLabel;

  /// No description provided for @unitModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitModeLabel;

  /// No description provided for @servingSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get servingSmall;

  /// No description provided for @servingMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get servingMedium;

  /// No description provided for @servingLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get servingLarge;

  /// No description provided for @unitGrams.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitGrams;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitMl.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get unitMl;

  /// No description provided for @unitLiter.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get unitLiter;

  /// No description provided for @generalNotificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'General Notifications'**
  String get generalNotificationChannelName;

  /// No description provided for @generalNotificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Standard app notifications'**
  String get generalNotificationChannelDescription;

  /// No description provided for @testNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Successful'**
  String get testNotificationTitle;

  /// No description provided for @testNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Immediate notifications are working!'**
  String get testNotificationBody;

  /// No description provided for @testScheduledTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Test'**
  String get testScheduledTitle;

  /// No description provided for @testScheduledBody.
  ///
  /// In en, this message translates to:
  /// **'This fired 5 seconds later.'**
  String get testScheduledBody;

  /// No description provided for @retryNow.
  ///
  /// In en, this message translates to:
  /// **'Retry now'**
  String get retryNow;

  /// No description provided for @bearerTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Bearer token'**
  String get bearerTokenLabel;

  /// No description provided for @pendingFeedback.
  ///
  /// In en, this message translates to:
  /// **'Pending feedback: {count}'**
  String pendingFeedback(Object count);

  /// No description provided for @submissionResult.
  ///
  /// In en, this message translates to:
  /// **'Submitted {submitted}, {failed} failed'**
  String submissionResult(Object failed, Object submitted);

  /// No description provided for @bytesUnit.
  ///
  /// In en, this message translates to:
  /// **'{bytes} B'**
  String bytesUnit(Object bytes);

  /// No description provided for @kbUnit.
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String kbUnit(Object size);

  /// No description provided for @mbUnit.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String mbUnit(Object size);

  /// No description provided for @unreleasedVersion.
  ///
  /// In en, this message translates to:
  /// **'Unreleased'**
  String get unreleasedVersion;

  /// No description provided for @categoryDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get categoryDairy;

  /// No description provided for @categoryMilks.
  ///
  /// In en, this message translates to:
  /// **'Milks'**
  String get categoryMilks;

  /// No description provided for @categoryMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get categoryMilk;

  /// No description provided for @categoryYogurts.
  ///
  /// In en, this message translates to:
  /// **'Yogurts'**
  String get categoryYogurts;

  /// No description provided for @categoryCheeses.
  ///
  /// In en, this message translates to:
  /// **'Cheeses'**
  String get categoryCheeses;

  /// No description provided for @categoryEggsAndProducts.
  ///
  /// In en, this message translates to:
  /// **'Eggs and their products'**
  String get categoryEggsAndProducts;

  /// No description provided for @categoryMeats.
  ///
  /// In en, this message translates to:
  /// **'Meats'**
  String get categoryMeats;

  /// No description provided for @categoryFishesAndSeafoods.
  ///
  /// In en, this message translates to:
  /// **'Fishes and seafoods'**
  String get categoryFishesAndSeafoods;

  /// No description provided for @categoryBeverages.
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get categoryBeverages;

  /// No description provided for @categoryAlcoholicBeverages.
  ///
  /// In en, this message translates to:
  /// **'Alcoholic beverages'**
  String get categoryAlcoholicBeverages;

  /// No description provided for @categoryBreads.
  ///
  /// In en, this message translates to:
  /// **'Breads'**
  String get categoryBreads;

  /// No description provided for @categoryCerealsAndPotatoes.
  ///
  /// In en, this message translates to:
  /// **'Cereals and potatoes'**
  String get categoryCerealsAndPotatoes;

  /// No description provided for @categoryFruitsAndVegetables.
  ///
  /// In en, this message translates to:
  /// **'Fruits and vegetables based foods'**
  String get categoryFruitsAndVegetables;

  /// No description provided for @categoryConfectioneries.
  ///
  /// In en, this message translates to:
  /// **'Confectioneries'**
  String get categoryConfectioneries;

  /// No description provided for @categorySugarySnacks.
  ///
  /// In en, this message translates to:
  /// **'Sugary snacks'**
  String get categorySugarySnacks;

  /// No description provided for @categorySaltySnacks.
  ///
  /// In en, this message translates to:
  /// **'Salty snacks'**
  String get categorySaltySnacks;

  /// No description provided for @categoryFats.
  ///
  /// In en, this message translates to:
  /// **'Fats'**
  String get categoryFats;

  /// No description provided for @categorySauces.
  ///
  /// In en, this message translates to:
  /// **'Sauces'**
  String get categorySauces;

  /// No description provided for @categorySoups.
  ///
  /// In en, this message translates to:
  /// **'Soups'**
  String get categorySoups;

  /// No description provided for @categoryPreparedMeals.
  ///
  /// In en, this message translates to:
  /// **'Prepared meals'**
  String get categoryPreparedMeals;

  /// No description provided for @categoryFrozenFoods.
  ///
  /// In en, this message translates to:
  /// **'Frozen foods'**
  String get categoryFrozenFoods;

  /// No description provided for @categoryDesserts.
  ///
  /// In en, this message translates to:
  /// **'Desserts'**
  String get categoryDesserts;

  /// No description provided for @categoryPastries.
  ///
  /// In en, this message translates to:
  /// **'Pastries'**
  String get categoryPastries;

  /// No description provided for @categoryBiscuitsAndCakes.
  ///
  /// In en, this message translates to:
  /// **'Biscuits and cakes'**
  String get categoryBiscuitsAndCakes;

  /// No description provided for @categoryPizzas.
  ///
  /// In en, this message translates to:
  /// **'Pizzas'**
  String get categoryPizzas;

  /// No description provided for @categorySandwiches.
  ///
  /// In en, this message translates to:
  /// **'Sandwiches'**
  String get categorySandwiches;

  /// No description provided for @categoryBabyFoods.
  ///
  /// In en, this message translates to:
  /// **'Baby foods'**
  String get categoryBabyFoods;

  /// No description provided for @categoryDietaryFoods.
  ///
  /// In en, this message translates to:
  /// **'Dietary foods'**
  String get categoryDietaryFoods;

  /// No description provided for @categorySpicesAndHerbs.
  ///
  /// In en, this message translates to:
  /// **'Spices and herbs'**
  String get categorySpicesAndHerbs;

  /// No description provided for @categoryNutsAndProducts.
  ///
  /// In en, this message translates to:
  /// **'Nuts and their products'**
  String get categoryNutsAndProducts;

  /// No description provided for @categoryPlantBasedFoods.
  ///
  /// In en, this message translates to:
  /// **'Plant based foods'**
  String get categoryPlantBasedFoods;

  /// No description provided for @categoryLegumesAndProducts.
  ///
  /// In en, this message translates to:
  /// **'Legumes and their products'**
  String get categoryLegumesAndProducts;

  /// No description provided for @categoryCoffees.
  ///
  /// In en, this message translates to:
  /// **'Coffees'**
  String get categoryCoffees;

  /// No description provided for @categoryTeas.
  ///
  /// In en, this message translates to:
  /// **'Teas'**
  String get categoryTeas;

  /// No description provided for @categoryChocolateProducts.
  ///
  /// In en, this message translates to:
  /// **'Chocolate products'**
  String get categoryChocolateProducts;

  /// No description provided for @categoryIceCreams.
  ///
  /// In en, this message translates to:
  /// **'Ice creams'**
  String get categoryIceCreams;

  /// No description provided for @categoryFruitJuices.
  ///
  /// In en, this message translates to:
  /// **'Fruit juices'**
  String get categoryFruitJuices;

  /// No description provided for @categorySodas.
  ///
  /// In en, this message translates to:
  /// **'Sodas'**
  String get categorySodas;

  /// No description provided for @categoryWaters.
  ///
  /// In en, this message translates to:
  /// **'Waters'**
  String get categoryWaters;

  /// No description provided for @categoryMeatAndProducts.
  ///
  /// In en, this message translates to:
  /// **'Meat and their products'**
  String get categoryMeatAndProducts;

  /// No description provided for @categoryBreakfasts.
  ///
  /// In en, this message translates to:
  /// **'Breakfasts'**
  String get categoryBreakfasts;

  /// No description provided for @categoryBread.
  ///
  /// In en, this message translates to:
  /// **'Bread'**
  String get categoryBread;

  /// No description provided for @categoryCakes.
  ///
  /// In en, this message translates to:
  /// **'Cakes'**
  String get categoryCakes;

  /// No description provided for @categoryCereals.
  ///
  /// In en, this message translates to:
  /// **'Cereals'**
  String get categoryCereals;

  /// No description provided for @categoryChocolate.
  ///
  /// In en, this message translates to:
  /// **'Chocolate'**
  String get categoryChocolate;

  /// No description provided for @categoryCondiments.
  ///
  /// In en, this message translates to:
  /// **'Condiments'**
  String get categoryCondiments;

  /// No description provided for @categoryEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get categoryEggs;

  /// No description provided for @categoryFish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get categoryFish;

  /// No description provided for @categoryFruit.
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get categoryFruit;

  /// No description provided for @categoryFruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get categoryFruits;

  /// No description provided for @categoryGrains.
  ///
  /// In en, this message translates to:
  /// **'Grains'**
  String get categoryGrains;

  /// No description provided for @categoryHotBeverages.
  ///
  /// In en, this message translates to:
  /// **'Hot beverages'**
  String get categoryHotBeverages;

  /// No description provided for @categoryLegumes.
  ///
  /// In en, this message translates to:
  /// **'Legumes'**
  String get categoryLegumes;

  /// No description provided for @categoryOils.
  ///
  /// In en, this message translates to:
  /// **'Oils'**
  String get categoryOils;

  /// No description provided for @categoryPasta.
  ///
  /// In en, this message translates to:
  /// **'Pasta'**
  String get categoryPasta;

  /// No description provided for @categoryPoultry.
  ///
  /// In en, this message translates to:
  /// **'Poultry'**
  String get categoryPoultry;

  /// No description provided for @categorySeeds.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get categorySeeds;

  /// No description provided for @categorySnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get categorySnacks;

  /// No description provided for @categorySpreads.
  ///
  /// In en, this message translates to:
  /// **'Spreads'**
  String get categorySpreads;

  /// No description provided for @categorySweetSpreads.
  ///
  /// In en, this message translates to:
  /// **'Sweet spreads'**
  String get categorySweetSpreads;

  /// No description provided for @categoryVegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get categoryVegetables;

  /// No description provided for @categoryBiscuitsAndCrackers.
  ///
  /// In en, this message translates to:
  /// **'Biscuits and crackers'**
  String get categoryBiscuitsAndCrackers;

  /// No description provided for @categoryLegumeOils.
  ///
  /// In en, this message translates to:
  /// **'Legume oils'**
  String get categoryLegumeOils;

  /// No description provided for @categoryUhtMilks.
  ///
  /// In en, this message translates to:
  /// **'UHT milks'**
  String get categoryUhtMilks;

  /// No description provided for @categoryCannedSardines.
  ///
  /// In en, this message translates to:
  /// **'Canned sardines'**
  String get categoryCannedSardines;

  /// No description provided for @categoryCerealFlours.
  ///
  /// In en, this message translates to:
  /// **'Cereal flours'**
  String get categoryCerealFlours;

  /// No description provided for @categoryCerealStarches.
  ///
  /// In en, this message translates to:
  /// **'Cereal starches'**
  String get categoryCerealStarches;

  /// No description provided for @categoryCerealsAndProducts.
  ///
  /// In en, this message translates to:
  /// **'Cereals and their products'**
  String get categoryCerealsAndProducts;

  /// No description provided for @categoryDairies.
  ///
  /// In en, this message translates to:
  /// **'Dairies'**
  String get categoryDairies;

  /// No description provided for @categoryInstantBeverages.
  ///
  /// In en, this message translates to:
  /// **'Instant beverages'**
  String get categoryInstantBeverages;

  /// No description provided for @categoryMilkfat.
  ///
  /// In en, this message translates to:
  /// **'Milkfat'**
  String get categoryMilkfat;

  /// No description provided for @categoryStarches.
  ///
  /// In en, this message translates to:
  /// **'Starches'**
  String get categoryStarches;

  /// No description provided for @pluEntryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Enter PLU code (produce)'**
  String get pluEntryTooltip;

  /// No description provided for @enterPluCode.
  ///
  /// In en, this message translates to:
  /// **'Enter PLU Code'**
  String get enterPluCode;

  /// No description provided for @pluCodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'PLU code not recognized'**
  String get pluCodeNotFound;

  /// No description provided for @digitLabel.
  ///
  /// In en, this message translates to:
  /// **'Digit'**
  String get digitLabel;

  /// No description provided for @deleteDigit.
  ///
  /// In en, this message translates to:
  /// **'Delete digit'**
  String get deleteDigit;

  /// No description provided for @quickAddProduceTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quickAddProduceTitle;

  /// No description provided for @quickAddProduceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Based on your purchases and seasonal availability'**
  String get quickAddProduceTooltip;

  /// No description provided for @quickAddProduceEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start adding produce to see quick picks here!'**
  String get quickAddProduceEmpty;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @hemisphereSetting.
  ///
  /// In en, this message translates to:
  /// **'Hemisphere'**
  String get hemisphereSetting;

  /// No description provided for @hemisphereAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto (detect from country)'**
  String get hemisphereAuto;

  /// No description provided for @hemisphereNorthern.
  ///
  /// In en, this message translates to:
  /// **'Northern Hemisphere'**
  String get hemisphereNorthern;

  /// No description provided for @hemisphereSouthern.
  ///
  /// In en, this message translates to:
  /// **'Southern Hemisphere'**
  String get hemisphereSouthern;

  /// No description provided for @hemisphereChanged.
  ///
  /// In en, this message translates to:
  /// **'Hemisphere updated'**
  String get hemisphereChanged;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt': {
  switch (locale.countryCode) {
    case 'BR': return AppLocalizationsPtBr();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
