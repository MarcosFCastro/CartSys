unit uVendaService;

{ ----------------------------------------------------------------------------
  Service principal de Venda. Orquestra:
  - Persistencia (DAO) em transacao
  - Envio do titulo ao Financeiro (em thread, nao trava UI)
  - Tratamento das callbacks de quitacao/cancelamento vindas do Financeiro
  - Geracao de PDF do pedido + envio por e-mail
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.Classes, System.Threading, System.Generics.Collections,
  FireDAC.Comp.Client,
  uVenda, uVendaDAO, uIntegracaoFinanceiroService;

type
  TNotificacaoVendaEvent = procedure(AIdVenda: Integer; const AMensagem: string) of object;

  IVendaService = interface
    ['{B1F2A3D4-5E6F-4789-A1B2-C3D4E5F6A7B8}']
    function Salvar(AVenda: TVenda): Integer;
    function BuscarPorId(AIdVenda: Integer): TVenda;
    function ListarPorPeriodo(ADtInicio, ADtFim: TDateTime): TObjectList<TVenda>;
    procedure ProcessarQuitacao(AIdVenda: Integer; ADtQuitacao: TDateTime;
      const AFormaPagamento: string);
    procedure ProcessarCancelamento(AIdVenda: Integer; const AMotivo: string);
  end;

  TVendaService = class(TInterfacedObject, IVendaService)
  strict private
    FConexao: TFDConnection;
    FDAO: TVendaDAO;
    FOnIntegracaoConcluida: TNotificacaoVendaEvent;
    FOnEmailEnviado: TNotificacaoVendaEvent;

    procedure EnviarTituloAssincrono(AIdVenda: Integer);
    procedure GerarPdfEEnviarEmail(AIdVenda: Integer);
    function ConstruirCorpoEmail(AVenda: TVenda): string;
  public
    constructor Create(AConexao: TFDConnection);
    destructor Destroy; override;

    function Salvar(AVenda: TVenda): Integer;
    function BuscarPorId(AIdVenda: Integer): TVenda;
    function ListarPorPeriodo(ADtInicio, ADtFim: TDateTime): TObjectList<TVenda>;
    procedure ProcessarQuitacao(AIdVenda: Integer; ADtQuitacao: TDateTime;
      const AFormaPagamento: string);
    procedure ProcessarCancelamento(AIdVenda: Integer; const AMotivo: string);

    property OnIntegracaoConcluida: TNotificacaoVendaEvent
      read FOnIntegracaoConcluida write FOnIntegracaoConcluida;
    property OnEmailEnviado: TNotificacaoVendaEvent
      read FOnEmailEnviado write FOnEmailEnviado;
  end;

implementation

uses
  System.IOUtils,
  uConnection, uLogger, uExceptions, uEmailService, uRptPedido;

{ TVendaService }

constructor TVendaService.Create(AConexao: TFDConnection);
begin
  inherited Create;
  FConexao := AConexao;
  FDAO := TVendaDAO.Create(AConexao);
end;

destructor TVendaService.Destroy;
begin
  FDAO.Free;
  inherited;
end;

function TVendaService.Salvar(AVenda: TVenda): Integer;
begin
  AVenda.Validar;

  // Persiste cabecalho + itens em transacao gerenciada pelo DAO
  Result := FDAO.Inserir(AVenda);
  TLogger.Instance.Info('Venda %d (numero %d) gravada', [Result, AVenda.Numero]);

  // Dispara integracao em background - nao trava a UI nem aborta a venda
  // se o financeiro estiver fora.
  EnviarTituloAssincrono(Result);
end;

procedure TVendaService.EnviarTituloAssincrono(AIdVenda: Integer);
begin
  TTask.Run(
    procedure
    var
      LConexao: TFDConnection;
      LIntegracao: TIntegracaoFinanceiroService;
      LDAO: TVendaDAO;
      LVenda: TVenda;
      LResultado: TResultadoIntegracao;
    begin
      // Conexao propria para a thread
      LConexao := TConnection.Instance.NovaConexao;
      try
        LDAO := TVendaDAO.Create(LConexao);
        LIntegracao := TIntegracaoFinanceiroService.Create(LConexao);
        try
          LVenda := LDAO.BuscarPorId(AIdVenda);
          if LVenda = nil then
          begin
            TLogger.Instance.Error(
              'Venda %d nao encontrada para envio ao financeiro', [AIdVenda]);
            Exit;
          end;
          try
            LResultado := LIntegracao.EnviarTitulo(LVenda);
            if LResultado.Sucesso then
              TLogger.Instance.Info(
                'Titulo da venda %d criado no financeiro (id %d)',
                [AIdVenda, LResultado.IdTituloFinanceiro])
            else
              TLogger.Instance.Warn(
                'Integracao da venda %d com falha: %s',
                [AIdVenda, LResultado.MensagemErro]);

            if Assigned(FOnIntegracaoConcluida) then
              TThread.Queue(nil,
                procedure
                begin
                  FOnIntegracaoConcluida(AIdVenda, LResultado.MensagemErro);
                end);
          finally
            LVenda.Free;
          end;
        finally
          LIntegracao.Free;
          LDAO.Free;
        end;
      finally
        LConexao.Free;
      end;
    end);
end;

procedure TVendaService.ProcessarQuitacao(AIdVenda: Integer; ADtQuitacao: TDateTime;
  const AFormaPagamento: string);
var
  LVenda: TVenda;
begin
  LVenda := FDAO.BuscarPorId(AIdVenda);
  if LVenda = nil then
    raise ENotFoundException.CreateFmt('Venda %d nao encontrada.', [AIdVenda]);
  try
    if not LVenda.PodeQuitar then
      raise EBusinessException.CreateFmt(
        'Venda %d nao pode ser quitada (status atual: %s).',
        [AIdVenda, LVenda.Status.ToString]);

    FDAO.AtualizarQuitacao(AIdVenda, ADtQuitacao);
    TLogger.Instance.Info(
      'Venda %d quitada (forma: %s)', [AIdVenda, AFormaPagamento]);
  finally
    LVenda.Free;
  end;

  // Pos-quitacao: gera PDF e envia por e-mail (em background)
  TTask.Run(
    procedure
    begin
      try
        GerarPdfEEnviarEmail(AIdVenda);
      except
        on E: Exception do
          TLogger.Instance.Error('Falha pos-quitacao da venda', E);
      end;
    end);
end;

procedure TVendaService.ProcessarCancelamento(AIdVenda: Integer; const AMotivo: string);
var
  LVenda: TVenda;
begin
  LVenda := FDAO.BuscarPorId(AIdVenda);
  if LVenda = nil then
    raise ENotFoundException.CreateFmt('Venda %d nao encontrada.', [AIdVenda]);
  try
    if not LVenda.PodeCancelar then
      raise EBusinessException.CreateFmt(
        'Venda %d nao pode ser cancelada (status atual: %s).',
        [AIdVenda, LVenda.Status.ToString]);

    FDAO.AtualizarCancelamento(AIdVenda, Now);
    TLogger.Instance.Info(
      'Venda %d cancelada. Motivo: %s', [AIdVenda, AMotivo]);
  finally
    LVenda.Free;
  end;
end;

function TVendaService.BuscarPorId(AIdVenda: Integer): TVenda;
begin
  Result := FDAO.BuscarPorId(AIdVenda);
  if Result = nil then
    raise ENotFoundException.CreateFmt('Venda %d nao encontrada.', [AIdVenda]);
end;

function TVendaService.ListarPorPeriodo(ADtInicio, ADtFim: TDateTime): TObjectList<TVenda>;
begin
  Result := FDAO.ListarPorPeriodo(ADtInicio, ADtFim);
end;

function TVendaService.ConstruirCorpoEmail(AVenda: TVenda): string;
var
  LSb: TStringBuilder;
  LItem: TVendaItem;
begin
  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('<html><body style="font-family: Arial, sans-serif;">');
    LSb.AppendFormat('<h2>Confirmacao do Pedido #%d</h2>', [AVenda.Numero]);
    LSb.AppendFormat('<p>Ola, <b>%s</b>,</p>', [AVenda.Cliente.Nome]);
    LSb.AppendLine('<p>Recebemos a confirmacao de pagamento do seu pedido. Segue o resumo:</p>');
    LSb.AppendLine('<table border="1" cellpadding="6" cellspacing="0" style="border-collapse: collapse;">');
    LSb.AppendLine('<tr style="background:#eee;"><th>Produto</th><th>Qtd</th><th>Preco Unit.</th><th>Total</th></tr>');
    for LItem in AVenda.Itens do
      LSb.AppendFormat('<tr><td>%s</td><td align="right">%.4f</td>' +
                       '<td align="right">R$ %.2f</td><td align="right">R$ %.2f</td></tr>',
        [LItem.Produto.Descricao, LItem.Quantidade, LItem.PrecoUnitario, LItem.ValorTotal]);
    LSb.AppendLine('</table>');
    LSb.AppendFormat('<p><b>Total da venda:</b> R$ %.2f<br/>', [AVenda.ValorTotal]);
    LSb.AppendFormat('<b>Desconto:</b> R$ %.2f<br/>', [AVenda.Desconto]);
    LSb.AppendFormat('<b>Valor liquido pago:</b> R$ %.2f</p>', [AVenda.ValorLiquido]);
    LSb.AppendLine('<p>Em anexo segue o relatorio em PDF.</p>');
    LSb.AppendLine('<p>Atenciosamente,<br/>CartSys</p>');
    LSb.AppendLine('</body></html>');
    Result := LSb.ToString;
  finally
    LSb.Free;
  end;
end;

procedure TVendaService.GerarPdfEEnviarEmail(AIdVenda: Integer);
var
  LConexao: TFDConnection;
  LDAO: TVendaDAO;
  LVenda: TVenda;
  LRpt: TRptPedido;
  LEmail: TEmailService;
  LAnexos: TStringList;
  LCaminhoPdf: string;
begin
  LConexao := TConnection.Instance.NovaConexao;
  try
    LDAO := TVendaDAO.Create(LConexao);
    try
      LVenda := LDAO.BuscarPorId(AIdVenda);
      if LVenda = nil then
        Exit;
      try
        if Trim(LVenda.Cliente.Email) = '' then
        begin
          TLogger.Instance.Warn(
            'Cliente da venda %d sem e-mail. Pulando envio.', [AIdVenda]);
          Exit;
        end;

        LCaminhoPdf := TPath.Combine(
          TPath.GetTempPath,
          Format('Pedido_%d.pdf', [LVenda.Numero]));

        // Gera PDF via ReportBuilder usando a conexao exclusiva desta thread
        LRpt := TRptPedido.Create(nil);
        try
          LCaminhoPdf := LRpt.GerarPdf(LVenda, LCaminhoPdf, LConexao);
          TLogger.Instance.Info(
            'PDF da venda %d gerado em %s', [AIdVenda, LCaminhoPdf]);
        finally
          LRpt.Free;
        end;

        LEmail := TEmailService.Create;
        LAnexos := TStringList.Create;
        try
          if FileExists(LCaminhoPdf) then
            LAnexos.Add(LCaminhoPdf);
          LEmail.Enviar(
            LVenda.Cliente.Email,
            Format('Confirmacao do Pedido #%d', [LVenda.Numero]),
            ConstruirCorpoEmail(LVenda),
            LAnexos);

          LDAO.MarcarEmailEnviado(AIdVenda);
          TLogger.Instance.Info(
            'E-mail de confirmacao enviado para %s (venda %d)',
            [LVenda.Cliente.Email, AIdVenda]);

          if Assigned(FOnEmailEnviado) then
            TThread.Queue(nil,
              procedure
              begin
                FOnEmailEnviado(AIdVenda, 'E-mail enviado com sucesso.');
              end);
        finally
          LAnexos.Free;
          LEmail.Free;
        end;
      finally
        LVenda.Free;
      end;
    finally
      LDAO.Free;
    end;
  finally
    LConexao.Free;
  end;
end;

end.
