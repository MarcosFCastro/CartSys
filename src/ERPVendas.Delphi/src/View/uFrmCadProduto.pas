unit uFrmCadProduto;

{ Cadastro de Produto - mesmo padrao de uFrmCadCliente. }

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls,
  uProduto, uProdutoService;

type
  TFrmCadProduto = class(TForm)
    pnlFiltro: TPanel;
    lblFiltro: TLabel;
    edtFiltro: TEdit;
    lvProdutos: TListView;
    pnlBotoes: TPanel;
    btnNovo: TButton;
    btnEditar: TButton;
    btnExcluir: TButton;
    btnFechar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
    procedure edtFiltroChange(Sender: TObject);
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
  System.UITypes,
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
  LProduto: TProduto;
  LItem: TListItem;
begin
  FreeAndNil(FProdutos);
  FProdutos := FService.Listar(edtFiltro.Text);

  lvProdutos.Items.BeginUpdate;
  try
    lvProdutos.Items.Clear;
    for LProduto in FProdutos do
    begin
      LItem := lvProdutos.Items.Add;
      LItem.Caption := LProduto.Codigo;
      LItem.SubItems.Add(LProduto.Descricao);
      LItem.SubItems.Add(LProduto.Unidade);
      LItem.SubItems.Add(FormatFloat('0.00', LProduto.PrecoVenda));
      if LProduto.Ativo then
        LItem.SubItems.Add('Sim')
      else
        LItem.SubItems.Add('Nao');
    end;
  finally
    lvProdutos.Items.EndUpdate;
  end;
end;

function TFrmCadProduto.ProdutoSelecionado: TProduto;
var
  LIdx: Integer;
begin
  Result := nil;
  if lvProdutos.Selected = nil then Exit;
  LIdx := lvProdutos.Selected.Index;
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
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
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

procedure TFrmCadProduto.edtFiltroChange(Sender: TObject);
begin
  CarregarGrid;
end;

end.
