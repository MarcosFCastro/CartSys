unit uClienteDAO;

{ ----------------------------------------------------------------------------
  DAO de Cliente. Toda interacao com o banco eh via parametros (sem concat).
  Recebe TFDConnection injetado para suportar transacoes coordenadas externamente.
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, FireDAC.Comp.Client,
  uCliente;

type
  TClienteDAO = class
  strict private
    FConexao: TFDConnection;
    procedure DataSetParaEntidade(ADataSet: TDataSet; ACliente: TCliente);
  public
    constructor Create(AConexao: TFDConnection);

    function Inserir(ACliente: TCliente): Integer;
    procedure Atualizar(ACliente: TCliente);
    procedure Excluir(AId: Integer);
    procedure DesativarLogicamente(AId: Integer);

    function BuscarPorId(AId: Integer): TCliente;
    function ExistePorCpfCnpj(const ACpfCnpj: string; AIdIgnorar: Integer = 0): Boolean;
    function Listar(const AFiltroNome: string = ''): TObjectList<TCliente>;
  end;

implementation

uses
  FireDAC.Stan.Param,
  uExceptions;

const
  SQL_INSERT =
    'INSERT INTO CLIENTES ' +
    '(NOME, CPF_CNPJ, EMAIL, TELEFONE, ENDERECO, CIDADE, UF, CEP, ATIVO) ' +
    'VALUES (:NOME, :CPF_CNPJ, :EMAIL, :TELEFONE, :ENDERECO, :CIDADE, :UF, :CEP, :ATIVO) ' +
    'RETURNING ID';

  SQL_UPDATE =
    'UPDATE CLIENTES SET ' +
    '  NOME=:NOME, CPF_CNPJ=:CPF_CNPJ, EMAIL=:EMAIL, TELEFONE=:TELEFONE, ' +
    '  ENDERECO=:ENDERECO, CIDADE=:CIDADE, UF=:UF, CEP=:CEP, ATIVO=:ATIVO ' +
    'WHERE ID=:ID';

  SQL_DELETE = 'DELETE FROM CLIENTES WHERE ID=:ID';
  SQL_DESATIVAR = 'UPDATE CLIENTES SET ATIVO=''N'' WHERE ID=:ID';
  SQL_SELECT_BY_ID = 'SELECT * FROM CLIENTES WHERE ID=:ID';
  SQL_EXISTS_DOC = 'SELECT COUNT(*) FROM CLIENTES WHERE CPF_CNPJ=:DOC AND ID<>:ID';

{ TClienteDAO }

constructor TClienteDAO.Create(AConexao: TFDConnection);
begin
  inherited Create;
  if not Assigned(AConexao) then
    raise EInfraException.Create('Conexao nao informada ao TClienteDAO.');
  FConexao := AConexao;
end;

procedure TClienteDAO.DataSetParaEntidade(ADataSet: TDataSet; ACliente: TCliente);
begin
  ACliente.Id          := ADataSet.FieldByName('ID').AsInteger;
  ACliente.Nome        := ADataSet.FieldByName('NOME').AsString;
  ACliente.CpfCnpj     := ADataSet.FieldByName('CPF_CNPJ').AsString;
  ACliente.Email       := ADataSet.FieldByName('EMAIL').AsString;
  ACliente.Telefone    := ADataSet.FieldByName('TELEFONE').AsString;
  ACliente.Endereco    := ADataSet.FieldByName('ENDERECO').AsString;
  ACliente.Cidade      := ADataSet.FieldByName('CIDADE').AsString;
  ACliente.Uf          := ADataSet.FieldByName('UF').AsString;
  ACliente.Cep         := ADataSet.FieldByName('CEP').AsString;
  ACliente.Ativo       := ADataSet.FieldByName('ATIVO').AsString = 'S';
  ACliente.DtCadastro  := ADataSet.FieldByName('DT_CADASTRO').AsDateTime;
end;

function TClienteDAO.Inserir(ACliente: TCliente): Integer;
var
  LQry: TFDQuery;
begin
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text := SQL_INSERT;
    LQry.ParamByName('NOME').AsString     := ACliente.Nome;
    LQry.ParamByName('CPF_CNPJ').AsString := ACliente.CpfCnpj;
    LQry.ParamByName('EMAIL').AsString    := ACliente.Email;
    LQry.ParamByName('TELEFONE').AsString := ACliente.Telefone;
    LQry.ParamByName('ENDERECO').AsString := ACliente.Endereco;
    LQry.ParamByName('CIDADE').AsString   := ACliente.Cidade;
    LQry.ParamByName('UF').AsString       := ACliente.Uf;
    LQry.ParamByName('CEP').AsString      := ACliente.Cep;
    if ACliente.Ativo then
      LQry.ParamByName('ATIVO').AsString := 'S'
    else
      LQry.ParamByName('ATIVO').AsString := 'N';

    LQry.Open;
    Result := LQry.Fields[0].AsInteger;
    ACliente.Id := Result;
  finally
    LQry.Free;
  end;
end;

procedure TClienteDAO.Atualizar(ACliente: TCliente);
var
  LQry: TFDQuery;
begin
  if ACliente.Id <= 0 then
    raise EValidationException.Create('Id do cliente eh obrigatorio para atualizacao.');

  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text := SQL_UPDATE;
    LQry.ParamByName('ID').AsInteger      := ACliente.Id;
    LQry.ParamByName('NOME').AsString     := ACliente.Nome;
    LQry.ParamByName('CPF_CNPJ').AsString := ACliente.CpfCnpj;
    LQry.ParamByName('EMAIL').AsString    := ACliente.Email;
    LQry.ParamByName('TELEFONE').AsString := ACliente.Telefone;
    LQry.ParamByName('ENDERECO').AsString := ACliente.Endereco;
    LQry.ParamByName('CIDADE').AsString   := ACliente.Cidade;
    LQry.ParamByName('UF').AsString       := ACliente.Uf;
    LQry.ParamByName('CEP').AsString      := ACliente.Cep;
    if ACliente.Ativo then
      LQry.ParamByName('ATIVO').AsString := 'S'
    else
      LQry.ParamByName('ATIVO').AsString := 'N';
    LQry.ExecSQL;

    if LQry.RowsAffected = 0 then
      raise ENotFoundException.CreateFmt('Cliente id %d nao encontrado.', [ACliente.Id]);
  finally
    LQry.Free;
  end;
end;

procedure TClienteDAO.Excluir(AId: Integer);
var
  LQry: TFDQuery;
begin
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text := SQL_DELETE;
    LQry.ParamByName('ID').AsInteger := AId;
    LQry.ExecSQL;
    if LQry.RowsAffected = 0 then
      raise ENotFoundException.CreateFmt('Cliente id %d nao encontrado.', [AId]);
  finally
    LQry.Free;
  end;
end;

procedure TClienteDAO.DesativarLogicamente(AId: Integer);
var
  LQry: TFDQuery;
begin
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text := SQL_DESATIVAR;
    LQry.ParamByName('ID').AsInteger := AId;
    LQry.ExecSQL;
    if LQry.RowsAffected = 0 then
      raise ENotFoundException.CreateFmt('Cliente id %d nao encontrado.', [AId]);
  finally
    LQry.Free;
  end;
end;

function TClienteDAO.BuscarPorId(AId: Integer): TCliente;
var
  LQry: TFDQuery;
begin
  Result := nil;
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text := SQL_SELECT_BY_ID;
    LQry.ParamByName('ID').AsInteger := AId;
    LQry.Open;
    if not LQry.IsEmpty then
    begin
      Result := TCliente.Create;
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

function TClienteDAO.ExistePorCpfCnpj(const ACpfCnpj: string;
  AIdIgnorar: Integer): Boolean;
var
  LQry: TFDQuery;
begin
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text := SQL_EXISTS_DOC;
    LQry.ParamByName('DOC').AsString := ACpfCnpj;
    LQry.ParamByName('ID').AsInteger := AIdIgnorar;
    LQry.Open;
    Result := LQry.Fields[0].AsInteger > 0;
  finally
    LQry.Free;
  end;
end;

function TClienteDAO.Listar(const AFiltroNome: string): TObjectList<TCliente>;
var
  LQry: TFDQuery;
  LCliente: TCliente;
begin
  Result := TObjectList<TCliente>.Create(True);
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    if AFiltroNome <> '' then
    begin
      LQry.SQL.Text := 'SELECT * FROM CLIENTES WHERE UPPER(NOME) LIKE UPPER(:F) ORDER BY NOME';
      LQry.ParamByName('F').AsString := '%' + AFiltroNome + '%';
    end
    else
      LQry.SQL.Text := 'SELECT * FROM CLIENTES ORDER BY NOME';

    LQry.Open;
    while not LQry.Eof do
    begin
      LCliente := TCliente.Create;
      try
        DataSetParaEntidade(LQry, LCliente);
        Result.Add(LCliente);
      except
        LCliente.Free;
        raise;
      end;
      LQry.Next;
    end;
  finally
    LQry.Free;
  end;
end;

end.
