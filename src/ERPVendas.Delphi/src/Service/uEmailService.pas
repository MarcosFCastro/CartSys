unit uEmailService;

{ ----------------------------------------------------------------------------
  Service de envio de e-mail via Indy SMTP com SSL/TLS.
  Recebe corpo (HTML ou texto) e lista de anexos. Logger registra resultado.
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.Classes,
  IdSMTP, IdMessage, IdSSLOpenSSL, IdAttachmentFile, IdExplicitTLSClientServerBase,
  IdMessageBuilder;

type
  TEmailService = class
  strict private
    FHost: string;
    FPort: Integer;
    FUser: string;
    FPassword: string;
    FFrom: string;
    FUseSSL: Boolean;
  public
    constructor Create;

    procedure Enviar(const ADestinatario, AAssunto, ACorpoHTML: string;
      AAnexos: TStrings = nil);
  end;

implementation

uses
  uConfig, uLogger, uExceptions;

{ TEmailService }

constructor TEmailService.Create;
var
  LCfg: TConfig;
begin
  inherited Create;
  LCfg := TConfig.Instance;
  FHost := LCfg.SmtpHost;
  FPort := LCfg.SmtpPort;
  FUser := LCfg.SmtpUser;
  FPassword := LCfg.SmtpPassword;
  FFrom := LCfg.SmtpFrom;
  FUseSSL := LCfg.SmtpUseSSL;
end;

procedure TEmailService.Enviar(const ADestinatario, AAssunto, ACorpoHTML: string;
  AAnexos: TStrings);
var
  LSMTP: TIdSMTP;
  LMsg: TIdMessage;
  LSSL: TIdSSLIOHandlerSocketOpenSSL;
  LBuilder: TIdMessageBuilderHtml;
  I: Integer;
begin
  if (Trim(FHost) = '') or (Trim(FFrom) = '') then
    raise EIntegrationException.Create('SMTP nao configurado (host ou remetente vazios).');
  if Trim(ADestinatario) = '' then
    raise EIntegrationException.Create('Destinatario obrigatorio.');

  LSMTP := TIdSMTP.Create(nil);
  LMsg := TIdMessage.Create(nil);
  LSSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  LBuilder := TIdMessageBuilderHtml.Create;
  try
    LBuilder.Html.Text := ACorpoHTML;
    LBuilder.HtmlCharSet := 'utf-8';
    if Assigned(AAnexos) then
      for I := 0 to AAnexos.Count - 1 do
        if FileExists(AAnexos[I]) then
          LBuilder.Attachments.Add(AAnexos[I]);
    LBuilder.FillMessage(LMsg);

    LMsg.From.Address := FFrom;
    LMsg.From.Name := 'CartSys ERP Vendas';
    LMsg.Recipients.Add.Address := ADestinatario;
    LMsg.Subject := AAssunto;

    LSMTP.Host := FHost;
    LSMTP.Port := FPort;
    LSMTP.Username := FUser;
    LSMTP.Password := FPassword;
    LSMTP.AuthType := satDefault;

    if FUseSSL then
    begin
      LSSL.SSLOptions.SSLVersions := [sslvTLSv1_2];
      LSMTP.IOHandler := LSSL;
      if FPort = 465 then
        LSMTP.UseTLS := utUseImplicitTLS
      else
        LSMTP.UseTLS := utUseExplicitTLS;
    end;

    try
      LSMTP.Connect;
      try
        LSMTP.Authenticate;
        LSMTP.Send(LMsg);
        TLogger.Instance.Info('E-mail enviado para %s | assunto: %s',
          [ADestinatario, AAssunto]);
      finally
        LSMTP.Disconnect;
      end;
    except
      on E: Exception do
      begin
        TLogger.Instance.Error('Falha SMTP', E);
        raise EIntegrationException.CreateFmt(
          'Falha ao enviar e-mail: %s', [E.Message]);
      end;
    end;
  finally
    LBuilder.Free;
    LSSL.Free;
    LMsg.Free;
    LSMTP.Free;
  end;
end;

end.
