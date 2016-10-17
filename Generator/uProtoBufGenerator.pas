unit uProtoBufGenerator;

interface

uses
  System.SysUtils,
  System.Classes,
  uAbstractProtoBufClasses,
  uProtoBufParserAbstractClasses,
  uProtoBufParserClasses;

type
  TProtoBufGenerator = class(TObject)
  strict private
    procedure GenerateInterfaceSection(Proto: TProtoFile; SL: TStrings);
    procedure GenerateImplementationSection(Proto: TProtoFile; SL: TStrings);
  public
    procedure Generate(Proto: TProtoFile; Output: TStrings); overload;
    procedure Generate(Proto: TProtoFile; OutputStream: TStream; Encoding: TEncoding = nil); overload;
    procedure Generate(Proto: TProtoFile; const OutputDir: string; Encoding: TEncoding = nil); overload;
  end;

implementation

function ProtoPropTypeToDelphiType(const PropTypeName: string): string;
var
  StandartType: TScalarPropertyType;
begin
  StandartType := StrToPropertyType(PropTypeName);
  case StandartType of
    sptDouble:
      Result := 'Double';
    sptFloat:
      Result := 'Float';
    sptInt32:
      Result := 'integer';
    sptInt64:
      Result := 'Int64';
    sptuInt32:
      Result := 'Cardinal';
    sptUint64:
      Result := 'UInt64';
    sptSInt32:
      Result := 'integer';
    sptSInt64:
      Result := 'Int64';
    sptFixed32:
      Result := 'integer';
    sptFixed64:
      Result := 'Int64';
    sptSFixed32:
      Result := 'integer';
    sptSFixed64:
      Result := 'Int64';
    sptBool:
      Result := 'Boolean';
    sptString:
      Result := 'string';
    sptBytes:
      Result := 'TBytes';
  else
    Result := 'T' + PropTypeName;
  end;
end;

type
  TDelphiProperty = record
    IsList: Boolean;
    isComplex: Boolean;
    isObject: Boolean;
    PropertyName: string;
    PropertyType: string;
  end;

procedure ParsePropType(Prop: TProtoBufProperty; Proto: TProtoFile; out DelphiProp: TDelphiProperty);
begin
  DelphiProp.IsList := Prop.PropKind = ptRepeated;
  DelphiProp.isComplex := StrToPropertyType(Prop.PropType) = sptComplex;
  if DelphiProp.isComplex then
    DelphiProp.isObject := Assigned(Proto.ProtoBufMessages.FindByName(Prop.PropType))
  else
    DelphiProp.isObject := False;
  if not DelphiProp.IsList then
    begin
      DelphiProp.PropertyName := Prop.Name;
      DelphiProp.PropertyType := ProtoPropTypeToDelphiType(Prop.PropType);
    end
  else
    begin
      DelphiProp.PropertyName := Format('%sList', [Prop.Name]);
      if DelphiProp.isObject then
        DelphiProp.PropertyType := Format('TProtoBufClassList<%s>', [ProtoPropTypeToDelphiType(Prop.PropType)])
      else
        DelphiProp.PropertyType := Format('TList<%s>', [ProtoPropTypeToDelphiType(Prop.PropType)]);
    end;

end;

{ TProtoBufGenerator }

procedure TProtoBufGenerator.Generate(Proto: TProtoFile; Output: TStrings);
var
  SLInterface, SLImplementation: TStrings;
begin
  // write name and interface uses
  SLInterface := TStringList.Create;
  try
    SLImplementation := TStringList.Create;
    try
      GenerateInterfaceSection(Proto, SLInterface);
      GenerateImplementationSection(Proto, SLImplementation);

      Output.Clear;
      Output.AddStrings(SLInterface);
      Output.AddStrings(SLImplementation);
    finally
      SLImplementation.Free;
    end;
  finally
    SLInterface.Free;
  end;
end;

procedure TProtoBufGenerator.Generate(Proto: TProtoFile; OutputStream: TStream; Encoding: TEncoding);
var
  SL: TStrings;
begin
  SL := TStringList.Create;
  try
    SL.WriteBOM := True;
    Generate(Proto, SL);
    SL.SaveToStream(OutputStream, Encoding);
  finally
    SL.Free;
  end;
end;

procedure TProtoBufGenerator.Generate(Proto: TProtoFile; const OutputDir: string; Encoding: TEncoding);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(IncludeTrailingPathDelimiter(OutputDir) + Proto.Name + '.pas', fmCreate);
  try
    Generate(Proto, FS, Encoding);
  finally
    FS.Free;
  end;
end;

procedure TProtoBufGenerator.GenerateImplementationSection(Proto: TProtoFile; SL: TStrings);
begin

end;

procedure TProtoBufGenerator.GenerateInterfaceSection(Proto: TProtoFile; SL: TStrings);
  procedure WriteEnumToSL(ProtoEnum: TProtoBufEnum; SL: TStrings);
  var
    i: Integer;
    s: string;
  begin
    SL.Add(Format('  T%s=(', [ProtoEnum.Name]));
    for i := 0 to ProtoEnum.Count - 1 do
      begin
        if i < (ProtoEnum.Count - 1) then
          s := ','
        else
          s := '';
        SL.Add(Format('    %s = %d%s', [ProtoEnum[i].Name, ProtoEnum[i].Value, s]));
      end;
    SL.Add('  );');
  end;

  procedure WriteMessageToSL(ProtoMsg: TProtoBufMessage; SL: TStrings);
  var
    i: Integer;
    Prop: TProtoBufProperty;
    DelphiProp: TDelphiProperty;
    bNeedConstructor: Boolean;
    s: string;
  begin
    bNeedConstructor := False;
    SL.Add(Format('  T%s = class(TAbstractProtoBufClass)', [ProtoMsg.Name]));
    SL.Add('  strict private');
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);
        s := Format('    F%s: %s;', [DelphiProp.PropertyName, DelphiProp.PropertyType]);
        SL.Add(s);
        bNeedConstructor := bNeedConstructor or DelphiProp.IsList or DelphiProp.isObject or Prop.PropOptions.HasValue['default'];
      end;
    SL.Add('  public');
    if bNeedConstructor then
      begin
        SL.Add('    constructor Create; override;');
        SL.Add('    destructor Destroy; override;');
        SL.Add('');
      end;
    SL.Add('    procedure LoadFromBuf(ProtoBuf: TProtoBufInput); override;');
    SL.Add('    procedure SaveToBuf(ProtoBuf: TProtoBufOutput); override;');
    SL.Add('');
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);
        s := Format('    property %s:%s read F%s', [DelphiProp.PropertyName, DelphiProp.PropertyType, DelphiProp.PropertyName]);
        if not(DelphiProp.IsList or DelphiProp.isObject) then
          s := s + Format(' write F%s', [DelphiProp.PropertyName]);
        if Prop.PropOptions.HasValue['default'] then
          s := s + Format(' default %s', [StringReplace(Prop.PropOptions.Value['default'], '"', '''', [rfReplaceAll])]);
        s := s + ';';
        SL.Add(s);
      end;
    SL.Add('  end;');
  end;

var
  i: Integer;
begin
  SL.Add(Format('unit %s', [Proto.Name]));
  SL.Add('');
  SL.Add('interface');
  SL.Add('');
  SL.Add('uses');
  SL.Add('  System.Generics.Collections,');
  SL.Add('  uAbstractProtoBufClasses;');
  SL.Add('');
  SL.Add('type');
  // add all enums
  for i := 0 to Proto.ProtoBufEnums.Count - 1 do
    begin
      WriteEnumToSL(Proto.ProtoBufEnums[i], SL);
      SL.Add('');
    end;

  // add all classes definitions
  for i := 0 to Proto.ProtoBufMessages.Count - 1 do
    begin
      WriteMessageToSL(Proto.ProtoBufMessages[i], SL);
      SL.Add('');
    end;
end;

end.
