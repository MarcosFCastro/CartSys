# CartSys — Desafio Programador Sênior (Delphi + C#)

Solução completa para o desafio CartSys: **ERP Vendas em Delphi 10.3** integrado via REST com **ERP Financeiro em C# .NET 4.8**, persistência em **Firebird 3.0**, relatórios com **ReportBuilder** (Delphi) e **Fast Report .NET** (C#), UI com **DevExpress** nos dois módulos.

## Visão Geral

```
┌─────────────────────┐         ┌─────────────────────┐
│   ERP Vendas        │  REST   │  ERP Financeiro     │
│   (Delphi 10.3)     │◄───────►│  (C# .NET 4.8)      │
│   - CRUD clientes   │  JSON   │  - Quitação         │
│   - CRUD produtos   │         │  - Cancelamento     │
│   - Vendas + itens  │         │  - Relatórios PDF   │
│   - PDF + e-mail    │         │  - Swagger UI       │
└──────────┬──────────┘         └──────────┬──────────┘
           │                               │
           ▼                               ▼
   ERP_VENDAS.FDB                ERP_FINANCEIRO.FDB
   (Firebird 3.0)                (Firebird 3.0)
```

Bancos separados — cada módulo é dono dos seus dados; a única ponte é a API REST.
Decisões arquiteturais documentadas em [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Pré-requisitos

| Componente | Versão mínima | Observação |
|---|---|---|
| Delphi | 10.3 Rio (Update 3+) | Compilação do ERP Vendas |
| .NET Framework | 4.8 | Runtime do ERP Financeiro |
| Visual Studio | 2019 / 2022 | Compilação da solution C# |
| Firebird | 3.0 | Servidor em `localhost:3050` |
| DevExpress VCL | 23.2 | Componentes Delphi (ver `$(DevExpressDir)` no `.dproj`) |
| DevExpress WinForms | 23.2 | Componentes C# (ver `$(DevExpressDir)` no `.csproj`) |
| ReportBuilder | 22+ | Relatórios PDF do módulo Delphi |
| Fast Report .NET | 2022+ | Template `.frx` incluído no projeto |
| Firebird Client | 3.0 | Biblioteca nativa para FireDAC e EF6 |

> **DevExpress path:** o `.dproj` usa a variável MSBuild `$(DevExpressDir)` (default `C:\Program Files (x86)\DevExpress 23.2\Components\`). Se sua instalação está em caminho diferente, defina a variável no ambiente antes de compilar.

## Estrutura

```
CartSys-Desafio/
├── docs/
│   ├── ARCHITECTURE.md          Decisões arquiteturais e trade-offs
│   └── API.md                   Contrato REST (payloads, status codes)
├── database/
│   ├── vendas/                  5 scripts DDL + seed (Firebird)
│   └── financeiro/              2 scripts DDL (Firebird)
├── postman/
│   └── CartSys.postman_collection.json
└── src/
    ├── ERPVendas.Delphi/
    │   ├── ERPVendas.dpr          Projeto principal
    │   ├── ERPVendas.Tests.dpr    Runner DUnitX (console)
    │   ├── config.ini             Configuração (banco, API, SMTP)
    │   └── src/                   Código-fonte (Infra / Model / Service / View / Reports)
    └── ERPFinanceiro.CSharp/
        ├── ERPFinanceiro.sln
        ├── ERPFinanceiro.Domain/
        ├── ERPFinanceiro.Application/
        ├── ERPFinanceiro.Data/
        ├── ERPFinanceiro.Api/     Host OWIN self-hosted (porta 5001)
        ├── ERPFinanceiro.UI/      WinForms + relatório Fast Report
        └── ERPFinanceiro.Tests/   xUnit + Moq + FluentAssertions
```

## Configuração rápida

### 1. Banco de dados

Abra um terminal com o Firebird `isql` no PATH (normalmente `C:\Program Files\Firebird\Firebird_3_0\`):

```bat
mkdir C:\CartSys\DB

isql -u SYSDBA -p masterkey -i database\vendas\01-create-database.sql
isql -u SYSDBA -p masterkey -i database\vendas\02-create-tables.sql
isql -u SYSDBA -p masterkey -i database\vendas\03-create-generators-triggers.sql
isql -u SYSDBA -p masterkey -i database\vendas\04-create-indexes.sql
isql -u SYSDBA -p masterkey -i database\vendas\05-seed-data.sql

isql -u SYSDBA -p masterkey -i database\financeiro\01-create-database.sql
isql -u SYSDBA -p masterkey -i database\financeiro\02-create-tables.sql
```

Resultado: `ERP_VENDAS.FDB` com 2 clientes e 3 produtos de teste; `ERP_FINANCEIRO.FDB` vazio.

### 2. ERP Financeiro (C#)

1. Abra `src/ERPFinanceiro.CSharp/ERPFinanceiro.sln` no Visual Studio
2. **Build → Restore NuGet Packages** (EntityFramework, Polly, SimpleInjector, etc.)
3. Ajuste a connection string em `ERPFinanceiro.Api/App.config` se necessário
4. **Inicie `ERPFinanceiro.Api` primeiro** (host OWIN console) — escuta em `http://localhost:5001`
5. Acesse `http://localhost:5001/swagger` para confirmar que está no ar
6. Inicie `ERPFinanceiro.UI` (WinForms) quando quiser operar pela interface gráfica

### 3. ERP Vendas (Delphi)

1. Abra `src/ERPVendas.Delphi/ERPVendas.dpr` no Delphi 10.3
2. **Project → Build** em configuração Release
3. Copie `config.ini` para a pasta do executável e ajuste (ver seção *Configurações*)
4. Execute — o sistema conecta no banco e inicia o servidor REST de callbacks na porta **5002**

### 4. Teste end-to-end

| Passo | O que fazer | O que verificar |
|---|---|---|
| 1 | ERP Vendas: criar cliente com e-mail válido | Registro aparece na grade |
| 2 | ERP Vendas: criar venda com 2+ itens e salvar | Mensagem "Venda N gravada" |
| 3 | Aguardar ~2 s | Log: *"Titulo da venda X criado no financeiro (id Y)"* |
| 4 | ERP Financeiro: atualizar lista de títulos | Título com status `PENDENTE` |
| 5 | ERP Financeiro: selecionar título → Quitar → PIX | Status muda para `QUITADO` |
| 6 | ERP Vendas: verificar venda | Status `QUITADA` |
| 7 | Caixa de entrada do cliente | E-mail com PDF do pedido em anexo |

### 5. Postman

Importe `postman/CartSys.postman_collection.json` para testar todas as rotas da API diretamente (health, criar título, quitar, cancelar, listar).

## Configurações

### `config.ini` — ERP Vendas

```ini
[Database]
Server=localhost
Port=3050
Path=C:\CartSys\DB\ERP_VENDAS.FDB
User=SYSDBA
Password=masterkey

[ApiFinanceiro]
Url=http://localhost:5001
ApiKey=cartsys-dev-key
TimeoutSeg=30

[ApiVendas]
Port=5002

[SMTP]
Host=smtp.gmail.com
Port=587
User=seu-email@gmail.com
Password=sua-senha-de-app
From=seu-email@gmail.com
UseSSL=True
```

> **Gmail com 2FA:** use uma senha de app gerada em `myaccount.google.com/apppasswords`.
> **Sem servidor SMTP real:** configure o [Mailtrap](https://mailtrap.io) — intercepta e-mails localmente sem envio real.

### `App.config` — ERP Financeiro

```xml
<connectionStrings>
  <add name="FinanceiroDb"
       connectionString="User=SYSDBA;Password=masterkey;Database=C:\CartSys\DB\ERP_FINANCEIRO.FDB;DataSource=localhost;Port=3050"
       providerName="FirebirdSql.Data.FirebirdClient"/>
</connectionStrings>
<appSettings>
  <add key="ApiKey"      value="cartsys-dev-key"/>
  <add key="VendasApiUrl" value="http://localhost:5002"/>
</appSettings>
```

## Testes automatizados

### Delphi — DUnitX (7 testes)

Abra `ERPVendas.Tests.dpr` no Delphi, compile e execute. O runner é console e gera `TestResults\*.xml` (NUnit format) para CI. Cobre:

- Cálculo de totais (`ValorTotal`, `ValorLiquido`, desconto)
- Validações (`EValidationException` para venda sem itens, sem cliente, desconto inválido)
- Transições de status (`PodeQuitar`, `PodeCancelar`)
- Regras de item (quantidade zero)

### C# — xUnit + Moq + FluentAssertions (5 testes)

```bat
cd src\ERPFinanceiro.CSharp
dotnet test --logger "console;verbosity=normal"
```

Cobre: criação de título, quitação, cancelamento, idempotência e validação de fluxo inválido (cancelar título quitado).

## Logs

| Onde | Arquivo |
|---|---|
| ERP Vendas | `C:\CartSys\Logs\Vendas\erpvendas_YYYY-MM-DD.log` |
| ERP Financeiro (geral) | `logs\financeiro_YYYY-MM-DD.log` (rotação diária, 30 dias) |
| ERP Financeiro (integração) | `logs\integracao_YYYY-MM-DD.log` (15 dias, só chamadas REST) |
| Banco de dados (ambos) | Tabela `LOG_INTEGRACAO` com request/response completos |

A tabela `LOG_INTEGRACAO` tem tela de visualização no ERP Vendas (**Integração → Log de Integração**) com suporte a reenvio manual.

## Troubleshooting

| Sintoma | Causa provável | Solução |
|---|---|---|
| "Cannot find FB library" | Firebird client ausente | Instalar Firebird 3.0 Client |
| HTTP 401 nas chamadas REST | API Key divergente | Conferir `ApiKey` no `config.ini` e `App.config` |
| E-mail não chega | Credencial SMTP incorreta | Usar senha de app Gmail ou Mailtrap |
| Callback de quitação falha | Porta 5002 bloqueada | Liberar no firewall ou alterar `[ApiVendas].Port` |
| `FirebirdSql` não resolve (EF6) | Provider não registrado | Conferir `<system.data>/<DbProviderFactories>` no `App.config` |
| DevExpress "package not found" | Caminho de instalação diferente | Definir `$(DevExpressDir)` nas variáveis de ambiente do MSBuild |

## Diferenciais implementados

- Tabela `LOG_INTEGRACAO` bilateral com tela de visualização e reenvio manual
- Swagger em `http://localhost:5001/swagger` com documentação interativa
- Coleção Postman com 7 requests prontas
- Health checks em ambos os lados (`GET /api/v1/health`)
- Retry com backoff exponencial — Polly no C# (1 s / 2 s / 4 s), manual no Delphi
- Idempotência por `idVendaExterna` (`UNIQUE`) — reenvio retorna 409 com o título existente
- Soft delete nos cadastros (campo `ATIVO`)
- Auditoria via triggers (`DT_CADASTRO`, `DT_ALTERACAO` em todas as tabelas)
- Paginação na API (`page` / `pageSize`)
- DI Container (SimpleInjector no C#)
- Configuração 100% externa — zero hardcode de URL ou credencial
- Template Fast Report (`.frx`) incluído — relatório financeiro pronto para uso

## Sugestões de evolução (fora do escopo do desafio)

- Docker Compose com Firebird + ambas as APIs
- Autenticação OAuth2/JWT substituindo API Key
- Dashboard de KPIs financeiros em tempo real
- Quitação parcial de títulos
- Mensageria assíncrona (RabbitMQ) em vez de callback HTTP síncrono
- CI/CD com GitHub Actions
