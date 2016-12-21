unit TestAssign;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, test;

type
  TForm1 = class(TForm)
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    FStruct1: TTestStruct;
    FStruct2: TTestStruct;

    FPerson1: TPerson;
    FPerson2: TPerson;
    procedure InitData;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  pbOutput, pbInput, System.Diagnostics, System.TypInfo;

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  lvWatch: TStopwatch;
  lvStream: TMemoryStream;
  I: Integer;
begin
  FStruct2.Assign(FStruct1);
  Assert(FStruct1.ToString = FStruct2.ToString, 'Assign Fail!');

  lvStream := TMemoryStream.Create;
  lvWatch := TStopWatch.StartNew;
  for I := 0 to 100000 do
  begin
    lvStream.Clear;
    FStruct1.SaveToStream(lvStream);
  end;
  lvWatch.Stop;
  ShowMessage(Format('Save: %d', [lvWatch.ElapsedMilliseconds]));

  lvWatch.Reset;
  lvWatch.Start;
  for I := 0 to 100000 do
  begin
    FStruct1.LoadFromStream(lvStream);
  end;
  lvWatch.Stop;
  ShowMessage(Format('Load: %d', [lvWatch.ElapsedMilliseconds]));

//test Persion
  lvWatch.Reset;
  lvWatch.Start;
  for I := 0 to 100000 do
  begin
    lvStream.Clear;
    FPerson1.SaveToStream(lvStream);
  end;
  lvWatch.Stop;
  ShowMessage(Format('Save: %d', [lvWatch.ElapsedMilliseconds]));

  lvStream.Free;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  InitData;
end;

procedure TForm1.InitData;
var
  ver1, ver2: TVersionInfo;
  ph1, ph2: TPhoneNumber;
begin
  FStruct1 := TTestStruct.Create;
  FStruct2 := TTestStruct.Create;

  FStruct1.aint := 2;
  FStruct1.aword := 3;
  FStruct1.bword := 5;

  ver1 := TVersionInfo.Create;
  ver1.majorVersion := 1;
  ver1.minorVersion := 2;
  ver1.realease := 3;
  ver1.build := 4;
  FStruct1.lstVerList.Add(ver1);

  ver2 := TVersionInfo.Create;
  ver2.majorVersion := 5;
  ver2.minorVersion := 6;
  ver2.realease := 7;
  ver2.build := 8;
  FStruct1.lstVerList.Add(ver2);

  FStruct1.arrIntList.Add(10);
  FStruct1.arrIntList.Add(15);
  FStruct1.arrStrList.Add('123');
  FStruct1.arrStrList.Add('456');

  //TPersion
  FPerson1 := TPerson.Create;
  FPerson1.Name := 'Marat Shaymardanov';
  FPerson1.Id := 1;
  FPerson1.Email := 'marat-sh@sibmail.com';
  ph1 := TPhoneNumber.Create;
  ph1.ptype := TPhoneType.HOME;
  ph1.number := '+7 392 224 3699';
  FPerson1.phoneList.Add(ph1);

  ph2 := TPhoneNumber.Create;
  ph2.ptype := TPhoneType.MOBILE;
  ph2.number := '+7 913 826 2144';
  FPerson1.phoneList.Add(ph2);
end;

end.
