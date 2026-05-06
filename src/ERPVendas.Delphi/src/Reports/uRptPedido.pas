unit uRptPedido;

{ Relatorio de pedido gerado como HTML (sem dependencia de ReportBuilder).
  O arquivo .html e gravado no diretorio temporario e pode ser anexado
  a e-mails ou aberto no navegador padrao. }

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  FireDAC.Comp.Client,
  uVenda;

type
  TRptPedido = class
  private
    function GerarHtml(AVenda: TVenda): string;
  public
    { Gera o relatorio em HTML e retorna o caminho do arquivo gravado. }
    function GerarPdf(AVenda: TVenda; const ACaminhoSaida: string;
      AConexao: TFDConnection): string;
    { Abre o relatorio no navegador padrao (preview). }
    procedure Visualizar(AVenda: TVenda);
  end;

implementation

uses
  Winapi.ShellAPI, Winapi.Windows;

{ TRptPedido }

function TRptPedido.GerarHtml(AVenda: TVenda): string;
var
  LSb: TStringBuilder;
  LItem: TVendaItem;
begin
  LSb := TStringBuilder.Create;
  try
    LSb.AppendLine('<!DOCTYPE html><html><head>');
    LSb.AppendLine('<meta charset="utf-8">');
    LSb.AppendLine('<title>Pedido</title>');
    LSb.AppendLine('<style>');
    LSb.AppendLine('  body { font-family: Arial, sans-serif; margin: 30px; color: #333; }');
    LSb.AppendLine('  h2 { color: #444; border-bottom: 2px solid #ccc; padding-bottom: 6px; }');
    LSb.AppendLine('  table { border-collapse: collapse; width: 100%; margin-top: 12px; }');
    LSb.AppendLine('  th, td { border: 1px solid #ccc; padding: 6px 10px; }');
    LSb.AppendLine('  th { background: #f0f0f0; text-align: left; }');
    LSb.AppendLine('  td.num { text-align: right; }');
    LSb.AppendLine('  .totais { margin-top: 14px; font-size: 1.05em; }');
    LSb.AppendLine('  .totais b { display: inline-block; width: 160px; }');
    LSb.AppendLine('</style></head><body>');

    LSb.AppendLine('<h2>CartSys &mdash; Relat&oacute;rio de Pedido</h2>');
    LSb.AppendFormat('<p><b>Pedido N&ordm;:</b> %d &nbsp;&nbsp; ' +
      '<b>Data:</b> %s</p>' + sLineBreak,
      [AVenda.Numero, FormatDateTime('dd/mm/yyyy', AVenda.DtVenda)]);

    if Assigned(AVenda.Cliente) then
    begin
      LSb.AppendLine('<h3>Cliente</h3><p>');
      LSb.AppendFormat('<b>Nome:</b> %s<br>' + sLineBreak, [AVenda.Cliente.Nome]);
      LSb.AppendFormat('<b>CPF/CNPJ:</b> %s<br>' + sLineBreak, [AVenda.Cliente.CpfCnpj]);
      LSb.AppendFormat('<b>E-mail:</b> %s</p>' + sLineBreak, [AVenda.Cliente.Email]);
    end;

    LSb.AppendLine('<h3>Itens</h3>');
    LSb.AppendLine('<table><tr><th>#</th><th>Produto</th>' +
      '<th>Qtd</th><th>Pre&ccedil;o Unit.</th><th>Total</th></tr>');
    for LItem in AVenda.Itens do
      LSb.AppendFormat(
        '<tr><td class="num">%s</td><td>%s</td>' +
        '<td class="num">%s</td><td class="num">R$ %.2f</td>' +
        '<td class="num">R$ %.2f</td></tr>' + sLineBreak,
        [LItem.Produto.Codigo, LItem.Produto.Descricao,
         FormatFloat('0.##', LItem.Quantidade),
         LItem.PrecoUnitario, LItem.ValorTotal]);
    LSb.AppendLine('</table>');

    LSb.AppendLine('<div class="totais">');
    LSb.AppendFormat('<p><b>Valor bruto:</b> R$ %.2f<br>' + sLineBreak, [AVenda.ValorTotal]);
    LSb.AppendFormat('<b>Desconto:</b> R$ %.2f<br>' + sLineBreak, [AVenda.Desconto]);
    LSb.AppendFormat('<b>Valor l&iacute;quido:</b> R$ %.2f</p></div>' + sLineBreak,
      [AVenda.ValorLiquido]);

    if Trim(AVenda.Observacoes) <> '' then
      LSb.AppendFormat('<p><b>Observa&ccedil;&otilde;es:</b> %s</p>' + sLineBreak,
        [AVenda.Observacoes]);

    LSb.AppendLine('<hr><p><small>CartSys ERP Vendas</small></p>');
    LSb.AppendLine('</body></html>');
    Result := LSb.ToString;
  finally
    LSb.Free;
  end;
end;

function TRptPedido.GerarPdf(AVenda: TVenda; const ACaminhoSaida: string;
  AConexao: TFDConnection): string;
var
  LCaminhoHtml: string;
  LWriter: TStreamWriter;
begin
  LCaminhoHtml := ChangeFileExt(ACaminhoSaida, '.html');
  LWriter := TStreamWriter.Create(LCaminhoHtml, False, TEncoding.UTF8);
  try
    LWriter.Write(GerarHtml(AVenda));
  finally
    LWriter.Free;
  end;
  Result := LCaminhoHtml;
end;

procedure TRptPedido.Visualizar(AVenda: TVenda);
var
  LCaminhoHtml: string;
  LWriter: TStreamWriter;
begin
  LCaminhoHtml := TPath.Combine(TPath.GetTempPath,
    Format('Pedido_%d_preview.html', [AVenda.Numero]));
  LWriter := TStreamWriter.Create(LCaminhoHtml, False, TEncoding.UTF8);
  try
    LWriter.Write(GerarHtml(AVenda));
  finally
    LWriter.Free;
  end;
  ShellExecute(0, 'open', PChar(LCaminhoHtml), nil, nil, SW_SHOWNORMAL);
end;

end.
