using System;
using System.Net;
using System.Net.Http;
using System.Web.Http.ExceptionHandling;
using System.Web.Http.Filters;
using ERPFinanceiro.Domain.Exceptions;
using NLog;

namespace ERPFinanceiro.Api.Filters
{
    /// <summary>
    /// Mapeia excecoes do dominio para respostas HTTP padronizadas (RFC 7807).
    /// </summary>
    public class GlobalExceptionFilter : ExceptionFilterAttribute
    {
        private static readonly Logger _logger = LogManager.GetCurrentClassLogger();

        public override void OnException(HttpActionExecutedContext context)
        {
            var ex = context.Exception;
            HttpStatusCode status;
            string title;

            switch (ex)
            {
                case ValidationException _:
                    status = HttpStatusCode.BadRequest;
                    title = "Dados invalidos";
                    break;
                case BusinessException _:
                    status = HttpStatusCode.Conflict;
                    title = "Conflito de regra";
                    break;
                case NotFoundException _:
                    status = HttpStatusCode.NotFound;
                    title = "Nao encontrado";
                    break;
                case IntegrationException _:
                    status = HttpStatusCode.BadGateway;
                    title = "Falha em sistema externo";
                    break;
                default:
                    status = HttpStatusCode.InternalServerError;
                    title = "Erro interno";
                    _logger.Error(ex, "Erro nao tratado");
                    break;
            }

            var problem = new
            {
                type = $"https://cartsys/erros/{title.ToLower().Replace(' ', '-')}",
                title,
                status = (int)status,
                detail = ex.Message,
                traceId = context.Request.GetCorrelationId().ToString()
            };

            context.Response = context.Request.CreateResponse(status, problem);
        }
    }
}
