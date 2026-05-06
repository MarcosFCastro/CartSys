unit uProduto;

interface

uses
  System.SysUtils;

type
  TProduto = class
  strict private
    FId: Integer;
    FCodigo: string;
    FDescricao: string;
    FUnidade: string;
    FPrecoVenda: Currency;
    FEstoque: Double;
    FAtivo: Boolean;
    FDtCadastro: TDateTime;
  public
    constructor Create;
    procedure Validar;

    property Id: Integer read FId write FId;
    property Codigo: string read FCodigo write FCodigo;
    property Descricao: string read FDescricao write FDescricao;
    property Unidade: string read FUnidade write FUnidade;
    property PrecoVenda: Currency read FPrecoVenda write FPrecoVenda;
    property Estoque: Double read FEstoque write FEstoque;
    property Ativo: Boolean read FAtivo write FAtivo;
    property DtCadastro: TDateTime read FDtCadastro write FDtCadastro;
  end;

implementation

uses
  uExceptions;

{ TProduto }

constructor TProduto.Create;
begin
  inherited;
  FUnidade := 'UN';
  FAtivo := True;
end;

procedure TProduto.Validar;
begin
  if Trim(FCodigo) = '' then
    raise EValidationException.Create('Codigo do produto eh obrigatorio.');
  if Trim(FDescricao) = '' then
    raise EValidationException.Create('Descricao do produto eh obrigatoria.');
  if FPrecoVenda < 0 then
    raise EValidationException.Create('Preco de venda nao pode ser negativo.');
  if Trim(FUnidade) = '' then
    raise EValidationException.Create('Unidade eh obrigatoria.');
end;

end.
