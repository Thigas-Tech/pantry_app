// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get myPantry => 'Minha Despensa';

  @override
  String get settings => 'Configurações';

  @override
  String get scanBarcode => 'Escanear Código';

  @override
  String get enterBarcode => 'Digitar Código';

  @override
  String get expired => 'Vencido';

  @override
  String get expiringSoon => 'Vence em breve';

  @override
  String get good => 'Bom';

  @override
  String get searchHint => 'Buscar por nome ou código';

  @override
  String get noItemsMatch => 'Nenhum item encontrado';

  @override
  String get emptyPantryTitle => 'Sua despensa está vazia';

  @override
  String get emptyPantrySubtitle => 'Toque no botão abaixo pra escanear seu primeiro produto';

  @override
  String get scanFirstProduct => 'Escanear um código';

  @override
  String get barcodeLabel => 'Código de barras';

  @override
  String get invalidBarcode => 'Digite um código de barras valido (8-13 digitos).';

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
  String get fat => 'Gordura';

  @override
  String get fiber => 'Fibra';

  @override
  String get salt => 'Sal';

  @override
  String get per100g => 'Por 100 g';

  @override
  String get ingredients => 'Ingredientes';

  @override
  String get yourInventory => 'Seu estoque';

  @override
  String get noItemsInPantry => 'Nenhum item na despensa ainda.';

  @override
  String get addToInventory => 'Adicionar ao Estoque';

  @override
  String get copyBarcode => 'Copiar código';

  @override
  String get barcodeCopied => 'Código copiado!';

  @override
  String get removedFromPantry => 'Removido da despensa.';

  @override
  String get updateItem => 'Atualizar Item';

  @override
  String get addToPantry => 'Adicionar à Despensa';

  @override
  String get quantityLabel => 'Quantidade';

  @override
  String get unitLabel => 'Unidade';

  @override
  String get locationLabel => 'Local';

  @override
  String get expiryDateOptional => 'Validade (opcional)';

  @override
  String get pickDate => 'Escolher data';

  @override
  String get notesLabel => 'Observações';

  @override
  String get theme => 'Tema';

  @override
  String get expiryNotifications => 'Notificações de validade';

  @override
  String get remindBeforeExpiry => 'Avisar antes de vencer';

  @override
  String get dataRetention => 'Retenção de dados';

  @override
  String get manageInventories => 'Gerenciar Despensas';

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
  String get inventoryItems => 'Itens do estoque';

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
    return 'Todos os itens de \"$name\" serão excluídos permanentemente.';
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
  String get itemUpdated => 'Item atualizado.';

  @override
  String get productUpdated => 'Product updated.';

  @override
  String get itemAdded => 'Item adicionado à despensa.';

  @override
  String get itemRemoved => 'Item removido da despensa.';

  @override
  String get saveFailed => 'Não foi possível salvar o item.';

  @override
  String get deleteInventoryItem => 'Excluir itens?';

  @override
  String deleteCountSub(Object count) {
    return 'Excluir $count itens selecionados?';
  }

  @override
  String itemsDeleted(Object count) {
    return '$count excluído(s).';
  }

  @override
  String get itemsRestored => 'Itens restaurados.';

  @override
  String get selectItems => 'Selecionar itens';

  @override
  String get deleteFailed => 'Não foi possível excluir o item.';

  @override
  String get moveToPantry => 'Mover para despensa';

  @override
  String get moveFailed => 'Não foi possível mover os itens.';

  @override
  String get inventoryLoadFailed => 'Não foi possível carregar o estoque.';

  @override
  String get expiryPrefix => 'Val';

  @override
  String get switchPantry => 'Trocar despensa';

  @override
  String get couldNotOpenPlayStore => 'Não foi possível abrir a Play Store.';

  @override
  String get viewOnOpenFoodFacts => 'Ver no Open Food Facts';

  @override
  String get couldNotOpenLink => 'Não foi possível abrir o link.';

  @override
  String get nutrient => 'Nutriente';

  @override
  String get deleteItemTitle => 'Excluir item?';

  @override
  String get deleteItemContent => 'Isso não pode ser desfeito.';

  @override
  String get delete => 'Excluir';

  @override
  String get failedToLoadInventoryItems => 'Não foi possível carregar os itens do estoque.';

  @override
  String get enterPositiveNumber => 'Digite um número positivo';

  @override
  String get notificationsEnabled => 'Notificações ativadas.';

  @override
  String get notificationsDisabled => 'Notificações desativadas.';

  @override
  String get notificationPermissionTitle => 'Notification Permission Required';

  @override
  String get notificationPermissionBody => 'To receive expiry reminders, grant notification permission in your device settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String themeChanged(String theme) {
    return 'Tema: $theme';
  }

  @override
  String retentionDaysValue(int days) {
    return '$days dias';
  }

  @override
  String get dataRetentionDialogTitle => 'Retenção de dados (dias)';

  @override
  String get daysLabel => 'Dias';

  @override
  String retentionPeriodSet(int days) {
    return 'Período de retenção definido para $days dias.';
  }

  @override
  String get noInventories => 'Nenhuma despensa.';

  @override
  String itemsCount(int count) {
    return 'Itens: $count';
  }

  @override
  String get nameLabel => 'Nome';

  @override
  String get create => 'Criar';

  @override
  String get rename => 'Renomear';

  @override
  String inventoryCreated(String name) {
    return '\"$name\" criada.';
  }

  @override
  String inventoryRenamed(String name) {
    return 'Renomeada para \"$name\".';
  }

  @override
  String inventoryDeleted(String name) {
    return '\"$name\" excluída.';
  }

  @override
  String get couldNotCreateInventory => 'Não foi possível criar a despensa.';

  @override
  String get couldNotRenameInventory => 'Não foi possível renomear a despensa.';

  @override
  String get couldNotDeleteInventory => 'Não foi possível excluir a despensa.';

  @override
  String get networkError => 'Erro de rede. Verifique sua conexão.';

  @override
  String get productNotFound => 'Produto nao encontrado no banco de dados.';

  @override
  String get productNotFoundHint => 'Esse produto ainda não está no Open Food Facts. Você pode adicionar manualmente ou contribuir pra comunidade.';

  @override
  String get addManually => 'Adicionar manualmente';

  @override
  String get contributeToOpenFoodFacts => 'Contribuir pro Open Food Facts';

  @override
  String get retry => 'Tentar de novo';

  @override
  String get expiringSoonDays => 'Aviso de vencimento';

  @override
  String expiringSoonDaysValue(int days) {
    return '$days dias';
  }

  @override
  String get expiringSoonDaysDialogTitle => 'Aviso de vencimento (dias)';

  @override
  String expiringSoonDaysSet(int days) {
    return 'Aviso de vencimento definido para $days dias.';
  }

  @override
  String get expiringToday => 'Comida vencendo hoje';

  @override
  String expiresTomorrow(String barcode) {
    return '$barcode vence amanhã';
  }

  @override
  String expiresToday(String barcode) {
    return '$barcode vence hoje!';
  }

  @override
  String get expiryChannelName => 'Lembretes de validade';

  @override
  String get expiryChannelDescription => 'Avisa sobre alimentos vencendo';

  @override
  String get itemRestored => 'Item restaurado.';

  @override
  String get undo => 'Desfazer';

  @override
  String get scanHint => 'Alinhe o código de barras dentro da moldura';

  @override
  String get confirmExitScanner => 'Parar de escanear?';

  @override
  String get confirmExitScannerHint => 'A leitura atual será descartada.';

  @override
  String get stay => 'Ficar';

  @override
  String get leave => 'Sair';

  @override
  String get enterCustomUnit => 'Digite a unidade personalizada';

  @override
  String get enterCustomLocation => 'Digite o local personalizado';

  @override
  String get enterProductDetails => 'Preencha os dados do produto';

  @override
  String get productNameLabel => 'Nome do produto';

  @override
  String get requiredField => 'Campo obrigatório';

  @override
  String get servingSizeHint => 'ex: 100 g, 1 biscoito (28 g)';

  @override
  String get nutritionInfo => 'Nutrição (por 100 g / 100 ml)';

  @override
  String get captureImages => 'Fotos';

  @override
  String get nutritionTableImage => 'Foto da tabela nutricional';

  @override
  String get ingredientsImage => 'Foto da lista de ingredientes';

  @override
  String get productImage => 'Foto do produto';

  @override
  String get saveProduct => 'Salvar produto';

  @override
  String get offlineWarning => 'Você está offline — adicionando produto manualmente';

  @override
  String get nutriscoreExplanation => 'Nutri-Score é um selo nutricional que classifica produtos de A (melhor) a E (pior) com base na qualidade nutricional. Ajuda a comparar produtos parecidos rapidamente.';

  @override
  String nutriscoreNotApplicable(Object category) {
    return 'Nutri-Score não se aplica a esse produto ($category).';
  }

  @override
  String get nutriscoreNotApplicableGeneric => 'Nutri-Score não se aplica a essa categoria de produto.';

  @override
  String get flushCache => 'Limpar cache';

  @override
  String get flushCacheSub => 'Excluir dados e imagens em cache';

  @override
  String get flushCacheConfirm => 'Isso vai excluir todos os dados e imagens em cache obtidos do Open Food Facts. Produtos adicionados manualmente e seus itens de estoque serão mantidos. Os produtos em cache serão baixados de novo na próxima vez que você visualizá-los.';

  @override
  String get flushCacheSuccess => 'Cache limpo. Os produtos serão atualizados automaticamente.';

  @override
  String get flushCacheFailed => 'Não foi possível limpar o cache. Tente de novo.';

  @override
  String get submissionPending => 'Envio pendente pro Open Food Facts';

  @override
  String get submissionSubmitted => 'Enviado pro Open Food Facts';

  @override
  String get submissionFailed => 'Falha no envio pro Open Food Facts';

  @override
  String showInLanguage(String language) {
    return 'Show in $language';
  }

  @override
  String get ingredientsOriginal => 'Show original ingredients';

  @override
  String get ingredientsTranslated => 'Show translated ingredients';

  @override
  String get submissionNotSubmitted => 'Não enviado pro Open Food Facts';

  @override
  String get submissionSuccess => 'Produto enviado pro Open Food Facts.';

  @override
  String get submissionError => 'Falha ao enviar o produto. Toque pra tentar de novo.';

  @override
  String get navHome => 'Início';

  @override
  String get navSearch => 'Buscar';

  @override
  String get navStats => 'Estatísticas';

  @override
  String get navSettings => 'Config';

  @override
  String get searchTitle => 'Buscar Produtos';

  @override
  String get searchProductsHint => 'Busque produtos por nome ou código de barras';

  @override
  String get noSearchResults => 'Nenhum produto encontrado';

  @override
  String totalItemsCount(Object count) {
    return 'Total de itens: $count';
  }

  @override
  String expiringSoonCount(Object count) {
    return 'Vencendo em breve: $count';
  }

  @override
  String addedThisWeek(Object count) {
    return 'Adicionados esta semana: $count';
  }

  @override
  String get filterAll => 'Todos';

  @override
  String get filterByCategory => 'Categoria';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsDataManagement => 'Gerenciamento de Dados';

  @override
  String get settingsMaintenance => 'Manutenção';

  @override
  String get whatsNewTitle => 'Novidades';

  @override
  String whatsNewVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get whatsNewDismiss => 'Entendi';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get comingSoonDescription => 'Este recurso estará disponível em breve.';

  @override
  String get priceTracking => 'Controle de Preços';

  @override
  String get priceTrackingDescription => 'Acompanhe seus gastos.';

  @override
  String get receiptTracking => 'Notas NFC-e';

  @override
  String get receiptTrackingDescription => 'Escanear notas para adicionar produtos.';

  @override
  String get photoCompletenessTitle => 'Fotos dos Produtos';

  @override
  String get contributePhotos => 'Contribuir com fotos';

  @override
  String offNeedsPhotos(Object count) {
    return 'OFF precisa de fotos para $count produtos';
  }

  @override
  String get noCategories => 'Nenhuma categoria';

  @override
  String get statsEmptyTitle => 'Nenhum item para analisar';

  @override
  String get statsEmptySubtitle => 'Adicione produtos à sua despensa para ver estatísticas aqui.';

  @override
  String get addedThisWeekLabel => 'Esta semana';

  @override
  String get addedThisMonthLabel => 'Este mês';

  @override
  String get productDataUnavailable => 'Dados do produto indisponíveis — atualize para baixar';

  @override
  String get locationStats => 'Local';

  @override
  String get nutritionPhoto => 'Nutrição';

  @override
  String get ingredientsPhoto => 'Ingredientes';

  @override
  String get productPhoto => 'Produto';

  @override
  String get sendFeedback => 'Enviar Feedback';

  @override
  String get issueType => 'Tipo de problema';

  @override
  String get bugReport => 'Relato de Bug';

  @override
  String get featureRequest => 'Sugestão de Funcionalidade';

  @override
  String get generalFeedback => 'Feedback Geral';

  @override
  String get regressionReport => 'Regressao';

  @override
  String get bugReportExplanation => 'Algo esta quebrado ou nao funciona como esperado.';

  @override
  String get featureRequestExplanation => 'Sugira uma nova funcionalidade ou melhoria.';

  @override
  String get generalFeedbackExplanation => 'Outros comentarios, duvidas ou sugestoes.';

  @override
  String get regressionReportExplanation => 'Uma funcionalidade que funcionava antes mas nao funciona mais.';

  @override
  String get issueTitle => 'Título';

  @override
  String get issueTitleRequired => 'Título obrigatório (mín. 5 caracteres)';

  @override
  String get issueDescription => 'Descrição';

  @override
  String get issueDescriptionRequired => 'Descrição obrigatória (mín. 10 caracteres)';

  @override
  String get attachScreenshot => 'Anexar captura de tela';

  @override
  String get takePhoto => 'Tirar foto';

  @override
  String get chooseFromGallery => 'Escolher da galeria';

  @override
  String get includeDeviceInfo => 'Incluir informações do dispositivo';

  @override
  String get sending => 'Enviando...';

  @override
  String get issueCreate => 'Criar issue';

  @override
  String get issueSubmitted => 'Obrigado! Seu relato foi enviado.';

  @override
  String get issueQueuedOffline => 'Você está offline. Seu relato será enviado quando você estiver online.';

  @override
  String get issueSubmissionFailed => 'Falha ao enviar. Tente novamente.';

  @override
  String get viewOnGitHub => 'Ver no GitHub';

  @override
  String get issueDuplicate => 'Você enviou um relato similar recentemente.';

  @override
  String get removeScreenshot => 'Remover';

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
  String get couldNotAttachImage => 'Não foi possível anexar a imagem';

  @override
  String get appVersionLabel => 'Versão do app';

  @override
  String get osLabel => 'SO';

  @override
  String get cameraPermissionDenied => 'Permissao da camera negada. Conceda acesso nas Configuracoes.';

  @override
  String get cameraNotAvailable => 'Camera nao disponivel neste dispositivo.';

  @override
  String get scannerGenericError => 'Ocorreu um erro inesperado ao iniciar a camera.';

  @override
  String get switchToManualEntry => 'Digitar codigo manualmente';

  @override
  String get retryScan => 'Tentar de novo';

  @override
  String get couldNotOpenSettings => 'Nao foi possivel abrir as Configuracoes.';

  @override
  String get toggleTorch => 'Alternar lanterna';

  @override
  String get inactivityReminderTitle => 'Hora de reabastecer sua despensa?';

  @override
  String inactivityReminderBody(int days) {
    return 'Voce nao adicionou nenhum produto em $days dias.';
  }

  @override
  String get inactivityReminderEnabled => 'Lembrar de adicionar produtos regularmente';

  @override
  String get inactivityThresholdDays => 'Limite de inatividade (dias)';

  @override
  String get inactivityReminderChannelName => 'Lembretes de inatividade';

  @override
  String get inactivityReminderChannelDescription => 'Lembra voce de adicionar produtos regularmente';

  @override
  String get notificationDeniedWarning => 'Notificacoes desativadas. Lembretes de validade e inatividade so aparecerao ao abrir o app. Ative nas Configuracoes a qualquer momento.';

  @override
  String inactivityThresholdSet(int days) {
    return 'Limite de inatividade definido para $days dias.';
  }

  @override
  String get amoledDarkMode => 'Modo escuro AMOLED';

  @override
  String get amoledDarkModeExplanation => 'Usar fundo preto no modo escuro para economizar bateria em telas AMOLED';

  @override
  String get amoledDarkModeEnabled => 'Modo escuro AMOLED ativado.';

  @override
  String get amoledDarkModeDisabled => 'Modo escuro AMOLED desativado.';

  @override
  String get amoledNudgeTitle => 'Trocar para o modo escuro?';

  @override
  String get amoledNudgeBody => 'O modo escuro pode economizar bateria no seu dispositivo, especialmente se a tela for AMOLED. Voce tambem pode ativar o fundo preto puro nas Configuracoes para economia maxima de energia.';

  @override
  String get amoledNudgeEnable => 'Ativar modo escuro';

  @override
  String get amoledNudgeDismiss => 'Agora nao';

  @override
  String get translationReport => 'Relato de Traducao';

  @override
  String get translationReportExplanation => 'Relate um problema com a traducao de um produto ou sugira uma nova traducao.';

  @override
  String get feedbackRateLimit => 'Voce so pode enviar um relato por minuto e ate 5 por dia. Tente novamente mais tarde.';

  @override
  String get couldNotOpenLinkFallback => 'URL copiada para a area de transferencia.';

  @override
  String get includeLogs => 'Incluir registros do app';

  @override
  String get includeLogsExplanation => 'Avisos e erros recentes desta sessao';

  @override
  String get logsPrivacyNote => 'Os registros podem conter nomes de produtos e horarios.';

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
  String get navList => 'Lista';

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
  String get dismiss => 'Dispensar';

  @override
  String get priceHidden => 'Preco oculto';

  @override
  String get scanFailed => 'Falha ao escanear codigo de barras.';

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
      other: '$count itens selecionados',
      one: '1 item selecionado',
      zero: 'Nenhum item selecionado',
    );
    return '$_temp0';
  }

  @override
  String get moveButton => 'Mover';

  @override
  String get noOtherInventories => 'Nenhuma outra despensa disponível.';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr(): super('pt_BR');

  @override
  String get myPantry => 'Minha Despensa';

  @override
  String get settings => 'Configurações';

  @override
  String get scanBarcode => 'Escanear Código';

  @override
  String get enterBarcode => 'Digitar Código';

  @override
  String get expired => 'Vencido';

  @override
  String get expiringSoon => 'Vence em breve';

  @override
  String get good => 'Bom';

  @override
  String get searchHint => 'Buscar por nome ou código';

  @override
  String get noItemsMatch => 'Nenhum item encontrado';

  @override
  String get emptyPantryTitle => 'Sua despensa está vazia';

  @override
  String get emptyPantrySubtitle => 'Toque no botão abaixo pra escanear seu primeiro produto';

  @override
  String get scanFirstProduct => 'Escanear um código';

  @override
  String get barcodeLabel => 'Código de barras';

  @override
  String get invalidBarcode => 'Digite um código de barras valido (8-13 digitos).';

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
  String get fat => 'Gordura';

  @override
  String get fiber => 'Fibra';

  @override
  String get salt => 'Sal';

  @override
  String get per100g => 'Por 100 g';

  @override
  String get ingredients => 'Ingredientes';

  @override
  String get yourInventory => 'Seu estoque';

  @override
  String get noItemsInPantry => 'Nenhum item na despensa ainda.';

  @override
  String get addToInventory => 'Adicionar ao Estoque';

  @override
  String get copyBarcode => 'Copiar código';

  @override
  String get barcodeCopied => 'Código copiado!';

  @override
  String get removedFromPantry => 'Removido da despensa.';

  @override
  String get updateItem => 'Atualizar Item';

  @override
  String get addToPantry => 'Adicionar à Despensa';

  @override
  String get quantityLabel => 'Quantidade';

  @override
  String get unitLabel => 'Unidade';

  @override
  String get locationLabel => 'Local';

  @override
  String get expiryDateOptional => 'Validade (opcional)';

  @override
  String get pickDate => 'Escolher data';

  @override
  String get notesLabel => 'Observações';

  @override
  String get theme => 'Tema';

  @override
  String get expiryNotifications => 'Notificações de validade';

  @override
  String get remindBeforeExpiry => 'Avisar antes de vencer';

  @override
  String get dataRetention => 'Retenção de dados';

  @override
  String get manageInventories => 'Gerenciar Despensas';

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
  String get inventoryItems => 'Itens do estoque';

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
    return 'Todos os itens de \"$name\" serão excluídos permanentemente.';
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
  String get itemUpdated => 'Item atualizado.';

  @override
  String get productUpdated => 'Produto atualizado.';

  @override
  String get itemAdded => 'Item adicionado à despensa.';

  @override
  String get itemRemoved => 'Item removido da despensa.';

  @override
  String get saveFailed => 'Não foi possível salvar o item.';

  @override
  String get deleteInventoryItem => 'Excluir itens?';

  @override
  String deleteCountSub(Object count) {
    return 'Excluir $count itens selecionados?';
  }

  @override
  String itemsDeleted(Object count) {
    return '$count excluído(s).';
  }

  @override
  String get itemsRestored => 'Itens restaurados.';

  @override
  String get selectItems => 'Selecionar itens';

  @override
  String get deleteFailed => 'Não foi possível excluir o item.';

  @override
  String get moveToPantry => 'Mover para despensa';

  @override
  String get moveFailed => 'Não foi possível mover os itens.';

  @override
  String get inventoryLoadFailed => 'Não foi possível carregar o estoque.';

  @override
  String get expiryPrefix => 'Val';

  @override
  String get switchPantry => 'Trocar despensa';

  @override
  String get couldNotOpenPlayStore => 'Não foi possível abrir a Play Store.';

  @override
  String get viewOnOpenFoodFacts => 'Ver no Open Food Facts';

  @override
  String get couldNotOpenLink => 'Não foi possível abrir o link.';

  @override
  String get nutrient => 'Nutriente';

  @override
  String get deleteItemTitle => 'Excluir item?';

  @override
  String get deleteItemContent => 'Isso não pode ser desfeito.';

  @override
  String get delete => 'Excluir';

  @override
  String get failedToLoadInventoryItems => 'Não foi possível carregar os itens do estoque.';

  @override
  String get enterPositiveNumber => 'Digite um número positivo';

  @override
  String get notificationsEnabled => 'Notificações ativadas.';

  @override
  String get notificationsDisabled => 'Notificações desativadas.';

  @override
  String get notificationPermissionTitle => 'Permissao de Notificacao Necessaria';

  @override
  String get notificationPermissionBody => 'Para receber lembretes de validade, conceda permissao de notificacao nas configuracoes do dispositivo.';

  @override
  String get openSettings => 'Abrir Configuracoes';

  @override
  String themeChanged(String theme) {
    return 'Tema: $theme';
  }

  @override
  String retentionDaysValue(int days) {
    return '$days dias';
  }

  @override
  String get dataRetentionDialogTitle => 'Retenção de dados (dias)';

  @override
  String get daysLabel => 'Dias';

  @override
  String retentionPeriodSet(int days) {
    return 'Período de retenção definido para $days dias.';
  }

  @override
  String get noInventories => 'Nenhuma despensa.';

  @override
  String itemsCount(int count) {
    return 'Itens: $count';
  }

  @override
  String get nameLabel => 'Nome';

  @override
  String get create => 'Criar';

  @override
  String get rename => 'Renomear';

  @override
  String inventoryCreated(String name) {
    return '\"$name\" criada.';
  }

  @override
  String inventoryRenamed(String name) {
    return 'Renomeada para \"$name\".';
  }

  @override
  String inventoryDeleted(String name) {
    return '\"$name\" excluída.';
  }

  @override
  String get couldNotCreateInventory => 'Não foi possível criar a despensa.';

  @override
  String get couldNotRenameInventory => 'Não foi possível renomear a despensa.';

  @override
  String get couldNotDeleteInventory => 'Não foi possível excluir a despensa.';

  @override
  String get networkError => 'Erro de rede. Verifique sua conexão.';

  @override
  String get productNotFound => 'Produto nao encontrado no banco de dados.';

  @override
  String get productNotFoundHint => 'Esse produto ainda não está no Open Food Facts. Você pode adicionar manualmente ou contribuir pra comunidade.';

  @override
  String get addManually => 'Adicionar manualmente';

  @override
  String get contributeToOpenFoodFacts => 'Contribuir pro Open Food Facts';

  @override
  String get retry => 'Tentar de novo';

  @override
  String get expiringSoonDays => 'Aviso de vencimento';

  @override
  String expiringSoonDaysValue(int days) {
    return '$days dias';
  }

  @override
  String get expiringSoonDaysDialogTitle => 'Aviso de vencimento (dias)';

  @override
  String expiringSoonDaysSet(int days) {
    return 'Aviso de vencimento definido para $days dias.';
  }

  @override
  String get expiringToday => 'Comida vencendo hoje';

  @override
  String expiresTomorrow(String barcode) {
    return '$barcode vence amanhã';
  }

  @override
  String expiresToday(String barcode) {
    return '$barcode vence hoje!';
  }

  @override
  String get expiryChannelName => 'Lembretes de validade';

  @override
  String get expiryChannelDescription => 'Avisa sobre alimentos vencendo';

  @override
  String get itemRestored => 'Item restaurado.';

  @override
  String get undo => 'Desfazer';

  @override
  String get scanHint => 'Alinhe o código de barras dentro da moldura';

  @override
  String get confirmExitScanner => 'Parar de escanear?';

  @override
  String get confirmExitScannerHint => 'A leitura atual será descartada.';

  @override
  String get stay => 'Ficar';

  @override
  String get leave => 'Sair';

  @override
  String get enterCustomUnit => 'Digite a unidade personalizada';

  @override
  String get enterCustomLocation => 'Digite o local personalizado';

  @override
  String get enterProductDetails => 'Preencha os dados do produto';

  @override
  String get productNameLabel => 'Nome do produto';

  @override
  String get requiredField => 'Campo obrigatório';

  @override
  String get servingSizeHint => 'ex: 100 g, 1 biscoito (28 g)';

  @override
  String get nutritionInfo => 'Nutrição (por 100 g / 100 ml)';

  @override
  String get captureImages => 'Fotos';

  @override
  String get nutritionTableImage => 'Foto da tabela nutricional';

  @override
  String get ingredientsImage => 'Foto da lista de ingredientes';

  @override
  String get productImage => 'Foto do produto';

  @override
  String get saveProduct => 'Salvar produto';

  @override
  String get offlineWarning => 'Você está offline — adicionando produto manualmente';

  @override
  String get nutriscoreExplanation => 'Nutri-Score é um selo nutricional que classifica produtos de A (melhor) a E (pior) com base na qualidade nutricional. Ajuda a comparar produtos parecidos rapidamente.';

  @override
  String nutriscoreNotApplicable(Object category) {
    return 'Nutri-Score não se aplica a esse produto ($category).';
  }

  @override
  String get nutriscoreNotApplicableGeneric => 'Nutri-Score não se aplica a essa categoria de produto.';

  @override
  String get flushCache => 'Limpar cache';

  @override
  String get flushCacheSub => 'Excluir dados e imagens em cache';

  @override
  String get flushCacheConfirm => 'Isso vai excluir todos os dados e imagens em cache obtidos do Open Food Facts. Produtos adicionados manualmente e seus itens de estoque serão mantidos. Os produtos em cache serão baixados de novo na próxima vez que você visualizá-los.';

  @override
  String get flushCacheSuccess => 'Cache limpo. Os produtos serão atualizados automaticamente.';

  @override
  String get flushCacheFailed => 'Não foi possível limpar o cache. Tente de novo.';

  @override
  String get submissionPending => 'Envio pendente pro Open Food Facts';

  @override
  String get submissionSubmitted => 'Enviado pro Open Food Facts';

  @override
  String get submissionFailed => 'Falha no envio pro Open Food Facts';

  @override
  String showInLanguage(String language) {
    return 'Mostrar em $language';
  }

  @override
  String get ingredientsOriginal => 'Show original ingredients';

  @override
  String get ingredientsTranslated => 'Show translated ingredients';

  @override
  String get submissionNotSubmitted => 'Não enviado pro Open Food Facts';

  @override
  String get submissionSuccess => 'Produto enviado pro Open Food Facts.';

  @override
  String get submissionError => 'Falha ao enviar o produto. Toque pra tentar de novo.';

  @override
  String get navHome => 'Início';

  @override
  String get navSearch => 'Buscar';

  @override
  String get navStats => 'Estatísticas';

  @override
  String get navSettings => 'Config';

  @override
  String get searchTitle => 'Buscar Produtos';

  @override
  String get searchProductsHint => 'Busque produtos por nome ou código de barras';

  @override
  String get noSearchResults => 'Nenhum produto encontrado';

  @override
  String totalItemsCount(Object count) {
    return 'Total de itens: $count';
  }

  @override
  String expiringSoonCount(Object count) {
    return 'Vencendo em breve: $count';
  }

  @override
  String addedThisWeek(Object count) {
    return 'Adicionados esta semana: $count';
  }

  @override
  String get filterAll => 'Todos';

  @override
  String get filterByCategory => 'Categoria';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsDataManagement => 'Gerenciamento de Dados';

  @override
  String get settingsMaintenance => 'Manutenção';

  @override
  String get whatsNewTitle => 'Novidades';

  @override
  String whatsNewVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get whatsNewDismiss => 'Entendi';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get comingSoonDescription => 'Este recurso estará disponível em breve.';

  @override
  String get priceTracking => 'Controle de Preços';

  @override
  String get priceTrackingDescription => 'Acompanhe seus gastos.';

  @override
  String get receiptTracking => 'Notas NFC-e';

  @override
  String get receiptTrackingDescription => 'Escanear notas para adicionar produtos.';

  @override
  String get photoCompletenessTitle => 'Fotos dos Produtos';

  @override
  String get contributePhotos => 'Contribuir com fotos';

  @override
  String offNeedsPhotos(Object count) {
    return 'OFF precisa de fotos para $count produtos';
  }

  @override
  String get noCategories => 'Nenhuma categoria';

  @override
  String get statsEmptyTitle => 'Nenhum item para analisar';

  @override
  String get statsEmptySubtitle => 'Adicione produtos à sua despensa para ver estatísticas aqui.';

  @override
  String get addedThisWeekLabel => 'Esta semana';

  @override
  String get addedThisMonthLabel => 'Este mês';

  @override
  String get productDataUnavailable => 'Dados do produto indisponíveis — atualize para baixar';

  @override
  String get locationStats => 'Local';

  @override
  String get nutritionPhoto => 'Nutrição';

  @override
  String get ingredientsPhoto => 'Ingredientes';

  @override
  String get productPhoto => 'Produto';

  @override
  String get sendFeedback => 'Enviar Feedback';

  @override
  String get issueType => 'Tipo de problema';

  @override
  String get bugReport => 'Relato de Bug';

  @override
  String get featureRequest => 'Sugestão de Funcionalidade';

  @override
  String get generalFeedback => 'Feedback Geral';

  @override
  String get regressionReport => 'Regressao';

  @override
  String get bugReportExplanation => 'Algo esta quebrado ou nao funciona como esperado.';

  @override
  String get featureRequestExplanation => 'Sugira uma nova funcionalidade ou melhoria.';

  @override
  String get generalFeedbackExplanation => 'Outros comentarios, duvidas ou sugestoes.';

  @override
  String get regressionReportExplanation => 'Uma funcionalidade que funcionava antes mas nao funciona mais.';

  @override
  String get issueTitle => 'Título';

  @override
  String get issueTitleRequired => 'Título obrigatório (mín. 5 caracteres)';

  @override
  String get issueDescription => 'Descrição';

  @override
  String get issueDescriptionRequired => 'Descrição obrigatória (mín. 10 caracteres)';

  @override
  String get attachScreenshot => 'Anexar captura de tela';

  @override
  String get takePhoto => 'Tirar foto';

  @override
  String get chooseFromGallery => 'Escolher da galeria';

  @override
  String get includeDeviceInfo => 'Incluir informações do dispositivo';

  @override
  String get sending => 'Enviando...';

  @override
  String get issueCreate => 'Criar issue';

  @override
  String get issueSubmitted => 'Obrigado! Seu relato foi enviado.';

  @override
  String get issueQueuedOffline => 'Você está offline. Seu relato será enviado quando você estiver online.';

  @override
  String get issueSubmissionFailed => 'Falha ao enviar. Tente novamente.';

  @override
  String get viewOnGitHub => 'Ver no GitHub';

  @override
  String get issueDuplicate => 'Você enviou um relato similar recentemente.';

  @override
  String get removeScreenshot => 'Remover';

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
  String get couldNotAttachImage => 'Não foi possível anexar a imagem';

  @override
  String get appVersionLabel => 'Versao do app';

  @override
  String get osLabel => 'SO';

  @override
  String get cameraPermissionDenied => 'Permissao da camera negada. Conceda acesso nas Configuracoes.';

  @override
  String get cameraNotAvailable => 'Camera nao disponivel neste dispositivo.';

  @override
  String get scannerGenericError => 'Ocorreu um erro inesperado ao iniciar a camera.';

  @override
  String get switchToManualEntry => 'Digitar codigo manualmente';

  @override
  String get retryScan => 'Tentar de novo';

  @override
  String get couldNotOpenSettings => 'Nao foi possivel abrir as Configuracoes.';

  @override
  String get toggleTorch => 'Alternar lanterna';

  @override
  String get inactivityReminderTitle => 'Hora de reabastecer sua despensa?';

  @override
  String inactivityReminderBody(int days) {
    return 'Voce nao adicionou nenhum produto em $days dias.';
  }

  @override
  String get inactivityReminderEnabled => 'Lembrar de adicionar produtos regularmente';

  @override
  String get inactivityThresholdDays => 'Limite de inatividade (dias)';

  @override
  String get inactivityReminderChannelName => 'Lembretes de inatividade';

  @override
  String get inactivityReminderChannelDescription => 'Lembra voce de adicionar produtos regularmente';

  @override
  String get notificationDeniedWarning => 'Notificacoes desativadas. Lembretes de validade e inatividade so aparecerao ao abrir o app. Ative nas Configuracoes a qualquer momento.';

  @override
  String inactivityThresholdSet(int days) {
    return 'Limite de inatividade definido para $days dias.';
  }

  @override
  String get amoledDarkMode => 'Modo escuro AMOLED';

  @override
  String get amoledDarkModeExplanation => 'Usar fundo preto no modo escuro para economizar bateria em telas AMOLED';

  @override
  String get amoledDarkModeEnabled => 'Modo escuro AMOLED ativado.';

  @override
  String get amoledDarkModeDisabled => 'Modo escuro AMOLED desativado.';

  @override
  String get amoledNudgeTitle => 'Trocar para o modo escuro?';

  @override
  String get amoledNudgeBody => 'O modo escuro pode economizar bateria no seu dispositivo, especialmente se a tela for AMOLED. Voce tambem pode ativar o fundo preto puro nas Configuracoes para economia maxima de energia.';

  @override
  String get amoledNudgeEnable => 'Ativar modo escuro';

  @override
  String get amoledNudgeDismiss => 'Agora nao';

  @override
  String get translationReport => 'Relato de Traducao';

  @override
  String get translationReportExplanation => 'Relate um problema com a traducao de um produto ou sugira uma nova traducao.';

  @override
  String get feedbackRateLimit => 'Voce so pode enviar um relato por minuto e ate 5 por dia. Tente novamente mais tarde.';

  @override
  String get couldNotOpenLinkFallback => 'URL copiada para a area de transferencia.';

  @override
  String get includeLogs => 'Incluir registros do app';

  @override
  String get includeLogsExplanation => 'Avisos e erros recentes desta sessao';

  @override
  String get logsPrivacyNote => 'Os registros podem conter nomes de produtos e horarios.';

  @override
  String get price => 'Preco';

  @override
  String get prices => 'Precos';

  @override
  String get addPrice => 'Adicionar preco';

  @override
  String get editPrice => 'Editar preco';

  @override
  String get deletePrice => 'Excluir preco';

  @override
  String get priceAdded => 'Preco adicionado.';

  @override
  String get priceUpdated => 'Preco atualizado.';

  @override
  String get priceDeleted => 'Preco excluido.';

  @override
  String get priceHistory => 'Historico de precos';

  @override
  String get noPrices => 'Nenhum preco registrado.';

  @override
  String get totalValue => 'Valor total';

  @override
  String get averagePrice => 'Preco medio';

  @override
  String get showPrices => 'Mostrar precos';

  @override
  String get hidePrices => 'Ocultar precos por privacidade';

  @override
  String get hidePricesDescription => 'Substituir valores de preco por texto mascarado em todos os lugares, incluindo a tela de estatisticas.';

  @override
  String get pricesHidden => 'Precos ocultos.';

  @override
  String get pricesVisible => 'Precos visiveis.';

  @override
  String get priceTrackingEnabled => 'Ativar controle de precos';

  @override
  String get priceRetentionDays => 'Retencao de precos';

  @override
  String priceRetentionDaysValue(int days) {
    return 'Manter precos por $days dias (0 = manter para sempre)';
  }

  @override
  String get currency => 'Moeda';

  @override
  String get baseCurrency => 'Moeda base';

  @override
  String get baseCurrencyDescription => 'Todos os precos sao exibidos nesta moeda.';

  @override
  String get store => 'Loja';

  @override
  String get discounted => 'Com desconto';

  @override
  String get regularPrice => 'Preco normal';

  @override
  String get confirmDeletePrice => 'Excluir esta entrada de preco?';

  @override
  String get syncToOpenPrices => 'Compartilhar com Open Prices';

  @override
  String get syncToOpenPricesDescription => 'Contribua com seus dados de preco para o banco de dados comunitario.';

  @override
  String get openPricesToken => 'Token da API Open Prices';

  @override
  String get openPricesTokenDescription => 'Token gerado da sua conta do Open Food Facts.';

  @override
  String get openPricesTokenSaved => 'Token salvo.';

  @override
  String get openPricesSyncStarted => 'Sincronizando precos...';

  @override
  String openPricesSyncComplete(int count) {
    return '$count precos sincronizados.';
  }

  @override
  String get priceSyncStatus => 'Sincronizado';

  @override
  String get priceSyncPending => 'Sincronizacao pendente';

  @override
  String get priceSyncFailed => 'Falha na sincronizacao';

  @override
  String get priceTrendUp => 'Precos estao subindo';

  @override
  String get priceTrendDown => 'Precos estao caindo';

  @override
  String get priceTrendStable => 'Precos estaveis';

  @override
  String get datePurchased => 'Data da compra';

  @override
  String get pricedItems => 'Itens com precos';

  @override
  String itemWithPriceCount(int count, int total) {
    return '$count de $total itens tem precos';
  }

  @override
  String get openPricesProofExplanation => 'Para compartilhar com o Open Prices, uma foto do recibo ou da etiqueta de prateleira e necessaria como comprovante. Precos sem foto permanecem apenas na sua despensa local.';

  @override
  String get openPricesConsentTitle => 'Contribuir com Open Prices';

  @override
  String get openPricesConsentBody => 'Open Prices e um banco de dados comunitario de precos de alimentos. Para contribuir, uma foto do recibo ou da etiqueta de prateleira e necessaria como comprovante.\n\nAo adicionar ou editar um preco, voce tera a opcao de tirar uma foto de comprovante. Precos sem foto permanecem na sua despensa local e nao sao compartilhados.';

  @override
  String get iUnderstand => 'Entendi';

  @override
  String get notes => 'Observacoes';

  @override
  String get navList => 'Lista';

  @override
  String get shoppingList => 'Lista de Compras';

  @override
  String get addShoppingItem => 'Adicionar item';

  @override
  String get itemName => 'Nome do item';

  @override
  String get markPurchased => 'Marcar como comprado';

  @override
  String get unmarkPurchased => 'Desmarcar comprado';

  @override
  String get moveToInventory => 'Mover para despensa';

  @override
  String get addAgain => 'Adicionar de novo';

  @override
  String get emptyShoppingList => 'Sua lista de compras esta vazia';

  @override
  String get emptyShoppingListSub => 'Adicione itens de um produto ou toque em + para adicionar manualmente';

  @override
  String get deleteItem => 'Excluir item';

  @override
  String get clearPurchased => 'Limpar comprados';

  @override
  String get clearPurchasedConfirm => 'Remover todos os itens comprados?';

  @override
  String get purchasedItems => 'Comprados';

  @override
  String get pendingItems => 'Para comprar';

  @override
  String get quickAddHint => 'Nome, ex: Leite';

  @override
  String get undoDeleteShoppingItem => 'Item excluido';

  @override
  String get undoClearPurchased => 'Itens comprados limpos';

  @override
  String get shareShoppingList => 'Compartilhar lista';

  @override
  String get add => 'Adicionar';

  @override
  String get quantity => 'Quantidade';

  @override
  String get addToShoppingList => 'Adicionar a lista de compras';

  @override
  String get addToShoppingListTooltip => 'Lista de compras';

  @override
  String get addToPantryAfterPrice => 'Adicionar a sua despensa?';

  @override
  String get addToPantryAfterPriceDesc => 'Registre a quantidade comprada para acompanhar no seu estoque.';

  @override
  String get howManyBought => 'Quantas unidades voce comprou?';

  @override
  String get choosePantry => 'Escolher despensa';

  @override
  String get addToPantrySkipped => 'Preco salvo. Adicione pela pagina do produto para acompanhar.';

  @override
  String get invalidPriceAmount => 'Digite um valor de preco valido';

  @override
  String get dismiss => 'Dispensar';

  @override
  String get priceHidden => 'Preco oculto';

  @override
  String get scanFailed => 'Falha ao escanear codigo de barras.';

  @override
  String selectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens selecionados',
      one: '1 item selecionado',
      zero: 'Nenhum item selecionado',
    );
    return '$_temp0';
  }

  @override
  String get moveButton => 'Mover';

  @override
  String get noOtherInventories => 'Nenhuma outra despensa disponível.';
}
