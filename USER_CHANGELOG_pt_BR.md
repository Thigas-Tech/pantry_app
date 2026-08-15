# Registro de alteracoes do usuario

## Unreleased

- Corrigido um problema que impedia o banco de dados local do app de abrir
  em alguns dispositivos Android mais recentes, o que fazia o app iniciar
  sem seus produtos e configuracoes salvos.

- Seu cache de produtos agora e armazenado apenas no seu dispositivo.
  Informacoes de produtos em cache com mais de dois meses sao removidas
  automaticamente e recarregadas na proxima vez que voce visualizar o
  produto, entao o app continua funcionando offline enquanto permanece
  organizado ao longo do tempo.

- O app nao usa mais o Firebase nem exige uma conta. Tudo o que voce insere
  permanece no seu dispositivo e nada e enviado para a nuvem.

- As informacoes de produtos do Open Food Facts agora aparecem no idioma
  do seu dispositivo quando disponivel (por exemplo, usuarios de frances
  veem nomes de produtos em frances). Se um produto aparecer em outro
  idioma, um botao "Mostrar em [idioma]" permite recarregar no seu idioma
  com um toque.

- Agora voce pode ativar sugestoes semanais de receitas nas Configuracoes.
  Quando ativado, o app escolhe uma receita que combina com os ingredientes
  que voce tem na despensa e mostra como uma notificacao toda semana, no dia
  e horario que voce escolher. As sugestoes pulam a ultima receita exibida.

- A lista de compras ficou mais facil de usar: cada item da lista "Para
  comprar" agora tem botoes + e - para mudar a quantidade, e voce pode
  tocar na quantidade (ou no icone de lapis) para editar o nome, a
  quantidade ou a unidade do item. Tambem e possivel arrastar os itens para
  reordenar, e a barra de navegacao mostra um selo com quantos itens ainda
  faltam comprar.

- O marcador "Notas NFC-e" e o botao "Contribuir com fotos" na tela de
  Estatisticas foram removidos como parte de uma reducao de escopo. O app
  nao divulga mais funcionalidades que nao estao planejadas.

- Os precos agora registram o tamanho da embalagem comprada (por exemplo
  12 ovos ou 1 L de leite), para que o preco unitario e a estimativa de
  custo da receita sejam precisos mesmo quando o produto nao tem dados de
  embalagem cadastrados.

- A estimativa de custo das receitas agora e mais precisa para produtos
  frescos e os valores sao arredondados de forma consistente, sem centavos
  quebrados.

- O valor total da despensa e o preco medio agora seguem o mesmo calculo
  de custo das receitas para produtos embalados, para que os numeros
  concordem em todos os lugares.

- As listas de ingredientes das receitas agora mostram a quantidade com a
  unidade (por exemplo "500 g x Farinha") e, quando a receita tem porcoes,
  a quantidade por porcao.

- Os relatorios de feedback no aplicativo foram removidos. O app agora
  usa apenas os servicos gratuitos do Firebase; voce pode entrar em
  contato diretamente pelo repositorio do projeto no GitHub.

- O app agora abre mais rapidamente em redes lentas: o login e a
  atualizacao dos dados em cache acontecem depois que a primeira tela
  aparece, em vez de atrasar a abertura.

- As telas de receitas agora carregam as informacoes dos produtos e os
  custos mais rapidamente, especialmente em receitas com muitos
  ingredientes.

- As imagens dos produtos agora sao armazenadas menores e o app mantem
  apenas uma quantidade limitada delas no dispositivo, entao o app usa
  menos armazenamento ao longo do tempo.

- As telas de detalhes do produto e de receitas nao mostram mais
  brevemente um indicador de carregamento quando a tela atualiza por
  outros motivos (por exemplo, apos mudar as configuracoes): os dados
  permanecem visiveis enquanto estao atualizados.

- A lista inicial agora carrega apenas os itens que estao visiveis, entao
  percorrer despensas grandes e mais suave e usa menos memoria.

- Itens que expiram exatamente daqui a alguns dias (a janela de
  "expira em breve") nao desaparecem mais da lista por um dia: eles
  aparecem em "Bom" ate entrarem na janela de expiracao proxima.

- O app nao mostra mais brevemente a despensa, o tema ou as configuracoes
  erradas logo apos a abertura: os valores salvos agora sao carregados
  antes do primeiro quadro ser renderizado.
## Unreleased

- As mensagens de erro agora mostram uma mensagem generica e amigavel em
  vez de detalhes tecnicos brutos, enquanto o app ainda registra o erro
  completo para depuracao.

- As notificacoes de "Produto nao encontrado" agora usam o idioma do app, e
  as opcoes de tamanho de porcao de produtos (Pequeno, Medio, Grande) sao
  localizadas.
- A atualizacao de produtos em segundo plano nao e mais executada enquanto
  voce esta offline. Os produtos em cache so sao atualizados quando o
  dispositivo tem conectividade, reduzindo pedidos de rede falhados em
  segundo plano.

- Abrir "O que ha de novo" quando o changelog nao pode ser carregado agora
  mostra uma mensagem de erro clara em vez da mensagem de falha na limpeza
  do cache.

- Adicionar o mesmo produto uma segunda vez com uma data de validade diferente
  agora mantem as duas entradas separadas na despensa, cada uma com sua data
  de validade. Duas entradas so sao combinadas quando sao verdadeiramente o
  mesmo lote (mesma data de validade, mesma unidade e mesma localizacao de
  armazenamento).

- As fotos dos produtos agora podem ser recortadas e rotacionadas antes de
  salvar. Ao visualizar uma foto, voce encontrara uma acao de recorte que
  permite ajustar o enquadramento e a orientacao; a foto recortada substitui
  a original. Recortar uma foto em um tamanho pequeno demais e bloqueado para
  que as fotos dos produtos permaneçam sempre nitidas.

- Tirar uma foto de produto agora abre sempre a camara traseira em vez da
  frontal.

- Ao inserir informacao nutricional manualmente, agora voce pode escolher a
  unidade de cada nutriente (gramas, miligramas ou microgramas para a maioria
  dos nutrientes; quilocalorias ou quilojoules para a energia) e adicionar
  nutrientes extras, como vitaminas, minerais, acucares ou gorduras, que nao
  fazem parte da lista padrao. Os valores sao armazenados em uma unidade
  consistente e mostrados na tabela nutricional do produto.

- Ao inserir um produto manualmente, agora voce pode escolher a unidade da
  porcao a partir de uma lista (gramas, miligramas, microgramas, mililitros
  ou litros) em vez de digita-la junto com a quantidade.
- Os itens da despensa agora podem usar unidades de miligrama e micrograma,
  para que produtos como vitaminas e suplementos mantenham suas quantidades
  corretas.

- Se suas credenciais do Open Food Facts forem rejeitadas, o aplicativo agora
  avisa isso claramente e nao continua tentando. Use seu nome de usuario do
  Open Food Facts (e nao seu endereco de e-mail) como id de usuario na
  configuracao do aplicativo.
- A tela inicial ja nao mostra a faixa de verificacoes recentes, deixando o
  aplicativo mais limpo. Voce ainda pode encontrar qualquer produto pela
  pesquisa, pela sua despensa ou escaneando o codigo de barras.
- Salvar um produto inserido manualmente agora e separado de envia-lo para o
  Open Food Facts. "Salvar no inventario" apenas mantem o produto na sua
  despensa; "Enviar para o Open Food Facts" faz isso e o envia para o banco
  de dados publico de alimentos. Ambas as acoes estao sempre disponiveis,
  entao, se um envio for rejeitado, voce ainda pode manter o produto
  localmente.
- Quando o Open Food Facts nao conhece um codigo de barras, o botao
  "Contribuir para o Open Food Facts" agora abre o formulario do produto
  pronto para envio, em vez de mostrar uma mensagem "Em breve".
- Escanear um produto que nao esta no banco de dados do Open Food Facts agora
  leva direto ao formulario para contribui-lo, em vez de apenas mostrar uma
  mensagem "produto nao encontrado".
- Os envios agora incluem os valores nutricionais do produto, a quantidade
  da embalagem e o idioma do app, para que o que voce contribui fique
  completo e no idioma certo.

- Para um produto inserido manualmente, a pagina do produto agora mostra em
  que ponto esta o envio para o Open Food Facts. Se ele falhar, voce pode
  tentar novamente ali mesmo, sem voltar ao formulario.
- As fotos de um produto inserido manualmente agora podem ser gerenciadas
  pela pagina do produto: toque em uma foto para ve-la em tela cheia,
  substitua-a ou remova-a. Se remover uma por engano, voce pode desfazer a
  acao, e os arquivos que voce excluir sao limpos ao sair da pagina.

- Ao salvar um produto inserido manualmente, o app agora verifica primeiro
  se esse codigo de barras ja existe no Open Food Facts. Se existir, o envio
  e interrompido e voce e informado de que o produto ja esta la, em vez de
  sobrescreve-lo.
- Se o envio de um produto falhar por um motivo que voce pode corrigir — por
  exemplo, dados de produto invalidos — o app agora explica o que aconteceu,
  em vez de mostrar um erro generico.
- As fotos sao enviadas uma de cada vez, e uma foto que falha nao bloqueia
  mais as outras; quando a conexao voltar, apenas as fotos que faltam sao
  reenviadas, nao as que ja foram.
- As fotos dos produtos sao compactadas antes do envio, para chegarem mais
  rapido e gastarem menos dados moveis.
- Ao salvar um produto inserido manualmente, voce agora ve o andamento do
  envio para o Open Food Facts: primeiro os detalhes do produto e depois
  cada foto enquanto e enviada.
- O formulario fica aberto enquanto o produto esta sendo enviado e fecha
  sozinho com uma confirmacao quando concluido com sucesso.
- Se o envio falhar, voce pode tentar novamente direto no formulario, e a
  mensagem indica o motivo — por exemplo, sem conexao com a internet ou
  Open Food Facts ocupado.

- Ha agora mais mensagens traduzidas para o portugues. Algumas telas
  mostravam antes texto em ingles quando faltava uma traducao, e essas
  lacunas agora estao preenchidas.
- Se recarregar um produto em outro idioma falhar porque voce esta offline,
  agora ve uma mensagem clara em vez de um erro tecnico.

- As fotos dos produtos ficam mais faceis de gerenciar ao adicionar um produto
  manualmente. Toque em uma foto para ve-la em tela cheia e depois tire uma
  nova, escolha outra da sua galeria ou exclua-a. As caixas de foto vazias
  permitem escolher entre a camera e a galeria, e se voce remover uma foto
  por engano pode desfazer a acao.
- Se voce recusar o acesso a camera em definitivo, o app agora explica o
  motivo e oferece um botao para abrir as configuracoes do dispositivo.
  Recusar apenas uma vez mostra uma mensagem curta, para que voce possa
  tentar de novo sem ir as configuracoes.
- Se o app nao conseguir abrir a galeria, agora ele explica o motivo e
  oferece um botao para abrir as configuracoes do dispositivo.
- As fotos que voce adiciona a um produto inserido manualmente sao salvas
  junto com o produto. Se voce sair do formulario sem salvar, as fotos que
  adicionou sao removidas para nao ficarem no dispositivo.

- Os precos agora sao salvos por despensa: cada despensa (Casa, Trabalho,
  etc.) tem o seu proprio historico de precos. A pagina do produto mostra o
  ultimo preco da despensa atual com um pequeno grafico de tendencia e os
  ultimos 5 precos, com um link para o historico completo.
- Excluir uma despensa nao apaga mais os precos registrados nela. Suas
  observacoes de preco ficam salvas se voce adicionar o produto a outra
  despensa depois.
- As receitas agora sao salvas por despensa: cada despensa (Casa, Trabalho,
  etc.) tem o seu proprio conjunto de receitas. Voce pode alternar a
  despensa diretamente na tela de receitas usando o mesmo seletor da tela
  inicial. Suas receitas existentes sao movidas automaticamente para a sua
  primeira despensa.
- Quando voce exclui uma despensa, as receitas dela tambem sao excluidas.
- O custo de uma receita agora e calculado a partir dos precos da despensa a
  que a receita pertence, para que trocar de despensa nunca misture precos de
  outra. Ingredientes sem preco registrado nessa despensa contam como custando
  zero.
- Os custos das receitas agora refletem a quantidade realmente usada em vez
  do pacote inteiro: uma receita que usa 2 ovos de um pacote de 12 conta
  apenas um sexto do preco do pacote.
- Ao registrar um preco, voce pode informar o tamanho do pacote (por exemplo,
  12 unidades, 500 g ou 1 L). Um preco unitario e mostrado abaixo do preco,
  como R$ 0,83 por unidade ou R$ 8,00 por kg, facilitando a comparacao entre
  produtos com embalagens de tamanhos diferentes. O preco unitario continua
  oculto se voce tiver escolhido ocultar os precos.
- Os totais da despensa e o preco medio dos itens agora levam em conta a
  quantidade de cada produto que voce tem, para que os numeros reflitam o
  estoque real.

## [0.0.9+5]

- Corrigido um problema em que um produto ou suas fotos podiam ser marcados
  como "falha no envio" para o Open Food Facts mesmo depois de um envio bem
  sucedido. O envio agora tenta novamente automaticamente quando o servidor
  esta ocupado, tornando o registro de produtos manuais mais confiavel.

- Corrigido um problema raro em que um produto podia aparecer mais de uma vez
  na mesma despensa numa instalacao nova, causando quantidades duplicadas. As
  instalacoes novas agora correspondem as instalacoes atualizadas: cada produto
  aparece uma vez por despensa, e adicionar um produto existente novamente
  aumenta a sua quantidade.

- Verificacoes recentes: depois de ler um codigo de barras, ele aparece na
  secao "Verificacoes recentes" da tela inicial. Pode adicionar rapidamente um
  produto verificado novamente a despensa com um toque, ou abri-lo para ver os
  detalhes. As ultimas 50 verificacoes sao guardadas.
- Busca melhorada: a busca agora e mais rapida e confiavel ao procurar
  produtos, ingredientes e produtos frescos.
- Aviso de "Ida ao mercado": a mensagem "Em breve" exibida ao tocar em
  "Ida ao mercado" agora aparece como um aviso mais bem apresentado e
  facil de ler na parte inferior da tela.
- Preenchimento automatico de ingrediente de receita: ao adicionar um produto
  como ingrediente em uma receita, a quantidade e a unidade sao preenchidas
  automaticamente a partir do tamanho da porcao do produto (ex.: "200 g" para
  farinha). Funciona tanto para produtos embalados quanto para produtos
  frescos. Voce ainda pode altera-los se necessario.
- Preenchimento automatico de quantidade: ao adicionar um produto embalado a
  sua despensa, os campos de quantidade e unidade sao preenchidos
  automaticamente a partir do rotulo do produto. Voce ainda pode altera-los
  se necessario.
- Porcao de produtos frescos: ao adicionar frutas ou vegetais a sua despensa,
  a quantidade agora padrao e o peso da porcao tipica (por exemplo, 182 g
  para uma maca). Voce ainda pode alterar ou mudar para o modo de unidade.
- Removido o carrossel de produtos frescos da tela inicial: a linha de chips
  de adicao rapida (Maca, Banana, Tomate, etc.) abaixo da barra de pesquisa
  nao e mais exibida. Use a barra de pesquisa ou o menu do FAB para
  encontrar e adicionar produtos frescos.
- Indicador na despensa: resultados de busca de Produtos Embalados e Produtos
  Frescos agora mostram um icone de despensa quando voce ja possui aquele
  produto. Um chip "Na Despensa" permite ver apenas resultados ja na sua
  despensa. O deslizar para adicionar mostra um fundo azul para produtos que
  voce ja possui.
- Aba de receitas: Receitas agora tem sua propria aba na barra de navegacao inferior.
- Seletor de fonte de busca: escolha entre "Produtos Embalados", "Produtos Frescos" ou sua despensa ao buscar. Agora eh um menu compacto.
- Busca na tela inicial: tocar na barra de busca abre uma busca inline que substitui o conteudo da tela. Tocar em um resultado retorna a sua despensa antes de abrir os detalhes. Use a seta de voltar ou o botao fisico para sair do modo de busca.
- Busca de ingredientes de receitas: ao registrar uma receita, buscar por um produto agora abre um seletor em tela cheia com filtros de fonte e categoria, em vez de apenas uma planilha simples.
- A barra de busca nao desce mais quando o modo de busca e ativado -- a seta de voltar aparece dentro da propria barra, mantendo a barra superior estavel.
- Nao encontrado em Produtos Embalados: quando a busca nao retorna resultados, voce pode escanear ou digitar o codigo de barras para tentar novamente. Se ainda nao for encontrado, voce pode salvar o produto localmente ou ver uma previa do recurso "Contribuir com Open Food Facts" em breve.
- Tela de detalhes da receita: veja ingredientes, instrucoes e custo de
  qualquer receita. Toque em uma receita na lista para abri-la.
- "Fiz esta receita": marque uma receita como feita — os ingredientes sao
  deduzidos automaticamente da sua despensa (primeiro os mais antigos).
  Avisos de falta impedem o cozimento quando nao ha estoque suficiente.
  Acao desfeita via undo.
- Historico de receitas: toda vez que voce cozinha uma receita, fica
  registrado permanentemente.
- Olho: alternar visibilidade de precos nas telas de lista e detalhes da
  receita, igual nas telas inicial e de estatisticas.
- Formulario de receita: adicionar o mesmo ingrediente duas vezes agora
  aumenta a quantidade em vez de mostrar duas linhas separadas.
- Visibilidade de precos agora tambem oculta custos nos cartoes da lista
  de receitas e no banner de custo medio.
- Pesquisar produto: um novo botao no formulario de receita permite
  pesquisar no Open Food Facts e no banco de dados local por nome ou
  codigo de barras para encontrar ingredientes.
- Registro de receitas: salve receitas com ingredientes e instrucoes,
  auto-preenchidas a partir da sua despensa. Visualize, edite e exclua receitas.
- Custo da receita: veja quanto cada receita custa, mais a media de todas as
  receitas. Os custos usam sua configuracao de moeda.

## [0.0.8+4]

- Os dados dos produtos agora sao armazenados em cache na nuvem, tornando as
  consultas repetidas mais rapidas mesmo apos limpar o cache local.
- Sua despensa selecionada agora e lembrada entre as reinicializacoes do app.
- Corrigida uma travada rara ao navegar de volta de algumas telas.
- Corrigida uma travada rara na inicializacao que podia ocorrer quando o cache
  de produtos era atualizado durante o primeiro quadro.

## [0.0.8]

### Corrigido

- Os dados nutricionais do USDA para produtos alimenticios agora carregam corretamente (estava retornando 403 devido a posicao incorreta da chave de API).
- Produtos alimenticios nao causam mais avisos de "falha na atualizacao" durante o pull-to-refresh.
- Traducao de "apple" corrigida de "Maca" para "Maçã".
- Os graficos da tela de estatisticas agora sao exibidos corretamente com legendas de eixo e dados de loja adequados.
- O teclado nao esconde mais o conteudo das folhas inferiores ao inserir dados.

### Adicionado

- Produtos alimenticios agora mostram um icone de folha verde nos resultados de pesquisa e na lista de compras, em vez do icone de codigo de barras.
- A folha "Novidades" agora mostra o changelog em portugues ou portugues brasileiro quando o idioma do aplicativo esta configurado de acordo.

### Alterado

- Os nomes dos produtos agora sao devidamente localizados nos cartoes de inventario e telas de detalhes do produto.
- Sistema de changelog simplificado. O changelog no aplicativo agora le diretamente de um arquivo voltado para o usuario, sem necessidade de analise ou limpeza.

## [0.0.7]

### Corrigido

- O formatador da calculadora de precos nao mostra mais zeros a esquerda.
- As folhas inferiores nao sao mais obscurecidas pela barra de navegacao do sistema.
- O teclado nao esconde mais o conteudo das folhas inferiores.

## [0.0.6]

### Adicionado

- As notificacoes de expiracao agora mostram nomes de produtos em vez de codigos de barras.
- A lista de compras sugere produtos da sua despensa.
- Novos graficos de estatisticas: gastos mensais, gastos por loja, Nutri-Score por loja.
- Suporte para produtos sem codigo de barras (codigos PLU para produtos alimenticios).
- Alternancia de peso e unidade para produtos alimenticios.
- Carrossel de produtos alimenticios de adicao rapida na tela inicial.
- Monitoramento de precos na lista de compras com subtotais por moeda.
- Mova itens comprados para sua despensa com um toque.
- A lista de compras agora e por despensa.
- Pesquisa de produtos ao adicionar itens a lista de compras.
- Autocomplete persistente de lojas ao inserir precos.

### Corrigido

- Os itens da lista de compras estao limitados ao inventario ativo.
- Sem itens duplicados ao mover para sua despensa.

## [0.0.5]

### Corrigido

- Vazamento de traducao na pagina de detalhes do produto.
- O scanner da camera nao fica mais preso em um loop de erros.
- Alternancia de lanterna/adicionada ao scanner.
- Feedback ao usuario quando a leitura do codigo de barras falha.

### Adicionado

- Toque para focar e zoom automatico no scanner.
- A sobreposicao do scanner e pausada quando o aplicativo esta em segundo plano para economizar bateria.

### Alterado

- As notificacoes sao inicializadas mais cedo, evitando lembretes perdidos.
- Melhor tratamento da conectividade na inicializacao.
- Precos em moedas mistas agora sao convertidos corretamente.
- Entradas manuais de produtos nao sobrescrevem mais dados de API em cache.
- As capturas de tela de feedback agora sao comprimidas e enviadas corretamente.
- Melhorias de desempenho do banco de dados com novos indices.
- O carregamento da lista de compras nao mostra mais estado vazio intermitente.
- O texto dos cartoes de inventario e truncado em vez de transbordar.

## [0.0.4]

### Adicionado

- Lista de compras como uma nova guia na barra de navegacao inferior.
- Monitoramento de precos com conversao de moedas.
- Modo escuro AMOLED para economia de energia em telas compativeis.
- Configuracoes e persistencia de tema entre reinicializacoes do aplicativo.
- Notificacao de lembrete de inatividade.
- Guia de testes manuais para QA.

### Alterado

- Tela de pesquisa atualizada para a barra de pesquisa Material 3.
- Pesquisa sem acentos para melhor descoberta de produtos.
- Servico de notificacoes reescrito para maior confiabilidade.
- Comentarios de documentacao agora usam referencias entre colchetes para melhor navegacao.

### Corrigido

- O formulario de feedback agora suporta multiplos anexos de capturas de tela.
- Strings nao traduzidas nas telas de estatisticas e feedback agora estao localizadas.
- Seletor de inventario redesenhado com distintivo Nutri-Score.
- A pesquisa da API OFF tenta novamente em caso de falha.

## [0.0.3]

### Adicionado

- Tela de estatisticas com graficos Nutri-Score, discriminacao por categoria e localizacao.
- Widgets placeholder ComingSoonView para funcionalidades futuras.
- Miniaturas de produtos nos resultados de pesquisa.
- Botao "Novidades" nas configuracoes para ver o changelog sob demanda.
- GitHub Wiki para documentacao da API.

### Corrigido

- As imagens dos detalhes do produto agora respeitam a resolucao da tela.
- Legendas dos graficos visiveis no modo escuro.
- Pesquisa agora corresponde aos resultados do site OFF com mais precisao.
- Registros de notificacao de expiracao mostram informacao correta do produto.

## [0.0.2]

### Adicionado

- Pressao longa para selecionar itens de inventario para operacoes em lote.
- Mover itens em lote entre despensas.
- Deslizar entre guias de navegacao inferior.
- Deslizar para a direita nos resultados de pesquisa para adicionar a despensa.
- Menu de contexto com pressao longa nos resultados de pesquisa.
- Deslizar para excluir itens de inventario e despensas.
- Pull-to-refresh na tela de estatisticas.

### Corrigido

- Pesquisa agora trata corretamente caracteres acentuados.
- Sem mais falhas da tela de pesquisa apos descarte.
- Sem mais atualizacao de fundo duplicada na inicializacao.

## [0.0.1]

### Adicionado

- Pesquisa com autocomplete e miniaturas de produtos.
- Pesquisa sem acentos.
- Pin-to-zoom em fotos de produtos.
- Tela de configuracoes agrupada em secoes.

### Nutri-Score

- Distintivo cinza para produtos nao aplicaveis.
- Dica explicando porque o Nutri-Score nao e aplicavel.

### Exclusao em lote

- Caixas de selecao multisselecao nos cartoes de inventario.
- Confirmacao de exclusao com desfazer.

### Ajuste rapido de quantidade

- Botoes de mais e menos nos tiles de inventario.
- Toque na quantidade para digitar um valor diretamente.

## [0.1.0] -- Lancamento inicial (MVP)

### Core

- Leitura de codigo de barras via camera do dispositivo.
- Pesquisa de produtos Open Food Facts.
- Cache local offline-first.
- Monitoramento de data de vencimento com notificacoes.
- Tabela nutricional e lista de ingredientes.

### Gerenciamento de produtos

- Adicionar produtos ao inventario com quantidade, unidade e localizacao.
- Entrada manual de produtos quando o codigo de barras e desconhecido.
- Envio de produtos ao Open Food Facts.

### UI

- Suporte para modo escuro.
- Tela de configuracoes com preferencias de tema e notificacoes.

### Multi-inventario

- Despensas nomeadas (Casa, Trabalho, Camping).
- Visualizacoes e estatisticas de inventario por despensa.
