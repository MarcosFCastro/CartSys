unit uVendaDAO;

{ ----------------------------------------------------------------------------
  DAO de Venda - persiste cabecalho e itens em UMA transacao.
  Quem chama eh responsavel por StartTransaction / Commit / Rollback se
  desejar abranger transacao maior; caso contrario o proprio DAO usa.
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, FireDAC.Comp.Client,
  uVenda, uCliente, uProduto;

type
  TVendaDAO = class
  strict private
    FConexao: TFDConnection;
    procedure InserirItens(AVenda: TVenda);
    procedure DataSetParaVendaSemItens(ADataSet: TDataSet; AVenda: TVenda);
    procedure CarregarItens(AVenda: TVenda);
  public
    constructor Create(AConexao: TFDConnection);

    function Inserir(AVenda: TVenda): Integer;
    procedure AtualizarStatus(AIdVenda: Integer; ANovoStatus: TStatusVenda;
      AIdFinanceiroExterno: Integer = 0);
    procedure AtualizarQuitacao(AIdVenda: Integer; ADtQuitacao: TDateTime);
    procedure AtualizarCancelamento(AIdVenda: Integer; ADtCancelamento: TDateTime);
    procedure MarcarEmailEnviado(AIdVenda: Integer);

    function BuscarPorId(AId: Integer): TVenda;
    function ListarPorPeriodo(ADtInicio, ADtFim: TDateTime): TObjectList<TVenda>;
  end;

implementation

uses
  FireDAC.Stan.Param,
  uExceptions;

{ TVendaDAO }

constructor TVendaDAO.Create(AConexao: TFDConnection);
begin
  inherited Create;
  if not Assigned(AConexao) then
    raise EInfraException.Create('Conexao nao informada ao TVendaDAO.');
  FConexao := AConexao;
end;

function TVendaDAO.Inserir(AVenda: TVenda): Integer;
var
  LQry: TFDQuery;
  LTransacaoLocal: Boolean;
begin
  LTransacaoLocal := not FConexao.InTransaction;
  if LTransacaoLocal then
    FConexao.StartTransaction;
  try
    LQry := TFDQuery.Create(nil);
    try
      LQry.Connection := FConexao;
      LQry.SQL.Text :=
        'INSERT INTO VENDAS (ID_CLIENTE, DT_VENDA, VALOR_TOTAL, DESCONTO, ' +
        '                    VALOR_LIQUIDO, STATUS, OBSERVACOES) ' +
        'VALUES (:ID_CLIENTE, :DT_VENDA, :VALOR_TOTAL, :DESCONTO, ' +
        '        :VALOR_LIQUIDO, :STATUS, :OBSERVACOES) ' +
        'RETURNING ID, NUMERO';
      LQry.ParamByName('ID_CLIENTE').AsInteger      := AVenda.Cliente.Id;
      LQry.ParamByName('DT_VENDA').AsDateTime       := AVenda.DtVenda;
      LQry.ParamByName('VALOR_TOTAL').AsCurrency    := AVenda.ValorTotal;
      LQry.ParamByName('DESCONTO').AsCurrency       := AVenda.Desconto;
      LQry.ParamByName('VALOR_LIQUIDO').AsCurrency  := AVenda.ValorLiquido;
      LQry.ParamByName('STATUS').AsString           := AVenda.Status.ToString;
      LQry.ParamByName('OBSERVACOES').AsString      := AVenda.Observacoes;
      LQry.Open;

      AVenda.Id := LQry.FieldByName('ID').AsInteger;
      AVenda.Numero := LQry.FieldByName('NUMERO').AsInteger;
      Result := AVenda.Id;
    finally
      LQry.Free;
    end;

    InserirItens(AVenda);

    if LTransacaoLocal then
      FConexao.Commit;
  except
    if LTransacaoLocal and FConexao.InTransaction then
      FConexao.Rollback;
    raise;
  end;
end;

procedure TVendaDAO.InserirItens(AVenda: TVenda);
var
  LQry: TFDQuery;
  LItem: TVendaItem;
begin
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text :=
      'INSERT INTO VENDAS_ITENS (ID_VENDA, ID_PRODUTO, QUANTIDADE, PRECO_UNITARIO, ' +
      '                          DESCONTO, VALOR_TOTAL) ' +
      'VALUES (:ID_VENDA, :ID_PRODUTO, :QUANTIDADE, :PRECO_UNITARIO, ' +
      '        :DESCONTO, :VALOR_TOTAL) ' +
      'RETURNING ID';
    for LItem in AVenda.Itens do
    begin
      LQry.ParamByName('ID_VENDA').AsInteger        := AVenda.Id;
      LQry.ParamByName('ID_PRODUTO').AsInteger      := LItem.Produto.Id;
      LQry.ParamByName('QUANTIDADE').AsFloat        := LItem.Quantidade;
      LQry.ParamByName('PRECO_UNITARIO').AsCurrency := LItem.PrecoUnitario;
      LQry.ParamByName('DESCONTO').AsCurrency       := LItem.Desconto;
      LQry.ParamByName('VALOR_TOTAL').AsCurrency    := LItem.ValorTotal;
      LQry.Open;
      LItem.Id := LQry.Fields[0].AsInteger;
      LQry.Close;
    end;
  finally
    LQry.Free;
  end;
end;

procedure TVendaDAO.AtualizarStatus(AIdVenda: Integer; ANovoStatus: TStatusVenda;
  AIdFinanceiroExterno: Integer);
var
  LQry: TFDQuery;
begin
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    if AIdFinanceiroExterno > 0 then
    begin
      LQry.SQL.Text :=
        'UPDATE VENDAS SET STATUS=:STATUS, ID_FINANCEIRO_EXTERNO=:IDFIN WHERE ID=:ID';
      LQry.ParamByName('IDFIN').AsInteger := AIdFinanceiroExterno;
    end
    else
      LQry.SQL.Text := 'UPDATE VENDAS SET STATUS=:STATUS WHERE ID=:ID';

    LQry.ParamByName('STATUS').AsString := ANovoStatus.ToString;
    LQry.ParamByName('ID').AsInteger    := AIdVenda;
    LQry.ExecSQL;
    if LQry.RowsAffected = 0 then
      raise ENotFoundException.CreateFmt('Venda id %d nao encontrada.', [AIdVenda]);
  finally
    LQry.Free;
  end;
end;

procedure TVendaDAO.AtualizarQuitacao(AIdVenda: Integer; ADtQuitacao: TDateTime);
var
  LQry: TFDQuery;
begin
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text :=
      'UPDATE VENDAS SET STATUS=:STATUS, DT_QUITACAO=:DT WHERE ID=:ID';
    LQry.ParamByName('STATUS').AsString := svQuitada.ToString;
    LQry.ParamByName('DT').AsDateTime   := ADtQuitacao;
    LQry.ParamByName('ID').AsInteger    := AIdVenda;
    LQry.ExecSQL;
    if LQry.RowsAffected = 0 then
      raise ENotFoundException.CreateFmt('Venda id %d nao encontrada.', [AIdVenda]);
  finally
    LQry.Free;
  end;
end;

procedure TVendaDAO.AtualizarCancelamento(AIdVenda: Integer; ADtCancelamento: TDateTime);
var
  LQry: TFDQuery;
begin
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text :=
      'UPDATE VENDAS SET STATUS=:STATUS, DT_CANCELAMENTO=:DT WHERE ID=:ID';
    LQry.ParamByName('STATUS').AsString := svCancelada.ToString;
    LQry.ParamByName('DT').AsDateTime   := ADtCancelamento;
    LQry.ParamByName('ID').AsInteger    := AIdVenda;
    LQry.ExecSQL;
    if LQry.RowsAffected = 0 then
      raise ENotFoundException.CreateFmt('Venda id %d nao encontrada.', [AIdVenda]);
  finally
    LQry.Free;
  end;
end;

procedure TVendaDAO.MarcarEmailEnviado(AIdVenda: Integer);
var
  LQry: TFDQuery;
begin
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text :=
      'UPDATE VENDAS SET EMAIL_ENVIADO=''S'', DT_EMAIL_ENVIADO=CURRENT_TIMESTAMP WHERE ID=:ID';
    LQry.ParamByName('ID').AsInteger := AIdVenda;
    LQry.ExecSQL;
  finally
    LQry.Free;
  end;
end;

procedure TVendaDAO.DataSetParaVendaSemItens(ADataSet: TDataSet; AVenda: TVenda);
begin
  AVenda.Id            := ADataSet.FieldByName('ID').AsInteger;
  AVenda.Numero        := ADataSet.FieldByName('NUMERO').AsInteger;
  AVenda.DtVenda       := ADataSet.FieldByName('DT_VENDA').AsDateTime;
  AVenda.Desconto      := ADataSet.FieldByName('DESCONTO').AsCurrency;
  AVenda.Status        := TStatusVenda.FromString(ADataSet.FieldByName('STATUS').AsString);
  AVenda.IdFinanceiroExterno := ADataSet.FieldByName('ID_FINANCEIRO_EXTERNO').AsInteger;
  AVenda.DtQuitacao    := ADataSet.FieldByName('DT_QUITACAO').AsDateTime;
  AVenda.DtCancelamento:= ADataSet.FieldByName('DT_CANCELAMENTO').AsDateTime;
  AVenda.EmailEnviado  := ADataSet.FieldByName('EMAIL_ENVIADO').AsString = 'S';
  AVenda.Observacoes   := ADataSet.FieldByName('OBSERVACOES').AsString;
end;

procedure TVendaDAO.CarregarItens(AVenda: TVenda);
var
  LQry: TFDQuery;
  LProduto: TProduto;
  LQuantidade: Double;
  LPrecoUnit, LDesconto: Currency;
begin
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text :=
      'SELECT VI.*, P.CODIGO, P.DESCRICAO, P.UNIDADE ' +
      'FROM VENDAS_ITENS VI ' +
      'INNER JOIN PRODUTOS P ON P.ID = VI.ID_PRODUTO ' +
      'WHERE VI.ID_VENDA = :ID ' +
      'ORDER BY VI.ID';
    LQry.ParamByName('ID').AsInteger := AVenda.Id;
    LQry.Open;

    while not LQry.Eof do
    begin
      LProduto := TProduto.Create;
      try
        LProduto.Id         := LQry.FieldByName('ID_PRODUTO').AsInteger;
        LProduto.Codigo     := LQry.FieldByName('CODIGO').AsString;
        LProduto.Descricao  := LQry.FieldByName('DESCRICAO').AsString;
        LProduto.Unidade    := LQry.FieldByName('UNIDADE').AsString;
        LProduto.PrecoVenda := LQry.FieldByName('PRECO_UNITARIO').AsCurrency;

        LQuantidade := LQry.FieldByName('QUANTIDADE').AsFloat;
        LPrecoUnit  := LQry.FieldByName('PRECO_UNITARIO').AsCurrency;
        LDesconto   := LQry.FieldByName('DESCONTO').AsCurrency;

        AVenda.AdicionarItem(LProduto, LQuantidade, LPrecoUnit, LDesconto, True);
      except
        LProduto.Free;
        raise;
      end;
      LQry.Next;
    end;
  finally
    LQry.Free;
  end;
end;

function TVendaDAO.BuscarPorId(AId: Integer): TVenda;
var
  LQry: TFDQuery;
  LCliente: TCliente;
begin
  Result := nil;
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text :=
      'SELECT V.*, C.NOME AS CLIENTE_NOME, C.CPF_CNPJ AS CLIENTE_DOC, ' +
      '       C.EMAIL AS CLIENTE_EMAIL ' +
      'FROM VENDAS V ' +
      'INNER JOIN CLIENTES C ON C.ID = V.ID_CLIENTE ' +
      'WHERE V.ID = :ID';
    LQry.ParamByName('ID').AsInteger := AId;
    LQry.Open;
    if LQry.IsEmpty then
      Exit;

    Result := TVenda.Create;
    try
      DataSetParaVendaSemItens(LQry, Result);
      LCliente := TCliente.Create;
      LCliente.Id      := LQry.FieldByName('ID_CLIENTE').AsInteger;
      LCliente.Nome    := LQry.FieldByName('CLIENTE_NOME').AsString;
      LCliente.CpfCnpj := LQry.FieldByName('CLIENTE_DOC').AsString;
      LCliente.Email   := LQry.FieldByName('CLIENTE_EMAIL').AsString;
      Result.DefinirCliente(LCliente, True);

      CarregarItens(Result);
      Result.Recalcular;
    except
      Result.Free;
      raise;
    end;
  finally
    LQry.Free;
  end;
end;

function TVendaDAO.ListarPorPeriodo(ADtInicio, ADtFim: TDateTime): TObjectList<TVenda>;
var
  LQry: TFDQuery;
  LVenda: TVenda;
  LCliente: TCliente;
begin
  Result := TObjectList<TVenda>.Create(True);
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text :=
      'SELECT V.*, C.NOME AS CLIENTE_NOME, C.CPF_CNPJ AS CLIENTE_DOC, ' +
      '       C.EMAIL AS CLIENTE_EMAIL ' +
      'FROM VENDAS V ' +
      'INNER JOIN CLIENTES C ON C.ID = V.ID_CLIENTE ' +
      'WHERE V.DT_VENDA BETWEEN :DTI AND :DTF ' +
      'ORDER BY V.DT_VENDA DESC';
    LQry.ParamByName('DTI').AsDateTime := ADtInicio;
    LQry.ParamByName('DTF').AsDateTime := ADtFim;
    LQry.Open;

    while not LQry.Eof do
    begin
      LVenda := TVenda.Create;
      try
        DataSetParaVendaSemItens(LQry, LVenda);
        LCliente := TCliente.Create;
        LCliente.Id      := LQry.FieldByName('ID_CLIENTE').AsInteger;
        LCliente.Nome    := LQry.FieldByName('CLIENTE_NOME').AsString;
        LCliente.CpfCnpj := LQry.FieldByName('CLIENTE_DOC').AsString;
        LCliente.Email   := LQry.FieldByName('CLIENTE_EMAIL').AsString;
        LVenda.DefinirCliente(LCliente, True);
        Result.Add(LVenda);
      except
        LVenda.Free;
        raise;
      end;
      LQry.Next;
    end;
  finally
    LQry.Free;
  end;
end;

end.
