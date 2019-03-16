program ProtoBufGenerator;

uses

 Vcl.Forms,
  ufmMain in 'ufmMain.pas' {fmMain},
  pbInput in '..\pbInput.pas',
  pbOutput in '..\pbOutput.pas',
  pbPublic in '..\pbPublic.pas',
  StrBuffer in '..\StrBuffer.pas',
  uAbstractProtoBufClasses in '..\uAbstractProtoBufClasses.pas',
  uProtoBufParserClasses in 'uProtoBufParserClasses.pas',
  uProtoBufParserAbstractClasses in 'uProtoBufParserAbstractClasses.pas',
  uProtoBufGenerator in 'uProtoBufGenerator.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
