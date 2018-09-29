unit ufmMain;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls;

type
  TForm15 = class(TForm)
    lblDescription: TLabel;
    btnSaveToPtotoBuf: TButton;
    btnLoadFromProtoBuf: TButton;
    btnSpeedTest: TButton;
    procedure btnSaveToPtotoBufClick(Sender: TObject);
    procedure btnLoadFromProtoBufClick(Sender: TObject);
    procedure btnSpeedTestClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form15: TForm15;

implementation

uses
  System.DateUtils,
  TestImport1,
  Test1;

{$R *.dfm}

procedure TForm15.btnLoadFromProtoBufClick(Sender: TObject);
var
  TestMsg1: TTestMsg1;
  TestExtension: TTestMsg1Extension1;
  Stream: TStream;
  sFileName: string;
begin
  // open data container, saved by btnSaveToPtotoBufClick method
  sFileName := ExtractFilePath(ParamStr(0)) + 'Msg1.bin';
  Stream := TFileStream.Create(sFileName, fmOpenRead);
  try
    TestMsg1 := TTestMsg1.Create(nil);
    try
      TestMsg1.LoadFromStream(Stream);

      // and now we have saved data
      // let`s check, that all properties loaded.
      Assert(TestMsg1.DefField1 = 20, 'Wrong value in DefField1');
      Assert(TestMsg1.DefField9 = 1.5, 'Wrong value in DefField9');
      Assert(TestMsg1.FieldArr1List.Count = 1, 'Wrong count in FieldArr1List');
      Assert(TestMsg1.FieldArr1List[0] = 743, 'Wrong value in FieldArr1List[0]');
      Assert(TestMsg1.FieldImp1 = gVal1, 'Wrong value in FieldImp1');
    finally
      TestMsg1.Free;
    end;
  finally
    Stream.Free;
  end;

  sFileName := ExtractFilePath(ParamStr(0)) + 'ExtendedMsg1.bin';
  Stream := TFileStream.Create(sFileName, fmOpenRead);
  try
    TestExtension := TTestMsg1Extension1.Create(nil);
    try
      TestExtension.LoadFromStream(Stream);
    finally
      TestExtension.Free;
    end;
  finally
    Stream.Free;
  end;

  ShowMessage('Success');
end;

procedure TForm15.btnSaveToPtotoBufClick(Sender: TObject);
var
  TestMsg1: TTestMsg1;
  TestExtension: TTestMsg1Extension1;
  Stream: TStream;
  sFileName: string;
begin
  // prepare container for output data
  // In this example we save objects to file
  sFileName := ExtractFilePath(ParamStr(0)) + 'Msg1.bin';
  Stream := TFileStream.Create(sFileName, fmCreate);
  try
    TestMsg1 := TTestMsg1.Create(nil);
    try
      // prepare data (random fill)
      TestMsg1.DefField1 := 20;
      TestMsg1.DefField9 := 1.5;
      TestMsg1.FieldArr1List.Add(743);
      TestMsg1.FieldImp1 := gVal1;

      // and now save data
      TestMsg1.SaveToStream(Stream);
    finally
      TestMsg1.Free;
    end;
  finally
    Stream.Free;
  end;

  sFileName := ExtractFilePath(ParamStr(0)) + 'ExtendedMsg1.bin';
  Stream := TFileStream.Create(sFileName, fmCreate);
  try
    TestExtension := TTestMsg1Extension1.Create(nil);
    try
      TestExtension.field_name_test_1 := 323;
      TestExtension.field_Name_test_2 := 5432;
      TestExtension.DefField2 := -3;
      TestExtension.DefField1 := 3;

      TestExtension.SaveToStream(Stream);
    finally
      TestExtension.Free;
    end;
  finally
    Stream.Free;
  end;
end;

procedure TForm15.btnSpeedTestClick(Sender: TObject);
  procedure GenerateData(msg: TTestMsg1);
  var
    i: Integer;
  begin
    for i := 0 to 9999 do
      begin
        msg.FieldArr3List.Add('foo some long-long value '+IntToStr(i));
        msg.FieldArr1List.Add(i);
      end;
  end;

var
  msgOutput, msgInput: TTestMsg1;
  Stream: TStream;

  dtStartSave: TDateTime;
  dtEndLoad: TDateTime;
begin
  Stream := TMemoryStream.Create;
  try
    msgOutput := TTestMsg1.Create(nil);
    msgInput := TTestMsg1.Create(nil);
    try
      GenerateData(msgOutput);

      dtStartSave := Now;

      msgOutput.SaveToStream(Stream);
      Stream.Seek(0, soBeginning);
      msgInput.LoadFromStream(Stream);

      dtEndLoad := Now;
    finally
      msgInput.Free;
      msgOutput.Free;
    end;
  finally
    Stream.Free;
  end;

  ShowMessage('ProtoBuf: 10 000 strings and 10 000 integers'#13#10'saved and loaded at ' + IntToStr(MillisecondsBetween(dtStartSave, dtEndLoad))+' milliseconds');
end;

end.
