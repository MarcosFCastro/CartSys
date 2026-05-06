using System.Configuration;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;

namespace ERPFinanceiro.Api.Filters
{
    /// <summary>
    /// Validacao da API Key no header X-API-Key. Aplicada como filtro global.
    /// Rota /api/v1/health continua publica.
    /// </summary>
    public class ApiKeyAuthorizationFilter : AuthorizationFilterAttribute
    {
        private const string HeaderName = "X-API-Key";

        public override void OnAuthorization(HttpActionContext actionContext)
        {
            var rota = actionContext.Request.RequestUri.AbsolutePath;
            if (rota.EndsWith("/health", System.StringComparison.OrdinalIgnoreCase))
                return;

            if (!actionContext.Request.Headers.TryGetValues(HeaderName, out var valores))
            {
                Negar(actionContext, "API Key ausente.");
                return;
            }

            var configurada = ConfigurationManager.AppSettings["ApiKey"];
            if (valores.FirstOrDefault() != configurada)
                Negar(actionContext, "API Key invalida.");
        }

        private static void Negar(HttpActionContext ctx, string motivo)
        {
            ctx.Response = ctx.Request.CreateResponse(
                HttpStatusCode.Unauthorized, new { title = "Nao autorizado", detail = motivo });
        }
    }
}
