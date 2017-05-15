program pbTest;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  UnitTest in 'UnitTest.pas';

begin
  try
    TestAll;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
