# Contrato de API REST - Integração CartSys

Comunicação entre **ERP Vendas (Delphi)** e **ERP Financeiro (C#)** via HTTP/JSON.

## Convenções

- **Content-Type:** `application/json; charset=utf-8`
- **Autenticação:** header `X-API-Key: <chave>` em todas as rotas (configurável)
- **Datas:** ISO 8601 (`2026-05-04T15:30:00`)
- **Decimais:** ponto como separador, sempre 2 casas para valores monetários
- **Erros:** RFC 7807 (Problem Details)

```json
{
  "type": "https://cartsys/erros/validacao",
  "title": "Dados inválidos",
  "status": 400,
  "detail": "Campo 'valor' deve ser maior que zero",
  "traceId": "8b1e9d2f-..."
}
```

---

## ERP Financeiro - exposto pelo C# (porta padrão 5001)

### POST /api/v1/titulos
Cria um novo título a receber a partir de uma venda.

**Request:**
```json
{
  "idVendaExterna": 123,
  "numeroVenda": 456,
  "idClienteExterno": 10,
  "nomeCliente": "Cliente Teste 01",
  "docCliente": "12345678901",
  "emailCliente": "cliente01@teste.com",
  "valor": 4620.00,
  "dtVencimento": "2026-06-04",
  "observacoes": "Pedido nº 456"
}
```

**Response 201 Created:**
```json
{
  "id": 78,
  "idVendaExterna": 123,
  "numeroVenda": 456,
  "valor": 4620.00,
  "status": "PENDENTE",
  "dtEmissao": "2026-05-04T15:30:00",
  "dtVencimento": "2026-06-04"
}
```

**Erros:** 400 (validação), 409 (título já existe para essa venda), 401 (API key inválida).

---

### GET /api/v1/titulos/{id}
Retorna detalhes do título.

### GET /api/v1/titulos?status=PENDENTE&clienteId=10&dataInicio=2026-01-01&dataFim=2026-12-31&page=1&pageSize=50
Lista títulos com filtros e paginação.

**Response:**
```json
{
  "page": 1,
  "pageSize": 50,
  "totalItems": 127,
  "totalPages": 3,
  "items": [ { ... } ]
}
```

---

### POST /api/v1/titulos/{id}/quitar
Quita o título e dispara callback ao ERP Vendas.

**Request:**
```json
{
  "formaPagamento": "PIX",
  "observacao": "Pago via PIX em 04/05/2026"
}
```

**Response 200:** título atualizado.

**Regra:** somente títulos `PENDENTE` podem ser quitados → 409 caso contrário.

---

### POST /api/v1/titulos/{id}/cancelar
Cancela o título e dispara callback ao ERP Vendas.

**Request:**
```json
{ "motivo": "Cliente desistiu" }
```

**Regra:** somente `PENDENTE` pode ser cancelado.

---

### GET /api/v1/health
Health check. Retorna `200 OK`.

---

## ERP Vendas - exposto pelo Delphi (porta padrão 5002)

### POST /api/v1/vendas/{id}/notificar-quitacao
Callback chamado pelo Financeiro após quitação.

**Request:**
```json
{
  "idTitulo": 78,
  "dtQuitacao": "2026-05-04T15:30:00",
  "formaPagamento": "PIX"
}
```

**Response 200:** `{ "ok": true }`

**Efeito colateral:** o ERP Vendas marca a venda como `QUITADA`, gera o PDF e envia por e-mail ao cliente.

---

### POST /api/v1/vendas/{id}/notificar-cancelamento
Callback de cancelamento.

```json
{ "idTitulo": 78, "motivo": "Cliente desistiu" }
```

---

### GET /api/v1/health
Health check.

---

## Resiliência

- **Timeout:** 30s
- **Retry:** 3 tentativas com backoff exponencial (1s, 2s, 4s) para erros 5xx e timeout
- **Idempotência:** envio de título usa `idVendaExterna` como chave - duplicatas retornam 409 com o título já existente
- **Logs:** ambos os lados gravam request/response na tabela `LOG_INTEGRACAO`
