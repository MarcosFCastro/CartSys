using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using ERPFinanceiro.Domain.Entities;
using ERPFinanceiro.Domain.Enums;

namespace ERPFinanceiro.Domain.Interfaces
{
    /// <summary>
    /// Repositorio de Titulos.
    /// </summary>
    public interface ITituloRepository
    {
        Task<Titulo> GetByIdAsync(int id);
        Task<Titulo> GetByIdVendaExternaAsync(int idVendaExterna);

        Task<(IList<Titulo> Items, int Total)> ListAsync(
            StatusTitulo? status,
            int? clienteId,
            DateTime? dataInicio,
            DateTime? dataFim,
            int page,
            int pageSize);

        Task<int> AddAsync(Titulo titulo);
        Task UpdateAsync(Titulo titulo);
    }

    /// <summary>
    /// Coordena commit transacional entre repositorios.
    /// </summary>
    public interface IUnitOfWork : IDisposable
    {
        ITituloRepository Titulos { get; }
        Task<int> CommitAsync();
    }

    /// <summary>
    /// Cliente HTTP para callbacks ao ERP Vendas.
    /// </summary>
    public interface IVendasIntegrationClient
    {
        Task NotificarQuitacaoAsync(int idVenda, int idTitulo,
            DateTime dtQuitacao, string formaPagamento);
        Task NotificarCancelamentoAsync(int idVenda, int idTitulo, string motivo);
    }
}
