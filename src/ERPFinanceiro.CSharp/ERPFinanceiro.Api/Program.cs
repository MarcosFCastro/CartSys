using System;
using System.Configuration;
using Microsoft.Owin.Hosting;
using NLog;

namespace ERPFinanceiro.Api
{
    /// <summary>
    /// Bootstrapper - hospeda a Web API em processo proprio (self-host OWIN).
    /// Em producao recomenda-se Windows Service via Topshelf.
    /// </summary>
    internal static class Program
    {
        private static readonly Logger _logger = LogManager.GetCurrentClassLogger();

        private static void Main()
        {
            var url = ConfigurationManager.AppSettings["ApiHostUrl"]
                      ?? "http://localhost:5001";

            try
            {
                using (WebApp.Start<Startup>(url))
                {
                    _logger.Info("ERP Financeiro API ouvindo em {0}", url);
                    Console.WriteLine($"API em {url}");
                    Console.WriteLine($"Swagger:  {url}/swagger");
                    Console.WriteLine("Pressione ENTER para encerrar.");
                    Console.ReadLine();
                }
            }
            catch (Exception ex)
            {
                _logger.Fatal(ex, "Falha ao iniciar API");
                throw;
            }
        }
    }
}
