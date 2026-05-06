unit uFrmCadCliente;

{ Cadastro de Cliente. View nao acessa DAO direto - sempre via Service. }

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls,
  uCliente, uClienteService;

type
  TFrmCadCliente = class(TForm)
    pnlFiltro: TPanel;
    lblFiltro: TLabel;
    edtFiltro: TEdit;
    lvClientes: TListView;
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
    FService: IClienteService;
    FClientes: TObjectList<TCliente>;
    procedure CarregarGrid;
    function ClienteSelecionado: TCliente;
    procedure EditarRegistro(ACliente: TCliente);
  public
    class procedure Listar;
  end;

implementation

{$R *.dfm}

uses
  System.UITypes,
  uConnection, uClienteDAO, uExceptions, uFrmCadClienteEdit;

class procedure TFrmCadCliente.Listar;
var
  LFrm: TFrmCadCliente;
begin
  LFrm := TFrmCadCliente.Create(nil);
  try
    LFrm.ShowModal;
  finally
    LFrm.Free;
  end;
end;

procedure TFrmCadCliente.FormCreate(Sender: TObject);
var
  LDAO: TClienteDAO;
begin
  Caption := 'Clientes';
  LDAO := TClienteDAO.Create(TConnection.Instance.Conexao);
  FService := TClienteService.Create(LDAO, True);
  FClientes := TObjectList<TCliente>.Create(True);
  CarregarGrid;
end;

procedure TFrmCadCliente.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FClientes);
  FService := nil;
end;

procedure TFrmCadCliente.CarregarGrid;
var
  LCliente: TCliente;
  LItem: TListItem;
begin
  FreeAndNil(FClientes);
  FClientes := FService.Listar(edtFiltro.Text);

  lvClientes.Items.BeginUpdate;
  try
    lvClientes.Items.Clear;
    for LCliente in FClientes do
    begin
      LItem := lvClientes.Items.Add;
      LItem.Caption := IntToStr(LCliente.Id);
      LItem.SubItems.Add(LCliente.Nome);
      LItem.SubItems.Add(LCliente.CpfCnpj);
      LItem.SubItems.Add(LCliente.Email);
      LItem.SubItems.Add(LCliente.Telefone);
      if LCliente.Ativo then
        LItem.SubItems.Add('Sim')
      else
        LItem.SubItems.Add('Nao');
    end;
  finally
    lvClientes.Items.EndUpdate;
  end;
end;

function TFrmCadCliente.ClienteSelecionado: TCliente;
var
  LIdx: Integer;
begin
  Result := nil;
  if lvClientes.Selected = nil then Exit;
  LIdx := lvClientes.Selected.Index;
  if (LIdx >= 0) and (LIdx < FClientes.Count) then
    Result := FClientes[LIdx];
end;

procedure TFrmCadCliente.EditarRegistro(ACliente: TCliente);
begin
  TFrmCadClienteEdit.Editar(FService, ACliente);
end;

procedure TFrmCadCliente.btnNovoClick(Sender: TObject);
var
  LCliente: TCliente;
begin
  LCliente := TCliente.Create;
  try
    EditarRegistro(LCliente);
    CarregarGrid;
  finally
    LCliente.Free;
  end;
end;

procedure TFrmCadCliente.btnEditarClick(Sender: TObject);
var
  LSelecionado: TCliente;
begin
  LSelecionado := ClienteSelecionado;
  if LSelecionado = nil then
  begin
    MessageDlg('Selecione um cliente.', mtInformation, [mbOK], 0);
    Exit;
  end;
  EditarRegistro(LSelecionado);
  CarregarGrid;
end;

procedure TFrmCadCliente.btnExcluirClick(Sender: TObject);
var
  LSelecionado: TCliente;
begin
  LSelecionado := ClienteSelecionado;
  if LSelecionado = nil then Exit;
  if MessageDlg(Format('Inativar o cliente %s?', [LSelecionado.Nome]),
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  try
    FService.Excluir(LSelecionado.Id);
    CarregarGrid;
  except
    on E: EAppException do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TFrmCadCliente.btnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmCadCliente.edtFiltroChange(Sender: TObject);
begin
  CarregarGrid;
end;

end.
