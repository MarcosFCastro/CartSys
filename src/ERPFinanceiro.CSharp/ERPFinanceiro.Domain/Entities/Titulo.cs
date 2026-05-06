using System;
using System.Collections.Generic;
using ERPFinanceiro.Domain.Enums;
using ERPFinanceiro.Domain.Exceptions;

namespace ERPFinanceiro.Domain.Entities
{
    /// <summary>
    /// Titulo a receber gerado a partir de uma venda.
    /// Contem regras de transicao de status (rich domain).
    /// </summary>
    public class Titulo
    {
        public int Id { get; set; }

        /// <summary>Id da venda no ERP de Vendas (chave logica).</summary>
        public int IdVendaExterna { get; set; }
        public int NumeroVenda { get; set; }

        public int IdClienteExterno { get; set; }
        public string NomeCliente { get; set; }
        public string DocCliente { get; set; }
        public string EmailCliente { get; set; }

        public decimal Valor { get; set; }

        public DateTime DtEmissao { get; set; }
        public DateTime DtVencimento { get; set; }
        public DateTime? DtQuitacao { get; set; }
        public DateTime? DtCancelamento { get; set; }

        public StatusTitulo Status { get; set; }
        public string FormaPagamento { get; set; }
        public string Observacoes { get; set; }

        public DateTime DtCadastro { get; set; }
        public DateTime? DtAlteracao { get; set; }

        public ICollection<Movimentacao> Movimentacoes { get; set; }

        public Titulo()
        {
            Status = StatusTitulo.Pendente;
            DtEmissao = DateTime.Now;
            DtCadastro = DateTime.Now;
            Movimentacoes = new List<Movimentacao>();
        }

        public bool PodeQuitar() => Status == StatusTitulo.Pendente;
        public bool PodeCancelar() => Status == StatusTitulo.Pendente;

        public void Quitar(string formaPagamento, string observacao, string usuario)
        {
            if (!PodeQuitar())
                throw new BusinessException(
                    $"Titulo {Id} nao pode ser quitado (status atual: {Status}).");

            Status = StatusTitulo.Quitado;
            DtQuitacao = DateTime.Now;
            FormaPagamento = formaPagamento;
            Movimentacoes.Add(Movimentacao.CriarQuitacao(this, observacao, usuario));
        }

        public void Cancelar(string motivo, string usuario)
        {
            if (!PodeCancelar())
                throw new BusinessException(
                    $"Titulo {Id} nao pode ser cancelado (status atual: {Status}).");

            Status = StatusTitulo.Cancelado;
            DtCancelamento = DateTime.Now;
            Movimentacoes.Add(Movimentacao.CriarCancelamento(this, motivo, usuario));
        }
    }
}
