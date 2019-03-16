program ProjectExample2;

uses
   madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
 Vcl.Forms,
  ufmMain in 'ufmMain.pas' {Form15},
  test1 in '..\Ready\test1.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm15, Form15);
  Application.Run;
end.
