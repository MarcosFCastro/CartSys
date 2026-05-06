unit uFrmCadVenda;

{ ----------------------------------------------------------------------------
  Cadastro de Venda. Forma agregadora: cabecalho + grid de itens.
  Botao "Adicionar Item" abre lookup de produtos. Salvar dispara
  Service.Salvar (que persiste + integra com financeiro em background).
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  cxButtons, cxTextEdit, cxCurrencyEdit, cxDateEdit, cxLookupEdit,
  cxGrid, cxGridLevel, cxGridCustomTableView, cxGridTableView, cxGridCustomView,
  uVenda, uCliente, uProduto, uVendaService;

type
  TFrmCadVenda = class(TForm)
    pnlCabecalho: TPanel;
    lblCliente: TLabel;
    edtCliente: TcxLookupComboBox;
    edtDataVenda: TcxDateEdit;
    edtDesconto: TcxCurrencyEdit;
    edtObservacoes: TcxTextEdit;
    pnlItens: TPanel;
    cxGridItens: TcxGrid;
    cxGridItensLevel: TcxGridLevel;
    btnAddItem: TcxButton;
    btnDelItem: TcxButton;
    pnlTotais: TPanel;
    lblTotal: TLabel;
    lblValorTotal: TLabel;
    pnlBotoes: TPanel;
    btnSalvar: TcxButton;
    btnCancelar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAddItemClick(Sender: TObject);
    procedure btnDelItemClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure edtDescontoPropertiesChange(Sender: TObject);
  private
    FService: IVendaService;
    FProdutoService: IProdutoService;
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
  uConnection, uExceptions, uProdutoDAO, uProdutoService;

class procedure TFrmCadVenda.Listar(AService: IVendaService);
begin
  // Aqui abriria o form de listagem de vendas com grid.
  // Mantido enxuto - a logica eh analoga aos demais cadastros.
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
  LDAO: TProdutoDAO;
begin
  Caption := 'Venda';
  if FVenda = nil then
    FVenda := TVenda.Create;
  // Servico de produto criado internamente para o lookup de itens
  LDAO := TProdutoDAO.Create(TConnection.Instance.Conexao);
  FProdutoService := TProdutoService.Create(LDAO, True);
end;

procedure TFrmCadVenda.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FVenda);
  FService := nil;
  FProdutoService := nil;
end;

procedure TFrmCadVenda.CarregarVendaParaTela;
begin
  if FVenda.Cliente <> nil then
    edtCliente.EditValue := FVenda.Cliente.Id;
  edtDataVenda.Date := FVenda.DtVenda;
  edtDesconto.Value := FVenda.Desconto;
  edtObservacoes.Text := FVenda.Observacoes;
  AtualizarTotais;
end;

procedure TFrmCadVenda.AplicarTelaParaVenda;
begin
  FVenda.DtVenda := edtDataVenda.Date;
  FVenda.Desconto := edtDesconto.Value;
  FVenda.Observacoes := edtObservacoes.Text;
  FVenda.Recalcular;
end;

procedure TFrmCadVenda.AtualizarGridItens;
var
  LView: TcxGridTableView;
  LItem: TVendaItem;
  I: Integer;
begin
  if not Assigned(FVenda) then Exit;
  LView := cxGridItens.Views[0] as TcxGridTableView;
  cxGridItens.BeginUpdate;
  try
    // Indices correspondem as colunas do DFM: 0=#seq,1=Produto,
    // 2=Quantidade,3=PrecoUnitario,4=ValorTotal
    LView.DataController.RecordCount := 0;
    LView.DataController.RecordCount := FVenda.Itens.Count;
    for I := 0 to FVenda.Itens.Count - 1 do
    begin
      LItem := FVenda.Itens[I];
      LView.DataController.Values[I, 0] := I + 1;
      LView.DataController.Values[I, 1] := LItem.Produto.Descricao;
      LView.DataController.Values[I, 2] := LItem.Quantidade;
      LView.DataController.Values[I, 3] := LItem.PrecoUnitario;
      LView.DataController.Values[I, 4] := LItem.ValorTotal;
    end;
  finally
    cxGridItens.EndUpdate;
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
    // Transfere posse para fora da lista antes de libera-la
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
    Format('Preco unitario (padrao R$ %.2f):', [LProduto.PrecoVenda]),
    FormatFloat('0.00', LProduto.PrecoVenda));
  if not TryStrToCurr(SPreco, LPreco) or (LPreco < 0) then
    LPreco := LProduto.PrecoVenda;

  // FVenda assume posse do produto (AOwnsProduto=True)
  FVenda.AdicionarItem(LProduto, LQtd, LPreco, 0, True);
  AtualizarTotais;
end;

procedure TFrmCadVenda.btnDelItemClick(Sender: TObject);
var
  LView: TcxGridTableView;
  LIdx: Integer;
begin
  LView := cxGridItens.Views[0] as TcxGridTableView;
  LIdx := LView.DataController.FocusedRecordIndex;
  if LIdx < 0 then Exit;
  if MessageDlg('Remover item selecionado?', mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then Exit;
  FVenda.RemoverItem(LIdx);
  AtualizarTotais;
end;

procedure TFrmCadVenda.edtDescontoPropertiesChange(Sender: TObject);
begin
  FVenda.Desconto := edtDesconto.Value;
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
