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
  Vcl.StdCtrls,
  Vcl.ExtCtrls;

type
  TfmMain = class(TForm)
    edProtoFileName: TEdit;
    btnOpenProtoFile: TButton;
    odProtoFile: TFileOpenDialog;
    btnGenerate: TButton;
    edOutputFolder: TEdit;
    btnChooseOutputFolder: TButton;
    lblInput: TLabel;
    lblOutput: TLabel;
    btnChooseProtoInputFolder: TButton;
    procedure btnOpenProtoFileClick(Sender: TObject);
    procedure btnChooseOutputFolderClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure btnChooseProtoInputFolderClick(Sender: TObject);
  private
    { Private declarations }
    procedure Generate(SourceFiles: TStrings; const OutputDir: string);
  public
    { Public declarations }
  end;

var
  fmMain: TfmMain;

implementation

uses
  System.IOUtils,
  System.IniFiles,
  Vcl.FileCtrl,
  uProtoBufGenerator;

{$R *.dfm}

procedure TfmMain.btnChooseOutputFolderClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edOutputFolder.Text;
  if SelectDirectory('Select output directory', '', Dir, [sdNewFolder, sdShowShares, sdNewUI, sdValidateDir], nil) then
    edOutputFolder.Text := Dir;
end;

procedure TfmMain.btnChooseProtoInputFolderClick(Sender: TObject);
var
  LFileList: TArray<string>;
  i: Integer;
begin
  odProtoFile.Options := odProtoFile.Options + [fdoPickFolders];
  if odProtoFile.Execute then
  begin
    edProtoFileName.Text := '';
    LFileList := TDirectory.GetFiles(odProtoFile.FileName,'*.proto', TSearchOption.soAllDirectories);
    for i := 0 to Length(LFileList) -1 do
    begin
      edProtoFileName.Text := edProtoFileName.Text + LFileList[i];
      if i <> Length(LFileList) -1 then
        edProtoFileName.Text := edProtoFileName.Text + odProtoFile.Files.Delimiter;
    end;

  end;
  odProtoFile.Options := odProtoFile.Options - [fdoPickFolders];
end;

procedure TfmMain.btnGenerateClick(Sender: TObject);
var
  FileNames: TStrings;
begin
  FileNames := TStringList.Create;
  try
    FileNames.Delimiter := odProtoFile.Files.Delimiter;
    FileNames.DelimitedText := edProtoFileName.Text;
    Generate(FileNames, edOutputFolder.Text);
    ShowMessage('Complete! Take a look into output directory');
  finally
    FileNames.Free;
  end;
end;

procedure TfmMain.btnOpenProtoFileClick(Sender: TObject);
begin
  if odProtoFile.Execute then
    edProtoFileName.Text := odProtoFile.Files.DelimitedText;
end;

procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
  ini: TIniFile;
  s: string;
begin
  s := TPath.Combine(TPath.GetHomePath, 'DelphiProtoBufGenerator');
  TDirectory.CreateDirectory(s);
  s := TPath.Combine(s, 'settings.ini');
  ini := TIniFile.Create(s);
  try
    ini.WriteString('Common', 'ProtoFiles', edProtoFileName.Text);
    ini.WriteString('Common', 'PasOutputFolder', edOutputFolder.Text);
  finally
    ini.Free;
  end;
end;

procedure TfmMain.FormCreate(Sender: TObject);
var
  ini: TIniFile;
  s: string;
begin
  s := TPath.Combine(TPath.GetHomePath, 'DelphiProtoBufGenerator');
  TDirectory.CreateDirectory(s);
  s := TPath.Combine(s, 'settings.ini');
  ini := TIniFile.Create(s);
  try
    edProtoFileName.Text := ini.ReadString('Common', 'ProtoFiles', '');
    edOutputFolder.Text := ini.ReadString('Common', 'PasOutputFolder', '');
  finally
    ini.Free;
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

end.
