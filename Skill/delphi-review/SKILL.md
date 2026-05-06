---
name: delphi-review
description: Revisão completa de código Delphi 10.3 Rio. Use quando revisar qualidade, segurança, performance, thread safety, SOLID, FireDAC e arquitetura do ERPVendas (CartSys).
allowed-tools: Read, Grep, Glob
---

# Delphi Code Review — Revisão Completa

> Revisão técnica de código Delphi 10.3 Rio no contexto do **CartSys ERPVendas**.
> Para **editar** código após a revisão, use a skill `delphi-pas-tools`.

---

## PROTOCOLO DE REVISÃO (execute nesta ordem)

### 1. LEITURA DO ESCOPO

Se o usuário indicou um arquivo, procedure ou trecho específico — leia-o primeiro.
Se indicou um diretório ou módulo — use Glob/Grep para mapear os `.pas` relevantes antes de ler.

Não analise o que não foi lido. Nunca suponha o conteúdo de um arquivo sem lê-lo.

### 2. ANÁLISE POR EIXO

Avalie cada eixo como ✅ OK | ⚠️ Atenção | 🔴 Crítico.
Reporte apenas problemas reais encontrados no código lido — não invente achados hipotéticos.

---

## Eixo 1 — Performance

- **Vazamento de memória:** objeto criado sem `try/finally` garantindo `Free`
- **Loop com alocação:** `TStringList`, `TFDQuery`, objeto criado dentro de loop sem necessidade
- **Acesso repetido a `.Count`:** cachear em variável local antes do loop
- **Concatenação de strings em loop:** usar `TStringBuilder` em vez de `S := S + C`
- **Query sem parâmetro:** concatenação direta em SQL → SQL Injection e plano de execução ruim
- **Open/Close desnecessário:** reabrir query já aberta quando `Close + Open` ou `Refresh` bastaria
- **TObjectList com OwnsObjects=True:** não chamar `Free` nos itens individualmente — a lista já libera

**Padrões FireDAC específicos:**
- `TFDConnection` não deve ser instanciada por chamada — usar o singleton `TConnection.Instance`
- `TFDConnection.InTransaction` deve ser verificado antes de `Rollback` no `except`
- `TFDQuery.ParamByName` deve ser usado — nunca concatenar SQL com valores externos
- `TFDQuery.ExecSQL` para DML sem retorno; `TFDQuery.Open` para SELECT

---

## Eixo 2 — Segurança

- **SQL Injection:** concatenação de input em `LQry.SQL.Text` → exigir `ParamByName`
- **Acesso a objeto não instanciado:** usar `Assigned()` antes de acessar ponteiros ou interfaces
- **Validação de input ausente:** validar dados vindos da UI antes de persistir
- **Credenciais hardcoded:** senhas ou tokens no código-fonte são inaceitáveis — usar `config.ini`
- **Exceção silenciada:** `except end;` sem log oculta falhas críticas

---

## Eixo 3 — Tratamento de Erros

- `try/finally` ausente onde há recursos alocados (objetos, transações)
- `except` genérico sem re-raise nem log (`on E: Exception do` vazio ou apenas `ShowMessage`)
- Exceções capturadas mas não propagadas quando o chamador precisa saber do erro
- `TFDConnection.Rollback` ausente no `except` de uma transação iniciada explicitamente

**Padrão correto — transação FireDAC:**
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

**Padrão correto — objeto local:**
```pascal
LObj := TMinhaClasse.Create;
try
  // uso
finally
  LObj.Free;
end;
```

**Padrão correto — TTask com exceção:**
```pascal
TTask.Run(
  procedure
  begin
    try
      // trabalho
    except
      on E: Exception do
        TLogger.Instance.Error('Falha na task', E);
    end;
  end);
```

---

## Eixo 4 — Qualidade de Código

- **Nomenclatura:** prefixos `F` (campo), `L` (local), `A` (parâmetro) — verificar consistência
- **Métodos longos:** > 40 linhas → candidato a extração de procedure auxiliar
- **Duplicação de código:** bloco idêntico em 2+ lugares → candidato a procedure/function
- **Magic strings:** `if Status = 'QUITADA'` → preferir constante nomeada ou enum `TStatusVenda`
- **Comentários desatualizados:** comentário que contradiz o código atual é pior que nenhum
- **Variáveis não usadas:** declaradas mas nunca lidas

---

## Eixo 5 — Arquitetura e Responsabilidades

**Separação em camadas:**
- `Service` não deve conhecer componentes VCL (`TEdit`, `TGrid`, `Application.MessageBox`)
- `DAO` não deve conter regras de negócio — apenas persistência
- `View` não deve acessar `DAO` diretamente — deve passar pelo `Service`
- Eventos de formulário (`OnClick`, `OnChange`) não devem conter lógica de negócio inline

**Acoplamento:**
- `uses` com units não relacionadas à responsabilidade da unit → responsabilidade misturada
- DAO que conhece detalhes internos de outro DAO sem interface pública

**Coesão:**
- Procedure fazendo parsing + validação + persistência + notificação ao mesmo tempo

**SOLID no contexto Delphi 10.3:**
- **SRP:** cada classe/unit tem uma responsabilidade clara?
- **OCP:** comportamento variável via interface (`IVendaService`), não via `if` no código-cliente
- **LSP:** subclasses que quebram o contrato da interface pai
- **DIP:** dependências hardcoded em vez de injetadas por construtor ou interface

---

## Eixo 6 — Interoperabilidade e Encoding

- **Unicode correto:** Delphi 10.3 usa `UnicodeString` por padrão; evitar mistura não intencional com `AnsiString`/`RawByteString`
- **Encoding de arquivos:** `.pas` devem ser UTF-8 — nunca salvar em ANSI/Windows-1252
- **REST/JSON:** serializar para a API C# usando `TRESTClient` ou `System.JSON` — nunca montar JSON por concatenação de string
- **Data/hora:** ao trafegar datas para a API, usar ISO 8601 (`yyyy-mm-ddThh:nn:ss`)
- **Currency vs Double:** usar `Currency` para valores monetários, `Double` para quantidades físicas

---

## Eixo 7 — Thread Safety

- Acesso a componentes VCL fora da thread principal → obrigatório usar `TThread.Queue` ou `TThread.Synchronize`
- `TTask.Run` sem tratamento de exceção no corpo → exceções são engolidas silenciosamente
- Variáveis capturadas em closures que podem ter sido liberadas quando a closure executar
- Cada `TTask` deve criar sua própria conexão via `TConnection.Instance.NovaConexao` e liberá-la no `finally`
- Acesso ao singleton `TConnection` sem lock em múltiplas threads → verificar uso do `TCriticalSection`

---

## Eixo 8 — Complexidade

- Complexidade ciclomática alta: muitos `if`/`case` aninhados (> 3 níveis) → extrair em funções menores
- Procedures com > 5 parâmetros → considerar `record` ou classe de parâmetros
- `case` com muitos ramos que poderiam ser tabela de dispatch ou polimorfismo
- Closures anônimas longas dentro de `TTask.Run` → extrair em method nomeado

---

## Eixo 9 — Conformidade com Guia de Estilo CartSys

### Formatação

- Indentação: **2 espaços** — tabs não devem existir
- `begin` deve ser sucedido por enter (nunca `begin X := 1;` na mesma linha)
- `else if` deve permanecer na mesma linha para evidenciar encadeamento

### Palavras Reservadas

Todas devem ser **minúsculas**: `begin`, `end`, `var`, `procedure`, `function`, `unit`, `uses`, `interface`, `implementation`, `type`, `class`, etc.

### Nomenclatura — Resumo

| Símbolo | Convenção | Exemplo |
|---|---|---|
| Classe | Prefixo `T` + CamelCase | `TVendaService` |
| Record | Prefixo `T` + CamelCase | `TResultadoIntegracao` |
| Enum | Prefixo `T` + CamelCase | `TStatusVenda` |
| Interface | Prefixo `I` + CamelCase | `IVendaService` |
| Campo privado | Prefixo `F` + CamelCase | `FConexao`, `FDAO` |
| Variável local | Prefixo `L` + CamelCase | `LQry`, `LVenda` |
| Parâmetro | Prefixo `A` + CamelCase | `AConexao`, `AIdVenda` |
| Constante | UPPER_SNAKE_CASE | `MAX_ITENS_VENDA` |
| Método/Função | CamelCase | `CalcularTotal` |
| Unit infra | `u` + PascalCase | `uConnection.pas` |
| Unit form | `uFrm` + PascalCase | `uFrmCadVenda.pas` |

### Verificações de Conformidade

- Palavras reservadas estão em minúsculo?
- Indentação usa espaços (não tabs)?
- Campos privados têm prefixo `F`?
- Variáveis locais têm prefixo `L`?
- Parâmetros têm prefixo `A`?
- Constantes estão em UPPER_SNAKE_CASE?

---

## Formato de Saída

### Scorecard

| Eixo | Status | Observação |
|---|---|---|
| Performance | ✅/⚠️/🔴 | resumo |
| Segurança | ✅/⚠️/🔴 | resumo |
| Tratamento de Erros | ✅/⚠️/🔴 | resumo |
| Qualidade de Código | ✅/⚠️/🔴 | resumo |
| Arquitetura | ✅/⚠️/🔴 | resumo |
| Interoperabilidade | ✅/⚠️/🔴 | resumo |
| Thread Safety | ✅/⚠️/🔴 | resumo |
| Complexidade | ✅/⚠️/🔴 | resumo |
| Guia de Estilo | ✅/⚠️/🔴 | resumo |

### Achados Detalhados

Para cada problema encontrado, reportar no formato:

**[SEVERIDADE]** `NomeDoArquivo.pas` linha X — `NomeDoMétodo`
> Descrição do problema
> Sugestão de correção com exemplo de código quando aplicável

Severidades: 🔴 CRÍTICO | 🟠 ALTO | 🟡 MÉDIO | 🔵 BAIXO

### Top 3 Prioridades

Ao final, listar os 3 achados de maior impacto com ação imediata sugerida.

---

## Relação com outras skills

| Skill | Quando usar |
|---|---|
| `delphi-review` | **Esta skill** — analisar qualidade, encontrar problemas |
| `delphi-pas-tools` | Editar o `.pas` após a revisão, compilar |
| `simplify` | Refatorar código já identificado como candidato a simplificação |

---

## Exemplos de invocação

- "revise o código desta unit"
- "analise a qualidade de `uVendaService.pas`"
- "tem vazamento de memória aqui?"
- "revise a procedure `Inserir` em busca de SQL Injection"
- "/delphi-review src/ERPVendas.Delphi/src/Service/uVendaService.pas"
- "analise o módulo inteiro de vendas"
