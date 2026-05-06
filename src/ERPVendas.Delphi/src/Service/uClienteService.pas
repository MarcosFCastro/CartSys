unit uClienteService;

{ ----------------------------------------------------------------------------
  Service - regras de negocio + orquestracao do DAO.
  Forms NUNCA falam com DAO direto.
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils, System.Generics.Collections,
  uCliente, uClienteDAO;

type
  IClienteService = interface
    ['{A8E1B8C1-7B72-4E5F-9A1F-1E5C2D8E3F4A}']
    function Salvar(ACliente: TCliente): Integer;
    procedure Excluir(AId: Integer);
    function BuscarPorId(AId: Integer): TCliente;
    function Listar(const AFiltro: string = ''): TObjectList<TCliente>;
  end;

  TClienteService = class(TInterfacedObject, IClienteService)
  strict private
    FDAO: TClienteDAO;
    FOwnsDAO: Boolean;
  public
    constructor Create(ADAO: TClienteDAO; AOwnsDAO: Boolean = False);
    destructor Destroy; override;

    function Salvar(ACliente: TCliente): Integer;
    procedure Excluir(AId: Integer);
    function BuscarPorId(AId: Integer): TCliente;
    function Listar(const AFiltro: string = ''): TObjectList<TCliente>;
  end;

implementation

uses
  uExceptions;

{ TClienteService }

constructor TClienteService.Create(ADAO: TClienteDAO; AOwnsDAO: Boolean);
begin
  inherited Create;
  FDAO := ADAO;
  FOwnsDAO := AOwnsDAO;
end;

destructor TClienteService.Destroy;
begin
  if FOwnsDAO then
    FDAO.Free;
  inherited;
end;

function TClienteService.Salvar(ACliente: TCliente): Integer;
begin
  ACliente.Validar;

  if FDAO.ExistePorCpfCnpj(ACliente.CpfCnpj, ACliente.Id) then
    raise EBusinessException.CreateFmt(
      'Ja existe outro cliente com o CPF/CNPJ %s.', [ACliente.CpfCnpj]);

  if ACliente.Id <= 0 then
    Result := FDAO.Inserir(ACliente)
  else
  begin
    FDAO.Atualizar(ACliente);
    Result := ACliente.Id;
  end;
end;

procedure TClienteService.Excluir(AId: Integer);
begin
  // Soft delete - preserva integridade referencial com vendas historicas.
  FDAO.DesativarLogicamente(AId);
end;

function TClienteService.BuscarPorId(AId: Integer): TCliente;
begin
  Result := FDAO.BuscarPorId(AId);
  if Result = nil then
    raise ENotFoundException.CreateFmt('Cliente id %d nao encontrado.', [AId]);
end;

function TClienteService.Listar(const AFiltro: string): TObjectList<TCliente>;
begin
  Result := FDAO.Listar(AFiltro);
end;

end.
