using System;
using FluentValidation;
using ERPFinanceiro.Application.DTOs;

namespace ERPFinanceiro.Application.Validators
{
    /// <summary>
    /// Validacao do DTO de criacao de titulo.
    /// Aplicada automaticamente pelo pipeline de Web API.
    /// </summary>
    public class CriarTituloDtoValidator : AbstractValidator<CriarTituloDto>
    {
        public CriarTituloDtoValidator()
        {
            RuleFor(x => x.IdVendaExterna)
                .GreaterThan(0).WithMessage("idVendaExterna deve ser maior que zero.");

            RuleFor(x => x.NumeroVenda)
                .GreaterThan(0).WithMessage("numeroVenda deve ser maior que zero.");

            RuleFor(x => x.IdClienteExterno)
                .GreaterThan(0).WithMessage("idClienteExterno deve ser maior que zero.");

            RuleFor(x => x.NomeCliente)
                .NotEmpty().WithMessage("nomeCliente eh obrigatorio.")
                .MaximumLength(120);

            RuleFor(x => x.Valor)
                .GreaterThan(0).WithMessage("valor deve ser maior que zero.");

            RuleFor(x => x.DtVencimento)
                .GreaterThanOrEqualTo(DateTime.Today)
                    .WithMessage("dtVencimento nao pode ser anterior a hoje.");

            RuleFor(x => x.EmailCliente)
                .EmailAddress()
                    .When(x => !string.IsNullOrWhiteSpace(x.EmailCliente))
                    .WithMessage("emailCliente invalido.");
        }
    }

    public class QuitarTituloDtoValidator : AbstractValidator<QuitarTituloDto>
    {
        public QuitarTituloDtoValidator()
        {
            RuleFor(x => x.FormaPagamento)
                .NotEmpty().WithMessage("formaPagamento eh obrigatorio.");
        }
    }

    public class CancelarTituloDtoValidator : AbstractValidator<CancelarTituloDto>
    {
        public CancelarTituloDtoValidator()
        {
            RuleFor(x => x.Motivo)
                .NotEmpty().WithMessage("motivo eh obrigatorio.")
                .MaximumLength(500);
        }
    }
}
