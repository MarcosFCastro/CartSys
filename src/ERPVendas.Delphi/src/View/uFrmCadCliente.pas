unit uFrmCadCliente;

{ ----------------------------------------------------------------------------
  Cadastro de Cliente. View nao acessa DAO direto - sempre via Service.
  Padrao: classe expoe metodos de classe Listar/Editar que cuidam do ciclo
  de vida do form, evitando vazamentos.
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxContainer, cxEdit, cxTextEdit,
  cxButtons, cxGrid, cxGridLevel, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGridCustomView,
  uCliente, uClienteService;

type
  TFrmCadCliente = class(TForm)
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
    procedure edtFiltroPropertiesChange(Sender: TObject);
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
  uConnection, uClienteDAO, uExceptions, uFrmCadClienteEdit;

{ TFrmCadCliente }

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
  LView: TcxGridTableView;
  LCliente: TCliente;
  I: Integer;
  LAtivoStr: string;
begin
  FreeAndNil(FClientes);
  FClientes := FService.Listar(edtFiltro.Text);

  LView := cxGrid.Views[0] as TcxGridTableView;
  cxGrid.BeginUpdate;
  try
    // Zera linhas antes de repovoar para evitar linhas fantasma
    LView.DataController.RecordCount := 0;
    LView.DataController.RecordCount := FClientes.Count;
    for I := 0 to FClientes.Count - 1 do
    begin
      LCliente := FClientes[I];
      if LCliente.Ativo then LAtivoStr := 'Sim' else LAtivoStr := 'Nao';
      // Indices correspondem as colunas declaradas no DFM (0=Id,1=Nome,
      // 2=CpfCnpj,3=Email,4=Telefone,5=Ativo)
      LView.DataController.Values[I, 0] := LCliente.Id;
      LView.DataController.Values[I, 1] := LCliente.Nome;
      LView.DataController.Values[I, 2] := LCliente.CpfCnpj;
      LView.DataController.Values[I, 3] := LCliente.Email;
      LView.DataController.Values[I, 4] := LCliente.Telefone;
      LView.DataController.Values[I, 5] := LAtivoStr;
    end;
  finally
    cxGrid.EndUpdate;
  end;
end;

function TFrmCadCliente.ClienteSelecionado: TCliente;
var
  LView: TcxGridTableView;
  LIdx: Integer;
begin
  Result := nil;
  LView := cxGrid.Views[0] as TcxGridTableView;
  LIdx := LView.DataController.FocusedRecordIndex;
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
  if LSelecionado = nil then
    Exit;
  if MessageDlg(Format('Inativar o cliente %s?', [LSelecionado.Nome]),
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
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

procedure TFrmCadCliente.edtFiltroPropertiesChange(Sender: TObject);
begin
  CarregarGrid;
end;

end.
