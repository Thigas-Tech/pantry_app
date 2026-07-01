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
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get appTitle;

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

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get exportCsv;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importCsv;

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

  /// No description provided for @alignBarcode.
  ///
  /// In en, this message translates to:
  /// **'Align the barcode inside the frame'**
  String get alignBarcode;

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

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete item.'**
  String get deleteFailed;

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
