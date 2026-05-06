using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using FastReport;
using ERPFinanceiro.Application.DTOs;

namespace ERPFinanceiro.UI.Reports
{
    /// <summary>
    /// Relatorio financeiro com Fast Report.
    /// Espera um arquivo .frx em /Reports/RelatorioFinanceiro.frx (template visual).
    /// </summary>
    public class RelatorioFinanceiro : IDisposable
    {
        private readonly Report _report;

        public RelatorioFinanceiro(IList<TituloResponseDto> titulos)
        {
            _report = new Report();
            var caminhoTemplate = Path.Combine(
                AppDomain.CurrentDomain.BaseDirectory,
                "Reports", "RelatorioFinanceiro.frx");

            if (File.Exists(caminhoTemplate))
                _report.Load(caminhoTemplate);

            _report.RegisterData(ToDataTable(titulos), "Titulos");
            _report.SetParameterValue("DataInicio", titulos.Min(t => t.DtEmissao));
            _report.SetParameterValue("DataFim", titulos.Max(t => t.DtEmissao));
            _report.SetParameterValue("TotalRecebido",
                titulos.Where(t => t.Status == "QUITADO").Sum(t => t.Valor));
            _report.SetParameterValue("TotalPendente",
                titulos.Where(t => t.Status == "PENDENTE").Sum(t => t.Valor));
            _report.SetParameterValue("TotalCancelado",
                titulos.Where(t => t.Status == "CANCELADO").Sum(t => t.Valor));
        }

        private static DataTable ToDataTable(IList<TituloResponseDto> items)
        {
            var dt = new DataTable("Titulos");
            dt.Columns.Add("Id", typeof(int));
            dt.Columns.Add("NumeroVenda", typeof(int));
            dt.Columns.Add("NomeCliente", typeof(string));
            dt.Columns.Add("Valor", typeof(decimal));
            dt.Columns.Add("DtEmissao", typeof(DateTime));
            dt.Columns.Add("DtVencimento", typeof(DateTime));
            dt.Columns.Add("Status", typeof(string));

            foreach (var t in items)
                dt.Rows.Add(t.Id, t.NumeroVenda, t.NomeCliente, t.Valor,
                            t.DtEmissao, t.DtVencimento, t.Status);
            return dt;
        }

        public void ShowPreview()
        {
            _report.Prepare();
            _report.ShowPrepared();
        }

        public void Dispose() => _report?.Dispose();
    }
}
