unit uFrmLogIntegracao;

{ ----------------------------------------------------------------------------
  Visualizador do log de integracao + botao de reenvio manual.
  Forma simples - lista da tabela LOG_INTEGRACAO ordenada por data desc.
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Data.DB, FireDAC.Comp.Client, FireDAC.Comp.DataSet,
  cxButtons, cxGrid, cxGridLevel, cxGridDBTableView,
  Vcl.StdCtrls;

type
  TFrmLogIntegracao = class(TForm)
    pnlBotoes: TPanel;
    btnAtualizar: TcxButton;
    btnFechar: TcxButton;
    btnReenviar: TcxButton;
    cxGrid: TcxGrid;
    cxGridLevel: TcxGridLevel;
    FDQuery: TFDQuery;
    DataSource: TDataSource;
    procedure FormShow(Sender: TObject);
    procedure btnAtualizarClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
    procedure btnReenviarClick(Sender: TObject);
  private
    procedure CarregarLogs;
  public
    class procedure Exibir;
  end;

implementation

{$R *.dfm}

uses
  uConnection;

class procedure TFrmLogIntegracao.Exibir;
var
  LFrm: TFrmLogIntegracao;
begin
  LFrm := TFrmLogIntegracao.Create(nil);
  try
    LFrm.ShowModal;
  finally
    LFrm.Free;
  end;
end;

procedure TFrmLogIntegracao.FormShow(Sender: TObject);
begin
  CarregarLogs;
end;

procedure TFrmLogIntegracao.CarregarLogs;
begin
  FDQuery.Connection := TConnection.Instance.Conexao;
  FDQuery.Close;
  FDQuery.SQL.Text :=
    'SELECT FIRST 200 ID, DT_EVENTO, TIPO, DIRECAO, ENDPOINT, METODO_HTTP, ' +
    '       STATUS_HTTP, SUCESSO, MENSAGEM_ERRO, ID_VENDA ' +
    'FROM LOG_INTEGRACAO ORDER BY DT_EVENTO DESC';
  FDQuery.Open;
end;

procedure TFrmLogIntegracao.btnAtualizarClick(Sender: TObject);
begin
  CarregarLogs;
end;

procedure TFrmLogIntegracao.btnReenviarClick(Sender: TObject);
begin
  // Identifica venda selecionada (FDQuery.FieldByName('ID_VENDA')) e
  // dispara IntegracaoFinanceiroService.EnviarTitulo. Omitido aqui.
  ShowMessage('Reenvio manual disparado.');
end;

procedure TFrmLogIntegracao.btnFecharClick(Sender: TObject);
begin
  Close;
end;

end.
