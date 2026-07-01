// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Despensa';

  @override
  String get myPantry => 'Minha Despensa';

  @override
  String get settings => 'Configurações';

  @override
  String get scanBarcode => 'Escanear código de barras';

  @override
  String get enterBarcode => 'Digitar código de barras';

  @override
  String get expired => 'Vencido';

  @override
  String get expiringSoon => 'Vence logo';

  @override
  String get good => 'Bom';

  @override
  String get searchHint => 'Buscar por nome ou código';

  @override
  String get noItemsMatch => 'Nenhum item encontrado';

  @override
  String get emptyPantryTitle => 'Sua despensa está vazia';

  @override
  String get emptyPantrySubtitle => 'Toque no botão abaixo para escanear seu primeiro produto';

  @override
  String get scanFirstProduct => 'Escanear um código de barras';

  @override
  String get barcodeLabel => 'Código';

  @override
  String get brandLabel => 'Marca';

  @override
  String get categoryLabel => 'Categoria';

  @override
  String get servingSize => 'Porção';

  @override
  String get energy => 'Energia';

  @override
  String get protein => 'Proteína';

  @override
  String get carbs => 'Carboidratos';

  @override
  String get fat => 'Gorduras';

  @override
  String get fiber => 'Fibras';

  @override
  String get salt => 'Sal';

  @override
  String get per100g => 'Por 100 g';

  @override
  String get ingredients => 'Ingredientes';

  @override
  String get yourInventory => 'Seu inventário';

  @override
  String get noItemsInPantry => 'Nenhum item na despensa ainda.';

  @override
  String get addToInventory => 'Adicionar ao inventário';

  @override
  String get updateItem => 'Atualizar item';

  @override
  String get addToPantry => 'Adicionar à despensa';

  @override
  String get quantityLabel => 'Quantidade';

  @override
  String get unitLabel => 'Unidade';

  @override
  String get locationLabel => 'Local';

  @override
  String get expiryDateOptional => 'Data de validade (opcional)';

  @override
  String get pickDate => 'Escolher data';

  @override
  String get notesLabel => 'Observações';

  @override
  String get theme => 'Tema';

  @override
  String get expiryNotifications => 'Notificações de validade';

  @override
  String get remindBeforeExpiry => 'Lembre antes de vencer';

  @override
  String get dataRetention => 'Retenção de dados';

  @override
  String get manageInventories => 'Gerenciar despensas';

  @override
  String get manageInventoriesSub => 'Criar, renomear ou excluir despensas';

  @override
  String get chooseTheme => 'Escolher tema';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get pantryStats => 'Estatísticas';

  @override
  String get totalProducts => 'Total de produtos';

  @override
  String get inventoryItems => 'Itens no inventário';

  @override
  String get exportCsv => 'Exportar CSV';

  @override
  String get importCsv => 'Importar CSV';

  @override
  String get createNewPantry => 'Criar nova despensa';

  @override
  String get newPantry => 'Nova despensa';

  @override
  String get renamePantry => 'Renomear despensa';

  @override
  String get deletePantry => 'Excluir despensa?';

  @override
  String deletePantryContent(String name) {
    return 'Todos os itens em \"$name\" serão excluídos permanentemente.';
  }

  @override
  String get manualEntryTooltip => 'Digitar código manualmente';

  @override
  String get cameraTooltip => 'Escanear com a câmera';

  @override
  String get typeOrPasteBarcode => 'Digite ou cole um código de barras';

  @override
  String get submit => 'Enviar';

  @override
  String get alignBarcode => 'Alinhe o código dentro do quadro';

  @override
  String get itemUpdated => 'Item atualizado.';

  @override
  String get itemAdded => 'Item adicionado à despensa.';

  @override
  String get itemRemoved => 'Item removido da despensa.';

  @override
  String get saveFailed => 'Falha ao salvar item.';

  @override
  String get deleteFailed => 'Falha ao excluir item.';

  @override
  String get inventoryLoadFailed => 'Falha ao carregar inventário.';

  @override
  String get expiryPrefix => 'Val';
}
