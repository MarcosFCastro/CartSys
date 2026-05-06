using System;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Description;
using ERPFinanceiro.Application.DTOs;
using ERPFinanceiro.Application.Services;
using ERPFinanceiro.Domain.Enums;
using ERPFinanceiro.Domain.Exceptions;

namespace ERPFinanceiro.Api.Controllers
{
    /// <summary>
    /// Endpoints de Titulos a Receber.
    /// Autenticacao via header X-API-Key (filter global).
    /// </summary>
    [RoutePrefix("api/v1/titulos")]
    public class TitulosController : ApiController
    {
        private readonly ITituloService _service;

        public TitulosController(ITituloService service)
        {
            _service = service ?? throw new ArgumentNullException(nameof(service));
        }

        /// <summary>Cria um novo titulo a partir de uma venda.</summary>
        [HttpPost, Route("")]
        [ResponseType(typeof(TituloResponseDto))]
        public async Task<IHttpActionResult> Criar([FromBody] CriarTituloDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var resp = await _service.CriarAsync(dto);
            return Created($"/api/v1/titulos/{resp.Id}", resp);
        }

        [HttpGet, Route("{id:int}")]
        [ResponseType(typeof(TituloResponseDto))]
        public async Task<IHttpActionResult> Obter(int id)
        {
            var resp = await _service.ObterAsync(id);
            return Ok(resp);
        }

        [HttpGet, Route("")]
        [ResponseType(typeof(PagedResponseDto<TituloResponseDto>))]
        public async Task<IHttpActionResult> Listar(
            string status = null, int? clienteId = null,
            DateTime? dataInicio = null, DateTime? dataFim = null,
            int page = 1, int pageSize = 50)
        {
            StatusTitulo? statusEnum = null;
            if (!string.IsNullOrWhiteSpace(status)
                && Enum.TryParse(status, true, out StatusTitulo s))
                statusEnum = s;

            var resp = await _service.ListarAsync(
                statusEnum, clienteId, dataInicio, dataFim, page, pageSize);
            return Ok(resp);
        }

        [HttpPost, Route("{id:int}/quitar")]
        [ResponseType(typeof(TituloResponseDto))]
        public async Task<IHttpActionResult> Quitar(int id, [FromBody] QuitarTituloDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var usuario = User?.Identity?.Name ?? "API";
            var resp = await _service.QuitarAsync(id, dto, usuario);
            return Ok(resp);
        }

        [HttpPost, Route("{id:int}/cancelar")]
        [ResponseType(typeof(TituloResponseDto))]
        public async Task<IHttpActionResult> Cancelar(int id, [FromBody] CancelarTituloDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var usuario = User?.Identity?.Name ?? "API";
            var resp = await _service.CancelarAsync(id, dto, usuario);
            return Ok(resp);
        }
    }

    [RoutePrefix("api/v1/health")]
    public class HealthController : ApiController
    {
        [HttpGet, Route("")]
        public IHttpActionResult Get() =>
            Ok(new { status = "UP", timestamp = DateTime.UtcNow });
    }
}
