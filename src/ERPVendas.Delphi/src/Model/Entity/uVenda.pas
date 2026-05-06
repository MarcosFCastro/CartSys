unit uVenda;

{ ----------------------------------------------------------------------------
  Agregado Venda + lista de Itens (composicao - venda eh dona dos itens).
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.Generics.Collections,
  uCliente, uProduto;

type
  TStatusVenda = (svPendente, svQuitada, svCancelada, svIntegracaoPendente);

  TStatusVendaHelper = record helper for TStatusVenda
    function ToString: string;
    class function FromString(const ATexto: string): TStatusVenda; static;
  end;

  TVendaItem = class
  strict private
    FId: Integer;
    FIdVenda: Integer;
    FProduto: TProduto;
    FProdutoOwned: Boolean;
    FQuantidade: Double;
    FPrecoUnitario: Currency;
    FDesconto: Currency;
    FValorTotal: Currency;
    procedure RecalcularTotal;
    procedure SetQuantidade(const AValor: Double);
    procedure SetPrecoUnitario(const AValor: Currency);
    procedure SetDesconto(const AValor: Currency);
  public
    constructor Create(AProduto: TProduto; AOwnsProduto: Boolean = False);
    destructor Destroy; override;

    procedure Validar;

    property Id: Integer read FId write FId;
    property IdVenda: Integer read FIdVenda write FIdVenda;
    property Produto: TProduto read FProduto;
    property Quantidade: Double read FQuantidade write SetQuantidade;
    property PrecoUnitario: Currency read FPrecoUnitario write SetPrecoUnitario;
    property Desconto: Currency read FDesconto write SetDesconto;
    property ValorTotal: Currency read FValorTotal;
  end;

  TVenda = class
  strict private
    FId: Integer;
    FNumero: Integer;
    FCliente: TCliente;
    FClienteOwned: Boolean;
    FDtVenda: TDateTime;
    FValorTotal: Currency;
    FDesconto: Currency;
    FValorLiquido: Currency;
    FStatus: TStatusVenda;
    FIdFinanceiroExterno: Integer;
    FDtQuitacao: TDateTime;
    FDtCancelamento: TDateTime;
    FEmailEnviado: Boolean;
    FDtEmailEnviado: TDateTime;
    FObservacoes: string;
    FItens: TObjectList<TVendaItem>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure DefinirCliente(ACliente: TCliente; AOwnsCliente: Boolean = False);
    function AdicionarItem(AProduto: TProduto; AQuantidade: Double;
      APrecoUnitario: Currency; ADesconto: Currency = 0;
      AOwnsProduto: Boolean = False): TVendaItem;
    procedure RemoverItem(AIndex: Integer);
    procedure Recalcular;
    procedure Validar;
    function PodeQuitar: Boolean;
    function PodeCancelar: Boolean;

    property Id: Integer read FId write FId;
    property Numero: Integer read FNumero write FNumero;
    property Cliente: TCliente read FCliente;
    property DtVenda: TDateTime read FDtVenda write FDtVenda;
    property ValorTotal: Currency read FValorTotal;
    property Desconto: Currency read FDesconto write FDesconto;
    property ValorLiquido: Currency read FValorLiquido;
    property Status: TStatusVenda read FStatus write FStatus;
    property IdFinanceiroExterno: Integer read FIdFinanceiroExterno write FIdFinanceiroExterno;
    property DtQuitacao: TDateTime read FDtQuitacao write FDtQuitacao;
    property DtCancelamento: TDateTime read FDtCancelamento write FDtCancelamento;
    property EmailEnviado: Boolean read FEmailEnviado write FEmailEnviado;
    property DtEmailEnviado: TDateTime read FDtEmailEnviado write FDtEmailEnviado;
    property Observacoes: string read FObservacoes write FObservacoes;
    property Itens: TObjectList<TVendaItem> read FItens;
  end;

implementation

uses
  uExceptions;

{ TStatusVendaHelper }

function TStatusVendaHelper.ToString: string;
begin
  case Self of
    svPendente:           Result := 'PENDENTE';
    svQuitada:            Result := 'QUITADA';
    svCancelada:          Result := 'CANCELADA';
    svIntegracaoPendente: Result := 'INTEGRACAO_PENDENTE';
  else
    Result := 'PENDENTE';
  end;
end;

class function TStatusVendaHelper.FromString(const ATexto: string): TStatusVenda;
begin
  if SameText(ATexto, 'QUITADA') then
    Result := svQuitada
  else if SameText(ATexto, 'CANCELADA') then
    Result := svCancelada
  else if SameText(ATexto, 'INTEGRACAO_PENDENTE') then
    Result := svIntegracaoPendente
  else
    Result := svPendente;
end;

{ TVendaItem }

constructor TVendaItem.Create(AProduto: TProduto; AOwnsProduto: Boolean);
begin
  inherited Create;
  if not Assigned(AProduto) then
    raise EValidationException.Create('Produto eh obrigatorio no item da venda.');
  FProduto := AProduto;
  FProdutoOwned := AOwnsProduto;
  FQuantidade := 1;
  FPrecoUnitario := AProduto.PrecoVenda;
  FDesconto := 0;
  RecalcularTotal;
end;

destructor TVendaItem.Destroy;
begin
  if FProdutoOwned then
    FProduto.Free;
  inherited;
end;

procedure TVendaItem.RecalcularTotal;
begin
  FValorTotal := (FQuantidade * FPrecoUnitario) - FDesconto;
  if FValorTotal < 0 then
    FValorTotal := 0;
end;

procedure TVendaItem.SetQuantidade(const AValor: Double);
begin
  FQuantidade := AValor;
  RecalcularTotal;
end;

procedure TVendaItem.SetPrecoUnitario(const AValor: Currency);
begin
  FPrecoUnitario := AValor;
  RecalcularTotal;
end;

procedure TVendaItem.SetDesconto(const AValor: Currency);
begin
  FDesconto := AValor;
  RecalcularTotal;
end;

procedure TVendaItem.Validar;
begin
  if not Assigned(FProduto) or (FProduto.Id <= 0) then
    raise EValidationException.Create('Produto invalido no item.');
  if FQuantidade <= 0 then
    raise EValidationException.Create('Quantidade do item deve ser maior que zero.');
  if FPrecoUnitario < 0 then
    raise EValidationException.Create('Preco unitario nao pode ser negativo.');
  if FDesconto < 0 then
    raise EValidationException.Create('Desconto do item nao pode ser negativo.');
  if FDesconto > (FQuantidade * FPrecoUnitario) then
    raise EValidationException.Create('Desconto maior que o valor bruto do item.');
end;

{ TVenda }

constructor TVenda.Create;
begin
  inherited;
  FItens := TObjectList<TVendaItem>.Create(True);
  FStatus := svPendente;
  FDtVenda := Now;
end;

destructor TVenda.Destroy;
begin
  FItens.Free;
  if FClienteOwned then
    FCliente.Free;
  inherited;
end;

procedure TVenda.DefinirCliente(ACliente: TCliente; AOwnsCliente: Boolean);
begin
  if FClienteOwned and Assigned(FCliente) then
    FreeAndNil(FCliente);
  FCliente := ACliente;
  FClienteOwned := AOwnsCliente;
end;

function TVenda.AdicionarItem(AProduto: TProduto; AQuantidade: Double;
  APrecoUnitario: Currency; ADesconto: Currency; AOwnsProduto: Boolean): TVendaItem;
begin
  Result := TVendaItem.Create(AProduto, AOwnsProduto);
  Result.Quantidade := AQuantidade;
  Result.PrecoUnitario := APrecoUnitario;
  Result.Desconto := ADesconto;
  FItens.Add(Result);
  Recalcular;
end;

procedure TVenda.RemoverItem(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FItens.Count) then
    raise EValidationException.Create('Indice de item invalido.');
  FItens.Delete(AIndex);
  Recalcular;
end;

procedure TVenda.Recalcular;
var
  LItem: TVendaItem;
begin
  FValorTotal := 0;
  for LItem in FItens do
    FValorTotal := FValorTotal + LItem.ValorTotal;
  FValorLiquido := FValorTotal - FDesconto;
  if FValorLiquido < 0 then
    FValorLiquido := 0;
end;

procedure TVenda.Validar;
var
  LItem: TVendaItem;
begin
  if not Assigned(FCliente) or (FCliente.Id <= 0) then
    raise EValidationException.Create('Cliente eh obrigatorio na venda.');
  if FItens.Count = 0 then
    raise EValidationException.Create('Venda deve ter pelo menos um item.');
  if FDesconto < 0 then
    raise EValidationException.Create('Desconto da venda nao pode ser negativo.');

  for LItem in FItens do
    LItem.Validar;

  Recalcular;

  if FDesconto > FValorTotal then
    raise EValidationException.Create('Desconto maior que o valor total da venda.');
  if FValorLiquido <= 0 then
    raise EValidationException.Create('Valor liquido da venda deve ser maior que zero.');
end;

function TVenda.PodeQuitar: Boolean;
begin
  Result := FStatus in [svPendente, svIntegracaoPendente];
end;

function TVenda.PodeCancelar: Boolean;
begin
  Result := FStatus in [svPendente, svIntegracaoPendente];
end;

end.
