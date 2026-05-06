using System;

namespace ERPFinanceiro.Domain.Entities
{
    /// <summary>
    /// Historico de movimentos de um titulo (emissao, quitacao, cancelamento).
    /// </summary>
    public class Movimentacao
    {
        public int Id { get; set; }
        public int IdTitulo { get; set; }
        public Titulo Titulo { get; set; }
        public string Tipo { get; set; }
        public decimal Valor { get; set; }
        public DateTime DtMovimentacao { get; set; }
        public string Observacao { get; set; }
        public string Usuario { get; set; }

        public Movimentacao()
        {
            DtMovimentacao = DateTime.Now;
        }

        public static Movimentacao CriarEmissao(Titulo titulo, string usuario) =>
            new Movimentacao
            {
                Titulo = titulo,
                IdTitulo = titulo.Id,
                Tipo = "EMISSAO",
                Valor = titulo.Valor,
                Observacao = "Emissao do titulo",
                Usuario = usuario
            };

        public static Movimentacao CriarQuitacao(Titulo titulo, string observacao, string usuario) =>
            new Movimentacao
            {
                Titulo = titulo,
                IdTitulo = titulo.Id,
                Tipo = "QUITACAO",
                Valor = titulo.Valor,
                Observacao = observacao,
                Usuario = usuario
            };

        public static Movimentacao CriarCancelamento(Titulo titulo, string motivo, string usuario) =>
            new Movimentacao
            {
                Titulo = titulo,
                IdTitulo = titulo.Id,
                Tipo = "CANCELAMENTO",
                Valor = titulo.Valor,
                Observacao = motivo,
                Usuario = usuario
            };
    }
}
