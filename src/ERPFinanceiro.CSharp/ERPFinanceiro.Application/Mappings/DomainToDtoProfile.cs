using AutoMapper;
using ERPFinanceiro.Application.DTOs;
using ERPFinanceiro.Domain.Entities;

namespace ERPFinanceiro.Application.Mappings
{
    public class DomainToDtoProfile : Profile
    {
        public DomainToDtoProfile()
        {
            CreateMap<Titulo, TituloResponseDto>()
                .ForMember(d => d.Status, o => o.MapFrom(s => s.Status.ToString().ToUpper()));
        }
    }
}
