unit ufmMain;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls;

type
  TfmMain = class(TForm)
    edtProtoFiles: TEdit;
    btnOpenProtoFile: TButton;
    odProtoFile: TFileOpenDialog;
    btnGenerate: TButton;
    edtOutputFolder: TEdit;
    btnChooseOutputFolder: TButton;
    procedure btnOpenProtoFileClick(Sender: TObject);
    procedure btnChooseOutputFolderClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FFiles: TArray<string>;
    FFileCount: Integer;

    procedure ClearFiles;
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;
  end;

  { Files Drop Class }
  TFileCatcher = class(TObject)
  private
    FDropHandle: THANDLE;
    function GetFile(Idx: Integer): string;
    function GetFileCount: Integer;
    function GetPoint: TPoint;
    procedure Generate(SourceFiles: TStrings; const OutputDir: string);
  public
    constructor Create(DropHandle: THANDLE);
    destructor Destroy; override;
    property FileCount: Integer read GetFileCount;
    property Files[Idx: Integer]: string read GetFile;
    property DropPoint: TPoint read GetPoint;
  end;

var
  fmMain: TfmMain;

implementation

uses
  Vcl.FileCtrl,
  Winapi.ShellAPI,
  uProtoBufGenerator;

const
  PROTO = '.proto';

{$R *.dfm}

procedure TfmMain.btnChooseOutputFolderClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtOutputFolder.Text;
  if SelectDirectory('choose output dir', '', Dir, [sdNewFolder, sdShowShares, sdNewUI, sdValidateDir], nil)
  then
    edtOutputFolder.Text := Dir;
end;

procedure TfmMain.btnGenerateClick(Sender: TObject);
var
  FileNames: TStrings;
  I: Integer;
begin
  FileNames := TStringList.Create;
  if edtOutputFolder.Text <> '' then
    ForceDirectories(edtOutputFolder.Text);

  Gen := TProtoBufGenerator.Create;
  try
    FileNames.Delimiter:=odProtoFile.Files.Delimiter;
    FileNames.DelimitedText:=edProtoFileName.Text;
    Generate(FileNames, edOutputFolder.Text);
    ShowMessage('Complete! Take a look into output directory');
    for I := 0 to Pred(FFileCount) do
    begin
      Gen.Generate(FFiles[I], edtOutputFolder.Text, TEncoding.UTF8);
    end;
  finally
    FileNames.Free;
  end;
end;

procedure TfmMain.btnOpenProtoFileClick(Sender: TObject);
var
  I: Integer;
begin
  if odProtoFile.Execute then
    edProtoFileName.Text := odProtoFile.Files.DelimitedText;
  begin
    FFileCount := odProtoFile.Files.Count;
    SetLength(FFiles, FFileCount);
    for I := 0 to Pred(FFileCount) do
    begin
      FFiles[I] := odProtoFile.Files[I];
      edtProtoFiles.Text := edtProtoFiles.Text + ExtractFileName(FFiles[I]) + ';';
    end;
  end;
end;

procedure TfmMain.Generate(SourceFiles: TStrings; const OutputDir: string);
var
  Gen: TProtoBufGenerator;
  i: Integer;
begin
  System.SysUtils.ForceDirectories(OutputDir);
  Gen := TProtoBufGenerator.Create;
  try
    for i := 0 to SourceFiles.Count - 1 do
      Gen.Generate(SourceFiles[i], edOutputFolder.Text, TEncoding.UTF8);
  finally
    Gen.Free;
  end;
end;
procedure TfmMain.ClearFiles;
begin
  SetLength(FFiles, 0);
  FFileCount := 0;
  edtProtoFiles.Text := '';
  edtProtoFiles.Font.Color := clWindowText;
end;

{ Drop Files Action }
procedure TfmMain.FormCreate(Sender: TObject);
begin
  odProtoFile.DefaultFolder := '.\';
  odProtoFile.DefaultExtension := PROTO;
  odProtoFile.Options := odProtoFile.Options + [fdoAllowMultiSelect];

  DragAcceptFiles(Self.Handle, True);
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  DragAcceptFiles(Self.Handle, False);
end;

procedure TfmMain.WMDropFiles(var Msg: TWMDropFiles);
var
  I, Len: Integer;
  Catcher: TFileCatcher;
begin
  inherited;
  ClearFiles;

  Catcher := TFileCatcher.Create(Msg.Drop);
  try
    FFileCount := Catcher.FileCount;
    SetLength(FFiles, FFileCount);
    for I := 0 to Pred(FFileCount) do
    begin
      FFiles[I] := Catcher.Files[I];
      if SameText(ExtractFileExt(FFiles[I]), PROTO) then
      begin
        edtProtoFiles.Text := edtProtoFiles.Text + ExtractFileName(FFiles[I]) + ';';
      end
      else
      begin
        edtProtoFiles.Font.Color := clRed;
        edtProtoFiles.Text := Format('Files Type need %s !!!', [PROTO]);
      end;
    end;
  finally
    Catcher.Free;
  end;
  Msg.Result := 0;
end;

{ TFileCatcher }

constructor TFileCatcher.Create(DropHandle: HDROP);
begin
  inherited Create;
  FDropHandle := DropHandle;
end;

destructor TFileCatcher.Destroy;
begin
  DragFinish(FDropHandle);
  inherited;
end;

function TFileCatcher.GetFile(Idx: Integer): string;
var
  FileNameLen: Integer;
begin
  FileNameLen := DragQueryFile(FDropHandle, Idx, nil, 0);
  SetLength(Result, FileNameLen);
  DragQueryFile(FDropHandle, Idx, PChar(Result), FileNameLen + 1);
end;

function TFileCatcher.GetFileCount: Integer;
begin
  Result := DragQueryFile(FDropHandle, $FFFFFFFF, nil, 0);
end;

function TFileCatcher.GetPoint: TPoint;
begin
  DragQueryPoint(FDropHandle, Result);
end;

end.
