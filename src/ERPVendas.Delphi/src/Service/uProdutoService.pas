unit uProdutoService;

interface

uses
  System.SysUtils, System.Generics.Collections,
  uProduto, uProdutoDAO;

type
  IProdutoService = interface
    ['{F9C2B7E3-3D81-4A92-8C5D-2E7B1A6F9D8C}']
    function Salvar(AProduto: TProduto): Integer;
    procedure Excluir(AId: Integer);
    function BuscarPorId(AId: Integer): TProduto;
    function Listar(const AFiltro: string = ''): TObjectList<TProduto>;
  end;

  TProdutoService = class(TInterfacedObject, IProdutoService)
  strict private
    FDAO: TProdutoDAO;
    FOwnsDAO: Boolean;
  public
    constructor Create(ADAO: TProdutoDAO; AOwnsDAO: Boolean = False);
    destructor Destroy; override;

    function Salvar(AProduto: TProduto): Integer;
    procedure Excluir(AId: Integer);
    function BuscarPorId(AId: Integer): TProduto;
    function Listar(const AFiltro: string = ''): TObjectList<TProduto>;
  end;

implementation

uses
  uExceptions;

{ TProdutoService }

constructor TProdutoService.Create(ADAO: TProdutoDAO; AOwnsDAO: Boolean);
begin
  inherited Create;
  FDAO := ADAO;
  FOwnsDAO := AOwnsDAO;
end;

destructor TProdutoService.Destroy;
begin
  if FOwnsDAO then
    FDAO.Free;
  inherited;
end;

function TProdutoService.Salvar(AProduto: TProduto): Integer;
begin
  AProduto.Validar;

  if FDAO.ExistePorCodigo(AProduto.Codigo, AProduto.Id) then
    raise EBusinessException.CreateFmt(
      'Ja existe outro produto com o codigo %s.', [AProduto.Codigo]);

  if AProduto.Id <= 0 then
    Result := FDAO.Inserir(AProduto)
  else
  begin
    FDAO.Atualizar(AProduto);
    Result := AProduto.Id;
  end;
end;

procedure TProdutoService.Excluir(AId: Integer);
begin
  FDAO.DesativarLogicamente(AId);
end;

function TProdutoService.BuscarPorId(AId: Integer): TProduto;
begin
  Result := FDAO.BuscarPorId(AId);
  if Result = nil then
    raise ENotFoundException.CreateFmt('Produto id %d nao encontrado.', [AId]);
end;

function TProdutoService.Listar(const AFiltro: string): TObjectList<TProduto>;
begin
  Result := FDAO.Listar(AFiltro);
end;

end.
