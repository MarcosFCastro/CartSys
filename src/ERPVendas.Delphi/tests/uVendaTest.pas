unit uVendaTest;

{ ----------------------------------------------------------------------------
  Testes unitarios da entidade Venda - validacao e calculo de totais.
  Framework: DUnitX.
  ---------------------------------------------------------------------------- }

interface

uses
  DUnitX.TestFramework,
  uVenda, uCliente, uProduto;

type
  [TestFixture]
  TVendaTest = class
  private
    function CriarClienteValido: TCliente;
    function CriarProdutoValido(const ACodigo: string; APreco: Currency): TProduto;
  public
    [Test]
    procedure CalculoTotal_SomaItensSubtraiDesconto;

    [Test]
    procedure ValidarSemItens_DeveLancarExcecao;

    [Test]
    procedure ValidarSemCliente_DeveLancarExcecao;

    [Test]
    procedure DescontoMaiorQueTotal_DeveLancarExcecao;

    [Test]
    procedure PodeQuitar_VendaPendente_DeveSerVerdadeiro;

    [Test]
    procedure PodeQuitar_VendaQuitada_DeveSerFalso;

    [Test]
    procedure ItemComQuantidadeZero_DeveLancarExcecao;
  end;

implementation

uses
  System.SysUtils,
  uExceptions;

{ TVendaTest }

function TVendaTest.CriarClienteValido: TCliente;
begin
  Result := TCliente.Create;
  Result.Id := 1;
  Result.Nome := 'Cliente Teste';
  Result.CpfCnpj := '12345678901';
end;

function TVendaTest.CriarProdutoValido(const ACodigo: string;
  APreco: Currency): TProduto;
begin
  Result := TProduto.Create;
  Result.Id := 1;
  Result.Codigo := ACodigo;
  Result.Descricao := 'Produto de teste ' + ACodigo;
  Result.PrecoVenda := APreco;
end;

procedure TVendaTest.CalculoTotal_SomaItensSubtraiDesconto;
var
  LVenda: TVenda;
begin
  LVenda := TVenda.Create;
  try
    LVenda.DefinirCliente(CriarClienteValido, True);
    LVenda.AdicionarItem(CriarProdutoValido('P1', 100), 2, 100, 0, True); // 200
    LVenda.AdicionarItem(CriarProdutoValido('P2', 50),  4, 50,  10, True); // 190
    LVenda.Desconto := 30;
    LVenda.Recalcular;

    Assert.AreEqual(Currency(390), LVenda.ValorTotal,    'Total bruto');
    Assert.AreEqual(Currency(360), LVenda.ValorLiquido, 'Total liquido');
  finally
    LVenda.Free;
  end;
end;

procedure TVendaTest.ValidarSemItens_DeveLancarExcecao;
var
  LVenda: TVenda;
begin
  LVenda := TVenda.Create;
  try
    LVenda.DefinirCliente(CriarClienteValido, True);
    Assert.WillRaise(
      procedure
      begin
        LVenda.Validar;
      end,
      EValidationException);
  finally
    LVenda.Free;
  end;
end;

procedure TVendaTest.ValidarSemCliente_DeveLancarExcecao;
var
  LVenda: TVenda;
begin
  LVenda := TVenda.Create;
  try
    LVenda.AdicionarItem(CriarProdutoValido('P1', 50), 1, 50, 0, True);
    Assert.WillRaise(
      procedure
      begin
        LVenda.Validar;
      end,
      EValidationException);
  finally
    LVenda.Free;
  end;
end;

procedure TVendaTest.DescontoMaiorQueTotal_DeveLancarExcecao;
var
  LVenda: TVenda;
begin
  LVenda := TVenda.Create;
  try
    LVenda.DefinirCliente(CriarClienteValido, True);
    LVenda.AdicionarItem(CriarProdutoValido('P1', 100), 1, 100, 0, True);
    LVenda.Desconto := 200;
    Assert.WillRaise(
      procedure
      begin
        LVenda.Validar;
      end,
      EValidationException);
  finally
    LVenda.Free;
  end;
end;

procedure TVendaTest.PodeQuitar_VendaPendente_DeveSerVerdadeiro;
var
  LVenda: TVenda;
begin
  LVenda := TVenda.Create;
  try
    LVenda.Status := svPendente;
    Assert.IsTrue(LVenda.PodeQuitar);
  finally
    LVenda.Free;
  end;
end;

procedure TVendaTest.PodeQuitar_VendaQuitada_DeveSerFalso;
var
  LVenda: TVenda;
begin
  LVenda := TVenda.Create;
  try
    LVenda.Status := svQuitada;
    Assert.IsFalse(LVenda.PodeQuitar);
  finally
    LVenda.Free;
  end;
end;

procedure TVendaTest.ItemComQuantidadeZero_DeveLancarExcecao;
var
  LVenda: TVenda;
  LItem: TVendaItem;
begin
  LVenda := TVenda.Create;
  try
    LItem := LVenda.AdicionarItem(CriarProdutoValido('P1', 50), 1, 50, 0, True);
    LItem.Quantidade := 0;
    Assert.WillRaise(
      procedure
      begin
        LItem.Validar;
      end,
      EValidationException);
  finally
    LVenda.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TVendaTest);

end.
