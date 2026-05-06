using System.Data.Entity;
using ERPFinanceiro.Data.Configurations;
using ERPFinanceiro.Domain.Entities;
using FirebirdSql.Data.EntityFramework6;

namespace ERPFinanceiro.Data.Context
{
    /// <summary>
    /// DbContext do EF6 conectando ao Firebird via FirebirdSql.Data.EntityFramework6.
    /// Conventions: PascalCase no codigo, UPPER_SNAKE_CASE no banco - mapeado em Configurations.
    /// </summary>
    public class FinanceiroDbContext : DbContext
    {
        public FinanceiroDbContext() : base("name=FinanceiroDb")
        {
            Configuration.LazyLoadingEnabled = false;
            Configuration.ProxyCreationEnabled = false;
        }

        public DbSet<Titulo> Titulos { get; set; }
        public DbSet<Movimentacao> Movimentacoes { get; set; }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            modelBuilder.HasDefaultSchema("");
            modelBuilder.Configurations.Add(new TituloConfiguration());
            modelBuilder.Configurations.Add(new MovimentacaoConfiguration());
            base.OnModelCreating(modelBuilder);
        }
    }
}
