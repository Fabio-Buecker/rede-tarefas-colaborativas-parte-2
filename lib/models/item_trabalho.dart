import '../core/enums.dart';
import '../core/exceptions.dart';

abstract class ItemTrabalho {
  final String id;
  final DateTime criadoEm;
  final DateTime? prazo;
  final PrioridadeTarefa prioridade;
  final String? descricao;

  String _titulo;
  StatusTarefa _status;
  double _progresso;

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
    if (id.trim().isEmpty) {
      throw const ValidacaoException('O id do item de trabalho e obrigatorio.');
    }
    this.titulo = _titulo;
    if (status == StatusTarefa.concluida) {
      this.status = StatusTarefa.concluida;
    } else {
      this.progresso = progresso;
    }
  }

  String get titulo => _titulo;

  set titulo(String novoTitulo) {
    final String tituloTratado = novoTitulo.trim();
    if (tituloTratado.length < 3) {
      throw const ValidacaoException(
        'O titulo deve possuir pelo menos 3 caracteres.',
      );
    }
    _titulo = tituloTratado;
  }

  StatusTarefa get status => _status;

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

  double get progresso => _progresso;

  set progresso(double novoProgresso) {
    if (novoProgresso < 0 || novoProgresso > 100) {
      throw const ValidacaoException(
        'O progresso deve estar entre 0 e 100.',
      );
    }
    _progresso = novoProgresso;
    if (novoProgresso >= 100) {
      _status = StatusTarefa.concluida;
    } else if (novoProgresso > 0 && _status == StatusTarefa.pendente) {
      _status = StatusTarefa.emAndamento;
    }
  }

  bool get estaAtrasado {
    final DateTime? dataPrazo = prazo;
    return dataPrazo != null &&
        status != StatusTarefa.concluida &&
        dataPrazo.isBefore(DateTime.now());
  }

  void executarPasso(double incremento);

  Map<String, dynamic> toMap();

  @override
  String toString() =>
      'ItemTrabalho(id: $id, titulo: $titulo, status: ${status.rotulo}, '
      'prioridade: ${prioridade.rotulo}, progresso: ${progresso.toStringAsFixed(0)}%)';
}
