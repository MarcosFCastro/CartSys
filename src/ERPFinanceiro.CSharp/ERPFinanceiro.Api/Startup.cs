using System.Web.Http;
using AutoMapper;
using ERPFinanceiro.Api.Filters;
using ERPFinanceiro.Api.Infrastructure;
using ERPFinanceiro.Application.Mappings;
using ERPFinanceiro.Application.Services;
using ERPFinanceiro.Application.Validators;
using ERPFinanceiro.Data.Context;
using ERPFinanceiro.Data.Repositories;
using ERPFinanceiro.Domain.Interfaces;
using ERPFinanceiro.Infrastructure.HttpClients;
using FluentValidation.WebApi;
using Microsoft.Owin;
using Owin;
using SimpleInjector;
using SimpleInjector.Integration.WebApi;
using SimpleInjector.Lifestyles;
using Swashbuckle.Application;

[assembly: OwinStartup(typeof(ERPFinanceiro.Api.Startup))]
namespace ERPFinanceiro.Api
{
    public class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            var config = new HttpConfiguration();

            // Container DI
            var container = new Container();
            container.Options.DefaultScopedLifestyle = new AsyncScopedLifestyle();

            container.Register<FinanceiroDbContext>(Lifestyle.Scoped);
            container.Register<IUnitOfWork, UnitOfWork>(Lifestyle.Scoped);
            container.Register<ITituloRepository, TituloRepository>(Lifestyle.Scoped);
            container.Register<ITituloService, TituloService>(Lifestyle.Scoped);
            container.Register<IVendasIntegrationClient, VendasIntegrationClient>(Lifestyle.Scoped);

            var mapperConfig = new MapperConfiguration(cfg =>
                cfg.AddProfile<DomainToDtoProfile>());
            container.RegisterInstance<IMapper>(mapperConfig.CreateMapper());

            container.RegisterWebApiControllers(config);
            container.Verify();

            config.DependencyResolver = new SimpleInjectorWebApiDependencyResolver(container);

            // Filtros globais
            config.Filters.Add(new ApiKeyAuthorizationFilter());
            config.Filters.Add(new GlobalExceptionFilter());

            // FluentValidation
            FluentValidationModelValidatorProvider.Configure(config, cfg =>
                cfg.ValidatorFactory = new SimpleInjectorValidatorFactory(container,
                    typeof(CriarTituloDtoValidator).Assembly));

            // Routing
            config.MapHttpAttributeRoutes();
            config.Formatters.JsonFormatter.SerializerSettings.ContractResolver =
                new Newtonsoft.Json.Serialization.CamelCasePropertyNamesContractResolver();

            // Swagger
            config.EnableSwagger(c => c.SingleApiVersion("v1", "CartSys ERP Financeiro API"))
                  .EnableSwaggerUi();

            app.UseWebApi(config);
        }
    }
}
