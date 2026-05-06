using System;
using System.Reflection;
using FluentValidation;
using SimpleInjector;

namespace ERPFinanceiro.Api.Infrastructure
{
    /// <summary>
    /// Pontes FluentValidation.WebApi com o container SimpleInjector.
    /// Registrado em Startup.Configuration via FluentValidationModelValidatorProvider.Configure.
    /// </summary>
    internal sealed class SimpleInjectorValidatorFactory : ValidatorFactoryBase
    {
        private readonly Container _container;

        public SimpleInjectorValidatorFactory(Container container, Assembly _)
        {
            _container = container ?? throw new ArgumentNullException(nameof(container));
        }

        public override IValidator CreateInstance(Type validatorType)
        {
            var registration = _container.GetRegistration(validatorType);
            return registration?.GetInstance() as IValidator;
        }
    }
}
