program ERPVendas.Tests;

{ Runner de testes DUnitX para o modulo ERP Vendas.
  Executa em modo console; gera XML NUnit em TestResults\. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  uExceptions  in 'src\Infra\uExceptions.pas',
  uCliente     in 'src\Model\Entity\uCliente.pas',
  uProduto     in 'src\Model\Entity\uProduto.pas',
  uVenda       in 'src\Model\Entity\uVenda.pas',
  uVendaTest   in 'tests\uVendaTest.pas';

{$R *.res}

var
  LRunner   : ITestRunner;
  LResults  : IRunResults;
  LConsole  : ITestLogger;
  LXml      : ITestLogger;
begin
  try
    LRunner := TDUnitX.CreateRunner;
    LRunner.UseRTTI := True;

    LConsole := TDUnitXConsoleLogger.Create(True);
    LXml     := TDUnitXXMLNUnitFileLogger.Create(
                  TDUnitX.Options.XMLOutputFile);
    LRunner.AddLogger(LConsole);
    LRunner.AddLogger(LXml);

    LResults := LRunner.Execute;
    if not LResults.AllPassed then
      System.ExitCode := EXIT_ERRORS;
  except
    on E: Exception do
    begin
      System.Writeln(E.ClassName + ': ' + E.Message);
      System.ExitCode := EXIT_ERRORS;
    end;
  end;

  {$IFNDEF CI}
  if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
  begin
    System.Write('Done. Press <Enter> to exit...');
    System.Readln;
  end;
  {$ENDIF}
end.
