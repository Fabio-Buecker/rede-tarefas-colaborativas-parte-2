# Defesa técnica - TaskLink 2

## Demonstração em até seis minutos

1. **0:00 a 0:40**: abrir a visão geral e mostrar quadros, tarefas, badges e a relação tarefa/subtarefas.
2. **0:40 a 1:40**: criar tarefa com dois participantes; tentar título vazio para mostrar validação. Adicionar subtarefa, concluir e explicar o cálculo do progresso.
3. **1:40 a 3:00**: ativar modo offline e desligar a rede ou parar a API. Criar, editar e excluir. Mostrar a fila, fechar e reabrir o app para comprovar SQLite.
4. **3:00 a 4:00**: religar a rede/servidor, desativar offline e sincronizar. Mostrar confirmação e GET no servidor.
5. **4:00 a 5:00**: executar `flutter test` e localizar testes de fallback, validação e SQLite.
6. **5:00 a 6:00**: explicar o fluxo UI -> controller -> repository -> DAO/API e mostrar que `build()` não faz SQL/HTTP.

Use o servidor `python scripts/demo_api.py` para uma demonstração remota persistente. O JSONPlaceholder apenas simula escritas. Antes da aula, teste o emulador, o endpoint correto e o dispositivo que será utilizado.

## Perguntas para estudar

**Por que SQLite é a fonte da verdade?** A UI sempre lê a cópia local, incluindo após reiniciar ou perder a conexão. HTTP confirma pendências; ele não é necessário para listar tarefas.

**Por que não excluir fisicamente imediatamente?** O registro mantém um tombstone até a confirmação DELETE. Sem ele, a informação de exclusão se perderia offline.

**Por que existe uma revisão?** A resposta de um envio pode chegar depois de uma edição. O DAO só confirma a revisão enviada, preservando a nova como pendente.

**Por que conservar o ID remoto de uma resposta antiga?** Uma tarefa pode ser editada ou excluída durante seu primeiro POST. O ID remoto precisa continuar conhecido para o PUT ou DELETE seguinte.

**O que é Future?** Um valor disponível mais tarde. `await` suspende a função sem bloquear a thread de interface; não cria uma thread por si só.

**Quando usar setState e ChangeNotifier?** `setState` atualiza estado efêmero do formulário/filtro. O controller com `ChangeNotifier` compartilha a visão local entre telas e `ListenableBuilder` reage às alterações.

**O que fazem initState/dispose?** Inicializam e liberam controllers do formulário. Não liberar controllers pode manter recursos e listeners desnecessários.

**Por que verificar mounted?** Depois de um `await`, a tela pode ter sido desmontada. Só se usa seu contexto ou se chama setState enquanto ela continua montada.

**Como os argumentos são seguros?** `onGenerateRoute` aceita `IdArgs`, valida o ID e entrega à tela. Dados malformados produzem uma tela de erro de navegação; IDs inexistentes são tratados na consulta local.

**Como funciona a composição?** A tarefa contém subtarefas. Ambas herdam `ItemTrabalho`, e o domínio calcula a média dos progressos das subtarefas.

**Como o repositório é testado sem internet?** Injeção de `LocalDatasource` e HTTP `MockClient`. É possível simular 500, timeout, SocketException, JSON inválido e sucesso sem rede.

**O DAO também é realmente testado?** Sim. `local_dao_test.dart` abre SQLite em memória e verifica FKs, CRUD, transações, tombstones e cascata.

**Qual a diferença entre teste de unidade e widget?** Unidade testa regra isolada. Widget constrói a árvore, simula ações e observa renderização/validação. Não equivale a executar o app em um aparelho físico.

**Onde ficam as preferências?** Tema, offline e data da última sincronização em `shared_preferences`. As entidades não ficam lá, pois exigem consultas e relações no SQLite.

**O projeto resolve conflitos distribuídos?** Não. É uma evolução móvel offline-first com REST. Não implementa sincronização bidirecional de vários dispositivos nem atualização em tempo real.

## Alterações pequenas para treinar ao vivo

- Alterar a validação de título de 3 para 5 caracteres e ajustar um teste.
- Adicionar uma nova prioridade: localizar enum, conversores e dropdown.
- Mudar o timeout do serviço e localizar o teste correspondente.
- Criar filtro de tarefas atrasadas usando `estaAtrasado`.
- Mostrar qual teste falha ao remover a condição de revisão de `confirmar`.

Cada integrante deve conseguir localizar e explicar esses trechos. O uso de IA está declarado no README e não substitui o domínio individual exigido na avaliação.
