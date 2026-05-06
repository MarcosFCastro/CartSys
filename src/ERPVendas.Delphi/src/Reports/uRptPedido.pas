unit uRptPedido;

{ ----------------------------------------------------------------------------
  Relatorio de Confirmacao de Pedido com ReportBuilder.
  Layout: cabecalho com dados da empresa, dados do cliente, tabela de itens,
  totais, observacoes e rodape. Gera PDF via ppDevicePDF.
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.Classes,
  Data.DB, FireDAC.Comp.Client, FireDAC.Comp.DataSet,
  ppDB, ppDBPipe, ppReport, ppClass, ppDevice, ppPDFDevice,
  uVenda;

type
  TRptPedido = class(TDataModule)
    Report: TppReport;
    QryCabecalho: TFDQuery;
    QryItens: TFDQuery;
    PipeCabecalho: TppDBPipeline;
    PipeItens: TppDBPipeline;
    DSCabecalho: TDataSource;
    DSItens: TDataSource;
  private
    procedure CarregarDadosVenda(AVenda: TVenda; AConexao: TFDConnection);
  public
    { Gera o relatorio em PDF e retorna o caminho do arquivo gravado.
      AConexao deve ser uma conexao exclusiva da thread chamadora. }
    function GerarPdf(AVenda: TVenda; const ACaminhoSaida: string;
      AConexao: TFDConnection): string;
    { Mostra o preview do relatorio a partir da UI (usa conexao principal). }
    procedure Visualizar(AVenda: TVenda);
  end;

implementation

{$R *.dfm}

uses
  uConnection;

{ TRptPedido }

procedure TRptPedido.CarregarDadosVenda(AVenda: TVenda; AConexao: TFDConnection);
begin
  QryCabecalho.Connection := AConexao;
  QryItens.Connection := AConexao;

  QryCabecalho.Close;
  QryCabecalho.SQL.Text :=
    'SELECT V.NUMERO, V.DT_VENDA, V.VALOR_TOTAL, V.DESCONTO, V.VALOR_LIQUIDO, ' +
    '       V.STATUS, V.OBSERVACOES, ' +
    '       C.NOME, C.CPF_CNPJ, C.EMAIL, C.TELEFONE, C.ENDERECO, C.CIDADE, ' +
    '       C.UF, C.CEP ' +
    'FROM VENDAS V ' +
    'INNER JOIN CLIENTES C ON C.ID = V.ID_CLIENTE ' +
    'WHERE V.ID = :ID';
  QryCabecalho.ParamByName('ID').AsInteger := AVenda.Id;
  QryCabecalho.Open;

  QryItens.Close;
  QryItens.SQL.Text :=
    'SELECT VI.QUANTIDADE, VI.PRECO_UNITARIO, VI.DESCONTO, VI.VALOR_TOTAL, ' +
    '       P.CODIGO, P.DESCRICAO, P.UNIDADE ' +
    'FROM VENDAS_ITENS VI ' +
    'INNER JOIN PRODUTOS P ON P.ID = VI.ID_PRODUTO ' +
    'WHERE VI.ID_VENDA = :ID ORDER BY VI.ID';
  QryItens.ParamByName('ID').AsInteger := AVenda.Id;
  QryItens.Open;
end;

function TRptPedido.GerarPdf(AVenda: TVenda; const ACaminhoSaida: string;
  AConexao: TFDConnection): string;
var
  LDevice: TppPDFDevice;
begin
  CarregarDadosVenda(AVenda, AConexao);
  LDevice := TppPDFDevice.Create(nil);
  try
    LDevice.Publisher := Report.Publisher;
    LDevice.FileName := ACaminhoSaida;
    LDevice.PDFSettings.OpenPDFFile := False;
    Report.PrintToDevices;
    Result := ACaminhoSaida;
  finally
    LDevice.Free;
  end;
end;

procedure TRptPedido.Visualizar(AVenda: TVenda);
begin
  CarregarDadosVenda(AVenda, TConnection.Instance.Conexao);
  Report.ShowPrintDialog := False;
  Report.Print;
end;

end.
