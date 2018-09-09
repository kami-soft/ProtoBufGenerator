program ProjectExample2;

uses
  Vcl.Forms,
  ufmMain in 'ufmMain.pas' {Form15};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm15, Form15);
  Application.Run;
end.
