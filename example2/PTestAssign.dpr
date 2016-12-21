program PTestAssign;

uses
  Vcl.Forms,
  TestAssign in 'TestAssign.pas' {Form1},
  test in 'test.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
