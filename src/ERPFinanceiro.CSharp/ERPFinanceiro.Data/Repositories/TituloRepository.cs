using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using ERPFinanceiro.Data.Context;
using ERPFinanceiro.Domain.Entities;
using ERPFinanceiro.Domain.Enums;
using ERPFinanceiro.Domain.Interfaces;

namespace ERPFinanceiro.Data.Repositories
{
    public class TituloRepository : ITituloRepository
    {
        private readonly FinanceiroDbContext _ctx;

        public TituloRepository(FinanceiroDbContext ctx)
        {
            _ctx = ctx ?? throw new ArgumentNullException(nameof(ctx));
        }

        public Task<Titulo> GetByIdAsync(int id) =>
            _ctx.Titulos
                .Include(t => t.Movimentacoes)
                .FirstOrDefaultAsync(t => t.Id == id);

        public Task<Titulo> GetByIdVendaExternaAsync(int idVendaExterna) =>
            _ctx.Titulos
                .FirstOrDefaultAsync(t => t.IdVendaExterna == idVendaExterna);

        public async Task<(IList<Titulo> Items, int Total)> ListAsync(
            StatusTitulo? status, int? clienteId,
            DateTime? dataInicio, DateTime? dataFim,
            int page, int pageSize)
        {
            var q = _ctx.Titulos.AsQueryable();
            if (status.HasValue)     q = q.Where(t => t.Status == status.Value);
            if (clienteId.HasValue)  q = q.Where(t => t.IdClienteExterno == clienteId.Value);
            if (dataInicio.HasValue) q = q.Where(t => t.DtEmissao >= dataInicio.Value);
            if (dataFim.HasValue)    q = q.Where(t => t.DtEmissao <= dataFim.Value);

            var total = await q.CountAsync();
            var items = await q
                .OrderByDescending(t => t.DtEmissao)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return (items, total);
        }

        public async Task<int> AddAsync(Titulo titulo)
        {
            _ctx.Titulos.Add(titulo);
            await _ctx.SaveChangesAsync();
            return titulo.Id;
        }

        public Task UpdateAsync(Titulo titulo)
        {
            _ctx.Entry(titulo).State = EntityState.Modified;
            return Task.CompletedTask;
        }
    }

    public class UnitOfWork : IUnitOfWork
    {
        private readonly FinanceiroDbContext _ctx;
        private ITituloRepository _titulos;

        public UnitOfWork(FinanceiroDbContext ctx)
        {
            _ctx = ctx ?? throw new ArgumentNullException(nameof(ctx));
        }

        public ITituloRepository Titulos =>
            _titulos ?? (_titulos = new TituloRepository(_ctx));

        public Task<int> CommitAsync() => _ctx.SaveChangesAsync();

        public void Dispose() => _ctx?.Dispose();
    }
}
