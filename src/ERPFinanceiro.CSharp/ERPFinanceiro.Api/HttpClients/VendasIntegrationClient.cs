using System;
using System.Configuration;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using ERPFinanceiro.Domain.Exceptions;
using ERPFinanceiro.Domain.Interfaces;
using Newtonsoft.Json;
using NLog;
using Polly;
using Polly.Retry;

namespace ERPFinanceiro.Infrastructure.HttpClients
{
    /// <summary>
    /// Cliente HTTP que chama os callbacks expostos pelo ERP Vendas.
    /// Aplica retry com backoff exponencial via Polly.
    /// </summary>
    public class VendasIntegrationClient : IVendasIntegrationClient
    {
        private static readonly Logger _logger = LogManager.GetCurrentClassLogger();
        private static readonly HttpClient _http = CreateHttpClient();
        private static readonly AsyncRetryPolicy _retry = Policy
            .Handle<HttpRequestException>()
            .Or<TaskCanceledException>()
            .WaitAndRetryAsync(3,
                tentativa => TimeSpan.FromSeconds(Math.Pow(2, tentativa - 1)),
                (ex, ts, attempt, ctx) =>
                    _logger.Warn(ex, "Retry {0} em {1}s no callback ao Vendas", attempt, ts.TotalSeconds));

        private static HttpClient CreateHttpClient()
        {
            var c = new HttpClient
            {
                BaseAddress = new Uri(ConfigurationManager.AppSettings["VendasApiUrl"]),
                Timeout = TimeSpan.FromSeconds(
                    int.Parse(ConfigurationManager.AppSettings["VendasApiTimeoutSeg"] ?? "30"))
            };
            c.DefaultRequestHeaders.Accept.Add(
                new MediaTypeWithQualityHeaderValue("application/json"));
            c.DefaultRequestHeaders.Add(
                "X-API-Key", ConfigurationManager.AppSettings["VendasApiKey"]);
            return c;
        }

        public Task NotificarQuitacaoAsync(int idVenda, int idTitulo,
            DateTime dtQuitacao, string formaPagamento)
        {
            var rota = $"/api/v1/vendas/{idVenda}/notificar-quitacao";
            var payload = new { idTitulo, dtQuitacao, formaPagamento };
            return PostComRetry(rota, payload);
        }

        public Task NotificarCancelamentoAsync(int idVenda, int idTitulo, string motivo)
        {
            var rota = $"/api/v1/vendas/{idVenda}/notificar-cancelamento";
            var payload = new { idTitulo, motivo };
            return PostComRetry(rota, payload);
        }

        private async Task PostComRetry(string rota, object payload)
        {
            var body = JsonConvert.SerializeObject(payload);
            var content = new StringContent(body, Encoding.UTF8, "application/json");

            try
            {
                var resp = await _retry.ExecuteAsync(() => _http.PostAsync(rota, content));
                if (!resp.IsSuccessStatusCode)
                {
                    var conteudo = await resp.Content.ReadAsStringAsync();
                    throw new IntegrationException(
                        $"Callback ao Vendas falhou: HTTP {(int)resp.StatusCode}",
                        (int)resp.StatusCode, conteudo);
                }
            }
            catch (Exception ex) when (!(ex is IntegrationException))
            {
                _logger.Error(ex, "Falha definitiva no callback {0}", rota);
                throw new IntegrationException(ex.Message);
            }
        }
    }
}
