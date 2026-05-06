unit uConnection;

{ ----------------------------------------------------------------------------
  Singleton thread-safe de conexao FireDAC com Firebird 3.0.
  Cada thread obtem sua propria instancia logica via TFDConnection.CloneConnection
  para evitar contencao em transacoes simultaneas.
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.Stan.Pool, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.DApt,
  FireDAC.VCLUI.Wait, FireDAC.ConsoleUI.Wait, FireDAC.Comp.UI;

type
  TConnection = class
  strict private
    class var FInstance: TConnection;
    class var FLock: TCriticalSection;
    var
      FDriverLink: TFDPhysFBDriverLink;
    FWaitCursor: TFDGUIxWaitCursor;
    FConnection: TFDConnection;

    constructor CreatePrivate;
    procedure Configurar;
  public
    class function Instance: TConnection;
    class destructor DestroyClass;
    destructor Destroy; override;

    /// Retorna a conexao principal (uso em UI/single thread).
    function Conexao: TFDConnection;

    /// Cria conexao independente para uso em threads (chamador deve liberar).
    function NovaConexao: TFDConnection;

    procedure Conectar;
    procedure Desconectar;
    function EstaConectado: Boolean;
  end;

implementation

uses
  uConfig;

{ TConnection }

class function TConnection.Instance: TConnection;
begin
  if FInstance = nil then
  begin
    if FLock = nil then
      FLock := TCriticalSection.Create;
    FLock.Enter;
    try
      if FInstance = nil then
        FInstance := TConnection.CreatePrivate;
    finally
      FLock.Leave;
    end;
  end;
  Result := FInstance;
end;

class destructor TConnection.DestroyClass;
begin
  FreeAndNil(FInstance);
  FreeAndNil(FLock);
end;

constructor TConnection.CreatePrivate;
begin
  inherited Create;
  FDriverLink := TFDPhysFBDriverLink.Create(nil);
  FWaitCursor := TFDGUIxWaitCursor.Create(nil);
  FWaitCursor.Provider := 'Console';
  FConnection := TFDConnection.Create(nil);
  Configurar;
end;

destructor TConnection.Destroy;
begin
  FreeAndNil(FConnection);
  FreeAndNil(FWaitCursor);
  FreeAndNil(FDriverLink);
  inherited;
end;

procedure TConnection.Configurar;
var
  LCfg: TConfig;
begin
  LCfg := TConfig.Instance;

  FConnection.LoginPrompt := False;
  FConnection.Params.Clear;
  FConnection.Params.DriverID := 'FB';
  FConnection.Params.Database := LCfg.DbPath;
  FConnection.Params.Add('Server=' + LCfg.DbServer);
  FConnection.Params.Add('Port=' + IntToStr(LCfg.DbPort));
  FConnection.Params.UserName := LCfg.DbUser;
  FConnection.Params.Password := LCfg.DbPassword;
  FConnection.Params.Add('CharacterSet=UTF8');
  FConnection.Params.Add('Protocol=TCPIP');

  FConnection.TxOptions.Isolation := xiReadCommitted;
  FConnection.TxOptions.AutoCommit := False;

  FConnection.ResourceOptions.AutoReconnect := True;
  FConnection.ResourceOptions.KeepConnection := True;
end;

procedure TConnection.Conectar;
begin
  if not FConnection.Connected then
    FConnection.Connected := True;
end;

procedure TConnection.Desconectar;
begin
  if FConnection.Connected then
    FConnection.Connected := False;
end;

function TConnection.EstaConectado: Boolean;
begin
  Result := Assigned(FConnection) and FConnection.Connected;
end;

function TConnection.Conexao: TFDConnection;
begin
  Conectar;
  Result := FConnection;
end;

function TConnection.NovaConexao: TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  try
    Result.LoginPrompt := False;
    Result.Params.Assign(FConnection.Params);
    Result.TxOptions.Isolation := xiReadCommitted;
    Result.TxOptions.AutoCommit := False;
    Result.Connected := True;
  except
    Result.Free;
    raise;
  end;
end;

end.
