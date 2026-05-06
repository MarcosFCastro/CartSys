unit uCliente;

{ ----------------------------------------------------------------------------
  Entidade de dominio Cliente. Sem dependencia de infra/UI.
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils;

type
  TCliente = class
  strict private
    FId: Integer;
    FNome: string;
    FCpfCnpj: string;
    FEmail: string;
    FTelefone: string;
    FEndereco: string;
    FCidade: string;
    FUf: string;
    FCep: string;
    FAtivo: Boolean;
    FDtCadastro: TDateTime;
  public
    constructor Create;

    procedure Validar;
    function EhPessoaJuridica: Boolean;

    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property CpfCnpj: string read FCpfCnpj write FCpfCnpj;
    property Email: string read FEmail write FEmail;
    property Telefone: string read FTelefone write FTelefone;
    property Endereco: string read FEndereco write FEndereco;
    property Cidade: string read FCidade write FCidade;
    property Uf: string read FUf write FUf;
    property Cep: string read FCep write FCep;
    property Ativo: Boolean read FAtivo write FAtivo;
    property DtCadastro: TDateTime read FDtCadastro write FDtCadastro;
  end;

implementation

uses
  uExceptions;

{ TCliente }

constructor TCliente.Create;
begin
  inherited;
  FAtivo := True;
end;

function TCliente.EhPessoaJuridica: Boolean;
var
  LSomenteDigitos: string;
  I: Integer;
begin
  LSomenteDigitos := '';
  for I := 1 to Length(FCpfCnpj) do
    if CharInSet(FCpfCnpj[I], ['0'..'9']) then
      LSomenteDigitos := LSomenteDigitos + FCpfCnpj[I];
  Result := Length(LSomenteDigitos) = 14;
end;

procedure TCliente.Validar;
begin
  if Trim(FNome) = '' then
    raise EValidationException.Create('Nome do cliente eh obrigatorio.');
  if Length(Trim(FNome)) < 3 then
    raise EValidationException.Create('Nome deve ter pelo menos 3 caracteres.');
  if Trim(FCpfCnpj) = '' then
    raise EValidationException.Create('CPF/CNPJ eh obrigatorio.');
  if (FEmail <> '') and (Pos('@', FEmail) = 0) then
    raise EValidationException.Create('E-mail invalido.');
  if (FUf <> '') and (Length(FUf) <> 2) then
    raise EValidationException.Create('UF deve ter 2 caracteres.');
end;

end.
