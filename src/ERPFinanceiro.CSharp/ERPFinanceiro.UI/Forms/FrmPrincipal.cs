using System;
using System.Configuration;
using System.Threading.Tasks;
using DevExpress.XtraBars.Ribbon;
using DevExpress.XtraEditors;
using DevExpress.XtraGrid.Views.BandedGrid;
using ERPFinanceiro.Application.DTOs;
using ERPFinanceiro.Application.Services;
using ERPFinanceiro.Domain.Enums;
using ERPFinanceiro.UI.Reports;

namespace ERPFinanceiro.UI.Forms
{
    /// <summary>
    /// Tela principal do ERP Financeiro. RibbonForm com botoes de:
    /// - Listar / atualizar titulos com filtros
    /// - Quitar titulo selecionado
    /// - Cancelar titulo selecionado
    /// - Imprimir relatorio financeiro
    /// </summary>
    public partial class FrmPrincipal : RibbonForm
    {
        private readonly ITituloService _service;

        public FrmPrincipal(ITituloService service)
        {
            InitializeComponent();
            _service = service ?? throw new ArgumentNullException(nameof(service));
            Text = "CartSys - ERP Financeiro";
        }

        private async void FrmPrincipal_Load(object sender, EventArgs e) =>
            await CarregarTitulosAsync();

        private async Task CarregarTitulosAsync()
        {
            try
            {
                var dtIni = dteInicio.EditValue as DateTime?;
                var dtFim = dteFim.EditValue as DateTime?;
                StatusTitulo? status = null;
                if (cboStatus.SelectedItem is string s && Enum.TryParse(s, true, out StatusTitulo st))
                    status = st;

                var resp = await _service.ListarAsync(status, null, dtIni, dtFim, 1, 200);
                gridControl.DataSource = resp.Items;
            }
            catch (Exception ex)
            {
                XtraMessageBox.Show($"Erro: {ex.Message}", "Erro",
                    System.Windows.Forms.MessageBoxButtons.OK,
                    System.Windows.Forms.MessageBoxIcon.Error);
            }
        }

        private TituloResponseDto TituloSelecionado()
        {
            var view = gridControl.MainView as BandedGridView;
            return view?.GetFocusedRow() as TituloResponseDto;
        }

        private async void btnAtualizar_ItemClick(object sender, DevExpress.XtraBars.ItemClickEventArgs e) =>
            await CarregarTitulosAsync();

        private async void btnQuitar_ItemClick(object sender, DevExpress.XtraBars.ItemClickEventArgs e)
        {
            var t = TituloSelecionado();
            if (t == null) return;

            using (var frm = new FrmQuitar(t))
            {
                if (frm.ShowDialog() != System.Windows.Forms.DialogResult.OK) return;
                try
                {
                    await _service.QuitarAsync(t.Id, frm.Dto, Environment.UserName);
                    XtraMessageBox.Show("Titulo quitado.");
                    await CarregarTitulosAsync();
                }
                catch (Exception ex)
                {
                    XtraMessageBox.Show($"Erro: {ex.Message}", "Erro");
                }
            }
        }

        private async void btnCancelar_ItemClick(object sender, DevExpress.XtraBars.ItemClickEventArgs e)
        {
            var t = TituloSelecionado();
            if (t == null) return;

            string motivo = XtraInputBox.Show("Motivo do cancelamento:", "Cancelar titulo", "");
            if (string.IsNullOrWhiteSpace(motivo)) return;

            try
            {
                await _service.CancelarAsync(t.Id,
                    new CancelarTituloDto { Motivo = motivo }, Environment.UserName);
                await CarregarTitulosAsync();
            }
            catch (Exception ex)
            {
                XtraMessageBox.Show($"Erro: {ex.Message}");
            }
        }

        private async void btnRelatorio_ItemClick(object sender, DevExpress.XtraBars.ItemClickEventArgs e)
        {
            var resp = await _service.ListarAsync(null, null,
                dteInicio.EditValue as DateTime?, dteFim.EditValue as DateTime?, 1, 1000);
            using (var rpt = new RelatorioFinanceiro(resp.Items))
                rpt.ShowPreview();
        }
    }
}
