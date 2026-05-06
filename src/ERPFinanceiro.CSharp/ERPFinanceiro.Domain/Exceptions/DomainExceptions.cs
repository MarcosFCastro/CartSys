using System;

namespace ERPFinanceiro.Domain.Exceptions
{
    /// <summary>Excecao base do dominio.</summary>
    public class DomainException : Exception
    {
        public DomainException(string message) : base(message) { }
    }

    /// <summary>Falha em regra de negocio (transicao invalida, conflito).</summary>
    public class BusinessException : DomainException
    {
        public BusinessException(string message) : base(message) { }
    }

    /// <summary>Validacao de entrada (DTO mal formado, campo obrigatorio).</summary>
    public class ValidationException : DomainException
    {
        public ValidationException(string message) : base(message) { }
    }

    /// <summary>Recurso nao encontrado.</summary>
    public class NotFoundException : DomainException
    {
        public NotFoundException(string message) : base(message) { }
    }

    /// <summary>Falha em comunicacao com sistemas externos.</summary>
    public class IntegrationException : DomainException
    {
        public int? StatusHttp { get; }
        public string ResponseBody { get; }

        public IntegrationException(string message, int? statusHttp = null, string responseBody = null)
            : base(message)
        {
            StatusHttp = statusHttp;
            ResponseBody = responseBody;
        }
    }
}
