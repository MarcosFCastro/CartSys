# Arquitetura - CartSys Desafio

Este documento explica as **decisões arquiteturais** adotadas, suas **justificativas** e os **trade-offs** envolvidos. O objetivo é demonstrar a linha de raciocínio, não somente entregar código funcional.

## 1. Visão geral

```
ERP Vendas (Delphi)              ERP Financeiro (C#)
┌──────────────┐                 ┌──────────────┐
│ View (VCL)   │                 │ UI (WinForms)│
├──────────────┤                 ├──────────────┤
│ Service      │                 │ API (Web API)│
├──────────────┤                 ├──────────────┤
│ DAO          │                 │ Application  │
├──────────────┤                 ├──────────────┤
│ Infra        │  ── REST/JSON ──│ Data (EF6)   │
│ (Connection, │                 ├──────────────┤
│  REST,Logger)│                 │ Domain       │
└──────────────┘                 └──────────────┘
       │                                │
       ▼                                ▼
  ERP_VENDAS.FDB              ERP_FINANCEIRO.FDB
```

## 2. Decisões e justificativas

### 2.1. Bancos separados

**Decisão:** cada módulo tem seu próprio banco (`ERP_VENDAS.FDB`, `ERP_FINANCEIRO.FDB`). A única forma de comunicação é a API REST.

**Por quê:** integração por banco compartilhado é um anti-padrão clássico em sistemas distribuídos. Acopla os esquemas, dificulta evolução independente, gera deadlocks e ferramentas concorrentes mexendo nos mesmos dados. Bancos separados forçam contrato explícito (a API) e permitem que cada módulo evolua, escale e seja deployado de forma autônoma.

**Trade-off:** consistência eventual (a venda fica `PENDENTE` até o financeiro confirmar). Aceitável neste domínio — em ERP de vendas/financeiro, divergências de poucos segundos são normais e são compensadas pelos callbacks.

### 2.2. Comunicação via callback (webhook), não polling

**Decisão:** ao quitar um título, o Financeiro chama o endpoint `/api/v1/vendas/{id}/notificar-quitacao` no Delphi. O Delphi mantém um servidor HTTP embarcado (Indy `TIdHTTPServer`).

**Por quê:**
- **Polling** seria mais simples mas ineficiente: o Vendas teria que perguntar "já quitou?" a cada N segundos, gerando carga desnecessária e atraso.
- **Callback** dispara o e-mail imediatamente após a quitação — atende o requisito "envio automático após quitação".
- Demonstra entendimento de arquiteturas orientadas a eventos.

**Trade-off:** se o servidor do Vendas estiver fora, o callback falha. Mitigamos com:
- Retry com backoff exponencial (3 tentativas, 1s/2s/4s)
- Log persistente em `LOG_INTEGRACAO` com botão de reenvio manual
- Idempotência: o callback pode ser chamado múltiplas vezes sem efeito colateral

### 2.3. Idempotência por chave externa

**Decisão:** o `idVendaExterna` no Financeiro é `UNIQUE`. Se a mesma venda for enviada duas vezes, retorna `409 Conflict` com o título existente.

**Por quê:** retries em redes instáveis são inevitáveis. Sem idempotência, geraríamos títulos duplicados.

### 2.4. Camadas no Delphi

```
View (Forms)
   ↓
Controller (omitido por simplicidade — uso direto do Service)
   ↓
Service (regras de negócio, orquestração)
   ↓
DAO (acesso a dados via FireDAC)
   ↓
Infra (Connection, REST, Logger, Config)
```

**Por quê separar Service de DAO:**
- DAO só sabe ler/gravar — sem regra de negócio
- Service combina múltiplos DAOs, valida invariantes, dispara eventos
- Permite testar o Service mockando o DAO
- Permite trocar o DAO (por exemplo, migrar de Firebird para SQL Server) sem mexer em regras

**Forms acessam SOMENTE Services**, nunca DAO direto. Quebrar essa regra leva a forms gigantes com regras espalhadas.

### 2.5. Camadas no C# (Clean Architecture simplificado)

```
ERPFinanceiro.Domain      - Entidades, enums, exceptions, interfaces (sem deps)
ERPFinanceiro.Application - DTOs, Services, Validators, Mappings
ERPFinanceiro.Data        - DbContext EF6, Repositories, Configurations
ERPFinanceiro.Api         - Controllers, Filters, Startup, host OWIN
ERPFinanceiro.UI          - WinForms DevExpress
ERPFinanceiro.Tests       - xUnit + Moq
```

**Domain** não depende de nada — entidades puras com lógica de negócio (rich domain). `Titulo.Quitar()` valida estado e cria a movimentação atomicamente.

**Application** depende de Domain. Coordena Repositories via UnitOfWork.

**Data** implementa as interfaces declaradas em Domain (inversão de dependência).

### 2.6. Rich Domain Model

O método `Titulo.Quitar()` encapsula a regra "só quita se PENDENTE" e cria a movimentação. Isso evita lógica anêmica espalhada no Service e centraliza invariantes do agregado.

### 2.7. UnitOfWork + Repository

EF6 já é um UnitOfWork (DbContext rastreia mudanças e `SaveChanges` faz commit), mas explicitar a interface:
- Padroniza com práticas de DDD
- Permite mock em testes
- Permite reuso fora de Web API (jobs, batches)

### 2.8. AutoMapper para Domain ↔ DTO

Evita código repetitivo de mapeamento e mantém a separação entre o modelo de domínio (que pode ter relacionamentos complexos) e o DTO da API (achatado para serialização).

### 2.9. FluentValidation

Validação declarativa, separada do DTO. Funciona bem com o pipeline da Web API — basta um filter para retornar 400 com mensagens estruturadas.

### 2.10. Autenticação API Key

**Decisão:** header `X-API-Key` em todas as rotas (exceto `/health`).

**Por quê:** o desafio não exige autenticação, mas:
- Demonstra preocupação com segurança básica
- Custo de implementação muito baixo (filtro simples)
- Suficiente para ambiente interno com TLS na frente

**O que faria em produção:** OAuth2/JWT com claims, rate limiting, mTLS entre módulos.

### 2.11. Logging em duas camadas

- **Arquivo diário** (`logs/erpvendas_2026-05-04.log`) — para diagnóstico operacional
- **Tabela `LOG_INTEGRACAO`** — só para chamadas REST (request/response completos), permite UI de auditoria e reenvio

### 2.12. Threads e UI

No Delphi, o envio do título ao financeiro acontece em `TTask.Run` para **não travar a UI**. A confirmação volta via `TThread.Queue` para atualizar a status bar na main thread. Cada thread cria sua **própria conexão** com o banco (`TConnection.NovaConexao`) para evitar contenção.

### 2.13. Soft delete

CRUD usa `ATIVO='S'/'N'` em vez de `DELETE` físico. Preserva integridade referencial — não dá pra excluir um cliente que tem vendas históricas.

### 2.14. Geração de PDF

ReportBuilder gera o PDF temporário (`%TEMP%\Pedido_NNNN.pdf`) que é anexado ao e-mail via Indy SMTP. Simples e direto.

## 3. Regras de negócio implementadas

| Regra | Onde |
|---|---|
| Venda sem itens é inválida | `TVenda.Validar` |
| Desconto > total é inválido | `TVenda.Validar` |
| Item com qtd ≤ 0 é inválido | `TVendaItem.Validar` |
| CPF/CNPJ duplicado é bloqueado | `TClienteService.Salvar` |
| Código de produto duplicado é bloqueado | `TProdutoService.Salvar` |
| Só PENDENTE pode ser quitado | `Titulo.PodeQuitar` + `Titulo.Quitar` |
| Só PENDENTE pode ser cancelado | `Titulo.PodeCancelar` + `Titulo.Cancelar` |
| Vencimento padrão: D+30 | `TIntegracaoFinanceiroService.VendaParaJson` |
| Idempotência por venda | `TituloService.CriarAsync` |
| Cliente sem e-mail: pula envio | `TVendaService.GerarPdfEEnviarEmail` |

## 4. Trade-offs aceitos

- **Quitação parcial:** não implementada — só total. O domínio fica simples.
- **Estorno após quitação:** não implementado — uma vez quitado, fim. Em produção seria estorno separado.
- **Autenticação simples:** API Key, não JWT.
- **Sem mensageria:** chamadas síncronas com retry. Em alto volume, RabbitMQ/Kafka seria melhor.
- **Sem versionamento de schema do banco:** nem Flyway nem Migrations do EF habilitadas — scripts manuais. Justificável pelo escopo de desafio; em produção seria automatizado.
- **Forms VCL com lógica de UI mínima nos exemplos:** o foco foi a arquitetura. Em entrega real, os forms seriam preenchidos com bindings completos cxGrid + cxNavigator etc.

## 5. O que faria diferente em produção

- Mensageria (RabbitMQ) entre Vendas e Financeiro — desacopla totalmente
- Migrations versionadas (Flyway/Liquibase para Firebird; EF Migrations para C#)
- Autenticação OAuth2 + autorização por escopo
- Observabilidade: tracing distribuído (OpenTelemetry), métricas (Prometheus), dashboards (Grafana)
- Containerização Docker Compose
- CI/CD com pipelines automatizados
- Testes de integração end-to-end com banco real (Testcontainers)
- Health checks ricos (banco, dependências externas)
- Circuit breaker (Polly já oferece)
