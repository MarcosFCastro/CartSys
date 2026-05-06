unit uFrmPrincipal;

{ ----------------------------------------------------------------------------
  Form principal - menu de acesso aos cadastros e listagens.
  Inicializa o servidor REST de callbacks na criacao.
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.ComCtrls,
  uVendaService, uRESTServer;

type
  TFrmPrincipal = class(TForm)
    StatusBar: TStatusBar;
    MainMenu: TMainMenu;
    mnuCadastros: TMenuItem;
    mnuClientes: TMenuItem;
    mnuProdutos: TMenuItem;
    mnuVendas: TMenuItem;
    mnuIntegracao: TMenuItem;
    mnuLogIntegracao: TMenuItem;
    mnuSistema: TMenuItem;
    mnuSair: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure mnuClientesClick(Sender: TObject);
    procedure mnuProdutosClick(Sender: TObject);
    procedure mnuVendasClick(Sender: TObject);
    procedure mnuLogIntegracaoClick(Sender: TObject);
    procedure mnuSairClick(Sender: TObject);
  private
    FVendaService: IVendaService;
    FServer: TRESTServer;
    procedure IniciarServidorREST;
    procedure NotificarStatus(const AMensagem: string);
    procedure OnIntegracaoConcluida(AIdVenda: Integer; const AMensagem: string);
    procedure OnEmailEnviado(AIdVenda: Integer; const AMensagem: string);
  public
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

{$R *.dfm}

uses
  System.UITypes,
  uConnection, uConfig, uLogger,
  uFrmCadCliente, uFrmCadProduto, uFrmCadVenda, uFrmLogIntegracao;

{ TFrmPrincipal }

procedure TFrmPrincipal.FormCreate(Sender: TObject);
var
  LVendaSvc: TVendaService;
begin
  Caption := 'CartSys - ERP Vendas';

  // Conecta no banco
  TConnection.Instance.Conectar;
  TLogger.Instance.Info('Aplicacao iniciada.');

  // Cria servico de venda (managed via interface)
  LVendaSvc := TVendaService.Create(TConnection.Instance.Conexao);
  LVendaSvc.OnIntegracaoConcluida := OnIntegracaoConcluida;
  LVendaSvc.OnEmailEnviado := OnEmailEnviado;
  FVendaService := LVendaSvc;

  IniciarServidorREST;
  NotificarStatus('Pronto.');
end;

procedure TFrmPrincipal.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FServer);
  FVendaService := nil;
  TConnection.Instance.Desconectar;
  TLogger.Instance.Info('Aplicacao encerrada.');
end;

procedure TFrmPrincipal.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('Deseja realmente sair?', mtConfirmation,
    [mbYes, mbNo], 0) = mrYes;
end;

procedure TFrmPrincipal.IniciarServidorREST;
begin
  FServer := TRESTServer.Create(FVendaService);
  try
    FServer.Iniciar(TConfig.Instance.ApiVendasPort, TConfig.Instance.ApiKey);
  except
    on E: Exception do
    begin
      TLogger.Instance.Error('Falha ao iniciar servidor REST', E);
      MessageDlg(
        'Falha ao iniciar servidor REST: ' + E.Message + sLineBreak +
        'O sistema continuara, porem callbacks do financeiro nao serao recebidos.',
        mtWarning, [mbOK], 0);
    end;
  end;
end;

procedure TFrmPrincipal.NotificarStatus(const AMensagem: string);
begin
  StatusBar.SimpleText := AMensagem;
end;

procedure TFrmPrincipal.OnIntegracaoConcluida(AIdVenda: Integer; const AMensagem: string);
begin
  if AMensagem = '' then
    NotificarStatus(Format('Venda %d integrada ao financeiro.', [AIdVenda]))
  else
    NotificarStatus(Format('Venda %d - integracao pendente: %s',
      [AIdVenda, AMensagem]));
end;

procedure TFrmPrincipal.OnEmailEnviado(AIdVenda: Integer; const AMensagem: string);
begin
  NotificarStatus(Format('Venda %d - %s', [AIdVenda, AMensagem]));
end;

procedure TFrmPrincipal.mnuClientesClick(Sender: TObject);
begin
  TFrmCadCliente.Listar;
end;

procedure TFrmPrincipal.mnuProdutosClick(Sender: TObject);
begin
  TFrmCadProduto.Listar;
end;

procedure TFrmPrincipal.mnuVendasClick(Sender: TObject);
begin
  TFrmCadVenda.Listar(FVendaService);
end;

procedure TFrmPrincipal.mnuLogIntegracaoClick(Sender: TObject);
begin
  TFrmLogIntegracao.Exibir;
end;

procedure TFrmPrincipal.mnuSairClick(Sender: TObject);
begin
  Close;
end;

end.
