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
  String get invalidBarcode => 'Digite um código de barras válido.';

  @override
  String get brandLabel => 'Marca';

  @override
  String get categoryLabel => 'Categorias';

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
  String deleteCountSub(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $count itens selecionados?',
      one: 'Excluir 1 item selecionado?',
    );
    return '$_temp0';
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
  String get expiryPrefix => 'Exp';

  @override
  String get switchPantry => 'Trocar despensa';

  @override
  String get couldNotOpenPlayStore => 'Não foi possível abrir a Play Store.';

  @override
  String get viewOnOpenFoodFacts => 'Ver no Open Food Facts';

  @override
  String get couldNotOpenLink => 'Não foi possível abrir o link.';

  @override
  String get nutrient => 'Nutrientes';

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
  String get couldNotResolveProduct => 'Não foi possível carregar os detalhes do produto.';

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
  String expiresTomorrow(String name) {
    return '$name vence amanhã';
  }

  @override
  String expiresToday(String name) {
    return '$name vence hoje!';
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
  String get navRecipes => 'Receitas';

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
  String get productNotFoundSearch => 'Nenhum produto encontrado em Produtos Embalados.';

  @override
  String get productNotFoundBarcodeHint => 'Tente escanear ou digitar o codigo de barras do produto.';

  @override
  String get productNotFoundOfflineHint => 'A pesquisa requer conexao com a internet.';

  @override
  String get enterBarcodePrompt => 'Digite ou cole um codigo de barras';

  @override
  String get productNotInDatabase => 'Este codigo de barras nao esta registrado no Open Food Facts.';

  @override
  String get productNotInDatabaseHint => 'Voce ainda pode usar este produto localmente.';

  @override
  String get contributeToOffComingSoonTitle => 'Em Breve';

  @override
  String get contributeToOffComingSoonBody => 'A contribuicao direta de produtos ao Open Food Facts ainda nao esta disponivel. Um issue no GitHub foi criado para acompanhar este recurso.';

  @override
  String get saveLocallyAction => 'Salvar Localmente';

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
  String get locationStats => 'Locais';

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
  String get price => 'Preco';

  @override
  String get prices => 'Precos';

  @override
  String get addPrice => 'Preco salvo';

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
  String get addNewStore => 'Adicionar nova loja';

  @override
  String get storeAdded => 'Loja adicionada';

  @override
  String get storeAlreadyExists => 'Já existe uma loja com este nome';

  @override
  String get storeName => 'Nome da loja';

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
  String get notes => 'Observações';

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
  String get productSearchHint => 'Buscar produtos por nome';

  @override
  String get addCustomItem => 'Adicionar item personalizado';

  @override
  String get noProductsFound => 'Nenhum produto encontrado. Tente um item personalizado.';

  @override
  String get backToSearch => 'Voltar a busca';

  @override
  String get removePrice => 'Preco removido';

  @override
  String shoppingTotal(String total) {
    return 'Total: $total';
  }

  @override
  String shoppingMixedCurrency(String total) {
    return '$total';
  }

  @override
  String get addToInventoryFromList => 'Adicionar a despensa';

  @override
  String addToInventoryConfirm(int count, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: ' $skipped itens sem codigo de barras ficarao na lista.',
      one: ' 1 item sem codigo de barras ficara na lista.',
      zero: '',
    );
    return 'Adicionar $count itens a sua despensa? Os precos serao salvos.$_temp0';
  }

  @override
  String itemsMovedToInventory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens adicionados a despensa',
      one: '1 item adicionado a despensa',
    );
    return '$_temp0';
  }

  @override
  String itemsSkippedNoBarcode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens restantes — adicione um codigo de barras ou crie um produto',
      one: '1 item restante — adicione um codigo de barras ou crie um produto',
    );
    return '$_temp0';
  }

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
  String get invalidPriceAmount => 'Digite um valor de preço válido';

  @override
  String get apiSearchWarning => 'Nao foi possivel buscar todos os resultados online. Alguns produtos podem estar faltando.';

  @override
  String get dismiss => 'Dispensar';

  @override
  String get priceHidden => 'Preco oculto';

  @override
  String get scanFailed => 'Falha ao escanear codigo de barras.';

  @override
  String get testNotification => 'Enviar notificacao de teste';

  @override
  String get testScheduledNotification => 'Enviar notificacao de teste agendada (2 min)';

  @override
  String get testNotificationScheduled => 'Notificacao de teste agendada.';

  @override
  String get testNotificationSent => 'Notificacao de teste enviada.';

  @override
  String get testNotificationFailed => 'Falha ao enviar notificacao de teste.';

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

  @override
  String get themeModeSystem => 'Sistema';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Escuro';

  @override
  String get defaultInventoryName => 'Casa';

  @override
  String get locationPantry => 'Despensa';

  @override
  String get locationFridge => 'Geladeira';

  @override
  String get locationFreezer => 'Freezer';

  @override
  String get unitSingular => 'unidade';

  @override
  String get unitPlural => 'unidades';

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
  String get generalNotificationChannelName => 'Notificacoes Gerais';

  @override
  String get generalNotificationChannelDescription => 'Notificacoes padrao do app';

  @override
  String get testNotificationTitle => 'Teste bem-sucedido';

  @override
  String get testNotificationBody => 'Notificacoes imediatas estao funcionando!';

  @override
  String get testScheduledTitle => 'Teste Agendado';

  @override
  String get testScheduledBody => 'Isso foi disparado 5 segundos depois.';

  @override
  String get retryNow => 'Tentar de novo agora';

  @override
  String get bearerTokenLabel => 'Token Bearer';

  @override
  String pendingFeedback(Object count) {
    return 'Feedback pendente: $count';
  }

  @override
  String submissionResult(Object failed, Object submitted) {
    return 'Enviados $submitted, $failed falharam';
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
  String get unreleasedVersion => 'Nao lancado';

  @override
  String get categoryDairy => 'Laticinios';

  @override
  String get categoryMilks => 'Leites';

  @override
  String get categoryMilk => 'Leite';

  @override
  String get categoryYogurts => 'Iogurtes';

  @override
  String get categoryCheeses => 'Queijos';

  @override
  String get categoryEggsAndProducts => 'Ovos e derivados';

  @override
  String get categoryMeats => 'Carnes';

  @override
  String get categoryFishesAndSeafoods => 'Peixes e frutos do mar';

  @override
  String get categoryBeverages => 'Bebidas';

  @override
  String get categoryAlcoholicBeverages => 'Bebidas alcoolicas';

  @override
  String get categoryBreads => 'Paes';

  @override
  String get categoryCerealsAndPotatoes => 'Cereais e batatas';

  @override
  String get categoryFruitsAndVegetables => 'Alimentos a base de frutas e vegetais';

  @override
  String get categoryConfectioneries => 'Confeitaria';

  @override
  String get categorySugarySnacks => 'Lanches doces';

  @override
  String get categorySaltySnacks => 'Lanches salgados';

  @override
  String get categoryFats => 'Gorduras';

  @override
  String get categorySauces => 'Molhos';

  @override
  String get categorySoups => 'Sopas';

  @override
  String get categoryPreparedMeals => 'Pratos prontos';

  @override
  String get categoryFrozenFoods => 'Alimentos congelados';

  @override
  String get categoryDesserts => 'Sobremesas';

  @override
  String get categoryPastries => 'Pasteis';

  @override
  String get categoryBiscuitsAndCakes => 'Biscoitos e bolos';

  @override
  String get categoryPizzas => 'Pizzas';

  @override
  String get categorySandwiches => 'Sanduiches';

  @override
  String get categoryBabyFoods => 'Alimentos infantis';

  @override
  String get categoryDietaryFoods => 'Alimentos dieteticos';

  @override
  String get categorySpicesAndHerbs => 'Especiarias e ervas';

  @override
  String get categoryNutsAndProducts => 'Nozes e castanhas';

  @override
  String get categoryPlantBasedFoods => 'Alimentos vegetais';

  @override
  String get categoryLegumesAndProducts => 'Leguminosas e derivados';

  @override
  String get categoryCoffees => 'Cafes';

  @override
  String get categoryTeas => 'Chas';

  @override
  String get categoryChocolateProducts => 'Produtos de chocolate';

  @override
  String get categoryIceCreams => 'Sorvetes';

  @override
  String get categoryFruitJuices => 'Sucos de fruta';

  @override
  String get categorySodas => 'Refrigerantes';

  @override
  String get categoryWaters => 'Aguas';

  @override
  String get categoryMeatAndProducts => 'Carnes e derivados';

  @override
  String get categoryBreakfasts => 'Cafés da manhã';

  @override
  String get categoryBread => 'Pão';

  @override
  String get categoryCakes => 'Bolos';

  @override
  String get categoryCereals => 'Cereais';

  @override
  String get categoryChocolate => 'Chocolate';

  @override
  String get categoryCondiments => 'Condimentos';

  @override
  String get categoryEggs => 'Ovos';

  @override
  String get categoryFish => 'Peixe';

  @override
  String get categoryFruit => 'Fruta';

  @override
  String get categoryFruits => 'Frutas';

  @override
  String get categoryGrains => 'Grãos';

  @override
  String get categoryHotBeverages => 'Bebidas quentes';

  @override
  String get categoryLegumes => 'Leguminosas';

  @override
  String get categoryOils => 'Óleos';

  @override
  String get categoryPasta => 'Massas';

  @override
  String get categoryPoultry => 'Aves';

  @override
  String get categorySeeds => 'Sementes';

  @override
  String get categorySnacks => 'Lanches';

  @override
  String get categorySpreads => 'Pastas';

  @override
  String get categorySweetSpreads => 'Pastas doces';

  @override
  String get categoryVegetables => 'Vegetais';

  @override
  String get categoryBiscuitsAndCrackers => 'Bolachas e biscoitos';

  @override
  String get categoryLegumeOils => 'Oleos de leguminosas';

  @override
  String get categoryUhtMilks => 'Leites UHT';

  @override
  String get categoryCannedSardines => 'Sardinhas enlatadas';

  @override
  String get categoryCerealFlours => 'Farinhas de cereais';

  @override
  String get categoryCerealStarches => 'Amidos de cereais';

  @override
  String get categoryCerealsAndProducts => 'Cereais e seus produtos';

  @override
  String get categoryDairies => 'Laticinios';

  @override
  String get categoryInstantBeverages => 'Bebidas instantaneas';

  @override
  String get categoryMilkfat => 'Gordura do leite';

  @override
  String get categoryStarches => 'Amidos';

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
  String get fromYourPantry => 'Da sua despensa';

  @override
  String get inYourPantry => 'Na sua despensa';

  @override
  String get monthlySpendingTitle => 'Gastos mensais';

  @override
  String get storeSpendingTitle => 'Gastos por loja';

  @override
  String get nutriscoreByStoreTitle => 'Nutri-Score por loja';

  @override
  String get noStoreData => 'Sem dados de compra';

  @override
  String get noSpendingData => 'Adicione precos para ver tendencias';

  @override
  String get monthLabel => 'Mes';

  @override
  String get averageScore => 'Nota media';

  @override
  String get produceApple => 'Maça';

  @override
  String get produceBanana => 'Banana';

  @override
  String get produceOrange => 'Laranja';

  @override
  String get produceTomato => 'Tomate';

  @override
  String get producePotato => 'Batata';

  @override
  String get produceCarrot => 'Cenoura';

  @override
  String get produceOnion => 'Cebola';

  @override
  String get produceLettuce => 'Alface';

  @override
  String get exactAlarmsDeniedHint => 'Notificações agendadas podem sofrer atrasos porque alarmes exatos não foram concedidos. Conceda em Configurações > Notificações > Agendar alarmes exatos.';

  @override
  String get notificationRationaleTitle => 'Notificações ajudam você a acompanhar';

  @override
  String get notificationRationaleBody => 'O Pantry usa notificações para:\n\n- Lembrar quando os alimentos estão perto de vencer\n- Lembrar de adicionar produtos regularmente\n- Confirmar que notificações de teste funcionam\n\nVocê pode mudar isso a qualquer momento em Configurações.';

  @override
  String get notificationRationaleAllow => 'Permitir';

  @override
  String get notificationRationaleNotNow => 'Agora não';

  @override
  String get addProduct => 'Adicionar produto';

  @override
  String get addProductSubtitle => 'Buscar por código de barras ou nome';

  @override
  String get registerRecipe => 'Registrar receita';

  @override
  String get registerRecipeSubtitle => 'Salvar receitas com controle de custo';

  @override
  String get scanBarcodeSubtitle => 'Escanear ou digitar código';

  @override
  String get marketTrip => 'Ida ao mercado';

  @override
  String get marketTripSubtitle => 'Escanear itens em sequencia';

  @override
  String get comingSoon => 'Em breve';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get recipes => 'Receitas';

  @override
  String get editRecipe => 'Editar receita';

  @override
  String get recipeName => 'Nome da receita';

  @override
  String get recipeNameHint => 'Ex.: Sanduíche de frango';

  @override
  String get recipeNameRequired => 'O nome da receita é obrigatório';

  @override
  String get recipeInstructions => 'Instruções';

  @override
  String get recipeInstructionsHint => 'Descreva como preparar...';

  @override
  String get recipeIngredients => 'Ingredientes';

  @override
  String get ingredientName => 'Nome do ingrediente';

  @override
  String get ingredientQuantity => 'Qtd';

  @override
  String get ingredientUnit => 'Unidade';

  @override
  String get addIngredient => 'Adicionar ingrediente';

  @override
  String get selectFromPantry => 'Selecione itens da sua despensa';

  @override
  String get addSelected => 'Adicionar selecionados';

  @override
  String get servings => 'Porcoes';

  @override
  String get servingsHint => 'ex.: 4';

  @override
  String get setServingsHint => 'Defina o numero de porcoes no editor da receita para ver a nutricao por porcao';

  @override
  String get addPhoto => 'Adicionar foto';

  @override
  String get changePhoto => 'Alterar foto';

  @override
  String get costPerServing => 'Custo por porcao';

  @override
  String get recipeNutritionPerServing => 'Por porcao';

  @override
  String get recipeNutriScore => 'Nutri-Score';

  @override
  String get recipeNoIngredients => 'A receita nao tem ingredientes';

  @override
  String recipeShortage(String name, double amount) {
    return '$name insuficiente: precisa de mais $amount';
  }

  @override
  String get saveRecipe => 'Salvar receita';

  @override
  String get recipeSaved => 'Receita salva';

  @override
  String get recipeDeleted => 'Receita excluída';

  @override
  String get noRecipes => 'Nenhuma receita ainda';

  @override
  String get noRecipesSubtitle => 'Registre receitas para controlar custos e planejar refeições';

  @override
  String get discardChanges => 'Descartar alterações?';

  @override
  String get discardChangesConfirm => 'Você tem alterações não salvas. Descartá-las?';

  @override
  String get recipeCost => 'Custo da receita';

  @override
  String get recipeCostUnknown => 'Desconhecido';

  @override
  String get recipeAverageCost => 'Custo médio das receitas';

  @override
  String ingredientCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingredientes',
      one: '$count ingrediente',
    );
    return '$_temp0';
  }

  @override
  String get deleteRecipeConfirm => 'Excluir esta receita?';

  @override
  String get madeRecipe => 'Fiz esta receita';

  @override
  String get cookRecipeSuccess => 'Receita feita';

  @override
  String get recipeCookFailed => 'Erro ao preparar receita';

  @override
  String get confirmDiscard => 'Descartar alteracoes?';

  @override
  String get confirmDiscardContent => 'Tem alteracoes nao salvas. Tem certeza que deseja voltar?';

  @override
  String get searchProduct => 'Pesquisar produto';

  @override
  String get history => 'Historico';

  @override
  String get noHistory => 'Nenhum historico de preparo ainda';

  @override
  String get onboardingPage1Title => 'Escanear Codigos de Barras';

  @override
  String get onboardingPage1Desc => 'Adicione rapidamente produtos a sua despensa escaneando os codigos de barras com a sua camera.';

  @override
  String get onboardingPage1Cta => 'Abrir Scanner';

  @override
  String get onboardingPage2Title => 'Pesquisar Produtos';

  @override
  String get onboardingPage2Desc => 'Navegue por milhoes de produtos na base do Open Food Facts para encontrar exatamente o que precisa.';

  @override
  String get onboardingPage2Cta => 'Abrir Pesquisa';

  @override
  String get onboardingPage3Title => 'Produtos Frescos';

  @override
  String get onboardingPage3Desc => 'Adicione frutas e vegetais comuns com um unico toque. Perfeito para bananas, macas, tomates e mais.';

  @override
  String get onboardingPage3Cta => 'Adicionar Produtos Frescos';

  @override
  String get onboardingPage4Title => 'Configurar Despensa';

  @override
  String get onboardingPage4Desc => 'Configure monitoramento de precos, moeda e preferencias de dados para aproveitar ao maximo a despensa.';

  @override
  String get onboardingPage4Cta => 'Configurar';

  @override
  String get onboardingPage5Title => 'Controle Tudo';

  @override
  String get onboardingPage5Desc => 'Monitore datas de validade, acompanhe precos, crie listas de compras e reduza o desperdicio de alimentos.';

  @override
  String get onboardingPage5Cta => 'Comecar';

  @override
  String get onboardingSkip => 'Pular';

  @override
  String get onboardingBack => 'Voltar';

  @override
  String get searchSourceLabel => 'Pesquisar em';

  @override
  String get searchSourceOff => 'Produtos Embalados';

  @override
  String get searchSourceUsda => 'Produtos Frescos';

  @override
  String get searchSourceInventory => 'Minha Despensa';

  @override
  String get inPantryIndicator => 'Na Despensa';

  @override
  String get inPantryFilter => 'Na Despensa';

  @override
  String get inPantryEmpty => 'Nenhum produto na sua despensa corresponde a esta pesquisa';

  @override
  String get inPantrySwipeLabel => 'Ja na despensa';
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
  String get invalidBarcode => 'Digite um código de barras válido.';

  @override
  String get brandLabel => 'Marca';

  @override
  String get categoryLabel => 'Categorias';

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
  String deleteCountSub(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $count itens selecionados?',
      one: 'Excluir 1 item selecionado?',
    );
    return '$_temp0';
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
  String get expiryPrefix => 'Exp';

  @override
  String get switchPantry => 'Trocar despensa';

  @override
  String get couldNotOpenPlayStore => 'Não foi possível abrir a Play Store.';

  @override
  String get viewOnOpenFoodFacts => 'Ver no Open Food Facts';

  @override
  String get couldNotOpenLink => 'Não foi possível abrir o link.';

  @override
  String get nutrient => 'Nutrientes';

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
  String get couldNotResolveProduct => 'Não foi possível carregar os detalhes do produto.';

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
  String expiresTomorrow(String name) {
    return '$name vence amanhã';
  }

  @override
  String expiresToday(String name) {
    return '$name vence hoje!';
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
  String get navRecipes => 'Receitas';

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
  String get productNotFoundSearch => 'Nenhum produto encontrado em Produtos Embalados.';

  @override
  String get productNotFoundBarcodeHint => 'Tente escanear ou digitar o codigo de barras do produto.';

  @override
  String get productNotFoundOfflineHint => 'A pesquisa requer conexao com a internet.';

  @override
  String get enterBarcodePrompt => 'Digite ou cole um codigo de barras';

  @override
  String get productNotInDatabase => 'Este codigo de barras nao esta registrado no Open Food Facts.';

  @override
  String get productNotInDatabaseHint => 'Voce ainda pode usar este produto localmente.';

  @override
  String get contributeToOffComingSoonTitle => 'Em Breve';

  @override
  String get contributeToOffComingSoonBody => 'A contribuicao direta de produtos ao Open Food Facts ainda nao esta disponivel. Um issue no GitHub foi criado para acompanhar este recurso.';

  @override
  String get saveLocallyAction => 'Salvar Localmente';

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
  String get locationStats => 'Locais';

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
  String get addPrice => 'Preco salvo';

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
  String get addNewStore => 'Adicionar nova loja';

  @override
  String get storeAdded => 'Loja adicionada';

  @override
  String get storeAlreadyExists => 'Já existe uma loja com este nome';

  @override
  String get storeName => 'Nome da loja';

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
  String get notes => 'Observações';

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
  String get productSearchHint => 'Buscar produtos por nome';

  @override
  String get addCustomItem => 'Adicionar item personalizado';

  @override
  String get noProductsFound => 'Nenhum produto encontrado. Tente um item personalizado.';

  @override
  String get backToSearch => 'Voltar a busca';

  @override
  String get removePrice => 'Preco removido';

  @override
  String shoppingTotal(String total) {
    return 'Total: $total';
  }

  @override
  String shoppingMixedCurrency(String total) {
    return '$total';
  }

  @override
  String get addToInventoryFromList => 'Adicionar a despensa';

  @override
  String addToInventoryConfirm(int count, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: ' $skipped itens sem codigo de barras ficarao na lista.',
      one: ' 1 item sem codigo de barras ficara na lista.',
      zero: '',
    );
    return 'Adicionar $count itens a sua despensa? Os precos serao salvos.$_temp0';
  }

  @override
  String itemsMovedToInventory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens adicionados a despensa',
      one: '1 item adicionado a despensa',
    );
    return '$_temp0';
  }

  @override
  String itemsSkippedNoBarcode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens restantes — adicione um codigo de barras ou crie um produto',
      one: '1 item restante — adicione um codigo de barras ou crie um produto',
    );
    return '$_temp0';
  }

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
  String get invalidPriceAmount => 'Digite um valor de preço válido';

  @override
  String get apiSearchWarning => 'Nao foi possivel buscar todos os resultados online. Alguns produtos podem estar faltando.';

  @override
  String get dismiss => 'Dispensar';

  @override
  String get priceHidden => 'Preco oculto';

  @override
  String get scanFailed => 'Falha ao escanear codigo de barras.';

  @override
  String get testNotification => 'Enviar notificação de teste';

  @override
  String get testScheduledNotification => 'Enviar notificação de teste agendada (2 min)';

  @override
  String get testNotificationScheduled => 'Notificação de teste agendada.';

  @override
  String get testNotificationSent => 'Notificação de teste enviada.';

  @override
  String get testNotificationFailed => 'Falha ao enviar notificação de teste.';

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

  @override
  String get themeModeSystem => 'Sistema';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Escuro';

  @override
  String get defaultInventoryName => 'Casa';

  @override
  String get locationPantry => 'Despensa';

  @override
  String get locationFridge => 'Geladeira';

  @override
  String get locationFreezer => 'Freezer';

  @override
  String get unitSingular => 'unidade';

  @override
  String get unitPlural => 'unidades';

  @override
  String get unitGrams => 'g';

  @override
  String get unitKg => 'kg';

  @override
  String get unitMl => 'ml';

  @override
  String get unitLiter => 'L';

  @override
  String get generalNotificationChannelName => 'Notificações Gerais';

  @override
  String get generalNotificationChannelDescription => 'Notificações padrão do app';

  @override
  String get testNotificationTitle => 'Teste bem-sucedido';

  @override
  String get testNotificationBody => 'Notificações imediatas estão funcionando!';

  @override
  String get testScheduledTitle => 'Teste Agendado';

  @override
  String get testScheduledBody => 'Isso foi disparado 5 segundos depois.';

  @override
  String get retryNow => 'Tentar de novo agora';

  @override
  String get bearerTokenLabel => 'Token Bearer';

  @override
  String pendingFeedback(Object count) {
    return 'Feedback pendente: $count';
  }

  @override
  String submissionResult(Object failed, Object submitted) {
    return 'Enviados $submitted, $failed falharam';
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
  String get unreleasedVersion => 'Não lançado';

  @override
  String get categoryDairy => 'Laticínios';

  @override
  String get categoryMilks => 'Leites';

  @override
  String get categoryMilk => 'Leite';

  @override
  String get categoryYogurts => 'Iogurtes';

  @override
  String get categoryCheeses => 'Queijos';

  @override
  String get categoryEggsAndProducts => 'Ovos e derivados';

  @override
  String get categoryMeats => 'Carnes';

  @override
  String get categoryFishesAndSeafoods => 'Peixes e frutos do mar';

  @override
  String get categoryBeverages => 'Bebidas';

  @override
  String get categoryAlcoholicBeverages => 'Bebidas alcoólicas';

  @override
  String get categoryBreads => 'Pães';

  @override
  String get categoryCerealsAndPotatoes => 'Cereais e batatas';

  @override
  String get categoryFruitsAndVegetables => 'Alimentos à base de frutas e vegetais';

  @override
  String get categoryConfectioneries => 'Confeitaria';

  @override
  String get categorySugarySnacks => 'Lanches doces';

  @override
  String get categorySaltySnacks => 'Lanches salgados';

  @override
  String get categoryFats => 'Gorduras';

  @override
  String get categorySauces => 'Molhos';

  @override
  String get categorySoups => 'Sopas';

  @override
  String get categoryPreparedMeals => 'Pratos prontos';

  @override
  String get categoryFrozenFoods => 'Alimentos congelados';

  @override
  String get categoryDesserts => 'Sobremesas';

  @override
  String get categoryPastries => 'Pastéis';

  @override
  String get categoryBiscuitsAndCakes => 'Biscoitos e bolos';

  @override
  String get categoryPizzas => 'Pizzas';

  @override
  String get categorySandwiches => 'Sanduíches';

  @override
  String get categoryBabyFoods => 'Alimentos infantis';

  @override
  String get categoryDietaryFoods => 'Alimentos dietéticos';

  @override
  String get categorySpicesAndHerbs => 'Especiarias e ervas';

  @override
  String get categoryNutsAndProducts => 'Nozes e castanhas';

  @override
  String get categoryPlantBasedFoods => 'Alimentos vegetais';

  @override
  String get categoryLegumesAndProducts => 'Leguminosas e derivados';

  @override
  String get categoryCoffees => 'Cafés';

  @override
  String get categoryTeas => 'Chás';

  @override
  String get categoryChocolateProducts => 'Produtos de chocolate';

  @override
  String get categoryIceCreams => 'Sorvetes';

  @override
  String get categoryFruitJuices => 'Sucos de fruta';

  @override
  String get categorySodas => 'Refrigerantes';

  @override
  String get categoryWaters => 'Águas';

  @override
  String get categoryMeatAndProducts => 'Carnes e derivados';

  @override
  String get categoryBreakfasts => 'Cafés da manhã';

  @override
  String get categoryBread => 'Pão';

  @override
  String get categoryCakes => 'Bolos';

  @override
  String get categoryCereals => 'Cereais';

  @override
  String get categoryChocolate => 'Chocolate';

  @override
  String get categoryCondiments => 'Condimentos';

  @override
  String get categoryEggs => 'Ovos';

  @override
  String get categoryFish => 'Peixe';

  @override
  String get categoryFruit => 'Fruta';

  @override
  String get categoryFruits => 'Frutas';

  @override
  String get categoryGrains => 'Grãos';

  @override
  String get categoryHotBeverages => 'Bebidas quentes';

  @override
  String get categoryLegumes => 'Leguminosas';

  @override
  String get categoryOils => 'Óleos';

  @override
  String get categoryPasta => 'Massas';

  @override
  String get categoryPoultry => 'Aves';

  @override
  String get categorySeeds => 'Sementes';

  @override
  String get categorySnacks => 'Lanches';

  @override
  String get categorySpreads => 'Pastas';

  @override
  String get categorySweetSpreads => 'Pastas doces';

  @override
  String get categoryVegetables => 'Vegetais';

  @override
  String get categoryBiscuitsAndCrackers => 'Biscoitos e bolachas';

  @override
  String get categoryLegumeOils => 'Óleos de leguminosas';

  @override
  String get categoryUhtMilks => 'Leites UHT';

  @override
  String get categoryCannedSardines => 'Sardinhas enlatadas';

  @override
  String get categoryCerealFlours => 'Farinhas de cereais';

  @override
  String get categoryCerealStarches => 'Amidos de cereais';

  @override
  String get categoryCerealsAndProducts => 'Cereais e seus produtos';

  @override
  String get categoryDairies => 'Laticínios';

  @override
  String get categoryInstantBeverages => 'Bebidas instantâneas';

  @override
  String get categoryMilkfat => 'Gordura do leite';

  @override
  String get categoryStarches => 'Amidos';

  @override
  String get fromYourPantry => 'Da sua despensa';

  @override
  String get inYourPantry => 'Na sua despensa';

  @override
  String get monthlySpendingTitle => 'Gastos mensais';

  @override
  String get storeSpendingTitle => 'Gastos por loja';

  @override
  String get nutriscoreByStoreTitle => 'Nutri-Score por loja';

  @override
  String get noStoreData => 'Sem dados de compra';

  @override
  String get noSpendingData => 'Adicione precos para ver tendencias';

  @override
  String get monthLabel => 'Mes';

  @override
  String get averageScore => 'Nota media';

  @override
  String get produceApple => 'Maça';

  @override
  String get produceBanana => 'Banana';

  @override
  String get produceOrange => 'Laranja';

  @override
  String get produceTomato => 'Tomate';

  @override
  String get producePotato => 'Batata';

  @override
  String get produceCarrot => 'Cenoura';

  @override
  String get produceOnion => 'Cebola';

  @override
  String get produceLettuce => 'Alface';

  @override
  String get exactAlarmsDeniedHint => 'Notificações agendadas podem sofrer atrasos porque alarmes exatos não foram concedidos. Conceda em Configurações > Notificações > Agendar alarmes exatos.';

  @override
  String get notificationRationaleTitle => 'Notificações ajudam você a acompanhar';

  @override
  String get notificationRationaleBody => 'O Pantry usa notificações para:\n\n- Lembrar quando os alimentos estão perto de vencer\n- Lembrar de adicionar produtos regularmente\n- Confirmar que notificações de teste funcionam\n\nVocê pode mudar isso a qualquer momento em Configurações.';

  @override
  String get notificationRationaleAllow => 'Permitir';

  @override
  String get notificationRationaleNotNow => 'Agora não';

  @override
  String get addProduct => 'Adicionar produto';

  @override
  String get addProductSubtitle => 'Buscar por código de barras ou nome';

  @override
  String get registerRecipe => 'Registrar receita';

  @override
  String get registerRecipeSubtitle => 'Salvar receitas com controle de custo';

  @override
  String get scanBarcodeSubtitle => 'Escanear ou digitar código';

  @override
  String get marketTrip => 'Ida ao mercado';

  @override
  String get marketTripSubtitle => 'Escanear itens em sequencia';

  @override
  String get comingSoon => 'Em breve';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get recipes => 'Receitas';

  @override
  String get editRecipe => 'Editar receita';

  @override
  String get recipeName => 'Nome da receita';

  @override
  String get recipeNameHint => 'Ex.: Sanduíche de frango';

  @override
  String get recipeNameRequired => 'O nome da receita é obrigatório';

  @override
  String get recipeInstructions => 'Instruções';

  @override
  String get recipeInstructionsHint => 'Descreva como preparar...';

  @override
  String get recipeIngredients => 'Ingredientes';

  @override
  String get ingredientName => 'Nome do ingrediente';

  @override
  String get ingredientQuantity => 'Qtd';

  @override
  String get ingredientUnit => 'Unidade';

  @override
  String get addIngredient => 'Adicionar ingrediente';

  @override
  String get selectFromPantry => 'Selecione itens da sua despensa';

  @override
  String get addSelected => 'Adicionar selecionados';

  @override
  String get servings => 'Porcoes';

  @override
  String get servingsHint => 'ex.: 4';

  @override
  String get setServingsHint => 'Defina o numero de porcoes no editor da receita para ver a nutricao por porcao';

  @override
  String get addPhoto => 'Adicionar foto';

  @override
  String get changePhoto => 'Alterar foto';

  @override
  String get costPerServing => 'Custo por porcao';

  @override
  String get recipeNutritionPerServing => 'Por porcao';

  @override
  String get recipeNutriScore => 'Nutri-Score';

  @override
  String get recipeNoIngredients => 'A receita nao tem ingredientes';

  @override
  String recipeShortage(String name, double amount) {
    return '$name insuficiente: precisa de mais $amount';
  }

  @override
  String get saveRecipe => 'Salvar receita';

  @override
  String get recipeSaved => 'Receita salva';

  @override
  String get recipeDeleted => 'Receita excluída';

  @override
  String get noRecipes => 'Nenhuma receita ainda';

  @override
  String get noRecipesSubtitle => 'Registre receitas para controlar custos e planejar refeições';

  @override
  String get discardChanges => 'Descartar alterações?';

  @override
  String get discardChangesConfirm => 'Você tem alterações não salvas. Descartá-las?';

  @override
  String get recipeCost => 'Custo da receita';

  @override
  String get recipeCostUnknown => 'Desconhecido';

  @override
  String get recipeAverageCost => 'Custo médio das receitas';

  @override
  String ingredientCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingredientes',
      one: '$count ingrediente',
    );
    return '$_temp0';
  }

  @override
  String get deleteRecipeConfirm => 'Excluir esta receita?';

  @override
  String get madeRecipe => 'Fiz esta receita';

  @override
  String get cookRecipeSuccess => 'Receita feita';

  @override
  String get recipeCookFailed => 'Erro ao preparar receita';

  @override
  String get confirmDiscard => 'Descartar alteracoes?';

  @override
  String get confirmDiscardContent => 'Voce tem alteracoes nao salvas. Tem certeza que deseja voltar?';

  @override
  String get searchProduct => 'Pesquisar produto';

  @override
  String get history => 'Historico';

  @override
  String get noHistory => 'Nenhum historico de preparo ainda';

  @override
  String get onboardingPage1Title => 'Escanear Codigos de Barras';

  @override
  String get onboardingPage1Desc => 'Adicione rapidamente produtos a sua despensa escaneando os codigos de barras com sua camera.';

  @override
  String get onboardingPage1Cta => 'Abrir Scanner';

  @override
  String get onboardingPage2Title => 'Pesquisar Produtos';

  @override
  String get onboardingPage2Desc => 'Navegue por milhoes de produtos na base do Open Food Facts para encontrar exatamente o que precisa.';

  @override
  String get onboardingPage2Cta => 'Abrir Pesquisa';

  @override
  String get onboardingPage3Title => 'Produtos Frescos';

  @override
  String get onboardingPage3Desc => 'Adicione frutas e vegetais comuns com um unico toque. Perfeito para bananas, macas, tomates e mais.';

  @override
  String get onboardingPage3Cta => 'Adicionar Produtos Frescos';

  @override
  String get onboardingPage4Title => 'Configurar Despensa';

  @override
  String get onboardingPage4Desc => 'Configure monitoramento de precos, moeda e preferencias de dados para aproveitar ao maximo a despensa.';

  @override
  String get onboardingPage4Cta => 'Configurar';

  @override
  String get onboardingPage5Title => 'Controle Tudo';

  @override
  String get onboardingPage5Desc => 'Monitore datas de validade, acompanhe precos, crie listas de compras e reduza o desperdicio de alimentos.';

  @override
  String get onboardingPage5Cta => 'Comecar';

  @override
  String get onboardingSkip => 'Pular';

  @override
  String get onboardingBack => 'Voltar';

  @override
  String get searchSourceLabel => 'Pesquisar em';

  @override
  String get searchSourceOff => 'Produtos Embalados';

  @override
  String get searchSourceUsda => 'Produtos Frescos';

  @override
  String get searchSourceInventory => 'Minha Despensa';

  @override
  String get inPantryIndicator => 'Na Despensa';

  @override
  String get inPantryFilter => 'Na Despensa';

  @override
  String get inPantryEmpty => 'Nenhum produto na sua despensa corresponde a esta pesquisa';

  @override
  String get inPantrySwipeLabel => 'Ja na despensa';
}
