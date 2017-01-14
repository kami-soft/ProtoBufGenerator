program ProtoBufGeneratorConsole;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  uProtoBufGenerator,
  uAbstractProtoBufClasses in '..\uAbstractProtoBufClasses.pas',
  StrBuffer in '..\StrBuffer.pas',
  pbPublic in '..\pbPublic.pas',
  pbOutput in '..\pbOutput.pas',
  pbInput in '..\pbInput.pas';

{ keys:
  /h /help - print help page
  /f / file - input file or folder name. Can be used several times.
  folder name should ends with '\'. If so, generator will search
  for all *.proto files in this folder
  /o /output - output folder. Folder must have write access rights.
}

const
  InputFileAliases: TArray<string> = ['f', 'file'];
  OutputFolderAliases: TArray<string> = ['o', 'output'];
  HelpAliases: TArray<string> = ['h', 'help'];

type
  TParam = record
    ParamKey: string;
    ParamValue: string;
    procedure Clear;
    function IsEmpty: Boolean;
  end;

  TParamList = class(TList<TParam>)
  public
    procedure Fill;

    function KeyExists(const KeyAliases: TArray<string>): Boolean;
    function FindParam(const KeyAliases: TArray<string>; const FromPos: integer = 0): integer;
  end;

  { TParamList }

procedure TParamList.Fill;
var
  i: integer;
  Param: TParam;
  s: string;
begin
  Clear;
  Param.Clear;
  for i := 1 to ParamCount do
    begin
      s := ParamStr(i);
      if s.StartsWith('/') or s.StartsWith('-') then
        begin
          if not Param.IsEmpty then
            Add(Param);
          Param.Clear;
          Param.ParamKey := s.Substring(1); // string helpers use zero-based strings
        end
      else
        Param.ParamValue := Param.ParamValue + s + ';';
    end;
  if not Param.IsEmpty then
    Add(Param);
end;

function TParamList.FindParam(const KeyAliases: TArray<string>; const FromPos: integer): integer;
var
  i: integer;
  j: integer;
begin
  Result := -1;
  for i := FromPos to Count - 1 do
    for j := 0 to Length(KeyAliases) do
      if SameText(Items[i].ParamKey, KeyAliases[j]) then
        begin
          Result := i;
          Break;
        end;
end;

function TParamList.KeyExists(const KeyAliases: TArray<string>): Boolean;
begin
  Result := FindParam(KeyAliases) <> -1;
end;

{ TParam }

procedure TParam.Clear;
begin
  ParamKey := '';
  ParamValue := '';
end;

procedure PrintHelp;
begin
  Writeln('/h /help  -  print help page');
  Writeln('/f / file -  input file or folder name. Can be used several times.');
  Writeln('             if you use folder name - generator will search');
  Writeln('             for all *.proto files in this folder');
  Writeln('             for parse several .proto files - separate them with space');
  Writeln('             do not forget to enquote paths with "", if them contains spaces');
  Writeln('/o /output - output folder. Folder must have write access rights.');
end;

procedure GenerateSingle(const InputFileOrDir, OutputDir: string);
var
  Gen: TProtoBufGenerator;
  procedure GenerateSingleFile(const InputFileName: string);
  begin
    Gen.Generate(InputFileName, OutputDir, TEncoding.UTF8);
  end;

  procedure GenerateDirectory(const Dir: string);
  var
    SR: TSearchRec;
    Res: integer;
  begin
    Res := FindFirst(IncludeTrailingPathDelimiter(Dir) + '*.proto', faAnyFile, SR);
    try
      while Res = 0 do
        begin
          GenerateSingleFile(IncludeTrailingPathDelimiter(Dir) + SR.Name);
          Res := FindNext(SR);
        end;
    finally
      FindClose(SR);
    end;
  end;

begin
  Gen := TProtoBufGenerator.Create;
  try
    if FileExists(InputFileOrDir) then
      GenerateSingleFile(InputFileOrDir)
    else
      if DirectoryExists(InputFileOrDir) then
        GenerateDirectory(InputFileOrDir);
  finally
    Gen.Free;
  end;
end;

procedure GenerateAll(ParamList: TParamList);
  procedure FillInputFileList(SL: TStrings);
  var
    i: integer;
  begin
    i := 0;
    while (ParamList.FindParam(InputFileAliases, i) <> -1) do
      begin
        SL.DelimitedText := SL.DelimitedText + ParamList[i].ParamValue;
        Inc(i);
      end;

    for i := SL.Count - 1 downto 0 do
      if Trim(SL[i]) = '' then
        SL.Delete(i)
      else
        SL[i] := Trim(SL[i]);
  end;

  function CheckFilesExists(SL: TStrings): Boolean;
  var
    i: integer;
  begin
    Result := True;
    for i := 0 to SL.Count - 1 do
      begin
        Result := FileExists(SL[i]) or DirectoryExists(SL[i]); // do not avoid files without '.proto' extencion
        if not Result then
          begin
            Writeln('input file or folder ' + SL[i] + ' does not exists');
            Break;
          end;
      end;

    if SL.Count = 0 then
      begin
        Writeln('input files not specified');
        Result := False;
      end;
  end;

  function FindOutputFolder(out Folder: string): Boolean;
  var
    i: integer;
  begin
    Result := False;
    i := ParamList.FindParam(OutputFolderAliases);
    if i = -1 then
      begin
        Writeln(' /o parameter not specified');
        exit;
      end;
    Folder := StringReplace(ParamList[i].ParamValue, ';', '', [rfReplaceAll]);

    if not DirectoryExists(Folder) then
      begin
        Writeln('output directory ' + Folder + ' does not exists');
        Folder := '';
        exit;
      end;
    Result := True;
  end;

var
  InputFileList: TStringList;
  OutputFolder: string;
  i: integer;
begin
  InputFileList := TStringList.Create;
  try
    InputFileList.Delimiter := ';';
    InputFileList.StrictDelimiter := True;
    FillInputFileList(InputFileList);
    if not CheckFilesExists(InputFileList) then
      exit;
    if not FindOutputFolder(OutputFolder) then
      exit;
    for i := 0 to InputFileList.Count - 1 do
      GenerateSingle(InputFileList[i], OutputFolder);
  finally
    InputFileList.Free;
  end;
end;

var
  ParamList: TParamList;

function TParam.IsEmpty: Boolean;
begin
  Result := ParamKey = '';
end;

begin
  try
    ParamList := TParamList.Create;
    try
      ParamList.Fill;

      if ParamList.KeyExists(HelpAliases) then
        PrintHelp
      else
        GenerateAll(ParamList);
    finally
      ParamList.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ToString);
  end;
  Readln;

end.
