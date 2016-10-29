program ProtoBufGeneratorTests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  TestuProtoBufParserClasses in 'TestuProtoBufParserClasses.pas',
  uProtoBufParserClasses in '..\uProtoBufParserClasses.pas',
  uProtoBufParserAbstractClasses in '..\uProtoBufParserAbstractClasses.pas',
  uProtoBufGenerator in '..\uProtoBufGenerator.pas',
  uAbstractProtoBufClasses in '..\..\uAbstractProtoBufClasses.pas',
  pbInput in '..\..\pbInput.pas',
  pbOutput in '..\..\pbOutput.pas',
  pbPublic in '..\..\pbPublic.pas',
  StrBuffer in '..\..\StrBuffer.pas',
  TestuProtoBufGenerator in 'TestuProtoBufGenerator.pas',
  test1 in 'Win32\Debug\test1.pas',
  TestGeneratedProtoBufPas in 'TestGeneratedProtoBufPas.pas',
  test2 in 'Win32\Debug\test2.pas';

{R *.RES}

begin
  DUnitTestRunner.RunRegisteredTests;
end.

