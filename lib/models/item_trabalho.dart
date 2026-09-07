import '../core/enums.dart';
import '../core/exceptions.dart';

/// Contrato e comportamento comum de qualquer item executável do domínio.
///
/// A classe é `abstract` porque serve de base para [TarefaColaborativa] e
/// [Subtarefa] (nas respectivas classes), mas não representa sozinha um objeto
/// completo. Ela centraliza identificação, prazo, prioridade, estado e regras
/// de progresso para evitar duplicação nas subclasses.
abstract class ItemTrabalho {
  /// Identificador único e imutável do item.
  final String id;

  /// Data de criação; recebe o instante atual quando não é fornecida.
  final DateTime criadoEm;

  /// Data limite opcional. O `?` permite que o campo seja `null`.
  final DateTime? prazo;

  /// Nível de importância, imutável após a construção.
  final PrioridadeTarefa prioridade;

  /// Detalhamento opcional do trabalho.
  final String? descricao;

  // O prefixo `_` torna os campos privados à biblioteca. As alterações passam
  // pelos setters públicos para que as validações sempre sejam executadas.
  String _titulo;
  StatusTarefa _status;
  double _progresso;

  /// Construtor-base usado pelas subclasses para inicializar um item.
  ///
  /// Parâmetros com `required` são obrigatórios; os demais são opcionais e
  /// podem possuir valores padrão. A lista após `:` é executada antes do corpo:
  /// define a data e preenche os campos privados.
  ItemTrabalho({
    required this.id,
    required String titulo,
    this.descricao,
    this.prazo,
    this.prioridade = PrioridadeTarefa.media,
    DateTime? criadoEm,
    StatusTarefa status = StatusTarefa.pendente,
    double progresso = 0,
  })  : criadoEm = criadoEm ?? DateTime.now(),
        _titulo = titulo.trim(),
        _status = status,
        _progresso = progresso {
    // `trim` desconsidera espaços nas extremidades ao validar o identificador.
    if (id.trim().isEmpty) {
      throw const ValidacaoException('O id do item de trabalho e obrigatorio.');
    }
    // Usar os setters, inclusive no construtor, reaproveita as mesmas regras.
    this.titulo = _titulo;
    if (status == StatusTarefa.concluida) {
      this.status = StatusTarefa.concluida;
    } else {
      this.progresso = progresso;
    }
  }

  /// Lê o título já validado sem expor diretamente o campo privado.
  String get titulo => _titulo;

  /// Remove espaços externos e exige ao menos três caracteres no novo título.
  set titulo(String novoTitulo) {
    final String tituloTratado = novoTitulo.trim();
    if (tituloTratado.length < 3) {
      throw const ValidacaoException(
        'O titulo deve possuir pelo menos 3 caracteres.',
      );
    }
    _titulo = tituloTratado;
  }

  /// Estado atual do item.
  StatusTarefa get status => _status;

  /// Atualiza o estado respeitando as transições permitidas.
  ///
  /// Uma tarefa concluída não volta diretamente a pendente. Ao concluir, seu
  /// progresso também passa automaticamente para 100%, mantendo consistência.
  set status(StatusTarefa novoStatus) {
    if (_status == StatusTarefa.concluida &&
        novoStatus == StatusTarefa.pendente) {
      throw const TransicaoStatusException(
        'Uma tarefa concluida nao pode voltar diretamente para pendente.',
      );
    }
    _status = novoStatus;
    if (novoStatus == StatusTarefa.concluida) {
      _progresso = 100;
    }
  }

  /// Percentual concluído, sempre no intervalo de 0 a 100.
  double get progresso => _progresso;

  /// Valida e aplica um novo percentual, ajustando o estado quando necessário.
  set progresso(double novoProgresso) {
    if (novoProgresso < 0 || novoProgresso > 100) {
      throw const ValidacaoException(
        'O progresso deve estar entre 0 e 100.',
      );
    }
    _progresso = novoProgresso;
    if (novoProgresso >= 100) {
      _status = StatusTarefa.concluida;
    } else if (novoProgresso > 0 && _status != StatusTarefa.bloqueada) {
      // Um progresso parcial reabre uma tarefa anteriormente concluída. O
      // estado bloqueado é preservado porque depende de uma ação explícita.
      _status = StatusTarefa.emAndamento;
    }
  }

  /// Informa se há prazo vencido e trabalho ainda não concluído.
  ///
  /// A variável local promove o tipo anulável: após `dataPrazo != null`, o
  /// analisador sabe que pode chamar [DateTime.isBefore] com segurança.
  bool get estaAtrasado {
    final DateTime? dataPrazo = prazo;
    return dataPrazo != null &&
        status != StatusTarefa.concluida &&
        dataPrazo.isBefore(DateTime.now());
  }

  /// Obriga cada subclasse a definir como um passo de trabalho será executado.
  void executarPasso(double incremento);

  /// Obriga cada subclasse a fornecer uma representação serializável em mapa.
  Map<String, dynamic> toMap();

  /// Resume os principais campos para logs e depuração.
  @override
  String toString() =>
      'ItemTrabalho(id: $id, titulo: $titulo, status: ${status.rotulo}, '
      'prioridade: ${prioridade.rotulo}, progresso: ${progresso.toStringAsFixed(0)}%)';
}
