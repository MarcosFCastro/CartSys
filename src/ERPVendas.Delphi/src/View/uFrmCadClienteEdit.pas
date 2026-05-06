unit uFrmCadClienteEdit;

{ Formulario modal de insercao/edicao de Cliente.
  Recebe a entidade e o service via Editar(); salva via FService.Salvar. }

interface

uses
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  cxButtons, cxTextEdit, cxCheckBox,
  uCliente, uClienteService;

type
  TFrmCadClienteEdit = class(TForm)
    pnlBotoes: TPanel;
    btnSalvar: TcxButton;
    btnCancelar: TcxButton;
    pnlCampos: TPanel;
    lblNome: TLabel;
    edtNome: TcxTextEdit;
    lblCpfCnpj: TLabel;
    edtCpfCnpj: TcxTextEdit;
    lblEmail: TLabel;
    edtEmail: TcxTextEdit;
    lblTelefone: TLabel;
    edtTelefone: TcxTextEdit;
    lblEndereco: TLabel;
    edtEndereco: TcxTextEdit;
    lblCidade: TLabel;
    edtCidade: TcxTextEdit;
    lblUf: TLabel;
    edtUf: TcxTextEdit;
    lblCep: TLabel;
    edtCep: TcxTextEdit;
    chkAtivo: TcxCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FService: IClienteService;
    FCliente: TCliente;
    procedure CarregarParaTela;
    procedure AplicarParaEntidade;
  public
    class function Editar(AService: IClienteService; ACliente: TCliente): Boolean;
  end;

implementation

{$R *.dfm}

uses
  uExceptions;

class function TFrmCadClienteEdit.Editar(AService: IClienteService;
  ACliente: TCliente): Boolean;
var
  LFrm: TFrmCadClienteEdit;
begin
  LFrm := TFrmCadClienteEdit.Create(nil);
  try
    LFrm.FService := AService;
    LFrm.FCliente := ACliente;
    LFrm.CarregarParaTela;
    Result := LFrm.ShowModal = mrOk;
  finally
    LFrm.Free;
  end;
end;

procedure TFrmCadClienteEdit.FormCreate(Sender: TObject);
begin
  Caption := 'Cliente';
end;

procedure TFrmCadClienteEdit.CarregarParaTela;
begin
  edtNome.Text     := FCliente.Nome;
  edtCpfCnpj.Text  := FCliente.CpfCnpj;
  edtEmail.Text    := FCliente.Email;
  edtTelefone.Text := FCliente.Telefone;
  edtEndereco.Text := FCliente.Endereco;
  edtCidade.Text   := FCliente.Cidade;
  edtUf.Text       := FCliente.Uf;
  edtCep.Text      := FCliente.Cep;
  chkAtivo.Checked := FCliente.Ativo;
end;

procedure TFrmCadClienteEdit.AplicarParaEntidade;
begin
  FCliente.Nome     := edtNome.Text;
  FCliente.CpfCnpj  := edtCpfCnpj.Text;
  FCliente.Email    := edtEmail.Text;
  FCliente.Telefone := edtTelefone.Text;
  FCliente.Endereco := edtEndereco.Text;
  FCliente.Cidade   := edtCidade.Text;
  FCliente.Uf       := edtUf.Text;
  FCliente.Cep      := edtCep.Text;
  FCliente.Ativo    := chkAtivo.Checked;
end;

procedure TFrmCadClienteEdit.btnSalvarClick(Sender: TObject);
begin
  try
    AplicarParaEntidade;
    FService.Salvar(FCliente);
    ModalResult := mrOk;
  except
    on E: EValidationException do
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
    on E: EAppException do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TFrmCadClienteEdit.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
