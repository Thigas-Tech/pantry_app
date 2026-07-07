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
  String get productNotFound => 'Produto não encontrado';

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
  String get productNotFound => 'Produto não encontrado';

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
}
