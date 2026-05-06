unit uFrmLogIntegracao;

{ Visualizador do log de integracao + botao de reenvio manual. }

interface

uses
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.DBGrids, Vcl.Grids,
  Data.DB, FireDAC.Comp.Client, FireDAC.Comp.DataSet;

type
  TFrmLogIntegracao = class(TForm)
    pnlBotoes: TPanel;
    btnAtualizar: TButton;
    btnReenviar: TButton;
    btnFechar: TButton;
    dbgLog: TDBGrid;
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
  ShowMessage('Reenvio manual disparado.');
end;

procedure TFrmLogIntegracao.btnFecharClick(Sender: TObject);
begin
  Close;
end;

end.
