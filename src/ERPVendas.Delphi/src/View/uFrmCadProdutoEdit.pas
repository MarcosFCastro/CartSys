unit uFrmCadProdutoEdit;

{ Formulario modal de insercao/edicao de Produto.
  Recebe a entidade e o service via Editar(); salva via FService.Salvar. }

interface

uses
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  uProduto, uProdutoService;

type
  TFrmCadProdutoEdit = class(TForm)
    pnlBotoes: TPanel;
    btnSalvar: TButton;
    btnCancelar: TButton;
    pnlCampos: TPanel;
    lblCodigo: TLabel;
    edtCodigo: TEdit;
    lblDescricao: TLabel;
    edtDescricao: TEdit;
    lblUnidade: TLabel;
    edtUnidade: TEdit;
    lblPrecoVenda: TLabel;
    edtPrecoVenda: TEdit;
    lblEstoque: TLabel;
    edtEstoque: TEdit;
    chkAtivo: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FService: IProdutoService;
    FProduto: TProduto;
    procedure CarregarParaTela;
    procedure AplicarParaEntidade;
  public
    class function Editar(AService: IProdutoService; AProduto: TProduto): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.UITypes,
  uExceptions;

class function TFrmCadProdutoEdit.Editar(AService: IProdutoService;
  AProduto: TProduto): Boolean;
var
  LFrm: TFrmCadProdutoEdit;
begin
  LFrm := TFrmCadProdutoEdit.Create(nil);
  try
    LFrm.FService := AService;
    LFrm.FProduto := AProduto;
    LFrm.CarregarParaTela;
    Result := LFrm.ShowModal = mrOk;
  finally
    LFrm.Free;
  end;
end;

procedure TFrmCadProdutoEdit.FormCreate(Sender: TObject);
begin
  Caption := 'Produto';
end;

procedure TFrmCadProdutoEdit.CarregarParaTela;
begin
  edtCodigo.Text    := FProduto.Codigo;
  edtDescricao.Text := FProduto.Descricao;
  edtUnidade.Text   := FProduto.Unidade;
  edtPrecoVenda.Text := FormatFloat('0.00', FProduto.PrecoVenda);
  edtEstoque.Text   := FormatFloat('0.##', FProduto.Estoque);
  chkAtivo.Checked  := FProduto.Ativo;
end;

procedure TFrmCadProdutoEdit.AplicarParaEntidade;
begin
  FProduto.Codigo    := edtCodigo.Text;
  FProduto.Descricao := edtDescricao.Text;
  FProduto.Unidade   := edtUnidade.Text;
  FProduto.PrecoVenda := StrToCurrDef(edtPrecoVenda.Text, 0);
  FProduto.Estoque   := StrToFloatDef(edtEstoque.Text, 0);
  FProduto.Ativo     := chkAtivo.Checked;
end;

procedure TFrmCadProdutoEdit.btnSalvarClick(Sender: TObject);
begin
  try
    AplicarParaEntidade;
    FService.Salvar(FProduto);
    ModalResult := mrOk;
  except
    on E: EValidationException do
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
    on E: EAppException do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TFrmCadProdutoEdit.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
