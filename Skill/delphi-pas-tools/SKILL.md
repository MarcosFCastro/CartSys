---
name: delphi-pas-tools
description: Ferramentas Delphi 10.3 Rio para o CartSys ERPVendas. Use para editar .pas/.dfm, compilar .dproj e navegar no código do projeto.
allowed-tools: Read, Edit, Grep, Glob, Bash
---

# Ferramentas Delphi/Pascal — CartSys ERPVendas

## Projeto

- **Raiz:** `C:\CartSys-Desafio\src\ERPVendas.Delphi\`
- **DPR:** `ERPVendas.dpr`
- **IDE:** RAD Studio 10.3 Rio (Delphi 10.3)
- **Banco:** Firebird 3.0 via FireDAC
- **UI:** VCL + DevExpress

## Encoding

Delphi 10.3 Rio salva `.pas` em UTF-8 (com ou sem BOM). Use a ferramenta **Edit** normalmente — não há risco de corrupção de acentos como no Delphi 2007.

**Antes de editar:** sempre leia o arquivo com **Read** para confirmar o trecho exato a substituir.

## Estrutura do Projeto

```
ERPVendas.Delphi\
  ERPVendas.dpr
  src\
    Infra\      ← uConfig, uConnection, uLogger, uExceptions, uRESTClient, uRESTServer
    Model\
      Entity\   ← uCliente, uProduto, uVenda
      DAO\      ← uClienteDAO, uProdutoDAO, uVendaDAO, uLogIntegracaoDAO
    Service\    ← uClienteService, uProdutoService, uVendaService,
                   uIntegracaoFinanceiroService, uEmailService
    View\       ← forms VCL (.pas + .dfm)
    Reports\    ← uRptPedido
  tests\
    uVendaTest.pas
```

## Compilação via MSBuild

```powershell
# Debug
msbuild "C:\CartSys-Desafio\src\ERPVendas.Delphi\ERPVendas.dproj" /p:Config=Debug /p:Platform=Win32

# Release
msbuild "C:\CartSys-Desafio\src\ERPVendas.Delphi\ERPVendas.dproj" /p:Config=Release /p:Platform=Win32
```

**Timeout:** 120000ms

**Saída:**
- Debug: `Win32\Debug\ERPVendas.exe`
- Release: `Win32\Release\ERPVendas.exe`

## Padrão FireDAC — Transação

```pascal
FConexao.StartTransaction;
try
  // operações DML
  FConexao.Commit;
except
  if FConexao.InTransaction then
    FConexao.Rollback;
  raise;
end;
```

**Sempre** use `ParamByName` — nunca concatene valores em SQL.

## TTask — Operações Assíncronas

Cada `TTask` deve criar sua própria conexão via `TConnection.Instance.NovaConexao` e liberá-la no `finally`. Callbacks que atualizam a UI **devem** usar `TThread.Queue(nil, procedure begin ... end)`.

## Guia de Estilo

- **Indentação:** 2 espaços — nunca tabs
- **Palavras reservadas:** sempre minúsculas (`begin`, `end`, `var`, `procedure`, `function`, `uses`...)
- **`begin`** sucedido por enter; **`else if`** na mesma linha
- **Campos privados:** prefixo `F` + CamelCase (`FConexao`, `FDAO`)
- **Variáveis locais:** prefixo `L` + CamelCase (`LQry`, `LVenda`)
- **Parâmetros:** prefixo `A` + CamelCase (`AConexao`, `AIdVenda`)
- **Classes/Records/Enums/Interfaces:** prefixo `T`/`I` + CamelCase
- **Constantes:** UPPER_SNAKE_CASE
- **Units infra:** `u` + PascalCase (`uConnection.pas`)
- **Units de form:** `uFrm` + PascalCase (`uFrmCadVenda.pas`)

**Memória:** sempre `try/finally...Free` para objetos criados localmente; `FreeAndNil` para campos.  
**Strings:** use `TStringBuilder` em loops de concatenação — nunca `S := S + C`.  
**Erros Win32:** use `RaiseLastOSError`, não `RaiseLastWin32Error`.

## Quando Usar

- Editar arquivos `.pas` ou `.dfm`
- Compilar o projeto via MSBuild
- Navegar no código com Grep/Glob
- Verificar a estrutura de units ou do DPR
