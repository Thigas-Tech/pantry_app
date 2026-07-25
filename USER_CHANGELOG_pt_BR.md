# Registro de alteracoes do usuario

## [0.0.10]

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

## [0.0.9]

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
