unit uExceptions;

{ ----------------------------------------------------------------------------
  Hierarquia de excecoes da aplicacao - permite tratamento especifico
  por camada/causa (validacao vs infraestrutura vs negocio).
  ---------------------------------------------------------------------------- }

interface

uses
  System.SysUtils;

type
  /// Excecao base do dominio.
  EAppException = class(Exception);

  /// Falhas em regras de negocio (entidade invalida, transicao proibida).
  EBusinessException = class(EAppException);

  /// Validacao de campos/entrada do usuario.
  EValidationException = class(EAppException);

  /// Recurso nao encontrado (registro inexistente).
  ENotFoundException = class(EAppException);

  /// Falhas de comunicacao com sistemas externos (REST, SMTP, etc).
  EIntegrationException = class(EAppException)
  strict private
    FStatusHttp: Integer;
    FResponseBody: string;
  public
    constructor Create(const AMsg: string; AStatusHttp: Integer = 0;
      const AResponseBody: string = ''); reintroduce;
    property StatusHttp: Integer read FStatusHttp;
    property ResponseBody: string read FResponseBody;
  end;

  /// Falhas de banco/infra.
  EInfraException = class(EAppException);

implementation

{ EIntegrationException }

constructor EIntegrationException.Create(const AMsg: string; AStatusHttp: Integer;
  const AResponseBody: string);
begin
  inherited Create(AMsg);
  FStatusHttp := AStatusHttp;
  FResponseBody := AResponseBody;
end;

end.
