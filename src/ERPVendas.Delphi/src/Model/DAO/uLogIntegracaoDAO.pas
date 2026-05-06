unit uLogIntegracaoDAO;

interface

uses
  System.SysUtils, FireDAC.Comp.Client;

type
  TLogIntegracaoDAO = class
  strict private
    FConexao: TFDConnection;
  public
    constructor Create(AConexao: TFDConnection);
    procedure Registrar(const ATipo, ADirecao, AEndpoint, AMetodoHttp,
      ARequestBody, AResponseBody: string; AStatusHttp: Integer;
      ASucesso: Boolean; const AMensagemErro: string = '';
      AIdVenda: Integer = 0);
  end;

implementation

{ TLogIntegracaoDAO }

constructor TLogIntegracaoDAO.Create(AConexao: TFDConnection);
begin
  inherited Create;
  FConexao := AConexao;
end;

procedure TLogIntegracaoDAO.Registrar(const ATipo, ADirecao, AEndpoint,
  AMetodoHttp, ARequestBody, AResponseBody: string; AStatusHttp: Integer;
  ASucesso: Boolean; const AMensagemErro: string; AIdVenda: Integer);
var
  LQry: TFDQuery;
begin
  LQry := TFDQuery.Create(nil);
  try
    LQry.Connection := FConexao;
    LQry.SQL.Text :=
      'INSERT INTO LOG_INTEGRACAO ' +
      '  (TIPO, DIRECAO, ENDPOINT, METODO_HTTP, REQUEST_BODY, RESPONSE_BODY, ' +
      '   STATUS_HTTP, SUCESSO, MENSAGEM_ERRO, ID_VENDA) ' +
      'VALUES ' +
      '  (:TIPO, :DIRECAO, :ENDPOINT, :METODO_HTTP, :REQ, :RES, ' +
      '   :STATUS, :SUCESSO, :ERRO, :ID_VENDA)';
    LQry.ParamByName('TIPO').AsString        := ATipo;
    LQry.ParamByName('DIRECAO').AsString     := ADirecao;
    LQry.ParamByName('ENDPOINT').AsString    := AEndpoint;
    LQry.ParamByName('METODO_HTTP').AsString := AMetodoHttp;
    LQry.ParamByName('REQ').AsString         := ARequestBody;
    LQry.ParamByName('RES').AsString         := AResponseBody;
    LQry.ParamByName('STATUS').AsInteger     := AStatusHttp;
    if ASucesso then
      LQry.ParamByName('SUCESSO').AsString := 'S'
    else
      LQry.ParamByName('SUCESSO').AsString := 'N';
    LQry.ParamByName('ERRO').AsString        := AMensagemErro;
    if AIdVenda > 0 then
      LQry.ParamByName('ID_VENDA').AsInteger := AIdVenda
    else
      LQry.ParamByName('ID_VENDA').Clear;
    LQry.ExecSQL;
  finally
    LQry.Free;
  end;
end;

end.
