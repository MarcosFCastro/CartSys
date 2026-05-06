using System;
using System.Windows.Forms;
using DevExpress.XtraEditors;
using ERPFinanceiro.Application.DTOs;

namespace ERPFinanceiro.UI.Forms
{
    /// <summary>
    /// Dialogo de quitacao - solicita forma de pagamento e observacao.
    /// </summary>
    public partial class FrmQuitar : XtraForm
    {
        public QuitarTituloDto Dto { get; private set; }

        public FrmQuitar(TituloResponseDto titulo)
        {
            InitializeComponent();
            Text = $"Quitar titulo #{titulo.Id} - {titulo.NomeCliente}";
            lblValor.Text = titulo.Valor.ToString("C2");

            cboFormaPagamento.Properties.Items.AddRange(
                new[] { "DINHEIRO", "PIX", "CARTAO_CREDITO", "CARTAO_DEBITO", "BOLETO", "TRANSFERENCIA" });
        }

        private void btnConfirmar_Click(object sender, EventArgs e)
        {
            if (cboFormaPagamento.SelectedIndex < 0)
            {
                XtraMessageBox.Show("Selecione a forma de pagamento.");
                return;
            }
            Dto = new QuitarTituloDto
            {
                FormaPagamento = cboFormaPagamento.SelectedItem.ToString(),
                Observacao = txtObservacao.Text
            };
            DialogResult = DialogResult.OK;
        }
    }
}
