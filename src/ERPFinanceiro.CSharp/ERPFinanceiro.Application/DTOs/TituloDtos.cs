using System;

namespace ERPFinanceiro.Application.DTOs
{
    /// <summary>Recebido pelo POST /api/v1/titulos.</summary>
    public class CriarTituloDto
    {
        public int IdVendaExterna { get; set; }
        public int NumeroVenda { get; set; }
        public int IdClienteExterno { get; set; }
        public string NomeCliente { get; set; }
        public string DocCliente { get; set; }
        public string EmailCliente { get; set; }
        public decimal Valor { get; set; }
        public DateTime DtVencimento { get; set; }
        public string Observacoes { get; set; }
    }

    /// <summary>Retornado nas operacoes de titulo.</summary>
    public class TituloResponseDto
    {
        public int Id { get; set; }
        public int IdVendaExterna { get; set; }
        public int NumeroVenda { get; set; }
        public int IdClienteExterno { get; set; }
        public string NomeCliente { get; set; }
        public string EmailCliente { get; set; }
        public decimal Valor { get; set; }
        public DateTime DtEmissao { get; set; }
        public DateTime DtVencimento { get; set; }
        public DateTime? DtQuitacao { get; set; }
        public DateTime? DtCancelamento { get; set; }
        public string Status { get; set; }
        public string FormaPagamento { get; set; }
    }

    /// <summary>POST /api/v1/titulos/{id}/quitar.</summary>
    public class QuitarTituloDto
    {
        public string FormaPagamento { get; set; }
        public string Observacao { get; set; }
    }

    /// <summary>POST /api/v1/titulos/{id}/cancelar.</summary>
    public class CancelarTituloDto
    {
        public string Motivo { get; set; }
    }

    /// <summary>Resposta paginada padrao.</summary>
    public class PagedResponseDto<T>
    {
        public int Page { get; set; }
        public int PageSize { get; set; }
        public int TotalItems { get; set; }
        public int TotalPages { get; set; }
        public System.Collections.Generic.IList<T> Items { get; set; }
    }
}
