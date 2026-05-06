unit uIntegracaoFinanceiroService;

{ ----------------------------------------------------------------------------
  Service responsavel por conversar com o ERP Financeiro via REST.
  Encapsula:
  - Serializacao da venda em JSON conforme contrato
  - Chamada com retry (delegada ao TRESTClienteHTTP)
  - Logging em LOG_INTEGRACAO
  - Tratamento de erros e atualizacao de status da venda
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.JSON, System.DateUtils,
  FireDAC.Comp.Client,
  uVenda, uRESTClient, uLogIntegracaoDAO, uVendaDAO;

type
  TResultadoIntegracao = record
    Sucesso: Boolean;
    IdTituloFinanceiro: Integer;
    MensagemErro: string;
    StatusHttp: Integer;
  end;

  TIntegracaoFinanceiroService = class
  strict private
    FConexao: TFDConnection;
    FCliente: TRESTClienteHTTP;
    FLogDAO: TLogIntegracaoDAO;
    FVendaDAO: TVendaDAO;

    function VendaParaJson(AVenda: TVenda): string;
    function ExtrairIdResposta(const AJson: string): Integer;
  public
    constructor Create(AConexao: TFDConnection);
    destructor Destroy; override;

    function EnviarTitulo(AVenda: TVenda): TResultadoIntegracao;
  end;

implementation

uses
  uConfig, uLogger, uExceptions;

const
  TIPO_LOG = 'ENVIO_TITULO';
  ENDPOINT_TITULOS = '/api/v1/titulos';

{ TIntegracaoFinanceiroService }

constructor TIntegracaoFinanceiroService.Create(AConexao: TFDConnection);
var
  LCfg: TConfig;
begin
  inherited Create;
  FConexao := AConexao;
  LCfg := TConfig.Instance;
  FCliente := TRESTClienteHTTP.Create(
    LCfg.ApiFinanceiroUrl, LCfg.ApiKey, LCfg.ApiTimeoutSeg);
  FLogDAO := TLogIntegracaoDAO.Create(AConexao);
  FVendaDAO := TVendaDAO.Create(AConexao);
end;

destructor TIntegracaoFinanceiroService.Destroy;
begin
  FVendaDAO.Free;
  FLogDAO.Free;
  FCliente.Free;
  inherited;
end;

function TIntegracaoFinanceiroService.VendaParaJson(AVenda: TVenda): string;
var
  LJson: TJSONObject;
  LDtVencimento: TDateTime;
begin
  // Vencimento padrao: 30 dias apos a data da venda.
  LDtVencimento := IncDay(AVenda.DtVenda, 30);

  LJson := TJSONObject.Create;
  try
    LJson.AddPair('idVendaExterna', TJSONNumber.Create(AVenda.Id));
    LJson.AddPair('numeroVenda', TJSONNumber.Create(AVenda.Numero));
    LJson.AddPair('idClienteExterno', TJSONNumber.Create(AVenda.Cliente.Id));
    LJson.AddPair('nomeCliente', AVenda.Cliente.Nome);
    LJson.AddPair('docCliente', AVenda.Cliente.CpfCnpj);
    LJson.AddPair('emailCliente', AVenda.Cliente.Email);
    LJson.AddPair('valor', TJSONNumber.Create(AVenda.ValorLiquido));
    LJson.AddPair('dtVencimento', FormatDateTime('yyyy-mm-dd', LDtVencimento));
    LJson.AddPair('observacoes', AVenda.Observacoes);
    Result := LJson.ToJSON;
  finally
    LJson.Free;
  end;
end;

function TIntegracaoFinanceiroService.ExtrairIdResposta(const AJson: string): Integer;
var
  LObj: TJSONObject;
  LValor: TJSONValue;
begin
  Result := 0;
  LObj := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  if LObj = nil then
    Exit;
  try
    LValor := LObj.GetValue('id');
    if Assigned(LValor) and (LValor is TJSONNumber) then
      Result := (LValor as TJSONNumber).AsInt;
  finally
    LObj.Free;
  end;
end;

function TIntegracaoFinanceiroService.EnviarTitulo(AVenda: TVenda): TResultadoIntegracao;
var
  LRequest: string;
  LResposta: TRespostaREST;
begin
  Result.Sucesso := False;
  Result.IdTituloFinanceiro := 0;
  Result.MensagemErro := '';
  Result.StatusHttp := 0;

  LRequest := VendaParaJson(AVenda);
  TLogger.Instance.Info('Enviando titulo da venda %d ao financeiro', [AVenda.Id]);

  try
    LResposta := FCliente.Post(ENDPOINT_TITULOS, LRequest);
    Result.StatusHttp := LResposta.StatusCode;

    if LResposta.Sucesso then
    begin
      Result.IdTituloFinanceiro := ExtrairIdResposta(LResposta.Conteudo);
      Result.Sucesso := Result.IdTituloFinanceiro > 0;
      if Result.Sucesso then
        FVendaDAO.AtualizarStatus(AVenda.Id, svPendente, Result.IdTituloFinanceiro)
      else
        Result.MensagemErro := 'Resposta sem id de titulo.';
    end
    else
    begin
      Result.MensagemErro := Format('HTTP %d: %s',
        [LResposta.StatusCode, LResposta.Conteudo]);
      FVendaDAO.AtualizarStatus(AVenda.Id, svIntegracaoPendente);
    end;

    FLogDAO.Registrar(TIPO_LOG, 'SAIDA', ENDPOINT_TITULOS, 'POST',
      LRequest, LResposta.Conteudo, LResposta.StatusCode,
      Result.Sucesso, Result.MensagemErro, AVenda.Id);
  except
    on E: Exception do
    begin
      Result.MensagemErro := E.Message;
      TLogger.Instance.Error('Falha ao enviar titulo', E);
      try
        FVendaDAO.AtualizarStatus(AVenda.Id, svIntegracaoPendente);
        FLogDAO.Registrar(TIPO_LOG, 'SAIDA', ENDPOINT_TITULOS, 'POST',
          LRequest, '', 0, False, E.Message, AVenda.Id);
      except
        // log do log nao pode estourar
      end;
    end;
  end;
end;

end.
