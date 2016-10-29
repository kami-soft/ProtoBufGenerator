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

uses
  System.StrUtils;

function ProtoPropTypeToDelphiType(const PropTypeName: string): string;
var
  StandartType: TScalarPropertyType;
begin
  StandartType := StrToPropertyType(PropTypeName);
  case StandartType of
    sptDouble:
      Result := 'Double';
    sptFloat:
      Result := 'Single';
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

function GetProtoBufMethodForScalarType(const PropTypeName: string): string;
var
  StandartType: TScalarPropertyType;
begin
  StandartType := StrToPropertyType(PropTypeName);
  case StandartType of
    sptComplex:
      ;
    sptDouble:
      Result := 'Double';
    sptFloat:
      Result := 'Float';
    sptInt32:
      Result := 'Int32';
    sptInt64:
      Result := 'Int64';
    sptuInt32:
      Result := 'UInt32';
    sptUint64:
      Result := 'Int64';
    sptSInt32:
      Result := 'SInt32';
    sptSInt64:
      Result := 'SInt64';
    sptFixed32:
      Result := 'Fixed32';
    sptFixed64:
      Result := 'Fixed64';
    sptSFixed32:
      Result := 'SFixed32';
    sptSFixed64:
      Result := 'SFixed64';
    sptBool:
      Result := 'Boolean';
    sptString:
      Result := 'String';
    sptBytes:
      Result := 'Bytes';
  end;
end;

function ReQuoteStr(const Str: string): string;
begin
  Result := Str;
  if not StartsStr('"', Str) then
    Exit;

  Result := StringReplace(Str, '''', '''''', [rfReplaceAll]);
  Result := StringReplace(Result, '""', '"', [rfReplaceAll]);
  Result[1] := '''';
  Result[Length(Result)] := '''';
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

function MsgNeedConstructor(ProtoMsg: TProtoBufMessage; Proto: TProtoFile): Boolean;
var
  i: integer;
  DelphiProp: TDelphiProperty;
  Prop: TProtoBufProperty;
begin
  Result := False;
  for i := 0 to ProtoMsg.Count - 1 do
    begin
      Prop := ProtoMsg[i];
      ParsePropType(Prop, Proto, DelphiProp);
      Result := (Prop.PropKind = ptRequired) or DelphiProp.IsList or DelphiProp.isObject or Prop.PropOptions.HasValue['default'];
      if Result then
        Break;
    end;
end;

function MsgContainsRepeatedFields(ProtoMsg: TProtoBufMessage): Boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to ProtoMsg.Count - 1 do
    if ProtoMsg[i].PropKind = TPropKind.ptRepeated then
      begin
        Result := True;
        Break;
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
  procedure WriteConstructor(ProtoMsg: TProtoBufMessage; SL: TStrings);
  var
    Prop: TProtoBufProperty;
    DelphiProp: TDelphiProperty;
    i: integer;
  begin
    SL.Add('');
    SL.Add(Format('constructor T%s.Create;', [ProtoMsg.Name]));
    SL.Add('begin');
    SL.Add('  inherited;');
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);
        if DelphiProp.IsList or DelphiProp.isObject then
          SL.Add(Format('  F%s := %s.Create;', [DelphiProp.PropertyName, DelphiProp.PropertyType]));
        if Prop.PropOptions.HasValue['default'] then
          SL.Add(Format('  F%s := %s;', [DelphiProp.PropertyName, ReQuoteStr(Prop.PropOptions.Value['default'])]));
        if Prop.PropKind = ptRequired then
          SL.Add(Format('  RegisterRequiredField(%d);', [Prop.PropTag]));
      end;
    SL.Add('end;');

    SL.Add('');
    SL.Add(Format('destructor T%s.Destroy;', [ProtoMsg.Name]));
    SL.Add('begin');
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);
        if DelphiProp.IsList or DelphiProp.isObject then
          SL.Add(Format('  F%s.Free;', [DelphiProp.PropertyName]));
      end;
    SL.Add('  inherited;');
    SL.Add('end;');
  end;

  procedure WriteLoadProc(ProtoMsg: TProtoBufMessage; SL: TStrings);
  var
    i: integer;
    Prop: TProtoBufProperty;
    DelphiProp: TDelphiProperty;
  begin
    SL.Add('');
    SL.Add(Format('procedure T%s.LoadFromBuf(ProtoBuf: TProtoBufInput);', [ProtoMsg.Name]));
    SL.Add('var');
    SL.Add('  fieldNumber: integer;');
    SL.Add('  Tag: integer;');
    if MsgNeedConstructor(ProtoMsg, Proto) then
      SL.Add('  tmpBuf: TProtoBufInput;'); // avoid compiler hint
    SL.Add('begin');
    SL.Add('  Tag := ProtoBuf.readTag;');
    SL.Add('  while Tag <> 0 do');
    SL.Add('    begin');
    SL.Add('      fieldNumber := getTagFieldNumber(Tag);');
    if ProtoMsg.Count > 0 then
      begin
        SL.Add('      case fieldNumber of');
        for i := 0 to ProtoMsg.Count - 1 do
          begin
            Prop := ProtoMsg[i];
            ParsePropType(Prop, Proto, DelphiProp);
            SL.Add(Format('        %d:', [Prop.PropTag]));
            SL.Add('          begin');
            if not DelphiProp.IsList then
              begin
                if not DelphiProp.isComplex then
                  SL.Add(Format('            F%s := ProtoBuf.read%s;', [DelphiProp.PropertyName, GetProtoBufMethodForScalarType(Prop.PropType)]))
                else
                  if not DelphiProp.isObject then
                    SL.Add(Format('            F%s := %s(ProtoBuf.readEnum);', [DelphiProp.PropertyName, DelphiProp.PropertyType]))
                  else
                    begin
                      SL.Add('            tmpBuf := ProtoBuf.ReadSubProtoBufInput;');
                      SL.Add('            try');
                      SL.Add(Format('              F%s.LoadFromBuf(tmpBuf);', [DelphiProp.PropertyName]));
                      SL.Add('            finally');
                      SL.Add('              tmpBuf.Free;');
                      SL.Add('            end;');
                    end;
              end
            else
              begin
                if not DelphiProp.isComplex then
                  SL.Add(Format('            F%s.Add(ProtoBuf.read%s);', [DelphiProp.PropertyName, GetProtoBufMethodForScalarType(Prop.PropType)]))
                else
                  if not DelphiProp.isObject then
                    SL.Add(Format('            F%s.Add(T%s(ProtoBuf.readEnum));', [DelphiProp.PropertyName, Prop.PropType]))
                  else
                    SL.Add(Format('            F%s.AddFromBuf(ProtoBuf, fieldNumber);', [DelphiProp.PropertyName]));
              end;
            SL.Add('          end;');
          end;
        SL.Add('      else');
        SL.Add('        ProtoBuf.skipField(Tag);');
        SL.Add('      end;');
      end
    else
      SL.Add('      ProtoBuf.skipField(Tag);');
    SL.Add('      AddLoadedField(fieldNumber);');
    SL.Add('      Tag := ProtoBuf.readTag;');
    SL.Add('    end;');
    SL.Add('  if not IsAllRequiredLoaded then');
    SL.Add('    raise EStreamError.Create(''not enought fields'');');
    SL.Add('end;');
  end;

  procedure WriteSaveProc(ProtoMsg: TProtoBufMessage; SL: TStrings);
  var
    i: integer;
    Prop: TProtoBufProperty;
    DelphiProp: TDelphiProperty;
  begin
    SL.Add('');
    SL.Add(Format('procedure T%s.SaveToBuf(ProtoBuf: TProtoBufOutput);', [ProtoMsg.Name]));
    if MsgNeedConstructor(ProtoMsg, Proto) or MsgContainsRepeatedFields(ProtoMsg) then // avoid compiler hints
      begin
        SL.Add('var');
        if MsgNeedConstructor(ProtoMsg, Proto) then
          SL.Add('  tmpBuf: TProtoBufOutput;');
        if MsgContainsRepeatedFields(ProtoMsg) then
          SL.Add('  i: integer;');
      end;
    SL.Add('begin');
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);

        if not DelphiProp.IsList then
          begin
            if not DelphiProp.isComplex then
              SL.Add(Format('  ProtoBuf.write%s(%d, F%s);', [GetProtoBufMethodForScalarType(Prop.PropType), Prop.PropTag, DelphiProp.PropertyName]))
            else
              if not DelphiProp.isObject then
                SL.Add(Format('  ProtoBuf.writeInt32(%d, integer(F%s));', [Prop.PropTag, DelphiProp.PropertyName]))
              else
                begin
                  SL.Add('  tmpBuf:=TProtoBufOutput.Create;');
                  SL.Add('  try');
                  SL.Add(Format('    F%s.SaveToBuf(tmpBuf);', [DelphiProp.PropertyName]));
                  SL.Add(Format('    ProtoBuf.writeMessage(%d, tmpBuf);', [Prop.PropTag]));
                  SL.Add('  finally');
                  SL.Add('    tmpBuf.Free;');
                  SL.Add('  end;');
                end;
          end
        else
          begin
            if not DelphiProp.isComplex then
              begin
                SL.Add(Format('  for i := 0 to F%s.Count-1 do', [DelphiProp.PropertyName]));
                SL.Add(Format('    ProtoBuf.write%s(%d, F%s[i]);', [GetProtoBufMethodForScalarType(Prop.PropType), Prop.PropTag, DelphiProp.PropertyName]));
              end
            else
              if not DelphiProp.isObject then
                begin
                  SL.Add(Format('  for i := 0 to F%s.Count-1 do', [DelphiProp.PropertyName]));
                  SL.Add(Format('    ProtoBuf.writeInt32(%d, F%s[i]);', [Prop.PropTag, DelphiProp.PropertyName]));
                end
              else
                SL.Add(Format('    F%s.SaveToBuf(ProtoBuf, %d);', [DelphiProp.PropertyName, Prop.PropTag]));
          end;
      end;

    SL.Add('end;');
  end;

  procedure WriteMessageToSL(ProtoMsg: TProtoBufMessage; SL: TStrings);
  var
    bNeedConstructor: Boolean;
  begin
    bNeedConstructor := MsgNeedConstructor(ProtoMsg, Proto);

    if bNeedConstructor then
      WriteConstructor(ProtoMsg, SL);
    WriteLoadProc(ProtoMsg, SL);
    WriteSaveProc(ProtoMsg, SL);
  end;

var
  i: integer;
begin
  SL.Add('');
  SL.Add('implementation');

  for i := 0 to Proto.ProtoBufMessages.Count - 1 do
    begin
      SL.Add('');
      WriteMessageToSL(Proto.ProtoBufMessages[i], SL);
    end;
  SL.Add('');
  SL.Add('end.');
end;

procedure TProtoBufGenerator.GenerateInterfaceSection(Proto: TProtoFile; SL: TStrings);
  procedure WriteEnumToSL(ProtoEnum: TProtoBufEnum; SL: TStrings);
  var
    i: integer;
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
    i: integer;
    Prop: TProtoBufProperty;
    DelphiProp: TDelphiProperty;
    bNeedConstructor: Boolean;
    s, sdefValue: string;
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
        if Prop.PropComment <> '' then
          SL.Add('//' + Prop.PropComment);
        s := Format('    property %s:%s read F%s', [DelphiProp.PropertyName, DelphiProp.PropertyType, DelphiProp.PropertyName]);
        if not(DelphiProp.IsList or DelphiProp.isObject) then
          s := s + Format(' write F%s', [DelphiProp.PropertyName]);
        if Prop.PropOptions.HasValue['default'] then
          begin
            sdefValue := Prop.PropOptions.Value['default'];
            if StartsStr('"', sdefValue) or ContainsStr(sdefValue, '.') or ContainsStr(sdefValue, 'e') then
              s := s + '; //';
            s := s + Format(' default %s', [ReQuoteStr(sdefValue)]);
          end;
        s := s + ';';
        SL.Add(s);
      end;
    SL.Add('  end;');
  end;

var
  i: integer;
begin
  SL.Add(Format('unit %s;', [Proto.Name]));
  SL.Add('');
  SL.Add('interface');
  SL.Add('');
  SL.Add('// *********************************** ');
  SL.Add(Format('//   classes for %s.proto', [Proto.Name]));
  SL.Add('//   generated by ProtoBufGenerator ');
  SL.Add('//             kami-soft 2016');
  SL.Add('// ***********************************');
  SL.Add('uses');
  SL.Add('  System.SysUtils,');
  SL.Add('  System.Classes,');
  SL.Add('  System.Generics.Collections,');
  SL.Add('  pbInput,');
  SL.Add('  pbOutput,');
  SL.Add('  pbPublic,');
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
