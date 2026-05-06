unit uConfig;

{ ----------------------------------------------------------------------------
  Carrega configuracoes externas do arquivo config.ini, evitando hardcode.
  Singleton thread-safe.
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.IniFiles, System.IOUtils, System.SyncObjs;

type
  TConfig = class
  strict private
    class var FInstance: TConfig;
    class var FLock: TCriticalSection;
    FArquivo: string;

    // Banco
    FDbServer: string;
    FDbPath: string;
    FDbUser: string;
    FDbPassword: string;
    FDbPort: Integer;

    // API Financeiro (consumida pelo Vendas)
    FApiFinanceiroUrl: string;
    FApiKey: string;
    FApiTimeoutSeg: Integer;

    // API Vendas (exposta pelo Vendas para callbacks)
    FApiVendasPort: Integer;

    // SMTP
    FSmtpHost: string;
    FSmtpPort: Integer;
    FSmtpUser: string;
    FSmtpPassword: string;
    FSmtpFrom: string;
    FSmtpUseSSL: Boolean;

    // Log
    FLogPath: string;

    constructor CreatePrivate;
    procedure Carregar;
  public
    class function Instance: TConfig;
    class destructor DestroyClass;

    procedure Recarregar;

    property DbServer: string read FDbServer;
    property DbPath: string read FDbPath;
    property DbUser: string read FDbUser;
    property DbPassword: string read FDbPassword;
    property DbPort: Integer read FDbPort;

    property ApiFinanceiroUrl: string read FApiFinanceiroUrl;
    property ApiKey: string read FApiKey;
    property ApiTimeoutSeg: Integer read FApiTimeoutSeg;

    property ApiVendasPort: Integer read FApiVendasPort;

    property SmtpHost: string read FSmtpHost;
    property SmtpPort: Integer read FSmtpPort;
    property SmtpUser: string read FSmtpUser;
    property SmtpPassword: string read FSmtpPassword;
    property SmtpFrom: string read FSmtpFrom;
    property SmtpUseSSL: Boolean read FSmtpUseSSL;

    property LogPath: string read FLogPath;
  end;

implementation

{ TConfig }

class function TConfig.Instance: TConfig;
begin
  if FInstance = nil then
  begin
    if FLock = nil then
      FLock := TCriticalSection.Create;
    FLock.Enter;
    try
      if FInstance = nil then
        FInstance := TConfig.CreatePrivate;
    finally
      FLock.Leave;
    end;
  end;
  Result := FInstance;
end;

class destructor TConfig.DestroyClass;
begin
  FreeAndNil(FInstance);
  FreeAndNil(FLock);
end;

constructor TConfig.CreatePrivate;
begin
  inherited Create;
  FArquivo := TPath.Combine(ExtractFilePath(ParamStr(0)), 'config.ini');
  Carregar;
end;

procedure TConfig.Recarregar;
begin
  Carregar;
end;

procedure TConfig.Carregar;
var
  LIni: TIniFile;
begin
  if not TFile.Exists(FArquivo) then
    raise Exception.CreateFmt('Arquivo de configuracao nao encontrado: %s', [FArquivo]);

  LIni := TIniFile.Create(FArquivo);
  try
    FDbServer   := LIni.ReadString('Database', 'Server',   'localhost');
    FDbPath     := LIni.ReadString('Database', 'Path',     'C:\CartSys\DB\ERP_VENDAS.FDB');
    FDbUser     := LIni.ReadString('Database', 'User',     'SYSDBA');
    FDbPassword := LIni.ReadString('Database', 'Password', 'masterkey');
    FDbPort     := LIni.ReadInteger('Database','Port',     3050);

    FApiFinanceiroUrl := LIni.ReadString ('ApiFinanceiro', 'Url',        'http://localhost:5001');
    FApiKey           := LIni.ReadString ('ApiFinanceiro', 'ApiKey',     'cartsys-dev-key');
    FApiTimeoutSeg    := LIni.ReadInteger('ApiFinanceiro', 'TimeoutSeg', 30);

    FApiVendasPort := LIni.ReadInteger('ApiVendas', 'Port', 5002);

    FSmtpHost     := LIni.ReadString ('SMTP', 'Host',     'smtp.gmail.com');
    FSmtpPort     := LIni.ReadInteger('SMTP', 'Port',     587);
    FSmtpUser     := LIni.ReadString ('SMTP', 'User',     '');
    FSmtpPassword := LIni.ReadString ('SMTP', 'Password', '');
    FSmtpFrom     := LIni.ReadString ('SMTP', 'From',     '');
    FSmtpUseSSL   := LIni.ReadBool   ('SMTP', 'UseSSL',   True);

    FLogPath := LIni.ReadString('Log', 'Path', TPath.Combine(ExtractFilePath(ParamStr(0)), 'logs'));
    if not TDirectory.Exists(FLogPath) then
      TDirectory.CreateDirectory(FLogPath);
  finally
    LIni.Free;
  end;
end;

end.
