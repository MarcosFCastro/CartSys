unit uLogger;

{ ----------------------------------------------------------------------------
  Logger thread-safe - escreve em arquivo diario na pasta configurada.
  Niveis: DEBUG, INFO, WARN, ERROR.
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.IOUtils;

type
  TLogLevel = (llDebug, llInfo, llWarn, llError);

  TLogger = class
  strict private
    class var FInstance: TLogger;
    class var FLock: TCriticalSection;
    FNivelMinimo: TLogLevel;

    constructor CreatePrivate;
    function NomeArquivoDoDia: string;
    function NivelStr(ANivel: TLogLevel): string;
    procedure EscreverLinha(const ALinha: string);
  public
    class function Instance: TLogger;
    class destructor DestroyClass;

    procedure Debug(const AMsg: string); overload;
    procedure Debug(const AFmt: string; const AArgs: array of const); overload;
    procedure Info(const AMsg: string); overload;
    procedure Info(const AFmt: string; const AArgs: array of const); overload;
    procedure Warn(const AMsg: string); overload;
    procedure Warn(const AFmt: string; const AArgs: array of const); overload;
    procedure Error(const AMsg: string); overload;
    procedure Error(const AFmt: string; const AArgs: array of const); overload;
    procedure Error(const AMsg: string; AException: Exception); overload;

    property NivelMinimo: TLogLevel read FNivelMinimo write FNivelMinimo;
  end;

implementation

uses
  uConfig;

{ TLogger }

class function TLogger.Instance: TLogger;
begin
  if FInstance = nil then
  begin
    if FLock = nil then
      FLock := TCriticalSection.Create;
    FLock.Enter;
    try
      if FInstance = nil then
        FInstance := TLogger.CreatePrivate;
    finally
      FLock.Leave;
    end;
  end;
  Result := FInstance;
end;

class destructor TLogger.DestroyClass;
begin
  FreeAndNil(FInstance);
  FreeAndNil(FLock);
end;

constructor TLogger.CreatePrivate;
begin
  inherited Create;
  FNivelMinimo := llInfo;
end;

function TLogger.NomeArquivoDoDia: string;
begin
  Result := TPath.Combine(TConfig.Instance.LogPath,
    'erpvendas_' + FormatDateTime('yyyy-mm-dd', Now) + '.log');
end;

function TLogger.NivelStr(ANivel: TLogLevel): string;
begin
  case ANivel of
    llDebug: Result := 'DEBUG';
    llInfo:  Result := 'INFO ';
    llWarn:  Result := 'WARN ';
    llError: Result := 'ERROR';
  else
    Result := '?????';
  end;
end;

procedure TLogger.EscreverLinha(const ALinha: string);
var
  LArquivo: string;
  LStream: TStreamWriter;
begin
  LArquivo := NomeArquivoDoDia;
  FLock.Enter;
  try
    LStream := TStreamWriter.Create(LArquivo, True, TEncoding.UTF8);
    try
      LStream.WriteLine(ALinha);
    finally
      LStream.Free;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TLogger.Debug(const AMsg: string);
begin
  if FNivelMinimo <= llDebug then
    EscreverLinha(Format('%s [%s] %s',
      [FormatDateTime('hh:nn:ss.zzz', Now), NivelStr(llDebug), AMsg]));
end;

procedure TLogger.Debug(const AFmt: string; const AArgs: array of const);
begin
  Debug(Format(AFmt, AArgs));
end;

procedure TLogger.Info(const AMsg: string);
begin
  if FNivelMinimo <= llInfo then
    EscreverLinha(Format('%s [%s] %s',
      [FormatDateTime('hh:nn:ss.zzz', Now), NivelStr(llInfo), AMsg]));
end;

procedure TLogger.Info(const AFmt: string; const AArgs: array of const);
begin
  Info(Format(AFmt, AArgs));
end;

procedure TLogger.Warn(const AMsg: string);
begin
  if FNivelMinimo <= llWarn then
    EscreverLinha(Format('%s [%s] %s',
      [FormatDateTime('hh:nn:ss.zzz', Now), NivelStr(llWarn), AMsg]));
end;

procedure TLogger.Warn(const AFmt: string; const AArgs: array of const);
begin
  Warn(Format(AFmt, AArgs));
end;

procedure TLogger.Error(const AMsg: string);
begin
  EscreverLinha(Format('%s [%s] %s',
    [FormatDateTime('hh:nn:ss.zzz', Now), NivelStr(llError), AMsg]));
end;

procedure TLogger.Error(const AFmt: string; const AArgs: array of const);
begin
  Error(Format(AFmt, AArgs));
end;

procedure TLogger.Error(const AMsg: string; AException: Exception);
begin
  if Assigned(AException) then
    Error('%s | Exception: %s | Message: %s',
      [AMsg, AException.ClassName, AException.Message])
  else
    Error(AMsg);
end;

end.
