program ERPVendas;

{ ----------------------------------------------------------------------------
  ERP Vendas - CartSys
  Programador Delphi e C# Senior / Especialista
  ---------------------------------------------------------------------------- }

uses
  Vcl.Forms,
  uFrmPrincipal in 'src\View\uFrmPrincipal.pas' {FrmPrincipal},
  uFrmCadCliente in 'src\View\uFrmCadCliente.pas' {FrmCadCliente},
  uFrmCadProduto in 'src\View\uFrmCadProduto.pas' {FrmCadProduto},
  uFrmCadVenda in 'src\View\uFrmCadVenda.pas' {FrmCadVenda},
  uFrmLogIntegracao in 'src\View\uFrmLogIntegracao.pas' {FrmLogIntegracao},

  uCliente in 'src\Model\Entity\uCliente.pas',
  uProduto in 'src\Model\Entity\uProduto.pas',
  uVenda in 'src\Model\Entity\uVenda.pas',

  uClienteDAO in 'src\Model\DAO\uClienteDAO.pas',
  uProdutoDAO in 'src\Model\DAO\uProdutoDAO.pas',
  uVendaDAO in 'src\Model\DAO\uVendaDAO.pas',
  uLogIntegracaoDAO in 'src\Model\DAO\uLogIntegracaoDAO.pas',

  uClienteService in 'src\Service\uClienteService.pas',
  uProdutoService in 'src\Service\uProdutoService.pas',
  uVendaService in 'src\Service\uVendaService.pas',
  uIntegracaoFinanceiroService in 'src\Service\uIntegracaoFinanceiroService.pas',
  uEmailService in 'src\Service\uEmailService.pas',

  uConfig in 'src\Infra\uConfig.pas',
  uConnection in 'src\Infra\uConnection.pas',
  uExceptions in 'src\Infra\uExceptions.pas',
  uLogger in 'src\Infra\uLogger.pas',
  uRESTClient in 'src\Infra\uRESTClient.pas',
  uRESTServer in 'src\Infra\uRESTServer.pas',

  uRptPedido in 'src\Reports\uRptPedido.pas' {RptPedido: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'CartSys - ERP Vendas';
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.Run;
end.
