using System;
using System.Threading.Tasks;
using AutoMapper;
using ERPFinanceiro.Application.DTOs;
using ERPFinanceiro.Application.Mappings;
using ERPFinanceiro.Application.Services;
using ERPFinanceiro.Domain.Entities;
using ERPFinanceiro.Domain.Enums;
using ERPFinanceiro.Domain.Exceptions;
using ERPFinanceiro.Domain.Interfaces;
using FluentAssertions;
using Moq;
using Xunit;

namespace ERPFinanceiro.Tests
{
    public class TituloServiceTests
    {
        private readonly Mock<IUnitOfWork> _uow = new Mock<IUnitOfWork>();
        private readonly Mock<ITituloRepository> _repo = new Mock<ITituloRepository>();
        private readonly Mock<IVendasIntegrationClient> _vendas = new Mock<IVendasIntegrationClient>();
        private readonly IMapper _mapper;
        private readonly TituloService _sut;

        public TituloServiceTests()
        {
            _uow.SetupGet(x => x.Titulos).Returns(_repo.Object);
            _uow.Setup(x => x.CommitAsync()).ReturnsAsync(1);
            var cfg = new MapperConfiguration(c => c.AddProfile<DomainToDtoProfile>());
            _mapper = cfg.CreateMapper();
            _sut = new TituloService(_uow.Object, _vendas.Object, _mapper);
        }

        [Fact]
        public async Task Criar_QuandoVendaJaPossuiTitulo_DeveLancarBusinessException()
        {
            _repo.Setup(r => r.GetByIdVendaExternaAsync(It.IsAny<int>()))
                 .ReturnsAsync(new Titulo { Id = 99, IdVendaExterna = 1 });

            var dto = NovoDto();

            Func<Task> act = () => _sut.CriarAsync(dto);
            await act.Should().ThrowAsync<BusinessException>()
                .WithMessage("*ja existe titulo*");
        }

        [Fact]
        public async Task Criar_QuandoNovoTitulo_DeveSalvarERetornarDto()
        {
            _repo.Setup(r => r.GetByIdVendaExternaAsync(It.IsAny<int>()))
                 .ReturnsAsync((Titulo)null);
            _repo.Setup(r => r.AddAsync(It.IsAny<Titulo>()))
                 .ReturnsAsync(42)
                 .Callback<Titulo>(t => t.Id = 42);

            var dto = NovoDto();
            var resp = await _sut.CriarAsync(dto);

            resp.Id.Should().Be(42);
            resp.Status.Should().Be("PENDENTE");
            _uow.Verify(x => x.CommitAsync(), Times.Once);
        }

        [Fact]
        public async Task Quitar_QuandoTituloNaoExiste_DeveLancarNotFound()
        {
            _repo.Setup(r => r.GetByIdAsync(It.IsAny<int>())).ReturnsAsync((Titulo)null);
            Func<Task> act = () => _sut.QuitarAsync(1, new QuitarTituloDto
            {
                FormaPagamento = "PIX"
            }, "user");
            await act.Should().ThrowAsync<NotFoundException>();
        }

        [Fact]
        public async Task Quitar_QuandoTituloJaQuitado_DeveLancarBusinessException()
        {
            _repo.Setup(r => r.GetByIdAsync(It.IsAny<int>()))
                 .ReturnsAsync(new Titulo { Id = 1, Status = StatusTitulo.Quitado });

            Func<Task> act = () => _sut.QuitarAsync(1,
                new QuitarTituloDto { FormaPagamento = "PIX" }, "user");
            await act.Should().ThrowAsync<BusinessException>();
        }

        [Fact]
        public async Task Quitar_QuandoSucesso_DeveNotificarVendas()
        {
            _repo.Setup(r => r.GetByIdAsync(1))
                 .ReturnsAsync(new Titulo { Id = 1, IdVendaExterna = 100, Valor = 100, Status = StatusTitulo.Pendente });

            await _sut.QuitarAsync(1, new QuitarTituloDto
            {
                FormaPagamento = "PIX",
                Observacao = "Pago"
            }, "user");

            _vendas.Verify(x => x.NotificarQuitacaoAsync(
                100, 1, It.IsAny<DateTime>(), "PIX"), Times.Once);
        }

        private static CriarTituloDto NovoDto() => new CriarTituloDto
        {
            IdVendaExterna = 1,
            NumeroVenda = 1,
            IdClienteExterno = 1,
            NomeCliente = "Teste",
            Valor = 100m,
            DtVencimento = DateTime.Today.AddDays(30)
        };
    }
}
