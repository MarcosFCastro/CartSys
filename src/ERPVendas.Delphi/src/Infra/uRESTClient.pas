unit uRESTClient;

{ ----------------------------------------------------------------------------
  Wrapper sobre TRESTClient/TRESTRequest com:
  - Timeout configuravel
  - Header X-API-Key automatico
  - Retry com backoff exponencial para erros 5xx/timeout
  - Logging completo de request/response
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.TypInfo,
  REST.Client, REST.Types,
  uExceptions;

type
  TRespostaREST = record
    StatusCode: Integer;
    Conteudo: string;
    Sucesso: Boolean;
  end;

  TRESTClienteHTTP = class
  strict private
    FBaseUrl: string;
    FApiKey: string;
    FTimeoutMs: Integer;
    FMaxTentativas: Integer;

    function ExecutarComRetry(const AMetodo: TRESTRequestMethod;
      const ARecurso, ABody: string): TRespostaREST;
    function DeveTentarNovamente(AStatusCode: Integer): Boolean;
  public
    constructor Create(const ABaseUrl, AApiKey: string; ATimeoutSeg: Integer;
      AMaxTentativas: Integer = 3);

    function Get(const ARecurso: string): TRespostaREST;
    function Post(const ARecurso, AJsonBody: string): TRespostaREST;
    function Put(const ARecurso, AJsonBody: string): TRespostaREST;
    function Delete(const ARecurso: string): TRespostaREST;
  end;

implementation

uses
  uLogger;

const
  HEADER_API_KEY = 'X-API-Key';

{ TRESTClienteHTTP }

constructor TRESTClienteHTTP.Create(const ABaseUrl, AApiKey: string;
  ATimeoutSeg, AMaxTentativas: Integer);
begin
  inherited Create;
  FBaseUrl := ABaseUrl;
  FApiKey := AApiKey;
  FTimeoutMs := ATimeoutSeg * 1000;
  FMaxTentativas := AMaxTentativas;
end;

function TRESTClienteHTTP.DeveTentarNovamente(AStatusCode: Integer): Boolean;
begin
  // Retry para erros transitorios: timeout (0) ou 5xx
  Result := (AStatusCode = 0) or (AStatusCode >= 500);
end;

function TRESTClienteHTTP.ExecutarComRetry(const AMetodo: TRESTRequestMethod;
  const ARecurso, ABody: string): TRespostaREST;
var
  LCliente: TRESTClient;
  LRequest: TRESTRequest;
  LResponse: TRESTResponse;
  LTentativa: Integer;
  LEsperaMs: Integer;
begin
  Result.StatusCode := 0;
  Result.Conteudo := '';
  Result.Sucesso := False;

  LCliente := TRESTClient.Create(nil);
  LResponse := TRESTResponse.Create(nil);
  LRequest := TRESTRequest.Create(nil);
  try
    LCliente.BaseURL := FBaseUrl;

    LRequest.Client := LCliente;
    LRequest.Response := LResponse;
    LRequest.Resource := ARecurso;
    LRequest.Method := AMetodo;
    LRequest.Timeout := FTimeoutMs;

    LRequest.Params.AddHeader(HEADER_API_KEY, FApiKey);
    LRequest.Params.AddHeader('Accept', 'application/json');

    if (AMetodo in [rmPOST, rmPUT]) and (ABody <> '') then
      LRequest.AddBody(ABody, ctAPPLICATION_JSON);

    LEsperaMs := 1000;
    for LTentativa := 1 to FMaxTentativas do
    begin
      try
        TLogger.Instance.Debug('REST -> [%s] %s%s tentativa %d',
          [GetEnumName(TypeInfo(TRESTRequestMethod), Ord(AMetodo)),
           FBaseUrl, ARecurso, LTentativa]);

        LRequest.Execute;

        Result.StatusCode := LResponse.StatusCode;
        Result.Conteudo := LResponse.Content;
        Result.Sucesso := (LResponse.StatusCode >= 200) and (LResponse.StatusCode < 300);

        TLogger.Instance.Debug('REST <- HTTP %d', [Result.StatusCode]);

        if Result.Sucesso or (not DeveTentarNovamente(Result.StatusCode)) then
          Exit;
      except
        on E: Exception do
        begin
          TLogger.Instance.Warn('Falha na tentativa %d: %s', [LTentativa, E.Message]);
          Result.StatusCode := 0;
          Result.Conteudo := E.Message;
          if LTentativa = FMaxTentativas then
            raise EIntegrationException.Create(
              Format('Falha apos %d tentativas em %s%s: %s',
                [FMaxTentativas, FBaseUrl, ARecurso, E.Message]));
        end;
      end;

      if LTentativa < FMaxTentativas then
      begin
        Sleep(LEsperaMs);
        LEsperaMs := LEsperaMs * 2; // backoff exponencial: 1s, 2s, 4s
      end;
    end;
  finally
    LRequest.Free;
    LResponse.Free;
    LCliente.Free;
  end;
end;

function TRESTClienteHTTP.Get(const ARecurso: string): TRespostaREST;
begin
  Result := ExecutarComRetry(rmGET, ARecurso, '');
end;

function TRESTClienteHTTP.Post(const ARecurso, AJsonBody: string): TRespostaREST;
begin
  Result := ExecutarComRetry(rmPOST, ARecurso, AJsonBody);
end;

function TRESTClienteHTTP.Put(const ARecurso, AJsonBody: string): TRespostaREST;
begin
  Result := ExecutarComRetry(rmPUT, ARecurso, AJsonBody);
end;

function TRESTClienteHTTP.Delete(const ARecurso: string): TRespostaREST;
begin
  Result := ExecutarComRetry(rmDELETE, ARecurso, '');
end;

end.
