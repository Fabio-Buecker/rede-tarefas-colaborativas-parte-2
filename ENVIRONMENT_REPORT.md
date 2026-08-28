# Relatorio do Ambiente de Desenvolvimento

> **PENDENTE DE PREENCHIMENTO NA MAQUINA DO GRUPO.** O ambiente automatizado em que o projeto foi preparado nao possui Flutter/Dart instalado e, portanto, nao seria correto inventar a saida exigida. Antes da entrega, execute o script indicado abaixo no computador usado pelo grupo.

## Como gerar a saida integral automaticamente

No PowerShell, aberto na raiz do projeto, execute:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\gerar_relatorio_ambiente.ps1
```

O script substituira este arquivo pela saida real e integral de:

- `flutter doctor -v`
- `flutter --version`
- `dart --version`
- `git --version`

Depois, abra este arquivo, confirme que a secao `flutter doctor -v` esta completa e faça um novo commit.

