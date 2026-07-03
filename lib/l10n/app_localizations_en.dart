// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pantry';

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
  String get exportCsv => 'Export as CSV';

  @override
  String get importCsv => 'Import CSV';

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
  String get alignBarcode => 'Align the barcode inside the frame';

  @override
  String get itemUpdated => 'Item updated.';

  @override
  String get itemAdded => 'Item added to pantry.';

  @override
  String get itemRemoved => 'Item removed from pantry.';

  @override
  String get saveFailed => 'Failed to save inventory item.';

  @override
  String get deleteFailed => 'Failed to delete item.';

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
  String get inLocation => 'in';

  @override
  String get noExpiry => 'No expiry';

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
  String get csvImportComingSoon => 'CSV import coming soon.';

  @override
  String get noDataToExport => 'No data to export.';

  @override
  String get pantryExport => 'Pantry Export';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get notificationsEnabled => 'Notifications enabled.';

  @override
  String get notificationsDisabled => 'Notifications disabled.';

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
}
