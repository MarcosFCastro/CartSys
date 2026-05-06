using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using AutoMapper;
using ERPFinanceiro.Application.DTOs;
using ERPFinanceiro.Domain.Entities;
using ERPFinanceiro.Domain.Enums;
using ERPFinanceiro.Domain.Exceptions;
using ERPFinanceiro.Domain.Interfaces;

namespace ERPFinanceiro.Application.Services
{
    public interface ITituloService
    {
        Task<TituloResponseDto> CriarAsync(CriarTituloDto dto);
        Task<TituloResponseDto> ObterAsync(int id);
        Task<PagedResponseDto<TituloResponseDto>> ListarAsync(
            StatusTitulo? status, int? clienteId,
            DateTime? dtInicio, DateTime? dtFim, int page, int pageSize);
        Task<TituloResponseDto> QuitarAsync(int id, QuitarTituloDto dto, string usuario);
        Task<TituloResponseDto> CancelarAsync(int id, CancelarTituloDto dto, string usuario);
    }

    /// <summary>
    /// Service de Titulos. Orquestra Repository + UnitOfWork + callback ao ERP Vendas.
    /// </summary>
    public class TituloService : ITituloService
    {
        private readonly IUnitOfWork _uow;
        private readonly IVendasIntegrationClient _vendasClient;
        private readonly IMapper _mapper;

        public TituloService(
            IUnitOfWork uow,
            IVendasIntegrationClient vendasClient,
            IMapper mapper)
        {
            _uow = uow ?? throw new ArgumentNullException(nameof(uow));
            _vendasClient = vendasClient ?? throw new ArgumentNullException(nameof(vendasClient));
            _mapper = mapper ?? throw new ArgumentNullException(nameof(mapper));
        }

        public async Task<TituloResponseDto> CriarAsync(CriarTituloDto dto)
        {
            // Idempotencia por venda - 409 se ja existe
            var existente = await _uow.Titulos.GetByIdVendaExternaAsync(dto.IdVendaExterna);
            if (existente != null)
                throw new BusinessException(
                    $"Ja existe titulo (id {existente.Id}) para a venda {dto.IdVendaExterna}.");

            var titulo = new Titulo
            {
                IdVendaExterna = dto.IdVendaExterna,
                NumeroVenda = dto.NumeroVenda,
                IdClienteExterno = dto.IdClienteExterno,
                NomeCliente = dto.NomeCliente,
                DocCliente = dto.DocCliente,
                EmailCliente = dto.EmailCliente,
                Valor = dto.Valor,
                DtVencimento = dto.DtVencimento,
                Observacoes = dto.Observacoes
            };
            titulo.Movimentacoes.Add(Movimentacao.CriarEmissao(titulo, "API"));

            await _uow.Titulos.AddAsync(titulo);
            await _uow.CommitAsync();

            return _mapper.Map<TituloResponseDto>(titulo);
        }

        public async Task<TituloResponseDto> ObterAsync(int id)
        {
            var t = await _uow.Titulos.GetByIdAsync(id);
            if (t == null)
                throw new NotFoundException($"Titulo {id} nao encontrado.");
            return _mapper.Map<TituloResponseDto>(t);
        }

        public async Task<PagedResponseDto<TituloResponseDto>> ListarAsync(
            StatusTitulo? status, int? clienteId,
            DateTime? dtInicio, DateTime? dtFim, int page, int pageSize)
        {
            if (page < 1) page = 1;
            if (pageSize < 1 || pageSize > 200) pageSize = 50;

            var (items, total) = await _uow.Titulos.ListAsync(
                status, clienteId, dtInicio, dtFim, page, pageSize);

            return new PagedResponseDto<TituloResponseDto>
            {
                Page = page,
                PageSize = pageSize,
                TotalItems = total,
                TotalPages = (int)Math.Ceiling((double)total / pageSize),
                Items = items.Select(_mapper.Map<TituloResponseDto>).ToList()
            };
        }

        public async Task<TituloResponseDto> QuitarAsync(int id, QuitarTituloDto dto, string usuario)
        {
            var titulo = await _uow.Titulos.GetByIdAsync(id);
            if (titulo == null)
                throw new NotFoundException($"Titulo {id} nao encontrado.");

            titulo.Quitar(dto.FormaPagamento, dto.Observacao, usuario);

            await _uow.Titulos.UpdateAsync(titulo);
            await _uow.CommitAsync();

            // Callback ao ERP Vendas - falha aqui NAO desfaz quitacao (eventual consistency).
            // O proprio cliente faz retry; se ainda falhar, fica registrado em LOG_INTEGRACAO
            // para reprocessamento posterior.
            try
            {
                await _vendasClient.NotificarQuitacaoAsync(
                    titulo.IdVendaExterna, titulo.Id,
                    titulo.DtQuitacao.Value, titulo.FormaPagamento);
            }
            catch (IntegrationException)
            {
                // log ja foi feito pelo cliente; segue
            }

            return _mapper.Map<TituloResponseDto>(titulo);
        }

        public async Task<TituloResponseDto> CancelarAsync(int id, CancelarTituloDto dto, string usuario)
        {
            var titulo = await _uow.Titulos.GetByIdAsync(id);
            if (titulo == null)
                throw new NotFoundException($"Titulo {id} nao encontrado.");

            titulo.Cancelar(dto.Motivo, usuario);

            await _uow.Titulos.UpdateAsync(titulo);
            await _uow.CommitAsync();

            try
            {
                await _vendasClient.NotificarCancelamentoAsync(
                    titulo.IdVendaExterna, titulo.Id, dto.Motivo);
            }
            catch (IntegrationException)
            {
                // log ja foi feito; nao reverte cancelamento
            }

            return _mapper.Map<TituloResponseDto>(titulo);
        }
    }
}
