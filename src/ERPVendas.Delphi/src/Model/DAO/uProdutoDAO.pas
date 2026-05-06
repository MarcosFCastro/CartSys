unit uProdutoDAO;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, FireDAC.Comp.Client,
  uProduto;

type
  TProdutoDAO = class
  strict private
    FConexao: TFDConnection;
    procedure DataSetParaEntidade(ADataSet: TDataSet; AProduto: TProduto);
  public
    constructor Create(AConexao: TFDConnection);

    function Inserir(AProduto: TProduto): Integer;
    procedure Atualizar(AProduto: TProduto);
    procedure Excluir(AId: Integer);
    procedure DesativarLogicamente(AId: Integer);

    function BuscarPorId(AId: Integer): TProduto;
    function BuscarPorCodigo(const ACodigo: string): TProduto;
    function ExistePorCodigo(const ACodigo: string; AIdIgnorar: Integer = 0): Boolean;
    function Listar(const AFiltro: string = ''): TObjectList<TProduto>;
  end;

implementation

uses
  uExceptions;

const
  SQL_INSERT =
    'INSERT INTO PRODUTOS (CODIGO, DESCRICAO, UNIDADE, PRECO_VENDA, ESTOQUE, ATIVO) ' +
    'VALUES (:CODIGO, :DESCRICAO, :UNIDADE, :PRECO_VENDA, :ESTOQUE, :ATIVO) ' +
    'RETURNING ID';

  SQL_UPDATE =
    'UPDATE PRODUTOS SET CODIGO=:CODIGO, DESCRICAO=:DESCRICAO, UNIDADE=:UNIDADE, ' +
    'PRECO_VENDA=:PRECO_VENDA, ESTOQUE=:ESTOQUE, ATIVO=:ATIVO WHERE ID=:ID';

{ TProdutoDAO }

constructor TProdutoDAO.Create(AConexao: TFDConnection);
begin
  inherited Create;
  if not Assigned(AConexao) then
    raise EInfraException.Create('Conexao nao informada ao TProdutoDAO.');
  FConexao := AConexao;
end;

procedure TProdutoDAO.DataSetParaEntidade(ADataSet: TDataSet; AProduto: TProduto);
begin
  AProduto.Id          := ADataSet.FieldByName('ID').AsInteger;
  AProduto.Codigo      := ADataSet.FieldByName('CODIGO').AsString;
  AProduto.Descricao   := ADataSet.FieldByName('DESCRICAO').AsString;
  AProduto.Unidade     := ADataSet.FieldByName('UNIDADE').AsString;
  AProduto.PrecoVenda  := ADataSet.FieldByName('PRECO_VENDA').AsCurrency;
  AProduto.Estoque     := ADataSet.FieldByName('ESTOQUE').AsFloat;
  AProduto.Ativo       := ADataSet.FieldByName('ATIVO').AsString = 'S';
  AProduto.DtCadastro  := ADataSet.FieldByName('DT_CADASTRO').AsDateTime;
end;

function TProdutoDAO.Inserir(AProduto: TProduto): Integer;
var
  LQry: TFDQuery;
begin
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text := SQL_INSERT;
    LQry.ParamByName('CODIGO').AsString        := AProduto.Codigo;
    LQry.ParamByName('DESCRICAO').AsString     := AProduto.Descricao;
    LQry.ParamByName('UNIDADE').AsString       := AProduto.Unidade;
    LQry.ParamByName('PRECO_VENDA').AsCurrency := AProduto.PrecoVenda;
    LQry.ParamByName('ESTOQUE').AsFloat        := AProduto.Estoque;
    if AProduto.Ativo then
      LQry.ParamByName('ATIVO').AsString := 'S'
    else
      LQry.ParamByName('ATIVO').AsString := 'N';

    LQry.Open;
    Result := LQry.Fields[0].AsInteger;
    AProduto.Id := Result;
  finally
    LQry.Free;
  end;
end;

procedure TProdutoDAO.Atualizar(AProduto: TProduto);
var
  LQry: TFDQuery;
begin
  if AProduto.Id <= 0 then
    raise EValidationException.Create('Id do produto eh obrigatorio para atualizacao.');

  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text := SQL_UPDATE;
    LQry.ParamByName('ID').AsInteger           := AProduto.Id;
    LQry.ParamByName('CODIGO').AsString        := AProduto.Codigo;
    LQry.ParamByName('DESCRICAO').AsString     := AProduto.Descricao;
    LQry.ParamByName('UNIDADE').AsString       := AProduto.Unidade;
    LQry.ParamByName('PRECO_VENDA').AsCurrency := AProduto.PrecoVenda;
    LQry.ParamByName('ESTOQUE').AsFloat        := AProduto.Estoque;
    if AProduto.Ativo then
      LQry.ParamByName('ATIVO').AsString := 'S'
    else
      LQry.ParamByName('ATIVO').AsString := 'N';
    LQry.ExecSQL;

    if LQry.RowsAffected = 0 then
      raise ENotFoundException.CreateFmt('Produto id %d nao encontrado.', [AProduto.Id]);
  finally
    LQry.Free;
  end;
end;

procedure TProdutoDAO.Excluir(AId: Integer);
var
  LQry: TFDQuery;
begin
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text := 'DELETE FROM PRODUTOS WHERE ID=:ID';
    LQry.ParamByName('ID').AsInteger := AId;
    LQry.ExecSQL;
    if LQry.RowsAffected = 0 then
      raise ENotFoundException.CreateFmt('Produto id %d nao encontrado.', [AId]);
  finally
    LQry.Free;
  end;
end;

procedure TProdutoDAO.DesativarLogicamente(AId: Integer);
var
  LQry: TFDQuery;
begin
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text := 'UPDATE PRODUTOS SET ATIVO=''N'' WHERE ID=:ID';
    LQry.ParamByName('ID').AsInteger := AId;
    LQry.ExecSQL;
  finally
    LQry.Free;
  end;
end;

function TProdutoDAO.BuscarPorId(AId: Integer): TProduto;
var
  LQry: TFDQuery;
begin
  Result := nil;
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text := 'SELECT * FROM PRODUTOS WHERE ID=:ID';
    LQry.ParamByName('ID').AsInteger := AId;
    LQry.Open;
    if not LQry.IsEmpty then
    begin
      Result := TProduto.Create;
      try
        DataSetParaEntidade(LQry, Result);
      except
        Result.Free;
        raise;
      end;
    end;
  finally
    LQry.Free;
  end;
end;

function TProdutoDAO.BuscarPorCodigo(const ACodigo: string): TProduto;
var
  LQry: TFDQuery;
begin
  Result := nil;
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text := 'SELECT * FROM PRODUTOS WHERE CODIGO=:C';
    LQry.ParamByName('C').AsString := ACodigo;
    LQry.Open;
    if not LQry.IsEmpty then
    begin
      Result := TProduto.Create;
      try
        DataSetParaEntidade(LQry, Result);
      except
        Result.Free;
        raise;
      end;
    end;
  finally
    LQry.Free;
  end;
end;

function TProdutoDAO.ExistePorCodigo(const ACodigo: string;
  AIdIgnorar: Integer): Boolean;
var
  LQry: TFDQuery;
begin
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text := 'SELECT COUNT(*) FROM PRODUTOS WHERE CODIGO=:C AND ID<>:ID';
    LQry.ParamByName('C').AsString  := ACodigo;
    LQry.ParamByName('ID').AsInteger := AIdIgnorar;
    LQry.Open;
    Result := LQry.Fields[0].AsInteger > 0;
  finally
    LQry.Free;
  end;
end;

function TProdutoDAO.Listar(const AFiltro: string): TObjectList<TProduto>;
var
  LQry: TFDQuery;
  LProduto: TProduto;
begin
  Result := TObjectList<TProduto>.Create(True);
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    if AFiltro <> '' then
    begin
      LQry.SQL.Text :=
        'SELECT * FROM PRODUTOS ' +
        'WHERE UPPER(DESCRICAO) LIKE UPPER(:F) OR UPPER(CODIGO) LIKE UPPER(:F) ' +
        'ORDER BY DESCRICAO';
      LQry.ParamByName('F').AsString := '%' + AFiltro + '%';
    end
    else
      LQry.SQL.Text := 'SELECT * FROM PRODUTOS ORDER BY DESCRICAO';

    LQry.Open;
    while not LQry.Eof do
    begin
      LProduto := TProduto.Create;
      try
        DataSetParaEntidade(LQry, LProduto);
        Result.Add(LProduto);
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

end.
