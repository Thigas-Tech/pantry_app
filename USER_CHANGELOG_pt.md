# Registro de alteracoes do usuario

## [0.0.8]

### Corrigido
- Os dados de nutricao do USDA para produtos alimentares agora carregam corretamente (estava a retornar 403 devido a posicao incorreta da chave de API).
- Os produtos alimentares ja nao causam avisos de "falha na atualizacao" durante o pull-to-refresh.
- Traducao de "apple" corrigida de "Maca" para "Maçã".
- Os graficos do ecra de estatisticas agora sao apresentados corretamente com legendas de eixo e dados de loja adequados.
- O teclado ja nao esconde o conteudo das folhas inferiores ao introduzir dados.

### Adicionado
- Os produtos alimentares agora mostram um icone de folha verde nos resultados de pesquisa e na folha de lista de compras, em vez do icone de codigo de barras.
- A folha "Novidades" agora mostra o changelog em portugues ou portugues brasileiro quando o idioma da aplicacao esta definido em conformidade.

### Alterado
- Os nomes dos produtos agora estao devidamente localizados nos cartoes de inventario e ecras de detalhe do produto.
- Sistema de changelog simplificado. O changelog na aplicacao agora le diretamente de um ficheiro voltado para o utilizador, sem necessidade de analise ou limpeza.

## [0.0.7]

### Corrigido
- O formatador da calculadora de precos ja nao mostra zeros a esquerda.
- As folhas inferiores ja nao sao obscurecidas pela barra de navegacao do sistema.
- O teclado ja nao esconde o conteudo das folhas inferiores.

## [0.0.6]

### Adicionado
- As notificacoes de expiracao agora mostram nomes de produtos em vez de codigos de barras.
- A lista de compras sugere produtos da sua despensa.
- Novos graficos de estatisticas: gastos mensais, gastos por loja, Nutri-Score por loja.
- Suporte para produtos sem codigo de barras (codigos PLU para produtos alimentares).
- Alternancia de peso e unidade para produtos alimentares.
- Carrossel de produtos alimentares de adicao rapida no ecra inicial.
- Monitorizacao de precos na lista de compras com subtotais por moeda.
- Mova itens comprados para a sua despensa com um toque.
- A lista de compras e agora por despensa.
- Pesquisa de produtos ao adicionar itens a lista de compras.
- Autocomplete persistente de lojas ao inserir precos.

### Corrigido
- Os itens da lista de compras estao limitados ao inventario ativo.
- Sem itens duplicados ao mover para a sua despensa.

## [0.0.5]

### Corrigido
- Fuga de traducao na pagina de detalhe do produto.
- O scanner da camara ja nao fica preso num loop de erros.
- Alternancia de lanterna/adicionado ao scanner.
- Feedback ao utilizador quando a leitura do codigo de barras falha.

### Adicionado
- Toque para focar e zoom automatico no scanner.
- A sobreposicao do scanner e pausada quando a aplicacao esta em segundo plano para poupar bateria.

### Alterado
- As notificacoes sao inicializadas mais cedo, evitando lembretes perdidos.
- Melhor tratamento da conectividade no arranque.
- Precos em moedas mistas agora sao convertidos corretamente.
- Entradas manuais de produtos ja nao sobrescrevem dados de API em cache.
- As capturas de ecra de feedback sao agora comprimidas e carregadas corretamente.
- Melhorias de desempenho da base de dados com novos indices.
- O carregamento da lista de compras ja nao mostra estado vazio intermitente.
- O texto dos cartoes de inventario e truncado em vez de transbordar.

## [0.0.4]

### Adicionado
- Lista de compras como um novo separador na barra de navegacao inferior.
- Monitorizacao de precos com conversao de moedas.
- Modo escuro AMOLED para poupanca de energia em ecras compativeis.
- Definicoes e persistencia de tema entre reinicios da aplicacao.
- Notificacao de lembrete de inatividade.
- Guia de testes manuais para QA.

### Alterado
- Ecra de pesquisa atualizado para a barra de pesquisa Material 3.
- Pesquisa sem acentos para melhor descoberta de produtos.
- Servico de notificacoes reescrito para maior fiabilidade.
- Comentarios de documentacao agora usam referencias entre parenteses retos para melhor navegacao.

### Corrigido
- O formulario de feedback agora suporta multiplos anexos de capturas de ecra.
- Strings nao traduzidas nos ecras de estatisticas e feedback agora estao localizadas.
- Seletor de inventario redesenhado com distintivo Nutri-Score.
- A pesquisa da API OFF tenta novamente em caso de falha.

## [0.0.3]

### Adicionado
- Ecra de estatisticas com graficos Nutri-Score, discriminacao por categoria e localizacao.
- Widgets placeholder ComingSoonView para funcionalidades futuras.
- Miniaturas de produtos nos resultados de pesquisa.
- Botao "Novidades" nas definicoes para ver o changelog a pedido.
- GitHub Wiki para documentacao da API.

### Corrigido
- As imagens dos detalhes do produto agora respeitam a resolucao do ecra.
- Legendas dos graficos visiveis em modo escuro.
- Pesquisa agora corresponde aos resultados do site OFF com mais precisao.
- Registos de notificacao de expiracao mostram informacao correta do produto.

## [0.0.2]

### Adicionado
- Pressao longa para selecionar itens de inventario para operacoes em lote.
- Mover itens em lote entre despensas.
- Deslizar entre separadores de navegacao inferior.
- Deslizar para a direita nos resultados de pesquisa para adicionar a despensa.
- Menu de contexto com pressao longa nos resultados de pesquisa.
- Deslizar para eliminar itens de inventario e despensas.
- Pull-to-refresh no ecra de estatisticas.

### Corrigido
- Pesquisa agora trata corretamente caracteres acentuados.
- Sem mais falhas do ecra de pesquisa apos eliminacao.
- Sem mais atualizacao de fundo duplicada no arranque.

## [0.0.1]

### Adicionado
- Pesquisa com autocomplete e miniaturas de produtos.
- Pesquisa sem acentos.
- Pin-to-zoom em fotos de produtos.
- Ecra de definicoes agrupado em secoes.

### Nutri-Score
- Distintivo cinza para produtos nao aplicaveis.
- Dica explicando porque o Nutri-Score nao e aplicavel.

### Eliminacao em lote
- Caixas de selecao multisselecao nos cartoes de inventario.
- Confirmacao de eliminacao com anular.

### Ajuste rapido de quantidade
- Botoes de mais e menos nos tiles de inventario.
- Toque na quantidade para digitar um valor diretamente.

## [0.1.0] -- Lancamento inicial (MVP)

### Core
- Leitura de codigo de barras via camara do dispositivo.
- Pesquisa de produtos Open Food Facts.
- Cache local offline-first.
- Monitorizacao de data de expiracao com notificacoes.
- Tabela nutricional e lista de ingredientes.

### Gestao de produtos
- Adicionar produtos ao inventario com quantidade, unidade e localizacao.
- Entrada manual de produtos quando o codigo de barras e desconhecido.
- Submissao de produtos ao Open Food Facts.

### UI
- Suporte para modo escuro.
- Ecra de definicoes com preferencias de tema e notificacoes.

### Multi-inventario
- Despensas nomeadas (Casa, Trabalho, Campismo).
- Vistas e estatisticas de inventario por despensa.
