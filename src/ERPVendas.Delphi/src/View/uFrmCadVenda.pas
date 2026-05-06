unit uFrmCadVenda;

{ Cadastro de Venda: cabecalho + grid de itens.
  Salvar dispara Service.Salvar (persiste + integra com financeiro em background). }

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.ComCtrls,
  uVenda, uCliente, uProduto, uVendaService, uClienteService, uProdutoService;

type
  TFrmCadVenda = class(TForm)
    pnlCabecalho: TPanel;
    lblCliente: TLabel;
    cmbCliente: TComboBox;
    lblDataVenda: TLabel;
    edtDataVenda: TDateTimePicker;
    lblDesconto: TLabel;
    edtDesconto: TEdit;
    lblObservacoes: TLabel;
    edtObservacoes: TEdit;
    pnlItens: TPanel;
    lvItens: TListView;
    btnAddItem: TButton;
    btnDelItem: TButton;
    pnlTotais: TPanel;
    lblTotal: TLabel;
    lblValorTotal: TLabel;
    pnlBotoes: TPanel;
    btnSalvar: TButton;
    btnCancelar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAddItemClick(Sender: TObject);
    procedure btnDelItemClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure edtDescontoChange(Sender: TObject);
  private
    FService: IVendaService;
    FProdutoService: IProdutoService;
    FClienteService: IClienteService;
    FClientes: TObjectList<TCliente>;
    FVenda: TVenda;
    procedure AtualizarTotais;
    procedure AtualizarGridItens;
    procedure CarregarVendaParaTela;
    procedure AplicarTelaParaVenda;
  public
    class procedure Listar(AService: IVendaService);
    class procedure Editar(AService: IVendaService; AVenda: TVenda);
  end;

implementation

{$R *.dfm}

uses
  System.UITypes,
  uConnection, uExceptions, uProdutoDAO, uClienteDAO;

class procedure TFrmCadVenda.Listar(AService: IVendaService);
var
  LVenda: TVenda;
begin
  LVenda := TVenda.Create;
  try
    Editar(AService, LVenda);
  finally
    LVenda.Free;
  end;
end;

class procedure TFrmCadVenda.Editar(AService: IVendaService; AVenda: TVenda);
var
  LFrm: TFrmCadVenda;
begin
  LFrm := TFrmCadVenda.Create(nil);
  try
    LFrm.FService := AService;
    LFrm.FVenda := AVenda;
    LFrm.CarregarVendaParaTela;
    LFrm.ShowModal;
  finally
    LFrm.Free;
  end;
end;

procedure TFrmCadVenda.FormCreate(Sender: TObject);
var
  LProdDAO: TProdutoDAO;
  LClienteDAO: TClienteDAO;
  LCliente: TCliente;
begin
  Caption := 'Venda';
  LProdDAO := TProdutoDAO.Create(TConnection.Instance.Conexao);
  FProdutoService := TProdutoService.Create(LProdDAO, True);

  LClienteDAO := TClienteDAO.Create(TConnection.Instance.Conexao);
  FClienteService := TClienteService.Create(LClienteDAO, True);
  FClientes := FClienteService.Listar;

  cmbCliente.Items.Clear;
  for LCliente in FClientes do
    cmbCliente.Items.Add(LCliente.Nome);
end;

procedure TFrmCadVenda.FormDestroy(Sender: TObject);
begin
  // FVenda nao eh de nossa propriedade - o chamador e responsavel por libera-lo.
  FreeAndNil(FClientes);
  FService := nil;
  FProdutoService := nil;
  FClienteService := nil;
end;

procedure TFrmCadVenda.CarregarVendaParaTela;
var
  I: Integer;
begin
  if FVenda.Cliente <> nil then
    for I := 0 to FClientes.Count - 1 do
      if FClientes[I].Id = FVenda.Cliente.Id then
      begin
        cmbCliente.ItemIndex := I;
        Break;
      end;
  edtDataVenda.Date := FVenda.DtVenda;
  edtDesconto.Text := FormatFloat('0.00', FVenda.Desconto);
  edtObservacoes.Text := FVenda.Observacoes;
  AtualizarTotais;
end;

procedure TFrmCadVenda.AplicarTelaParaVenda;
var
  LIdx: Integer;
begin
  LIdx := cmbCliente.ItemIndex;
  if (LIdx >= 0) and (LIdx < FClientes.Count) then
    FVenda.DefinirCliente(FClientes[LIdx], False);
  FVenda.DtVenda := edtDataVenda.Date;
  FVenda.Desconto := StrToCurrDef(edtDesconto.Text, 0);
  FVenda.Observacoes := edtObservacoes.Text;
  FVenda.Recalcular;
end;

procedure TFrmCadVenda.AtualizarGridItens;
var
  LItem: TVendaItem;
  LLI: TListItem;
  I: Integer;
begin
  if not Assigned(FVenda) then Exit;
  lvItens.Items.BeginUpdate;
  try
    lvItens.Items.Clear;
    for I := 0 to FVenda.Itens.Count - 1 do
    begin
      LItem := FVenda.Itens[I];
      LLI := lvItens.Items.Add;
      LLI.Caption := IntToStr(I + 1);
      LLI.SubItems.Add(LItem.Produto.Descricao);
      LLI.SubItems.Add(FormatFloat('0.##', LItem.Quantidade));
      LLI.SubItems.Add(FormatFloat('0.00', LItem.PrecoUnitario));
      LLI.SubItems.Add(FormatFloat('0.00', LItem.ValorTotal));
    end;
  finally
    lvItens.Items.EndUpdate;
  end;
end;

procedure TFrmCadVenda.AtualizarTotais;
begin
  FVenda.Recalcular;
  lblValorTotal.Caption :=
    Format('Total: R$ %.2f   |   Liquido: R$ %.2f',
      [FVenda.ValorTotal, FVenda.ValorLiquido]);
  AtualizarGridItens;
end;

procedure TFrmCadVenda.btnAddItemClick(Sender: TObject);
var
  LCodigo, SQtd, SPreco: string;
  LQtd: Double;
  LPreco: Currency;
  LLista: TObjectList<TProduto>;
  LProduto: TProduto;
begin
  LCodigo := InputBox('Adicionar Item', 'Codigo do produto:', '');
  if Trim(LCodigo) = '' then Exit;

  LLista := FProdutoService.Listar(LCodigo);
  try
    if LLista.Count = 0 then
    begin
      MessageDlg('Produto nao encontrado: ' + LCodigo, mtWarning, [mbOK], 0);
      Exit;
    end;
    LLista.OwnsObjects := False;
    LProduto := LLista[0];
  finally
    LLista.Free;
  end;

  SQtd := InputBox('Adicionar Item',
    Format('Produto: %s | Qtd:', [LProduto.Descricao]), '1');
  if not TryStrToFloat(SQtd, LQtd) or (LQtd <= 0) then
  begin
    MessageDlg('Quantidade invalida.', mtWarning, [mbOK], 0);
    LProduto.Free;
    Exit;
  end;

  SPreco := InputBox('Adicionar Item',
    Format('Preco unitario (padrao %.2f):', [LProduto.PrecoVenda]),
    FormatFloat('0.00', LProduto.PrecoVenda));
  if not TryStrToCurr(SPreco, LPreco) or (LPreco < 0) then
    LPreco := LProduto.PrecoVenda;

  FVenda.AdicionarItem(LProduto, LQtd, LPreco, 0, True);
  AtualizarTotais;
end;

procedure TFrmCadVenda.btnDelItemClick(Sender: TObject);
var
  LIdx: Integer;
begin
  if lvItens.Selected = nil then Exit;
  LIdx := lvItens.Selected.Index;
  if MessageDlg('Remover item selecionado?', mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then Exit;
  FVenda.RemoverItem(LIdx);
  AtualizarTotais;
end;

procedure TFrmCadVenda.edtDescontoChange(Sender: TObject);
begin
  if not Assigned(FVenda) then Exit;
  FVenda.Desconto := StrToCurrDef(edtDesconto.Text, 0);
  AtualizarTotais;
end;

procedure TFrmCadVenda.btnSalvarClick(Sender: TObject);
begin
  try
    AplicarTelaParaVenda;
    FService.Salvar(FVenda);
    MessageDlg(Format('Venda %d gravada. Integracao com o financeiro ' +
      'em andamento em segundo plano.', [FVenda.Numero]),
      mtInformation, [mbOK], 0);
    ModalResult := mrOk;
  except
    on E: EValidationException do
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
    on E: EAppException do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TFrmCadVenda.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
