unit uRESTServer;

{ ----------------------------------------------------------------------------
  Servidor HTTP embarcado usando Indy (TIdHTTPServer).
  Expoe os endpoints de callback chamados pelo ERP Financeiro:
    POST /api/v1/vendas/[id]/notificar-quitacao
    POST /api/v1/vendas/[id]/notificar-cancelamento
    GET  /api/v1/health

  Validacao da X-API-Key em todas as chamadas.
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.StrUtils, System.SyncObjs,
  IdHTTPServer, IdContext, IdCustomHTTPServer,
  uVendaService;

type
  TRESTServer = class
  strict private
    FHTTP: TIdHTTPServer;
    FVendaService: IVendaService;
    FApiKey: string;

    procedure HandleCommand(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);

    function ValidarApiKey(ARequest: TIdHTTPRequestInfo;
      AResponse: TIdHTTPResponseInfo): Boolean;
    function ExtrairIdRota(const ADocumento, APrefixo, ASufixo: string;
      out AId: Integer): Boolean;

    procedure ResponderJson(AResponse: TIdHTTPResponseInfo;
      AStatus: Integer; const AJson: string);
    procedure ResponderErro(AResponse: TIdHTTPResponseInfo;
      AStatus: Integer; const ATitulo, ADetalhe: string);

    procedure RotaQuitacao(AId: Integer;
      ARequest: TIdHTTPRequestInfo; AResponse: TIdHTTPResponseInfo);
    procedure RotaCancelamento(AId: Integer;
      ARequest: TIdHTTPRequestInfo; AResponse: TIdHTTPResponseInfo);
    procedure RotaHealth(AResponse: TIdHTTPResponseInfo);
  public
    constructor Create(AVendaService: IVendaService);
    destructor Destroy; override;

    procedure Iniciar(APorta: Integer; const AApiKey: string);
    procedure Parar;
  end;

implementation

uses
  System.DateUtils,
  uLogger, uExceptions;

const
  HEADER_API_KEY = 'X-API-Key';

{ TRESTServer }

constructor TRESTServer.Create(AVendaService: IVendaService);
begin
  inherited Create;
  if not Assigned(AVendaService) then
    raise EArgumentNilException.Create('VendaService obrigatorio.');
  FVendaService := AVendaService;
  FHTTP := TIdHTTPServer.Create(nil);
  FHTTP.OnCommandGet := HandleCommand;
end;

destructor TRESTServer.Destroy;
begin
  Parar;
  FHTTP.Free;
  inherited;
end;

procedure TRESTServer.Iniciar(APorta: Integer; const AApiKey: string);
begin
  if FHTTP.Active then
    Exit;
  FApiKey := AApiKey;
  FHTTP.DefaultPort := APorta;
  FHTTP.Active := True;
  TLogger.Instance.Info('Servidor REST do ERP Vendas ativo na porta %d', [APorta]);
end;

procedure TRESTServer.Parar;
begin
  if FHTTP.Active then
  begin
    FHTTP.Active := False;
    TLogger.Instance.Info('Servidor REST encerrado.');
  end;
end;

function TRESTServer.ValidarApiKey(ARequest: TIdHTTPRequestInfo;
  AResponse: TIdHTTPResponseInfo): Boolean;
var
  LChave: string;
begin
  LChave := ARequest.RawHeaders.Values[HEADER_API_KEY];
  Result := SameText(LChave, FApiKey);
  if not Result then
    ResponderErro(AResponse, 401, 'Nao autorizado', 'API Key invalida ou ausente.');
end;

function TRESTServer.ExtrairIdRota(const ADocumento, APrefixo, ASufixo: string;
  out AId: Integer): Boolean;
var
  LRestante, LIdStr: string;
  LPos: Integer;
begin
  Result := False;
  AId := 0;
  if not StartsText(APrefixo, ADocumento) then
    Exit;
  LRestante := Copy(ADocumento, Length(APrefixo) + 1, MaxInt);
  LPos := Pos(ASufixo, LRestante);
  if LPos <= 0 then
    Exit;
  LIdStr := Copy(LRestante, 1, LPos - 1);
  Result := TryStrToInt(LIdStr, AId);
end;

procedure TRESTServer.ResponderJson(AResponse: TIdHTTPResponseInfo;
  AStatus: Integer; const AJson: string);
begin
  AResponse.ResponseNo := AStatus;
  AResponse.ContentType := 'application/json; charset=utf-8';
  AResponse.CharSet := 'utf-8';
  AResponse.ContentText := AJson;
end;

procedure TRESTServer.ResponderErro(AResponse: TIdHTTPResponseInfo;
  AStatus: Integer; const ATitulo, ADetalhe: string);
var
  LJson: TJSONObject;
begin
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('title', ATitulo);
    LJson.AddPair('status', TJSONNumber.Create(AStatus));
    LJson.AddPair('detail', ADetalhe);
    ResponderJson(AResponse, AStatus, LJson.ToJSON);
  finally
    LJson.Free;
  end;
end;

procedure TRESTServer.RotaQuitacao(AId: Integer;
  ARequest: TIdHTTPRequestInfo; AResponse: TIdHTTPResponseInfo);
var
  LBody: string;
  LJson: TJSONObject;
  LDt: TDateTime;
  LForma: string;
  LValor: TJSONValue;
  LReader: TStreamReader;
begin
  LBody := '';
  if Assigned(ARequest.PostStream) then
  begin
    ARequest.PostStream.Position := 0;
    LReader := TStreamReader.Create(ARequest.PostStream, TEncoding.UTF8, False);
    try
      LBody := LReader.ReadToEnd;
    finally
      LReader.Free;
    end;
  end;
  LJson := TJSONObject.ParseJSONValue(LBody) as TJSONObject;
  if LJson = nil then
  begin
    ResponderErro(AResponse, 400, 'JSON invalido', 'Body nao eh um JSON valido.');
    Exit;
  end;
  try
    LDt := Now;
    LValor := LJson.GetValue('dtQuitacao');
    if Assigned(LValor) then
      LDt := ISO8601ToDate(LValor.Value, False);

    LForma := '';
    LValor := LJson.GetValue('formaPagamento');
    if Assigned(LValor) then
      LForma := LValor.Value;

    FVendaService.ProcessarQuitacao(AId, LDt, LForma);
    ResponderJson(AResponse, 200, '{"ok":true}');
  finally
    LJson.Free;
  end;
end;

procedure TRESTServer.RotaCancelamento(AId: Integer;
  ARequest: TIdHTTPRequestInfo; AResponse: TIdHTTPResponseInfo);
var
  LBody, LMotivo: string;
  LJson: TJSONObject;
  LValor: TJSONValue;
  LReader: TStreamReader;
begin
  LBody := '';
  if Assigned(ARequest.PostStream) then
  begin
    ARequest.PostStream.Position := 0;
    LReader := TStreamReader.Create(ARequest.PostStream, TEncoding.UTF8, False);
    try
      LBody := LReader.ReadToEnd;
    finally
      LReader.Free;
    end;
  end;
  LJson := TJSONObject.ParseJSONValue(LBody) as TJSONObject;
  LMotivo := '';
  if Assigned(LJson) then
  try
    LValor := LJson.GetValue('motivo');
    if Assigned(LValor) then
      LMotivo := LValor.Value;
  finally
    LJson.Free;
  end;

  FVendaService.ProcessarCancelamento(AId, LMotivo);
  ResponderJson(AResponse, 200, '{"ok":true}');
end;

procedure TRESTServer.RotaHealth(AResponse: TIdHTTPResponseInfo);
begin
  ResponderJson(AResponse, 200,
    Format('{"status":"UP","timestamp":"%s"}',
      [FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now)]));
end;

procedure TRESTServer.HandleCommand(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  LDoc: string;
  LId: Integer;
begin
  LDoc := ARequestInfo.Document;
  TLogger.Instance.Debug('REST in: %s %s', [ARequestInfo.Command, LDoc]);
  try
    // Health check eh publico
    if SameText(LDoc, '/api/v1/health') and SameText(ARequestInfo.Command, 'GET') then
    begin
      RotaHealth(AResponseInfo);
      Exit;
    end;

    if not ValidarApiKey(ARequestInfo, AResponseInfo) then
      Exit;

    if SameText(ARequestInfo.Command, 'POST') then
    begin
      if ExtrairIdRota(LDoc, '/api/v1/vendas/', '/notificar-quitacao', LId) then
      begin
        RotaQuitacao(LId, ARequestInfo, AResponseInfo);
        Exit;
      end;
      if ExtrairIdRota(LDoc, '/api/v1/vendas/', '/notificar-cancelamento', LId) then
      begin
        RotaCancelamento(LId, ARequestInfo, AResponseInfo);
        Exit;
      end;
    end;

    ResponderErro(AResponseInfo, 404, 'Nao encontrado',
      Format('Rota %s %s nao existe.', [ARequestInfo.Command, LDoc]));
  except
    on E: EValidationException do
      ResponderErro(AResponseInfo, 400, 'Validacao', E.Message);
    on E: EBusinessException do
      ResponderErro(AResponseInfo, 409, 'Conflito de regra', E.Message);
    on E: ENotFoundException do
      ResponderErro(AResponseInfo, 404, 'Nao encontrado', E.Message);
    on E: Exception do
    begin
      TLogger.Instance.Error('Erro no servidor REST', E);
      ResponderErro(AResponseInfo, 500, 'Erro interno', E.Message);
    end;
  end;
end;

end.
