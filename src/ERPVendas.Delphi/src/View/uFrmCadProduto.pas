unit uFrmCadProduto;

{ Cadastro de Produto - mesmo padrao de uFrmCadCliente. }

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  cxButtons, cxTextEdit, cxGrid, cxGridLevel,
  cxGridCustomTableView, cxGridTableView, cxGridCustomView,
  uProduto, uProdutoService;

type
  TFrmCadProduto = class(TForm)
    pnlFiltro: TPanel;
    lblFiltro: TLabel;
    edtFiltro: TcxTextEdit;
    cxGrid: TcxGrid;
    cxGridLevel: TcxGridLevel;
    pnlBotoes: TPanel;
    btnNovo: TcxButton;
    btnEditar: TcxButton;
    btnExcluir: TcxButton;
    btnFechar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
  private
    FService: IProdutoService;
    FProdutos: TObjectList<TProduto>;
    procedure CarregarGrid;
    function ProdutoSelecionado: TProduto;
  public
    class procedure Listar;
  end;

implementation

{$R *.dfm}

uses
  uConnection, uProdutoDAO, uExceptions, uFrmCadProdutoEdit;

class procedure TFrmCadProduto.Listar;
var
  LFrm: TFrmCadProduto;
begin
  LFrm := TFrmCadProduto.Create(nil);
  try
    LFrm.ShowModal;
  finally
    LFrm.Free;
  end;
end;

procedure TFrmCadProduto.FormCreate(Sender: TObject);
var
  LDAO: TProdutoDAO;
begin
  Caption := 'Produtos';
  LDAO := TProdutoDAO.Create(TConnection.Instance.Conexao);
  FService := TProdutoService.Create(LDAO, True);
  FProdutos := TObjectList<TProduto>.Create(True);
  CarregarGrid;
end;

procedure TFrmCadProduto.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FProdutos);
  FService := nil;
end;

procedure TFrmCadProduto.CarregarGrid;
var
  LView: TcxGridTableView;
  LProduto: TProduto;
  I: Integer;
  LAtivoStr: string;
begin
  FreeAndNil(FProdutos);
  FProdutos := FService.Listar(edtFiltro.Text);

  LView := cxGrid.Views[0] as TcxGridTableView;
  cxGrid.BeginUpdate;
  try
    // Indices: 0=Id,1=Codigo,2=Descricao,3=Unidade,4=PrecoVenda,5=Ativo
    LView.DataController.RecordCount := 0;
    LView.DataController.RecordCount := FProdutos.Count;
    for I := 0 to FProdutos.Count - 1 do
    begin
      LProduto := FProdutos[I];
      if LProduto.Ativo then LAtivoStr := 'Sim' else LAtivoStr := 'Nao';
      LView.DataController.Values[I, 0] := LProduto.Id;
      LView.DataController.Values[I, 1] := LProduto.Codigo;
      LView.DataController.Values[I, 2] := LProduto.Descricao;
      LView.DataController.Values[I, 3] := LProduto.Unidade;
      LView.DataController.Values[I, 4] := LProduto.PrecoVenda;
      LView.DataController.Values[I, 5] := LAtivoStr;
    end;
  finally
    cxGrid.EndUpdate;
  end;
end;

function TFrmCadProduto.ProdutoSelecionado: TProduto;
var
  LView: TcxGridTableView;
  LIdx: Integer;
begin
  Result := nil;
  LView := cxGrid.Views[0] as TcxGridTableView;
  LIdx := LView.DataController.FocusedRecordIndex;
  if (LIdx >= 0) and (LIdx < FProdutos.Count) then
    Result := FProdutos[LIdx];
end;

procedure TFrmCadProduto.btnNovoClick(Sender: TObject);
var
  LProd: TProduto;
begin
  LProd := TProduto.Create;
  try
    TFrmCadProdutoEdit.Editar(FService, LProd);
  finally
    LProd.Free;
  end;
  CarregarGrid;
end;

procedure TFrmCadProduto.btnEditarClick(Sender: TObject);
begin
  if ProdutoSelecionado = nil then Exit;
  TFrmCadProdutoEdit.Editar(FService, ProdutoSelecionado);
  CarregarGrid;
end;

procedure TFrmCadProduto.btnExcluirClick(Sender: TObject);
var
  LSel: TProduto;
begin
  LSel := ProdutoSelecionado;
  if LSel = nil then Exit;
  if MessageDlg(Format('Inativar produto %s?', [LSel.Descricao]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  try
    FService.Excluir(LSel.Id);
    CarregarGrid;
  except
    on E: EAppException do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TFrmCadProduto.btnFecharClick(Sender: TObject);
begin
  Close;
end;

end.
