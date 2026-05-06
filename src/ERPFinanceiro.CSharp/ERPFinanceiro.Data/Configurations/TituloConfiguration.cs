using System.Data.Entity.ModelConfiguration;
using ERPFinanceiro.Domain.Entities;

namespace ERPFinanceiro.Data.Configurations
{
    public class TituloConfiguration : EntityTypeConfiguration<Titulo>
    {
        public TituloConfiguration()
        {
            ToTable("TITULOS");
            HasKey(t => t.Id);

            Property(t => t.Id).HasColumnName("ID")
                .HasDatabaseGeneratedOption(System.ComponentModel.DataAnnotations.Schema.DatabaseGeneratedOption.Identity);
            Property(t => t.IdVendaExterna).HasColumnName("ID_VENDA_EXTERNA").IsRequired();
            Property(t => t.NumeroVenda).HasColumnName("NUMERO_VENDA").IsRequired();
            Property(t => t.IdClienteExterno).HasColumnName("ID_CLIENTE_EXTERNO").IsRequired();
            Property(t => t.NomeCliente).HasColumnName("NOME_CLIENTE").HasMaxLength(120).IsRequired();
            Property(t => t.DocCliente).HasColumnName("DOC_CLIENTE").HasMaxLength(20);
            Property(t => t.EmailCliente).HasColumnName("EMAIL_CLIENTE").HasMaxLength(120);
            Property(t => t.Valor).HasColumnName("VALOR").HasPrecision(15, 2).IsRequired();
            Property(t => t.DtEmissao).HasColumnName("DT_EMISSAO").IsRequired();
            Property(t => t.DtVencimento).HasColumnName("DT_VENCIMENTO").IsRequired();
            Property(t => t.DtQuitacao).HasColumnName("DT_QUITACAO").IsOptional();
            Property(t => t.DtCancelamento).HasColumnName("DT_CANCELAMENTO").IsOptional();
            Property(t => t.Status).HasColumnName("STATUS").IsRequired();
            Property(t => t.FormaPagamento).HasColumnName("FORMA_PAGAMENTO").HasMaxLength(30);
            Property(t => t.Observacoes).HasColumnName("OBSERVACOES").HasMaxLength(500);
            Property(t => t.DtCadastro).HasColumnName("DT_CADASTRO").IsRequired();
            Property(t => t.DtAlteracao).HasColumnName("DT_ALTERACAO").IsOptional();

            HasMany(t => t.Movimentacoes)
                .WithRequired(m => m.Titulo)
                .HasForeignKey(m => m.IdTitulo);
        }
    }

    public class MovimentacaoConfiguration : EntityTypeConfiguration<Movimentacao>
    {
        public MovimentacaoConfiguration()
        {
            ToTable("MOVIMENTACOES");
            HasKey(m => m.Id);

            Property(m => m.Id).HasColumnName("ID")
                .HasDatabaseGeneratedOption(System.ComponentModel.DataAnnotations.Schema.DatabaseGeneratedOption.Identity);
            Property(m => m.IdTitulo).HasColumnName("ID_TITULO").IsRequired();
            Property(m => m.Tipo).HasColumnName("TIPO").HasMaxLength(20).IsRequired();
            Property(m => m.Valor).HasColumnName("VALOR").HasPrecision(15, 2).IsRequired();
            Property(m => m.DtMovimentacao).HasColumnName("DT_MOVIMENTACAO").IsRequired();
            Property(m => m.Observacao).HasColumnName("OBSERVACAO").HasMaxLength(500);
            Property(m => m.Usuario).HasColumnName("USUARIO").HasMaxLength(60);
        }
    }
}
