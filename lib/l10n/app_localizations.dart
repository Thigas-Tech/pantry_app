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

  /// No description provided for @brandLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brandLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
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
  /// **'Delete {count} selected items?'**
  String deleteCountSub(Object count);

  /// No description provided for @itemsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} deleted.'**
  String itemsDeleted(Object count);

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
  /// **'Nutrient'**
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
  /// **'Product not found'**
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
  /// **'Submission to Open Food Facts failed'**
  String get submissionFailed;

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

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterByCategory;

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
  /// **'Track how much you spend.'**
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
