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
    procedure Generate(const InputFile: string; const OutputDir: string; Encoding: TEncoding = nil); overload;
  end;

implementation

uses
  System.StrUtils;

function ProtoPropTypeToDelphiType(const PropTypeName: string): string;
var
  StandartType: TScalarPropertyType;
  i: integer;
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
    i := LastDelimiter('.', PropTypeName);
    Result := 'T'+Copy(PropTypeName, i+1, Length(PropTypeName));
  end;
end;

function PropertyIsPrimitiveNumericPacked(Prop: TProtoBufProperty): Boolean;
begin
  Result := (Prop.PropOptions.Value['packed'] = 'true') and (StrToPropertyType(Prop.PropType) in [sptDouble, sptFloat, sptInt32, sptInt64, sptuInt32, sptUint64,
    sptSInt32, sptSInt64, sptBool, sptFixed32, sptSFixed32, sptFixed64, sptSFixed64])
end;

function GetProtoBufMethodForScalarType(const Prop: TProtoBufProperty): string;
var
  StandartType: TScalarPropertyType;
  bPacked: Boolean;
begin
  StandartType := StrToPropertyType(Prop.PropType);
  bPacked := (Prop.PropKind = ptRepeated) and PropertyIsPrimitiveNumericPacked(Prop);

  case StandartType of
    sptComplex:
      ;
    sptDouble:
      if bPacked then
        Result := 'RawData'
      else
        Result := 'Double';
    sptFloat:
      if bPacked then
        Result := 'RawData'
      else
        Result := 'Float';
    sptInt32:
      if bPacked then
        Result := 'RawVarint32'
      else
        Result := 'Int32';
    sptInt64:
      if bPacked then
        Result := 'RawVarint64'
      else
        Result := 'Int64';
    sptuInt32:
      if bPacked then
        Result := 'RawVarint32'
      else
        Result := 'UInt32';
    sptUint64:
      if bPacked then
        Result := 'RawVarint64'
      else
        Result := 'Int64';
    sptSInt32:
      if bPacked then
        Result := 'RawSInt32'
      else
        Result := 'SInt32';
    sptSInt64:
      if bPacked then
        Result := 'RawSInt64'
      else
        Result := 'SInt64';
    sptFixed32:
      if bPacked then
        Result := 'RawData'
      else
        Result := 'Fixed32';
    sptFixed64:
      if bPacked then
        Result := 'RawData'
      else
        Result := 'Fixed64';
    sptSFixed32:
      if bPacked then
        Result := 'RawData'
      else
        Result := 'SFixed32';
    sptSFixed64:
      if bPacked then
        Result := 'RawData'
      else
        Result := 'SFixed64';
    sptBool:
      if bPacked then
        Result := 'RawBoolean'
      else
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
          SL.Add(Format('  RegisterRequiredField(%d);', [Prop.PropFieldNum]));
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
    SL.Add(Format('function T%s.LoadSingleFieldFromBuf(ProtoBuf: TProtoBufInput; FieldNumber: integer; WireType: integer): Boolean;', [ProtoMsg.Name]));
    if MsgNeedConstructor(ProtoMsg, Proto) then
      begin
        SL.Add('var');
        SL.Add('  tmpBuf: TProtoBufInput;'); // avoid compiler hint
      end;
    SL.Add('begin');
    SL.Add('  Result := inherited LoadSingleFieldFromBuf(ProtoBuf, FieldNumber, WireType);');
    if ProtoMsg.Count = 0 then
      begin
        SL.Add('end;');
        Exit;
      end;
    SL.Add('  if Result then');
    SL.Add('    exit;');
    SL.Add('  case FieldNumber of');
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);
        SL.Add(Format('    %d:', [Prop.PropFieldNum]));
        SL.Add('      begin');
        if not DelphiProp.IsList then
          begin
            if not DelphiProp.isComplex then
              SL.Add(Format('        F%s := ProtoBuf.read%s;', [DelphiProp.PropertyName, GetProtoBufMethodForScalarType(Prop)]))
            else
              if not DelphiProp.isObject then
                SL.Add(Format('        F%s := %s(ProtoBuf.readEnum);', [DelphiProp.PropertyName, DelphiProp.PropertyType]))
              else
                begin
                  SL.Add('        tmpBuf := ProtoBuf.ReadSubProtoBufInput;');
                  SL.Add('        try');
                  SL.Add(Format('          F%s.LoadFromBuf(tmpBuf);', [DelphiProp.PropertyName]));
                  SL.Add('        finally');
                  SL.Add('          tmpBuf.Free;');
                  SL.Add('        end;');
                end;
          end
        else
          begin
            if not DelphiProp.isComplex then
              begin
                if PropertyIsPrimitiveNumericPacked(Prop) then
                  begin
                    SL.Add('        if WireType = WIRETYPE_LENGTH_DELIMITED then');
                    SL.Add('          begin');
                    SL.Add('            tmpBuf:=ProtoBuf.ReadSubProtoBufInput;');
                    SL.Add('            try');
                    SL.Add('              while tmpBuf.getPos<tmpBuf.BufSize do');
                    SL.Add(Format('                F%s.Add(tmpBuf.read%s);', [DelphiProp.PropertyName, GetProtoBufMethodForScalarType(Prop)]));
                    SL.Add('            finally');
                    SL.Add('              tmpBuf.Free;');
                    SL.Add('            end;');
                    SL.Add('          end');
                    SL.Add('        else');
                    SL.Add(Format('          F%s.Add(ProtoBuf.read%s);', [DelphiProp.PropertyName, GetProtoBufMethodForScalarType(Prop)]));
                  end
                else
                  SL.Add(Format('        F%s.Add(ProtoBuf.read%s);', [DelphiProp.PropertyName, GetProtoBufMethodForScalarType(Prop)]));
              end
            else
              if not DelphiProp.isObject then
                begin
                  if (Prop.PropOptions.Value['packed'] = 'true') then
                    begin
                      SL.Add('        if WireType = WIRETYPE_LENGTH_DELIMITED then');
                      SL.Add('          begin');
                      SL.Add('            tmpBuf:=ProtoBuf.ReadSubProtoBufInput;');
                      SL.Add('            try');
                      SL.Add('              while tmpBuf.getPos<tmpBuf.BufSize do');
                      SL.Add(Format('                F%s.Add(T%s(tmpBuf.readEnum));', [DelphiProp.PropertyName, Prop.PropType]));
                      SL.Add('            finally');
                      SL.Add('              tmpBuf.Free;');
                      SL.Add('            end;');
                      SL.Add('          end');
                      SL.Add('        else');
                      SL.Add(Format('          F%s.Add(T%s(ProtoBuf.readEnum));', [DelphiProp.PropertyName, Prop.PropType]));
                    end
                  else
                    SL.Add(Format('        F%s.Add(T%s(ProtoBuf.readEnum));', [DelphiProp.PropertyName, Prop.PropType]));
                end
              else
                SL.Add(Format('        F%s.AddFromBuf(ProtoBuf, makeTag(FieldNumber, WireType));', [DelphiProp.PropertyName]));
          end;
        SL.Add('        Result := True;');
        SL.Add('      end;');
      end;
    SL.Add('  end;');
    SL.Add('end;');
  end;

  procedure WriteSaveProc(ProtoMsg: TProtoBufMessage; SL: TStrings);
  var
    i: integer;
    Prop: TProtoBufProperty;
    DelphiProp: TDelphiProperty;
  begin
    SL.Add('');
    SL.Add(Format('procedure T%s.SaveFieldsToBuf(ProtoBuf: TProtoBufOutput);', [ProtoMsg.Name]));
    if MsgNeedConstructor(ProtoMsg, Proto) or MsgContainsRepeatedFields(ProtoMsg) then // avoid compiler hints
      begin
        SL.Add('var');
        if MsgNeedConstructor(ProtoMsg, Proto) then
          SL.Add('  tmpBuf: TProtoBufOutput;');
        if MsgContainsRepeatedFields(ProtoMsg) then
          SL.Add('  i: integer;');
      end;
    SL.Add('begin');
    SL.Add('  inherited;');
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);

        if not DelphiProp.IsList then
          begin
            if not DelphiProp.isComplex then
              SL.Add(Format('  ProtoBuf.write%s(%d, F%s);', [GetProtoBufMethodForScalarType(Prop), Prop.PropFieldNum, DelphiProp.PropertyName]))
            else
              if not DelphiProp.isObject then
                SL.Add(Format('  ProtoBuf.writeInt32(%d, integer(F%s));', [Prop.PropFieldNum, DelphiProp.PropertyName]))
              else
                begin
                  SL.Add('  tmpBuf:=TProtoBufOutput.Create;');
                  SL.Add('  try');
                  SL.Add(Format('    F%s.SaveToBuf(tmpBuf);', [DelphiProp.PropertyName]));
                  SL.Add(Format('    ProtoBuf.writeMessage(%d, tmpBuf);', [Prop.PropFieldNum]));
                  SL.Add('  finally');
                  SL.Add('    tmpBuf.Free;');
                  SL.Add('  end;');
                end;
          end
        else
          begin
            if not DelphiProp.isComplex then
              begin
                if PropertyIsPrimitiveNumericPacked(Prop) then
                  begin
                    SL.Add('  tmpBuf:=TProtoBufOutput.Create;');
                    SL.Add('  try');
                    SL.Add(Format('    for i := 0 to F%s.Count-1 do', [DelphiProp.PropertyName]));
                    SL.Add(Format('      tmpBuf.write%s(F%s[i]);', [GetProtoBufMethodForScalarType(Prop), DelphiProp.PropertyName]));
                    SL.Add(Format('    ProtoBuf.writeMessage(%d, tmpBuf);', [Prop.PropFieldNum]));
                    SL.Add('  finally');
                    SL.Add('    tmpBuf.Free;');
                    SL.Add('  end;');
                  end
                else
                  begin
                    SL.Add(Format('  for i := 0 to F%s.Count-1 do', [DelphiProp.PropertyName]));
                    SL.Add(Format('    ProtoBuf.write%s(%d, F%s[i]);', [GetProtoBufMethodForScalarType(Prop), Prop.PropFieldNum, DelphiProp.PropertyName]));
                  end;
              end
            else
              if not DelphiProp.isObject then
                begin
                  if Prop.PropOptions.Value['packed'] = 'true' then
                    begin
                      SL.Add('  tmpBuf:=TProtoBufOutput.Create;');
                      SL.Add('  try');
                      SL.Add(Format('    for i := 0 to F%s.Count-1 do', [DelphiProp.PropertyName]));
                      SL.Add(Format('      tmpBuf.writeRawVarint32(integer(F%s[i]));', [DelphiProp.PropertyName]));
                      SL.Add(Format('    ProtoBuf.writeMessage(%d, tmpBuf);', [Prop.PropFieldNum]));
                      SL.Add('  finally');
                      SL.Add('    tmpBuf.Free;');
                      SL.Add('  end;');
                    end
                  else
                    begin
                      SL.Add(Format('  for i := 0 to F%s.Count-1 do', [DelphiProp.PropertyName]));
                      SL.Add(Format('    ProtoBuf.writeInt32(%d, integer(F%s[i]));', [Prop.PropFieldNum, DelphiProp.PropertyName]));
                    end;
                end
              else
                SL.Add(Format('  F%s.SaveToBuf(ProtoBuf, %d);', [DelphiProp.PropertyName, Prop.PropFieldNum]));
          end;
      end;

    SL.Add('end;');
  end;

  procedure WriteMessageToSL(ProtoMsg: TProtoBufMessage; SL: TStrings);
  var
    bNeedConstructor: Boolean;
  begin
    if ProtoMsg.IsImported then
      Exit;
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
    if ProtoEnum.IsImported then
      Exit;

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
    s, sdefValue: string;
  begin
    if ProtoMsg.IsImported then
      Exit;
    if ProtoMsg.ExtendOf = '' then
      s := 'AbstractProtoBufClass'
    else
      s := ProtoMsg.ExtendOf;
    SL.Add(Format('  T%s = class(T%s)', [ProtoMsg.Name, s]));
    SL.Add('  strict private');
    for i := 0 to ProtoMsg.Count - 1 do
      begin
        Prop := ProtoMsg[i];
        ParsePropType(Prop, Proto, DelphiProp);
        s := Format('    F%s: %s;', [DelphiProp.PropertyName, DelphiProp.PropertyType]);
        SL.Add(s);
      end;
    SL.Add('  strict protected');
    SL.Add('    function LoadSingleFieldFromBuf(ProtoBuf: TProtoBufInput; FieldNumber: integer; WireType: integer): Boolean; override;');
    SL.Add('    procedure SaveFieldsToBuf(ProtoBuf: TProtoBufOutput); override;');

    SL.Add('  public');
    if MsgNeedConstructor(ProtoMsg, Proto) then
      begin
        SL.Add('    constructor Create; override;');
        SL.Add('    destructor Destroy; override;');
        SL.Add('');
      end;

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
  SL.Add('//        kami-soft 2016-2017');
  SL.Add('// ***********************************');
  SL.Add('uses');
  SL.Add('  System.SysUtils,');
  SL.Add('  System.Classes,');
  SL.Add('  System.Generics.Collections,');
  SL.Add('  pbInput,');
  SL.Add('  pbOutput,');
  SL.Add('  pbPublic,');
  if Proto.Imports.Count = 0 then
    SL.Add('  uAbstractProtoBufClasses;')
  else
    begin
      SL.Add('  uAbstractProtoBufClasses,');
      for i := 0 to Proto.Imports.Count - 2 do
        SL.Add('  ' + Proto.Imports[i] + ',');
      SL.Add('  ' + Proto.Imports[Proto.Imports.Count - 1] + ';');
    end;
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

procedure TProtoBufGenerator.Generate(const InputFile, OutputDir: string; Encoding: TEncoding);
var
  Proto: TProtoFile;
  SL: TStringList;
  iPos: integer;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(InputFile);
    Proto := TProtoFile.Create(nil);
    try
      Proto.FileName := InputFile;
      iPos := 1;
      Proto.ParseFromProto(SL.Text, iPos);
      Generate(Proto, OutputDir, Encoding);
    finally
      Proto.Free;
    end;
  finally
    SL.Free;
  end;
end;

end.
