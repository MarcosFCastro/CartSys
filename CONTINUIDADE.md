# CartSys - Desafio Programador Sênior (Delphi + C#)

> **Documento de continuidade** — gerado em 04/05/2026 a partir da sessão de planejamento e implementação inicial via Claude.ai.
> Use este arquivo como contexto inicial ao retomar o trabalho via Claude CLI.

---

## 1. Contexto do desafio

**Empresa:** CartSys
**Vaga:** Programador Sênior Delphi e C#
**Prazo original:** 7 dias
**Avaliação:** linha a linha (cobertura, qualidade, padrões)
**Entrega:** `rh@cartsys.com.br`

### Módulos exigidos

**Módulo 1 — ERP Vendas (Delphi):**
- CRUD de Clientes, Produtos e Vendas
- Relatório de Pedido (PDF)
- Envio automático de e-mail ao cliente após quitação da venda
- Stack: Delphi 13/12/**10.3 (escolhido)**, FireDAC, Firebird 3.0, DevExpress VCL, ReportBuilder

**Módulo 2 — ERP Financeiro (C#):**
- Quitação e cancelamento de títulos
- Relatórios financeiros
- Stack: C# .NET 4.8, DevExpress WinForms, Entity Framework 6, Fast Report

**Integração:** REST/JSON entre os dois módulos.

---

## 2. Decisões arquiteturais tomadas

Estas decisões já estão implementadas no código entregue. Mantenha-as ao continuar:

1. **Bancos separados** (`ERP_VENDAS.FDB` e `ERP_FINANCEIRO.FDB`) — anti-padrão de banco compartilhado foi rejeitado e justificado em `docs/ARCHITECTURE.md`.

2. **Comunicação por callback (webhook)**, não polling:
   - Delphi expõe servidor REST embarcado (Indy `TIdHTTPServer`) na **porta 5002**
   - C# expõe Web API self-hosted via OWIN na **porta 5001**

3. **Idempotência** por chave externa: `idVendaExterna` é `UNIQUE` no Financeiro. Reenvios retornam 409 com o título existente.

4. **Camadas Delphi:** `View → Service → DAO → Infra`. Forms NUNCA acessam DAO direto.

5. **Clean Architecture C# simplificada:** `Domain (puro) ← Application ← Data/Api/UI`.

6. **Rich Domain Model** em C# (`Titulo.Quitar()` encapsula transição de estado).

7. **API Key** simples no header `X-API-Key` (suficiente para o escopo; em produção seria OAuth2/JWT).

8. **Soft delete** nos cadastros (`ATIVO='S'/'N'`).

9. **Vencimento padrão D+30** na geração do título.

10. **Threads:** envio ao financeiro em `TTask.Run`, callback de quitação dispara PDF + e-mail em background.

11. **Logging duplo:** arquivo diário + tabela `LOG_INTEGRACAO` com request/response completos.

12. **Retry com backoff exponencial:** Polly no C# (1s/2s/4s, 3 tentativas), implementação manual no Delphi.

---

## 3. Estado atual do projeto

### 3.1. Estrutura de pastas

```
CartSys-Desafio/
├── README.md                                       [OK]
├── docs/
│   ├── ARCHITECTURE.md                             [OK]
│   └── API.md                                      [OK]
├── database/
│   ├── vendas/
│   │   ├── 01-create-database.sql                  [OK]
│   │   ├── 02-create-tables.sql                    [OK] - CLIENTES, PRODUTOS, VENDAS, VENDAS_ITENS, LOG_INTEGRACAO
│   │   ├── 03-create-generators-triggers.sql       [OK]
│   │   ├── 04-create-indexes.sql                   [OK]
│   │   └── 05-seed-data.sql                        [OK] - 2 clientes, 3 produtos
│   └── financeiro/
│       ├── 01-create-database.sql                  [OK]
│       └── 02-create-tables.sql                    [OK] - TITULOS, MOVIMENTACOES, LOG_INTEGRACAO + sequences/triggers/índices
├── postman/
│   └── CartSys.postman_collection.json             [OK]
└── src/
    ├── ERPVendas.Delphi/
    │   ├── ERPVendas.dpr                           [OK]
    │   ├── config.ini                              [OK]
    │   ├── src/Infra/
    │   │   ├── uConfig.pas                         [OK] - Singleton de configuração via INI
    │   │   ├── uConnection.pas                     [OK] - Singleton FireDAC + NovaConexao para threads
    │   │   ├── uExceptions.pas                     [OK] - hierarquia EAppException/EBusiness/EValidation/ENotFound/EIntegration/EInfra
    │   │   ├── uLogger.pas                         [OK] - thread-safe, arquivo diário
    │   │   ├── uRESTClient.pas                     [OK] - wrapper TRESTClient com retry exponencial
    │   │   └── uRESTServer.pas                     [OK] - Indy TIdHTTPServer com rotas de callback
    │   ├── src/Model/Entity/
    │   │   ├── uCliente.pas                        [OK]
    │   │   ├── uProduto.pas                        [OK]
    │   │   └── uVenda.pas                          [OK] - TVenda + TVendaItem + TStatusVenda enum/helper
    │   ├── src/Model/DAO/
    │   │   ├── uClienteDAO.pas                     [OK]
    │   │   ├── uProdutoDAO.pas                     [OK]
    │   │   ├── uVendaDAO.pas                       [OK] - Insert em transação cabeçalho+itens
    │   │   └── uLogIntegracaoDAO.pas               [OK]
    │   ├── src/Service/
    │   │   ├── uClienteService.pas                 [OK] - IClienteService
    │   │   ├── uProdutoService.pas                 [OK] - IProdutoService
    │   │   ├── uVendaService.pas                   [OK] - IVendaService, orquestra persistência+integração+email
    │   │   ├── uIntegracaoFinanceiroService.pas    [OK]
    │   │   └── uEmailService.pas                   [OK] - Indy SMTP+SSL
    │   ├── src/View/
    │   │   ├── uFrmPrincipal.pas                   [OK] - inicializa servidor REST, menus
    │   │   ├── uFrmCadCliente.pas                  [OK] - exemplo completo do padrão
    │   │   ├── uFrmCadProduto.pas                  [OK] - esqueleto compacto
    │   │   ├── uFrmCadVenda.pas                    [OK] - esqueleto compacto
    │   │   └── uFrmLogIntegracao.pas               [OK]
    │   ├── src/Reports/uRptPedido.pas              [OK] - ReportBuilder + PDF
    │   └── tests/uVendaTest.pas                    [OK] - 7 testes DUnitX
    └── ERPFinanceiro.CSharp/
        ├── ERPFinanceiro.Domain/
        │   ├── Enums/StatusTitulo.cs               [OK]
        │   ├── Entities/Titulo.cs                  [OK] - rich domain
        │   ├── Entities/Movimentacao.cs            [OK]
        │   ├── Exceptions/DomainExceptions.cs      [OK]
        │   └── Interfaces/IRepositories.cs         [OK]
        ├── ERPFinanceiro.Application/
        │   ├── DTOs/TituloDtos.cs                  [OK]
        │   ├── Validators/TituloValidators.cs      [OK] - FluentValidation
        │   ├── Services/TituloService.cs           [OK]
        │   └── Mappings/DomainToDtoProfile.cs      [OK] - AutoMapper
        ├── ERPFinanceiro.Data/
        │   ├── Context/FinanceiroDbContext.cs      [OK] - EF6 + FirebirdSql provider
        │   ├── Configurations/TituloConfiguration.cs [OK]
        │   └── Repositories/TituloRepository.cs    [OK] - Repository + UnitOfWork
        ├── ERPFinanceiro.Api/
        │   ├── Startup.cs                          [OK] - OWIN, SimpleInjector DI, Swagger
        │   ├── Program.cs                          [OK] - host self-host
        │   ├── App.config                          [OK]
        │   ├── Controllers/TitulosController.cs    [OK] - + HealthController
        │   ├── Filters/ApiKeyAuthorizationFilter.cs [OK]
        │   ├── Filters/GlobalExceptionFilter.cs    [OK] - RFC 7807
        │   └── HttpClients/VendasIntegrationClient.cs [OK] - Polly retry, callback Vendas
        ├── ERPFinanceiro.UI/
        │   ├── Forms/FrmPrincipal.cs               [OK] - DevExpress RibbonForm
        │   ├── Forms/FrmQuitar.cs                  [OK]
        │   └── Reports/RelatorioFinanceiro.cs      [OK] - Fast Report
        └── ERPFinanceiro.Tests/TituloServiceTests.cs [OK] - 5 testes xUnit+Moq+FluentAssertions
```

**Total:** 61 arquivos criados.

### 3.2. Contrato REST resumido

**ERP Financeiro (porta 5001):**
- `POST /api/v1/titulos` — cria título a partir de venda
- `GET /api/v1/titulos/{id}` — detalhe
- `GET /api/v1/titulos?status=&clienteId=&dataInicio=&dataFim=&page=&pageSize=` — lista paginada
- `POST /api/v1/titulos/{id}/quitar` — quita e dispara callback
- `POST /api/v1/titulos/{id}/cancelar` — cancela e dispara callback
- `GET /api/v1/health`

**ERP Vendas (porta 5002):**
- `POST /api/v1/vendas/{id}/notificar-quitacao` — callback
- `POST /api/v1/vendas/{id}/notificar-cancelamento` — callback
- `GET /api/v1/health`

Detalhes completos com payloads em `docs/API.md`.

### 3.3. Configurações

| Item | Valor padrão |
|---|---|
| Banco | `C:\CartSys\DB\` |
| API Key | `cartsys-dev-key` |
| Porta Financeiro | 5001 |
| Porta Vendas | 5002 |
| SMTP | Configurável (recomendação: Mailtrap para teste, ou Gmail com senha de app) |
| Logs Vendas | `C:\CartSys\Logs\Vendas\` |

---

## 4. Itens pendentes (a fazer ao continuar)

### 4.1. Críticos (necessários para compilar e rodar)

- [x] **Arquivos `.dfm`** dos forms VCL — gerados em 05/05/2026 (5 forms: Principal, CadCliente, CadProduto, CadVenda, LogIntegracao). `.pas` atualizados com declarações de componentes adicionais.
- [x] **`.csproj` e `.sln`** do projeto C# — gerados em 05/05/2026 (SDK-style, net48, 6 projetos + .sln + SimpleInjectorValidatorFactory.cs)
- [x] **`<PackageReference>`** — já incorporado nos `.csproj` SDK-style gerados em 05/05/2026 (EntityFramework 6.4.4, FirebirdSql.Data.EntityFramework6 9.1.1, FluentValidation 8.6.3+WebApi, AutoMapper 12.0.1, SimpleInjector 5.4.5+WebApi, Polly 7.2.4, OwinSelfHost 5.2.9, Swashbuckle.Core 5.6.0, NLog 5.3.4, Newtonsoft.Json 13.0.3, xunit 2.7.0, Moq 4.20.72, FluentAssertions 6.12.0).
- [x] **`nlog.config`** para o C# — gerado em 05/05/2026 (`ERPFinanceiro.Api/nlog.config`)
- [x] **`.frx`** do Fast Report — `RelatorioFinanceiro.frx` gerado em 05/05/2026 (XML, A4 landscape, bandas Title/PageHeader/Data/Footer, 7 colunas + 5 parâmetros).
- [x] **`.dpr` de teste** — `ERPVendas.Tests.dpr` gerado em 05/05/2026 (DUnitX console runner + NUnit XML, referencia `uVendaTest.pas`).

### 4.2. Forms de edição (apenas listagens estão prontas)

- [x] `uFrmCadClienteEdit.pas` + `.dfm` — gerados em 05/05/2026
- [x] `uFrmCadProdutoEdit.pas` + `.dfm` — gerados em 05/05/2026
- [x] **Bindings completos cxGrid → ObjectList<T>**: `CarregarGrid`, `ClienteSelecionado`, `ProdutoSelecionado`, `AtualizarGridItens` implementados em 05/05/2026
- [x] **Lookup de produtos** no form de venda (`uFrmCadVenda.btnAddItemClick`) — implementado via `FProdutoService.Listar`
- [x] **Dialog de quantidade/preço** ao adicionar item — InputBox com validação

### 4.3. Outras pendências

- [x] `.gitignore` — gerado em 05/05/2026 (raiz do repo, cobre Delphi + C# + segredos + bancos)
- [ ] **Compilação dos executáveis** (.exe entregáveis) — requer ambiente Delphi + Visual Studio
- [ ] Imagem de banner/logo no relatório PDF
- [x] Geração real do PDF no `uVendaService.GerarPdfEEnviarEmail` — implementado em 05/05/2026: `TRptPedido.GerarPdf(LVenda, LCaminhoPdf, LConexao)` com conexão exclusiva da thread; `uRptPedido.dfm` criado

### 4.4. Diferenciais opcionais

- [ ] Docker Compose com Firebird + ambas as APIs
- [ ] Migrations versionadas (Flyway para Firebird)
- [ ] Health checks ricos (banco, dependências)
- [ ] Testes de integração end-to-end com Testcontainers
- [ ] CI/CD pipeline (GitHub Actions / Azure DevOps)
- [ ] Dashboard de KPIs financeiros
- [ ] Estorno de quitação
- [ ] Quitação parcial

---

## 5. Pontos de atenção identificados

Itens que exigiriam esclarecimento com o avaliador, mas foram decididos por padrão e documentados:

1. **Banco compartilhado vs separado** → escolhido SEPARADO (justificado em `ARCHITECTURE.md`)
2. **Quitação parcial vs total** → TOTAL (mais simples, atende o requisito)
3. **Cancelamento de título quitado** → NÃO permitido (regra em `Titulo.PodeCancelar`)
4. **Autenticação** → API Key (não exigida no desafio, mas implementada)
5. **SMTP configurável** → INI (Vendas) e App.config (Financeiro) externos

---

## 6. Diferenciais já implementados

- Tabela `LOG_INTEGRACAO` bilateral com tela de visualização e botão de reenvio
- Swagger no C# (`http://localhost:5001/swagger`)
- Coleção Postman versionada (7 requests prontas)
- Health checks em ambos os lados
- Configuração 100% externa (zero hardcode de URL/credencial)
- Retry com backoff exponencial (Polly em C#, manual no Delphi)
- Soft delete nos cadastros
- Auditoria (`DT_CADASTRO`, `DT_ALTERACAO` em todas as tabelas via triggers)
- Paginação na API
- DI Container (SimpleInjector no C#)
- Documentação `ARCHITECTURE.md` com decisões e trade-offs

---

## 7. Como retomar via Claude CLI

### 7.1. Setup do diretório

```bash
cd /caminho/onde/extraiu/CartSys-Desafio
claude
```

### 7.2. Prompts sugeridos para continuar

**Para gerar arquivos de projeto C#:**
> "Leia o `README.md` e a estrutura do projeto. Gere o `.sln` e os 6 arquivos `.csproj` (Domain, Application, Data, Api, UI, Tests) com todas as referências NuGet apropriadas (.NET Framework 4.8). Use a lista de pacotes documentada em CONTINUIDADE.md item 4.1."

**Para gerar `.dfm` dos forms:**
> "Para cada `.pas` em `src/ERPVendas.Delphi/src/View/`, gere o `.dfm` correspondente com os componentes declarados. Use DevExpress VCL onde aparecer cx*. O form principal precisa de menu, status bar e ribbon. Mantenha alinhamentos profissionais."

**Para completar bindings cxGrid:**
> "No `uFrmCadCliente.pas`, complete o método `CarregarGrid` populando um `TFDMemTable` a partir de `FClientes` e ligando ao `cxGrid` via `cxGridDBTableView`. Faça o mesmo para `uFrmCadProduto.pas`."

**Para criar forms de edição:**
> "Crie `uFrmCadClienteEdit.pas` (form modal de inserção/edição de cliente) seguindo o mesmo padrão dos forms já criados. Receba o `TCliente` e o `IClienteService` no construtor. Valide e salve via service."

**Para gerar `nlog.config` e `.gitignore`:**
> "Gere o arquivo `nlog.config` para o ERP Financeiro (NLog 4.x, target file diário em logs/financeiro_yyyy-mm-dd.log) e um `.gitignore` cobrindo Delphi (`*.dcu`, `__history/`, `*.identcache`) e C# (`bin/`, `obj/`, `*.user`, `packages/`)."

**Para implementar o PDF real:**
> "No `uVendaService.GerarPdfEEnviarEmail`, descomente e implemente a chamada real para `TRptPedido.GerarPdf`. Verifique se o caminho retornado existe antes de anexar ao e-mail. Trate exceções."

### 7.3. Ordem recomendada para finalizar

1. `.gitignore` + `nlog.config` (rápidos, evita poluição no repo)
2. `.csproj` + `.sln` do C# (sem isso o C# não compila)
3. `.dfm` dos forms Delphi (sem isso o Delphi não compila)
4. Bindings cxGrid completos
5. Forms de edição
6. Implementação real da geração de PDF
7. Testes manuais end-to-end
8. Compilação dos executáveis
9. README final com checklist de validação
10. Empacotar e enviar

---

## 8. Comandos úteis

### Banco de dados (criar do zero)
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

### Resetar banco (se precisar recriar)
```bat
del C:\CartSys\DB\ERP_VENDAS.FDB
del C:\CartSys\DB\ERP_FINANCEIRO.FDB
:: depois rode os scripts acima novamente
```

### Testes C#
```bat
cd src\ERPFinanceiro.CSharp
dotnet test
```

### Verificar Health Checks
```bash
curl http://localhost:5001/api/v1/health
curl http://localhost:5002/api/v1/health
```

### Acessar Swagger
```
http://localhost:5001/swagger
```

---

## 9. Validação end-to-end (smoke test)

Sequência mínima para validar que o sistema funciona inteiro:

1. Inicie o ERP Financeiro (C#) — confirme `http://localhost:5001/swagger` abrindo
2. Inicie o ERP Vendas (Delphi) — confirme log "Servidor REST do ERP Vendas ativo na porta 5002"
3. No Delphi: cadastre um cliente com e-mail válido
4. No Delphi: crie uma venda com 2-3 itens
5. **Verifique:** o log do Delphi mostra "Titulo da venda X criado no financeiro (id Y)"
6. No C#: abra a UI, atualize a lista — o título aparece como `PENDENTE`
7. No C#: selecione o título → Quitar → forma `PIX` → confirma
8. **Verifique:** o status do título vai para `QUITADO`
9. **Verifique:** o status da venda no Delphi vai para `QUITADA`
10. **Verifique:** o cliente recebe e-mail com PDF do pedido em anexo

Se todos os 10 passos funcionam, o sistema está pronto para entrega.

---

## 10. Checklist final antes de enviar

- [ ] Todos os projetos compilam (Delphi + C#) sem warnings
- [ ] Todos os testes passam (DUnitX + xUnit)
- [ ] Smoke test end-to-end completo (10 passos do item 9)
- [ ] `README.md` revisado com instruções claras
- [ ] `ARCHITECTURE.md` revisado
- [ ] `.gitignore` em vigor (sem binários no repo)
- [ ] Executáveis gerados e testados em máquina limpa
- [ ] Connection strings/credenciais sensíveis NÃO commitadas (use placeholders)
- [ ] Pasta `logs/` NÃO commitada
- [ ] Zip final ou repositório Git público
- [ ] E-mail para `rh@cartsys.com.br` com:
  - Apresentação breve
  - Link/anexo do projeto
  - Instruções de execução resumidas
  - Dados de contato

---

## 11. Referências

- `README.md` — guia operacional completo
- `docs/ARCHITECTURE.md` — decisões técnicas justificadas (este é o documento que demonstra senioridade ao avaliador)
- `docs/API.md` — contrato REST formal
- `postman/CartSys.postman_collection.json` — testes manuais

---

**Boa sorte com a continuação!** Se ao longo do trabalho via CLI surgirem decisões que conflitem com as documentadas aqui, **atualize este arquivo** para manter o registro coerente — vale tanto para você quanto para qualquer pessoa que olhar o projeto depois.
