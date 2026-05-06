namespace ERPFinanceiro.Domain.Enums
{
    /// <summary>
    /// Estados validos de um titulo a receber.
    /// Persistido em banco como string para legibilidade.
    /// </summary>
    public enum StatusTitulo
    {
        Pendente = 0,
        Quitado = 1,
        Cancelado = 2
    }
}
